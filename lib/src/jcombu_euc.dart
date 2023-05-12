import './euc_table.dart' as euc;

class _EucImplData {
  int leftBytes = 0;
  int lastCode = 0;

  void reset() {
    leftBytes = 0;
    lastCode = 0;
  }
}

List<int> _convertEucJpImpl(_EucImplData data, Iterable<int> eucCodes) {
  var ucl = List<int>.empty(growable: true);

  for (final c in eucCodes) {
    if (c < 0 || c > 0xff) {
      data.reset();
      continue;
    }
    if (data.lastCode == 0) {
      if (c < 0x80) {
        ucl.add(c);
      } else if (c == 0x8F) {
        // Three bytes char start
        data.lastCode = c << 16;
        data.leftBytes = 2;
      } else {
        // Two bytes char start
        data.lastCode = c << 8;
        data.leftBytes = 1;
      }
    } else {
      if (c < 0x80) {
        // In multibyte 2 or 3 byte, 8th bit is 1.
        // Clear and treat as 1 byte data.
        data.reset();
        ucl.add(c);
      } else {
        if (data.leftBytes == 2) {
          data.lastCode |= c << 8;
          data.leftBytes = 1;
        } else {
          final ecode = data.lastCode | c;
          final u = euc.eucTable[ecode];
          if (u != null) {
            ucl.add(u);
          } else {
            ucl.add(c);
          }
          data.reset();
        }
      }
    }
  }

  return ucl;
}

/// Convert EUC-JP to Dart String
String convertEucJp(Iterable<int> eucCodes) {
  var data = _EucImplData();

  final ucl = _convertEucJpImpl(data, eucCodes);

  return String.fromCharCodes(ucl);
}

/// Convert EUC-JP to Dart String (Stream)
Stream<String> convertEucJpStream(Stream<Iterable<int>> eucCodesStream) async* {
  var data = _EucImplData();

  await for (final eucCodes in eucCodesStream) {
    final ucl = _convertEucJpImpl(data, eucCodes);
    yield String.fromCharCodes(ucl);
  }
}
