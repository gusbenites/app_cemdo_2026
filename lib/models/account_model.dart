class Account {
  final int idcliente;
  final String razonSocial;

  Account({required this.idcliente, required this.razonSocial});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      idcliente: json['idcliente'],
      razonSocial: json['razon_social'],
    );
  }
}
