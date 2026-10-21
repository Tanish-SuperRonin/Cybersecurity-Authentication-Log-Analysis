# Measured full-dataset validation

The supplied CSV was inspected before implementation. It has header `timestamp,source_ip,user_id,status`, exactly **5,000** data rows, and only `FAILED` and `SUCCESS` status values. All rows conform to the expected four-field structure.

| Measure | Measured value |
| --- | ---: |
| FAILED records | 1,140 |
| SUCCESS records | 3,860 |
| Distinct source IPs | 121 |
| Sum expected from IP job | 1,140 |

The three deliberately repeated documentation-range IPs appear among the largest failure counts: `192.0.2.77` (37), `198.51.100.24` (35), and `203.0.113.10` (32). These are synthetic indicators for review, not evidence of real attacks.

## Expected hourly failed-event output

| Hour | Count | Hour | Count | Hour | Count |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 00 | 40 | 08 | 58 | 16 | 39 |
| 01 | 41 | 09 | 32 | 17 | 52 |
| 02 | 100 | 10 | 34 | 18 | 49 |
| 03 | 73 | 11 | 45 | 19 | 43 |
| 04 | 42 | 12 | 47 | 20 | 48 |
| 05 | 47 | 13 | 46 | 21 | 45 |
| 06 | 41 | 14 | 50 | 22 | 39 |
| 07 | 33 | 15 | 49 | 23 | 47 |

The hourly values sum to 1,140. They summarize hour-of-day across all dates, not a chronological time series.

