package edu.college.cyberlog;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/** Aggregates valid FAILED authentication events by source IP address. */
public class IpFailedLoginJob {
    public static class FailedIpMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
        private static final IntWritable ONE = new IntWritable(1);
        private final Text ip = new Text();

        public void map(LongWritable key, Text value, Context context)
                throws java.io.IOException, InterruptedException {
            AuthLogParser.Event event = AuthLogParser.parse(value.toString());
            if (event != null && "FAILED".equals(event.getStatus())) {
                ip.set(event.getSourceIp());
                context.write(ip, ONE);
            }
        }
    }

    public static class SumReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws java.io.IOException, InterruptedException {
            int total = 0;
            for (IntWritable value : values) total += value.get();
            context.write(key, new IntWritable(total));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: IpFailedLoginJob <input> <output>");
            System.exit(2);
        }
        Job job = Job.getInstance(new Configuration(), "failed logins by IP");
        job.setJarByClass(IpFailedLoginJob.class);
        job.setMapperClass(FailedIpMapper.class);
        job.setReducerClass(SumReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}

