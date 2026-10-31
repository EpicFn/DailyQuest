class DailyJob {
  final String date;
  final int jobId;
  final String jobName;
  final String categoryName;
  final bool isCompleted;

  DailyJob({
    required this.date,
    required this.jobId,
    required this.jobName,
    required this.categoryName,
    required this.isCompleted,
  });
}
