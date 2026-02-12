class Service {
  final int id;
  final String nombre;
  final String tipo;

  Service({required this.id, required this.nombre, required this.tipo});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(id: json['id'], nombre: json['nombre'], tipo: json['tipo']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'tipo': tipo};
  }
}
