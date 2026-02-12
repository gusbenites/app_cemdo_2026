class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final int? ultimoIdCliente;
  final bool isAdmin;
  final String? emailVerifiedAt; // New field

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.ultimoIdCliente,
    required this.isAdmin,
    this.emailVerifiedAt, // New field
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      ultimoIdCliente: json['ultimo_idcliente'],
      isAdmin: json['is_admin'] == 1,
      emailVerifiedAt: json['email_verified_at'], // New field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'ultimo_idcliente': ultimoIdCliente,
      'is_admin': isAdmin ? 1 : 0,
      'email_verified_at': emailVerifiedAt, // New field
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    int? ultimoIdCliente,
    bool? isAdmin,
    String? emailVerifiedAt, // New field
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      ultimoIdCliente: ultimoIdCliente ?? this.ultimoIdCliente,
      isAdmin: isAdmin ?? this.isAdmin,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt, // New field
    );
  }
}
