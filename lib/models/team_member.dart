class TeamMember {
  final int? id;
  final String name;
  final String role;
  final String email;
  final int colorValue; // avatar colour, stored as ARGB int

  const TeamMember({
    this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.colorValue,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'role': role,
        'email': email,
        'color': colorValue,
      };

  factory TeamMember.fromMap(Map<String, Object?> m) => TeamMember(
        id: m['id'] as int,
        name: m['name'] as String,
        role: m['role'] as String,
        email: m['email'] as String,
        colorValue: m['color'] as int,
      );
}
