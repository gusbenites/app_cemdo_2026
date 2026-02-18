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
      idsuministro: _parseInt(json['idsuministro']),
      nrosum: _parseInt(json['nrosum']),
      nroorden: _parseInt(json['nroorden']),
      direccion: json['direccion'] ?? '',
      localidad: json['localidad'] ?? '',
      estado: json['estado'] ?? '',
      estadoId: _parseInt(json['estado_id']),
      categoria: json['categoria'] ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
