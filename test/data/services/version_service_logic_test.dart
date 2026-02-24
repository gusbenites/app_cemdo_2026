import 'package:flutter_test/flutter_test.dart';

// Since _compareVersions is private in VersionService, we test the logic here
// which reflects the implementation in the service.
int compareVersions(String v1, String v2) {
  String cleanV1 = v1.split('-').first;
  String cleanV2 = v2.split('-').first;

  List<int> v1Parts = cleanV1
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
  List<int> v2Parts = cleanV2
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();

  int length = v1Parts.length > v2Parts.length
      ? v1Parts.length
      : v2Parts.length;

  for (int i = 0; i < length; i++) {
    int p1 = i < v1Parts.length ? v1Parts[i] : 0;
    int p2 = i < v2Parts.length ? v2Parts[i] : 0;

    if (p1 > p2) return 1;
    if (p1 < p2) return -1;
  }
  return 0;
}

void main() {
  group('Version Comparison Logic', () {
    test('should return 0 for equal versions', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0', '1.0.0'), 0);
    });

    test('should return 1 when v1 > v2', () {
      expect(compareVersions('2.0.0', '1.0.0'), 1);
      expect(compareVersions('1.1.0', '1.0.9'), 1);
      expect(compareVersions('1.0.1', '1.0.0'), 1);
    });

    test('should return -1 when v1 < v2', () {
      expect(compareVersions('1.0.0', '2.0.0'), -1);
      expect(compareVersions('1.0.9', '1.1.0'), -1);
      expect(compareVersions('1.0.0', '1.0.1'), -1);
    });

    test('should handle version suffixes like -dev', () {
      expect(compareVersions('1.0.0-dev', '1.0.0'), 0);
      expect(compareVersions('1.0.1-dev', '1.0.0'), 1);
      expect(compareVersions('1.0.0', '1.0.1-dev'), -1);
    });

    test('should handle malformed segments', () {
      expect(compareVersions('1.a.0', '1.0.0'), 0);
      expect(compareVersions('1.2.0', '1.b.0'), 1);
    });
  });
}
