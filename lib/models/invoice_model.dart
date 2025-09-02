class Invoice {
  final int idcbte;
  final int idsuministro;
  final String nroFactura;
  final String fechaVto;
  final String servicio;
  final String srvImporte;
  final String srvSaldo;
  final String estado;
  final bool isVencida;
  final int? anio;
  final int? nroper;
  final String? domicilioSumR1;
  final String? domicilioSumR2;

  Invoice({
    required this.idcbte,
    required this.idsuministro,
    required this.nroFactura,
    required this.fechaVto,
    required this.servicio,
    required this.srvImporte,
    required this.srvSaldo,
    required this.estado,
    required this.isVencida,
    this.anio,
    this.nroper,
    this.domicilioSumR1,
    this.domicilioSumR2,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      idcbte: json['idcbte'],
      idsuministro: json['idsuministro'],
      nroFactura: json['nro_factura'],
      fechaVto: json['fecha_vto'],
      servicio: json['servicio'],
      srvImporte: json['srv_importe'],
      srvSaldo: json['srv_saldo'],
      estado: json['estado'],
      isVencida: json['is_vencida'],
      anio: json['anio'],
      nroper: json['nroper'],
      domicilioSumR1: json['domicilio_sum_r1'],
      domicilioSumR2: json['domicilio_sum_r2'],
    );
  }
}