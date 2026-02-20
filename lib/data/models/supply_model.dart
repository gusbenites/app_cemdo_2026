class Supply {
  final int idsuministro;
  final String direccion;
  final String localidad;
  final String estado;
  final String categoria;

  Supply({
    required this.idsuministro,
    required this.direccion,
    required this.localidad,
    required this.estado,
    required this.categoria,
  });

  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      idsuministro: _parseInt(json['idsuministro']),
      direccion: json['domicilio'] ?? json['direccion'] ?? '',
      localidad: json['localidad'] ?? '',
      estado: json['estado'] ?? '',
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
      'domicilio': direccion,
      'localidad': localidad,
      'estado': estado,
      'categoria': categoria,
    };
  }
}

class Coordinates {
  final double? latitud;
  final double? longitud;

  Coordinates({this.latitud, this.longitud});

  factory Coordinates.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Coordinates();
    return Coordinates(
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }
}

class Meter {
  final String marca;
  final String modelo;
  final String numero;

  Meter({required this.marca, required this.modelo, required this.numero});

  factory Meter.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Meter(marca: '', modelo: '', numero: '');
    return Meter(
      marca:
          json['marca']?.toString() ?? json['marca_medidor']?.toString() ?? '',
      modelo:
          json['modelo']?.toString() ??
          json['modelo_medidor']?.toString() ??
          '',
      numero:
          (json['nro_serie'] ??
                  json['nroSerie'] ??
                  json['numero'] ??
                  json['serie'])
              ?.toString() ??
          '',
    );
  }
}

class ConsumptionData {
  final int anio;
  final int periodo;
  final double consumo;

  ConsumptionData({
    required this.anio,
    required this.periodo,
    required this.consumo,
  });

  factory ConsumptionData.fromJson(Map<String, dynamic> json) {
    return ConsumptionData(
      anio: json['anio'] ?? 0,
      periodo: json['periodo'] ?? 0,
      consumo: (json['consumo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FamilyMember {
  final int id;
  final String apellido;
  final String nombre;
  final String parentesco;
  final String sepelio;
  final String ambulancia;
  final String enfermeria;

  FamilyMember({
    required this.id,
    required this.apellido,
    required this.nombre,
    required this.parentesco,
    required this.sepelio,
    required this.ambulancia,
    required this.enfermeria,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? 0,
      apellido: json['apellido'] ?? '',
      nombre: json['nombre'] ?? '',
      parentesco: json['parentesco'] ?? '',
      sepelio: json['3010'] ?? '',
      ambulancia: json['3210'] ?? '',
      enfermeria: json['3310'] ?? '',
    );
  }
}

class EnabledServices {
  final bool sepelio;
  final bool ambulancia;
  final bool enfermeria;

  EnabledServices({
    required this.sepelio,
    required this.ambulancia,
    required this.enfermeria,
  });

  factory EnabledServices.fromJson(Map<String, dynamic>? json) {
    if (json == null)
      return EnabledServices(
        sepelio: false,
        ambulancia: false,
        enfermeria: false,
      );
    return EnabledServices(
      sepelio: json['sepelio'] == true,
      ambulancia: json['ambulancia'] == true,
      enfermeria: json['enfermeria'] == true,
    );
  }
}

class SupplyDetails extends Supply {
  final Coordinates? coordenadas;
  final Meter? medidor;
  final Map<String, List<ConsumptionData>>? consumos;
  final List<FamilyMember>? grupoFamiliar;
  final EnabledServices? habilitados;

  SupplyDetails({
    required super.idsuministro,
    required super.direccion,
    required super.localidad,
    required super.estado,
    required super.categoria,
    this.coordenadas,
    this.medidor,
    this.consumos,
    this.grupoFamiliar,
    this.habilitados,
  });

  factory SupplyDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ConsumptionData>>? consumosMap;
    if (json['consumos'] != null) {
      if (json['consumos'] is Map) {
        consumosMap = (json['consumos'] as Map<String, dynamic>).map((
          key,
          value,
        ) {
          return MapEntry(
            key,
            (value as List).map((i) => ConsumptionData.fromJson(i)).toList(),
          );
        });
      } else if (json['consumos'] is List) {
        final flatConsumos = (json['consumos'] as List)
            .expand((group) => group as List)
            .map((i) => ConsumptionData.fromJson(i as Map<String, dynamic>))
            .toList();

        consumosMap = {};
        for (var data in flatConsumos) {
          final year = data.anio.toString();
          if (year != '0') {
            consumosMap.putIfAbsent(year, () => []).add(data);
          }
        }
      } else {
        consumosMap = null;
      }
    } else {
      consumosMap = null;
    }

    return SupplyDetails(
      idsuministro: Supply._parseInt(json['idsuministro']),
      direccion: json['domicilio'] ?? '',
      localidad: json['localidad'] ?? '',
      estado: json['estado'] ?? '',
      categoria: json['categoria'] ?? '',
      coordenadas: Coordinates.fromJson(json['coordenadas']),
      medidor: Meter.fromJson(json['medidor']),
      consumos: consumosMap,
      grupoFamiliar: json['grupo_familiar'] != null
          ? (json['grupo_familiar'] as List)
                .map((i) => FamilyMember.fromJson(i))
                .toList()
          : null,
      habilitados: EnabledServices.fromJson(json['habilitados']),
    );
  }
}
