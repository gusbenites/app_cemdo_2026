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
}