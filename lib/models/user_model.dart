class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final int? ultimoIdCliente;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.ultimoIdCliente,
    required this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      ultimoIdCliente: json['ultimo_idcliente'],
      isAdmin: json['is_admin'] == 1,
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
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    int? ultimoIdCliente,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      ultimoIdCliente: ultimoIdCliente ?? this.ultimoIdCliente,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}