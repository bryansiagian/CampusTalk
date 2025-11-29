class Prodi {
  final int id;
  final String name;

  Prodi({required this.id, required this.name});

  factory Prodi.fromJson(Map<String, dynamic> json) {
    return Prodi(
      id: json['id'],
      name: json['name'],
    );
  }

  // --- TAMBAHKAN INI (Equality Override) ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prodi && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}