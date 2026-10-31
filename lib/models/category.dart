class QuestCategory {
  final int id;
  String name;
  final bool isDefault;

  QuestCategory({
    required this.id,
    required this.name,
    this.isDefault = false,
  });
}