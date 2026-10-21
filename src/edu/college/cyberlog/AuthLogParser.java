package edu.college.cyberlog;

/** Parses the simple four-column authentication-log CSV used by this project. */
public final class AuthLogParser {
    private AuthLogParser() { }

    public static Event parse(String line) {
        if (line == null || line.trim().length() == 0 || line.startsWith("timestamp,")) {
            return null;
        }
        String[] fields = line.split(",", -1);
        if (fields.length != 4) {
            return null;
        }
        String timestamp = fields[0].trim();
        String sourceIp = fields[1].trim();
        String userId = fields[2].trim();
        String status = fields[3].trim();
        if (!timestamp.matches("\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}")
                || sourceIp.length() == 0 || userId.length() == 0
                || !("SUCCESS".equals(status) || "FAILED".equals(status))) {
            return null;
        }
        return new Event(timestamp, sourceIp, userId, status);
    }

    public static final class Event {
        private final String timestamp;
        private final String sourceIp;
        private final String userId;
        private final String status;

        private Event(String timestamp, String sourceIp, String userId, String status) {
            this.timestamp = timestamp;
            this.sourceIp = sourceIp;
            this.userId = userId;
            this.status = status;
        }
        public String getSourceIp() { return sourceIp; }
        public String getUserId() { return userId; }
        public String getStatus() { return status; }
        public String getHour() { return timestamp.substring(11, 13); }
    }
}

