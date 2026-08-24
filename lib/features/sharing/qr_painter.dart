import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// A QR code for the pairing screen.
///
/// The encoder is the `qr` package rather than something hand-rolled. An earlier
/// version here was hand-written to avoid a dependency; cross-checking its
/// output against a reference implementation showed 153 of 1089 modules wrong,
/// and a QR that scans to the wrong address is worse than no QR at all. The test
/// that caught it still runs against this.
class PairingQr {
  PairingQr._(this.size, this._modules);

  /// Side length in modules.
  final int size;
  final List<List<bool>> _modules;

  bool isDark(int row, int column) => _modules[row][column];

  /// Encodes [text], or returns null when it does not fit.
  ///
  /// Error correction level L: the pairing code is shown on screen at a
  /// comfortable size and scanned from a few centimetres away, so the capacity
  /// is worth more than the redundancy.
  static PairingQr? encode(String text) {
    try {
      final code = QrCode(
        payload: QrPayload.fromString(text),
        errorCorrectLevel: QrErrorCorrectLevel.low,
      );
      final image = QrImage(code);

      final moduleCount = image.moduleCount;
      return PairingQr._(
        moduleCount,
        List.generate(
          moduleCount,
          (row) =>
              List.generate(moduleCount, (column) => image.isDark(row, column)),
        ),
      );
    } on Object {
      // Too long for any version, or an encoding the package refuses.
      return null;
    }
  }
}

/// Paints a [PairingQr] as black modules on white.
class QrPainter extends CustomPainter {
  const QrPainter(this.code, {this.quietZone = 2});

  final PairingQr code;

  /// The white margin. Without it many scanners will not lock on.
  final int quietZone;

  @override
  void paint(Canvas canvas, Size size) {
    final total = code.size + quietZone * 2;
    final module = min(size.width, size.height) / total;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final foreground = Paint()..color = const Color(0xFF000000);
    for (var row = 0; row < code.size; row++) {
      for (var column = 0; column < code.size; column++) {
        if (!code.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (column + quietZone) * module,
            (row + quietZone) * module,
            // A hair of overlap, so seams do not show as white lines.
            module + 0.5,
            module + 0.5,
          ),
          foreground,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter oldDelegate) => oldDelegate.code != code;
}
