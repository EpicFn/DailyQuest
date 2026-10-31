class QuestJob {
  final int id;
  String name;
  int categoryId;
  bool isActive;

  QuestJob({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isActive = true,
  });
}