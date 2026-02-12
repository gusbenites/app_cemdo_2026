class Supply {
  final int id;
  final String nroSuministro;
  final String nombreServicio;
  final String direccion;
  final String estado;
  final int idServicio;

  Supply({
    required this.id,
    required this.nroSuministro,
    required this.nombreServicio,
    required this.direccion,
    required this.estado,
    required this.idServicio,
  });

  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      id: json['id'],
      nroSuministro: json['nro_suministro'],
      nombreServicio: json['nombre_servicio'],
      direccion: json['direccion'],
      estado: json['estado'],
      idServicio: json['id_servicio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nro_suministro': nroSuministro,
      'nombre_servicio': nombreServicio,
      'direccion': direccion,
      'estado': estado,
      'id_servicio': idServicio,
    };
  }
}
