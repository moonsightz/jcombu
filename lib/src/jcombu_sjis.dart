import './sjis_table.dart' as sjis;

class _SjisImplData {
  int lastCode = 0;

  void reset() {
    lastCode = 0;
  }
}

List<int> _convertShiftJisImpl(_SjisImplData data, Iterable<int> sjisCodes) {
  var ucl = List<int>.empty(growable: true);

  for (final c in sjisCodes) {
    if (c < 0 || c > 0xff) {
      data.reset();
      continue;
    }
    if (data.lastCode == 0) {
      if (c < 0x80) {
        ucl.add(c);
      } else if ((c >= 0xa1 && c < 0xe0)) {
        final u = sjis.sjisOneByteTable[c];
        if (u != null) {
          ucl.add(u);
        }
      } else if ((c >= 0x81 && c < 0xa0) || (c >= 0xe0 && c < 0xf0)) {
        // Two bytes char start
        data.lastCode = c;
      } else {
        ucl.add(c);
      }
    } else {
      final scode = (data.lastCode << 8) | c;
      final u = sjis.sjisTwoBytesTable[scode];
      if (u != null) {
        ucl.add(u);
      } else {
        // If valid as 7-bit code, push.
        if (c < 0x80) {
          ucl.add(c);
        } else {
          final u = sjis.sjisOneByteTable[c];
          if (u != null) {
            ucl.add(u);
          }
        }
      }
      data.reset();
    }
  }

  return ucl;
}

/// Convert Shift-JIS to Dart String
String convertShiftJis(Iterable<int> sjisCodes) {
  var data = _SjisImplData();

  final ucl = _convertShiftJisImpl(data, sjisCodes);

  return String.fromCharCodes(ucl);
}

/// Convert Shift-JIS to Dart String (Stream)
Stream<String> convertShiftJisStream(
    Stream<Iterable<int>> sjisCodesStream) async* {
  var data = _SjisImplData();

  await for (var sjisCodes in sjisCodesStream) {
    final ucl = _convertShiftJisImpl(data, sjisCodes);
    yield String.fromCharCodes(ucl);
  }
}
