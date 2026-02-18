import 'package:flutter_test/flutter_test.dart';
import 'package:app_cemdo/data/models/supply_model.dart';

void main() {
  group('Supply.fromJson', () {
    test('should parse correctly when all fields are correct types', () {
      final json = {
        'idsuministro': 1,
        'nrosum': 123,
        'nroorden': 456,
        'direccion': 'Calle 123',
        'localidad': 'Villa Dolores',
        'estado': 'Activo',
        'estado_id': 1,
        'categoria': 'Residencial',
      };

      final supply = Supply.fromJson(json);

      expect(supply.idsuministro, 1);
      expect(supply.nrosum, 123);
      expect(supply.nroorden, 456);
      expect(supply.estadoId, 1);
    });

    test('should parse correctly when numeric fields are strings', () {
      final json = {
        'idsuministro': '1',
        'nrosum': '123',
        'nroorden': '456',
        'direccion': 'Calle 123',
        'localidad': 'Villa Dolores',
        'estado': 'Activo',
        'estado_id': '1',
        'categoria': 'Residencial',
      };

      final supply = Supply.fromJson(json);

      expect(supply.idsuministro, 1);
      expect(supply.nrosum, 123);
      expect(supply.nroorden, 456);
      expect(supply.estadoId, 1);
    });

    test('should handle null or missing fields gracefully', () {
      final json = {'idsuministro': null, 'direccion': null};

      final supply = Supply.fromJson(json as Map<String, dynamic>);

      expect(supply.idsuministro, 0);
      expect(supply.direccion, '');
      expect(supply.nrosum, 0);
    });
  });
}
