class Supply {
  final int idsuministro;
  final int nrosum;
  final int nroorden;
  final String direccion;
  final String localidad;
  final String estado;
  final int estadoId;
  final String categoria;

  Supply({
    required this.idsuministro,
    required this.nrosum,
    required this.nroorden,
    required this.direccion,
    required this.localidad,
    required this.estado,
    required this.estadoId,
    required this.categoria,
  });

  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      idsuministro: json['idsuministro'],
      nrosum: json['nrosum'],
      nroorden: json['nroorden'],
      direccion: json['direccion'],
      localidad: json['localidad'],
      estado: json['estado'],
      estadoId: json['estado_id'],
      categoria: json['categoria'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idsuministro': idsuministro,
      'nrosum': nrosum,
      'nroorden': nroorden,
      'direccion': direccion,
      'localidad': localidad,
      'estado': estado,
      'estado_id': estadoId,
      'categoria': categoria,
    };
  }
}
