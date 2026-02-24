import 'package:flutter_test/flutter_test.dart';
import 'package:app_cemdo/data/models/supply_model.dart';

void main() {
  group('Supply.fromJson', () {
    test('should parse correctly when all fields are correct types', () {
      final json = {
        'idsuministro': 1,
        'domicilio': 'Calle 123',
        'localidad': 'Villa Dolores',
        'estado': 'Activo',
        'categoria': 'Residencial',
      };

      final supply = Supply.fromJson(json);

      expect(supply.idsuministro, 1);
      expect(supply.direccion, 'Calle 123');
      expect(supply.localidad, 'Villa Dolores');
      expect(supply.estado, 'Activo');
      expect(supply.categoria, 'Residencial');
    });

    test('should parse correctly when numeric fields are strings', () {
      final json = {
        'idsuministro': '1',
        'domicilio': 'Calle 123',
        'localidad': 'Villa Dolores',
        'estado': 'Activo',
        'categoria': 'Residencial',
      };

      final supply = Supply.fromJson(json);

      expect(supply.idsuministro, 1);
      expect(supply.direccion, 'Calle 123');
    });

    test('should handle null or missing fields gracefully', () {
      final json = {'idsuministro': null, 'domicilio': null};

      final supply = Supply.fromJson(json as Map<String, dynamic>);

      expect(supply.idsuministro, 0);
      expect(supply.direccion, '');
    });

    test('should use direccion field if domicilio is missing', () {
      final json = {'idsuministro': 1, 'direccion': 'Calle 456'};

      final supply = Supply.fromJson(json);

      expect(supply.direccion, 'Calle 456');
    });
  });
}
