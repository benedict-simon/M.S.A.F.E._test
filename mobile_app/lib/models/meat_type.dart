class MeatType {
  final int id;
  final String name;

  const MeatType({required this.id, required this.name});

  factory MeatType.fromRow(Map<String, dynamic> row) => MeatType(
        id: (row['meat_type_id'] as num).toInt(),
        name: (row['name'] as String?)?.trim() ?? '',
      );

  String get label => name;

  String get subtitle {
    switch (name.toLowerCase().trim()) {
      case 'pork':
        return 'Chops, belly, ground pork';
      case 'beef':
        return 'Steak, ground beef, cuts';
      case 'chicken':
      case 'poultry':
        return 'Breast, thigh, whole cuts';
      case 'fish':
      case 'seafood':
        return 'Fillets, whole fish, seafood';
      default:
        return 'Fresh and cooked cuts';
    }
  }

  String get apiValue => name.toLowerCase();

  @override
  bool operator ==(Object other) => other is MeatType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
