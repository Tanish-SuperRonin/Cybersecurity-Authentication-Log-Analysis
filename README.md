# Cybersecurity Authentication Log Analysis with Java Hadoop MapReduce

An academic mini-project that identifies repeated **failed** authentication events from a synthetic CSV dataset. It uses Java and Hadoop MapReduce only: no Spark, Python processing, web application, or machine-learning component.

Flagged addresses are review candidates, **not confirmed attackers**. The provided data is synthetic and contains controlled repeated failures for educational testing.

## What it produces

1. Failed-login total for every source IP (mandatory).
2. Failed-login total for each hour of day, `00`–`23` (mandatory).
3. A threshold report marking each IP `FLAGGED` when its count is at least the configured threshold (mandatory).
4. Failed-login total for each user ID (optional, included).

## Dataset inspection

The supplied `cybersecurity_auth_logs_5000.csv` was inspected before implementation:

| Property | Result |
| --- | --- |
| Header/schema | `timestamp,source_ip,user_id,status` |
| Data rows | 5,000 |
| Timestamp format | `yyyy-MM-dd HH:mm:ss` |
| Status values | `FAILED`, `SUCCESS` |
| FAILED / SUCCESS records | 1,140 / 3,860 |

Detailed measured outputs, including all hourly expected totals, are in [docs/VALIDATION.md](docs/VALIDATION.md). The parser accepts only four-field records with a valid timestamp, non-empty IP/user, and one of the two expected status values. Headers and malformed records are safely ignored.

## Architecture

```text
CSV in local filesystem
        | hdfs dfs -put
        v
HDFS input/auth_logs.csv
        |
        +--> IP Mapper: FAILED -> (source_ip, 1) --> shuffle/sort --> sum reducer --> HDFS ip-counts
        |
        +--> Hour Mapper: FAILED -> (hour, 1)      --> shuffle/sort --> sum reducer --> HDFS hourly-counts
        |
        +--> Optional user Mapper: FAILED -> (user_id, 1) -> sum reducer --> HDFS user-counts

HDFS ip-counts --> ThresholdReport (threshold >= 5 by default) --> HDFS review TSV
```

HDFS stores the input and outputs across the cluster. Each mapper parses records and emits a key plus `1` only for failed events. Hadoop shuffle and sort groups equal keys, then reducers sum their values. The hourly job is an **hour-of-day summary** over all dates; it is not a chronological timeline.

## Project layout

```text
src/edu/college/cyberlog/  Java jobs and parser
test/                     Small fixture and manually verified expected outputs
data/                     Put the supplied full CSV here before upload
docs/VALIDATION.md        Measured full-dataset validation values
build/                    Created during compilation (ignored)
dist/                     Generated JAR (ignored)
```

## Build on the Cloudera VM

Run the following from the directory containing this README. These commands intentionally obtain the classpath from the Hadoop installation instead of assuming a Hadoop version or path.

```bash
java -version
hadoop version
mkdir -p build/classes dist data
# Copy the supplied CSV into data/ if it is not already there.
cp /path/to/cybersecurity_auth_logs_5000.csv data/
javac -classpath "$(hadoop classpath)" -d build/classes $(find src -name '*.java')
jar -cvf dist/cyberlog-analysis.jar -C build/classes .
jar -tf dist/cyberlog-analysis.jar
```

The final command should list classes under `edu/college/cyberlog/`. If `hadoop classpath` is unavailable in an older installation, use that installation's documented Hadoop common and MapReduce JAR classpath instead.

## HDFS ingestion and mandatory runs

Start HDFS/YARN by the normal Cloudera VM method first if they are not already running. Use a new HDFS output directory for every rerun; never remove the input data.

```bash
hdfs dfs -mkdir -p /user/$USER/cyberlog/input
hdfs dfs -put -f data/cybersecurity_auth_logs_5000.csv /user/$USER/cyberlog/input/
hdfs dfs -ls /user/$USER/cyberlog/input
hdfs dfs -head /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv

hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.IpFailedLoginJob \
  /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv \
  /user/$USER/cyberlog/output/ip-counts-run1
hdfs dfs -cat /user/$USER/cyberlog/output/ip-counts-run1/part-r-00000

hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.HourlyFailedLoginJob \
  /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv \
  /user/$USER/cyberlog/output/hourly-counts-run1
hdfs dfs -cat /user/$USER/cyberlog/output/hourly-counts-run1/part-r-00000
```

The IP output is tab-separated `source_ip<TAB>failed_login_count`. The hourly output is tab-separated `hour<TAB>failed_login_count`. With the supplied file, the sum of IP counts and the sum of hourly counts must each be **1,140**.

## Threshold review report

The third argument is configurable. The required threshold is 5; the output is a TSV file in HDFS and includes all observed failed IPs, classified as `FLAGGED` or `NOT_FLAGGED`.

```bash
hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.ThresholdReport \
  /user/$USER/cyberlog/output/ip-counts-run1 \
  /user/$USER/cyberlog/output/ip-review-threshold-5.tsv 5
hdfs dfs -cat /user/$USER/cyberlog/output/ip-review-threshold-5.tsv
hdfs dfs -get /user/$USER/cyberlog/output/ip-review-threshold-5.tsv ./ip-review-threshold-5.tsv
```

Change only the last number to use another positive threshold, and choose a new report file name when rerunning.

## Optional user analysis

```bash
hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.UserFailedLoginJob \
  /user/$USER/cyberlog/input/cybersecurity_auth_logs_5000.csv \
  /user/$USER/cyberlog/output/user-counts-run1
hdfs dfs -cat /user/$USER/cyberlog/output/user-counts-run1/part-r-00000
```

## Test and validation procedure

The test fixture includes five failed events from `198.51.100.10`, four from `203.0.113.20`, one successful event, and a malformed row. It therefore proves successful events are excluded, repeated failures aggregate, exactly five is flagged, four is not flagged, malformed input does not terminate a job, and hour totals are correct.

```bash
hdfs dfs -mkdir -p /user/$USER/cyberlog/test-input
hdfs dfs -put -f test/auth_log_test.csv /user/$USER/cyberlog/test-input/
hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.IpFailedLoginJob \
  /user/$USER/cyberlog/test-input/auth_log_test.csv \
  /user/$USER/cyberlog/output/test-ip-run1
hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.HourlyFailedLoginJob \
  /user/$USER/cyberlog/test-input/auth_log_test.csv \
  /user/$USER/cyberlog/output/test-hourly-run1
hadoop jar dist/cyberlog-analysis.jar edu.college.cyberlog.ThresholdReport \
  /user/$USER/cyberlog/output/test-ip-run1 \
  /user/$USER/cyberlog/output/test-review-threshold-5.tsv 5
hdfs dfs -cat /user/$USER/cyberlog/output/test-ip-run1/part-r-00000
hdfs dfs -cat /user/$USER/cyberlog/output/test-hourly-run1/part-r-00000
hdfs dfs -cat /user/$USER/cyberlog/output/test-review-threshold-5.tsv
```

Compare these with the three files under `test/`. For the full dataset, verify independently:

```bash
hdfs dfs -cat /user/$USER/cyberlog/output/ip-counts-run1/part-r-00000 | awk -F '\t' '{sum += $2} END {print sum}'
hdfs dfs -cat /user/$USER/cyberlog/output/hourly-counts-run1/part-r-00000 | awk -F '\t' '{sum += $2} END {print sum}'
```

Both commands must print `1140`. This validates that successful records were not included and that two independent aggregations account for the same valid `FAILED` events.

## Viva notes, limitations, and future work

This project detects a simple frequency pattern: count failed logins by IP and flag counts at or above a review threshold. It does not establish malicious intent, account compromise, IP ownership, or attack chronology. The CSV parser is deliberately simple because the supplied data has no quoted commas. Future work could use a production CSV parser, add date/IP/user correlation windows, configurable formats, counters for malformed rows, SIEM enrichment, and alerting with analyst review.

