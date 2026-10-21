package edu.college.cyberlog;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/** Converts the IP aggregation output into a configurable review report in HDFS. */
public class ThresholdReport extends Configured implements Tool {
    public int run(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: ThresholdReport <ip-count-output-dir> <report-file> <threshold>");
            return 2;
        }
        int threshold;
        try { threshold = Integer.parseInt(args[2]); }
        catch (NumberFormatException e) { System.err.println("Threshold must be an integer."); return 2; }
        if (threshold < 1) { System.err.println("Threshold must be at least 1."); return 2; }

        Configuration conf = getConf();
        Path inputDirectory = new Path(args[0]);
        Path report = new Path(args[1]);
        FileSystem fs = report.getFileSystem(conf);
        if (fs.exists(report)) { System.err.println("Report already exists: " + report); return 1; }

        FSDataOutputStream outputStream = fs.create(report);
        BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(outputStream, "UTF-8"));
        try {
            writer.write("source_ip\tfailed_login_count\tflag_status\n");
            FileSystem inputFs = inputDirectory.getFileSystem(conf);
            for (FileStatus status : inputFs.listStatus(inputDirectory)) {
                Path part = status.getPath();
                if (!status.isFile() || !part.getName().startsWith("part-")) continue;
                FSDataInputStream inputStream = inputFs.open(part);
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"));
                try {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        String[] pieces = line.split("\\t", -1);
                        if (pieces.length != 2) continue;
                        try {
                            int count = Integer.parseInt(pieces[1]);
                            writer.write(pieces[0] + "\t" + count + "\t"
                                    + (count >= threshold ? "FLAGGED" : "NOT_FLAGGED") + "\n");
                        } catch (NumberFormatException ignored) { }
                    }
                } finally { reader.close(); }
            }
        } finally { writer.close(); }
        return 0;
    }
    public static void main(String[] args) throws Exception {
        System.exit(ToolRunner.run(new Configuration(), new ThresholdReport(), args));
    }
}

