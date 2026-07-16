class Customer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.createdAt,
  });

  Customer copyWith({String? name, String? phone, String? address}) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'created_at': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String,
        address: m['address'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
