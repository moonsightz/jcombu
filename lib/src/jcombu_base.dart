import './sjis_table.dart' as sjis;
import './euc_table.dart' as euc;
import './jis_table.dart' as jis;

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

/// Convert Shift-JIS to Dart String (Stream)
Stream<String> convertEucJpStream(Stream<Iterable<int>> eucCodesStream) async* {
  var data = _EucImplData();

  await for (var eucCodes in eucCodesStream) {
    final ucl = _convertEucJpImpl(data, eucCodes);
    yield String.fromCharCodes(ucl);
  }
}

// Camel case is difficult to read.
enum _JisMode {
  ascii,
  jis_x_6220,
  jis_c_6226,
  jis_x_0208,
  jis_x_0212,
  jis_x_0213_2000_1,
  jis_x_0213_2000_2,
  jis_x_0213_2004_1,
}

enum _JisEscapeMode {
  modeNone,
  modeEsc,
  mode28,
  mode24,
  mode2428,
}

class _JisImplData {
  var mode = _JisMode.ascii;
  var escMode = _JisEscapeMode.modeNone;
  int lastCode = 0;

  void reset() {
    lastCode = 0;
    escMode = _JisEscapeMode.modeNone;
  }

  void changeMode(_JisMode mode) {
    this.mode = mode;
    reset();
  }
}

List<int> _convertJisImpl(_JisImplData data, Iterable<int> jisCodes) {
  const ESC = 0x1b;
  var ucl = List<int>.empty(growable: true); // Unicode Codepoint List

  for (final c in jisCodes) {
    if (c < 0 || c > 0xff) {
      data.reset();
      continue;
    }

    switch (data.escMode) {
      case _JisEscapeMode.modeNone:
        switch (c) {
          case ESC:
            data.escMode = _JisEscapeMode.modeEsc;
            break;
          default:
            final u = _convertJisImplChar(data, c);
            if (u != null) {
              ucl.add(u);
            }
            break;
        }
        break;
      case _JisEscapeMode.modeEsc:
        switch (c) {
          case 0x28:
            data.escMode = _JisEscapeMode.mode28;
            break;
          case 0x24:
            data.escMode = _JisEscapeMode.mode24;
            break;
          default:
            final u0 = _convertJisImplChar(data, ESC);
            if (u0 != null) {
              ucl.add(u0);
            }
            final u1 = _convertJisImplChar(data, c);
            if (u1 != null) {
              ucl.add(u1);
            }
            data.escMode = _JisEscapeMode.modeNone;
            break;
        }
        break;
      case _JisEscapeMode.mode28:
        switch (c) {
          case 0x42:
            data.changeMode(_JisMode.ascii);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x4a:
            data.changeMode(_JisMode.jis_x_6220);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          default:
            final u0 = _convertJisImplChar(data, ESC);
            if (u0 != null) {
              ucl.add(u0);
            }
            final u1 = _convertJisImplChar(data, 0x28);
            if (u1 != null) {
              ucl.add(u1);
            }
            final u2 = _convertJisImplChar(data, c);
            if (u2 != null) {
              ucl.add(u2);
            }
            data.escMode = _JisEscapeMode.modeNone;
            break;
        }
        break;
      case _JisEscapeMode.mode24:
        switch (c) {
          case 0x40:
            data.changeMode(_JisMode.jis_c_6226);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x42:
            data.changeMode(_JisMode.jis_x_0208);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x28:
            data.escMode = _JisEscapeMode.mode2428;
            break;
          default:
            final u0 = _convertJisImplChar(data, ESC);
            if (u0 != null) {
              ucl.add(u0);
            }
            final u1 = _convertJisImplChar(data, 0x24);
            if (u1 != null) {
              ucl.add(u1);
            }
            final u2 = _convertJisImplChar(data, c);
            if (u2 != null) {
              ucl.add(u2);
            }
            data.escMode = _JisEscapeMode.modeNone;
            break;
        }
        break;
      case _JisEscapeMode.mode2428:
        switch (c) {
          case 0x44:
            data.changeMode(_JisMode.jis_x_0212);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x4f:
            data.changeMode(_JisMode.jis_x_0213_2000_1);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x50:
            data.changeMode(_JisMode.jis_x_0213_2000_2);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          case 0x51:
            data.changeMode(_JisMode.jis_x_0213_2004_1);
            data.escMode = _JisEscapeMode.modeNone;
            break;
          default:
            final u0 = _convertJisImplChar(data, ESC);
            if (u0 != null) {
              ucl.add(u0);
            }
            final u1 = _convertJisImplChar(data, 0x24);
            if (u1 != null) {
              ucl.add(u1);
            }
            final u2 = _convertJisImplChar(data, 0x28);
            if (u2 != null) {
              ucl.add(u2);
            }
            final u3 = _convertJisImplChar(data, c);
            if (u3 != null) {
              ucl.add(u3);
            }
            data.escMode = _JisEscapeMode.modeNone;
            break;
        }
        break;
      default:
        final u0 = _convertJisImplChar(data, ESC);
        if (u0 != null) {
          ucl.add(u0);
        }
        final u1 = _convertJisImplChar(data, c);
        if (u1 != null) {
          ucl.add(u1);
        }
        data.escMode = _JisEscapeMode.modeNone;
        break;
    }
  }

  return ucl;
}

int? _convertJisImplChar(_JisImplData data, int c) {
  int? r;
  switch (data.mode) {
    case _JisMode.ascii:
      r = c;
      break;
    case _JisMode.jis_x_6220:
      r = jis.iso2022_Jis_X_6220_Table[c];
      break;
    case _JisMode.jis_c_6226:
      r = _convertJisImplCharTwoBytes(data, c, jis.iso2022_Jis_C_6226_Table);
      break;
    case _JisMode.jis_x_0208:
      r = _convertJisImplCharTwoBytes(data, c, jis.iso2022_Jis_X_0208_Table);
      break;
    case _JisMode.jis_x_0212:
      r = _convertJisImplCharTwoBytes(data, c, jis.iso2022_Jis_X_0212_Table);
      break;
    case _JisMode.jis_x_0213_2000_1:
      r = _convertJisImplCharTwoBytes(
          data, c, jis.iso2022_Jis_X_0213_2000_1_Table);
      break;
    case _JisMode.jis_x_0213_2000_2:
      r = _convertJisImplCharTwoBytes(
          data, c, jis.iso2022_Jis_X_0213_2000_2_Table);
      break;
    case _JisMode.jis_x_0213_2004_1:
      r = _convertJisImplCharTwoBytes(
          data, c, jis.iso2022_Jis_X_0213_2004_1_Table);
      break;
    default:
      // Behave as ASCII.
      r = c;
      break;
  }

  return r;
}

int? _convertJisImplCharTwoBytes(_JisImplData data, int c, Map table) {
  int? r;
  if (data.lastCode == 0x00) {
    data.lastCode = c;
  } else {
    final code = (data.lastCode << 8) | c;
    final u = table[code];
    r = u;
    data.lastCode = 0;
  }

  return r;
}

/// Convert JIS(ISO-2022-JP) to Dart String
String convertJis(Iterable<int> jisCodes) {
  var data = _JisImplData();

  final ucl = _convertJisImpl(data, jisCodes);

  return String.fromCharCodes(ucl);
}

/// Convert JIS(ISO-2022-JP) to Dart String (Stream)
Stream<String> convertJisStream(Stream<Iterable<int>> jisCodesStream) async* {
  var data = _JisImplData();

  await for (var jisCodes in jisCodesStream) {
    final ucl = _convertJisImpl(data, jisCodes);
    yield String.fromCharCodes(ucl);
  }
}
