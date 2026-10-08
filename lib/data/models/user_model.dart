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
    final id = _asInt(json['id']);
    final name = _asString(json['name']);
    final email = _asString(json['email']);

    if (id == null || name == null || email == null) {
      // Campos obligatorios ausentes o con un tipo inesperado: mejor fallar
      // con un mensaje claro que guardar una sesión inconsistente.
      throw const FormatException(
        'Respuesta de usuario inválida: faltan "id", "name" o "email".',
      );
    }

    return User(
      id: id,
      name: name,
      email: email,
      avatar: _asString(json['avatar']),
      ultimoIdCliente: _asInt(json['ultimo_idcliente']),
      isAdmin: json['is_admin'] == 1,
      emailVerifiedAt: _asString(json['email_verified_at']), // New field
    );
  }

  /// Convierte de forma segura a [int]. Devuelve `null` si el valor no es
  /// numérico (por ejemplo, si el backend cambió el tipo del campo).
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Convierte de forma segura a [String]. Devuelve `null` si el valor es un
  /// mapa o una lista, en lugar de lanzar `TypeError`.
  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
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
