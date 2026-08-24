import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/features/sharing/qr_painter.dart';

void main() {
  const payload = 'http://popo:kt8qy87km6@192.168.43.1:8888';

  test('encodes a pairing URL', () {
    final code = PairingQr.encode(payload);

    expect(code, isNotNull);
    expect(code!.size, greaterThanOrEqualTo(21));

    // Finder patterns: solid ring, light gap, dark centre, in three corners.
    final last = code.size - 7;
    for (final (row, column) in [(0, 0), (0, last), (last, 0)]) {
      expect(code.isDark(row, column), isTrue);
      expect(code.isDark(row + 1, column + 1), isFalse);
      expect(code.isDark(row + 3, column + 3), isTrue);
    }
  });

  test('exports the matrix so a real decoder can check it', () {
    final code = PairingQr.encode(payload)!;
    final matrix = [
      for (var row = 0; row < code.size; row++)
        [
          for (var column = 0; column < code.size; column++)
            code.isDark(row, column) ? 1 : 0,
        ],
    ];

    Directory('build').createSync(recursive: true);
    File('build/qr_matrix.json')
        .writeAsStringSync(jsonEncode({'payload': payload, 'matrix': matrix}));

    expect(matrix, hasLength(code.size));
  });

  test('a payload too long for any version returns null, never a wrong code',
      () {
    expect(PairingQr.encode('x' * 8000), isNull);
  });
}
