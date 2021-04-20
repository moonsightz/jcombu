import 'package:jcombu/jcombu.dart' as jcombu;
import 'package:test/test.dart';
import 'dart:io' as io;

void main() {
  group('Shift-JIS', () {
    setUp(() {});

    test('Null test', () {
      expect(jcombu.convertShiftJis([0x00]), '\x00');
    });

    test('Backslash test', () {
      expect(jcombu.convertShiftJis([0x5c]), '\x5c');
    });

    test('Tilde test', () {
      expect(jcombu.convertShiftJis([0x7e]), '\x7e');
    });

    test('Basic test', () {
      final f = io.File('./test/basic.sjis').readAsBytesSync();
      expect(jcombu.convertShiftJis(f), 'Englishと日本語testsです。半角ｶﾅ。');
    });

    test('Future test', () async {
      final f = io.File('./test/basic.sjis').readAsBytes();
      final s = await f.then((sjisCodes) {
        return jcombu.convertShiftJis(sjisCodes);
      });
      expect(s, 'Englishと日本語testsです。半角ｶﾅ。');
    });

    test('Stream test', () async* {
      final file = io.File('./test/basic.sjis').openRead();
      final s = jcombu.convertShiftJisStream(file);
      expect(s, 'Englishと日本語testsです。半角ｶﾅ。');
    });

    test('Long stream test', () async* {
      final file = io.File('./test/constitution.sjis').openRead();
      final s = jcombu.convertShiftJisStream(file);
      final r = io.File('./test/constitution.utf8').readAsStringSync();
      expect(s, r);
    });
  });

  group('EUC-JP', () {
    setUp(() {});

    test('Null test', () {
      expect(jcombu.convertEucJp([0x00]), '\x00');
    });

    test('Basic test', () {
      final f = io.File('./test/basic.euc').readAsBytesSync();
      expect(jcombu.convertEucJp(f), 'Englishと日本語testsです。半角ｶﾅ。竽。');
    });

    test('Future test', () async {
      final f = io.File('./test/basic.euc').readAsBytes();
      final s = await f.then((sjisCodes) {
        return jcombu.convertEucJp(sjisCodes);
      });
      expect(s, 'Englishと日本語testsです。半角ｶﾅ。竽。');
    });

    test('Stream test', () async* {
      final file = io.File('./test/basic.euc').openRead();
      final s = jcombu.convertEucJpStream(file);
      expect(s, 'Englishと日本語testsです。半角ｶﾅ。竽。');
    });

    test('Long stream test', () async* {
      final file = io.File('./test/constitution.euc').openRead();
      final s = jcombu.convertEucJpStream(file);
      final r = io.File('./test/constitution.utf8').readAsStringSync();
      expect(s, r);
    });
  });

  group('ISO-20220-JP (JIS)', () {
    setUp(() {});

    test('Null test', () {
      expect(jcombu.convertJis([0x00]), '\x00');
    });

    test('Basic test', () {
      final f = io.File('./test/basic.jis').readAsBytesSync();
      expect(jcombu.convertJis(f), 'Englishと日本語testsです。');
    });

    test('Future test', () async {
      final f = io.File('./test/basic.jis').readAsBytes();
      final s = await f.then((jisCodes) {
        return jcombu.convertJis(jisCodes);
      });
      expect(s, 'Englishと日本語testsです。');
    });

    test('Char test', () {
      final f = io.File('./test/char.jis').readAsBytesSync();
      final s = jcombu.convertJis(f);
      final r = io.File('./test/char.utf8').readAsStringSync();
      expect(s, r);
    });

    test('Stream test', () async* {
      final fileStream = io.File('./test/basic.jis').openRead();
      var s = jcombu.convertJisStream(fileStream);
      expect(s, 'Englishと日本語testsです。');
    });

    test('Long stream test', () async* {
      final file = io.File('./test/constitution.jis').openRead();
      final s = jcombu.convertJisStream(file);
      final r = io.File('./test/constitution.utf8').readAsStringSync();
      expect(s, r);
    });

    test('Long stream test2', () async* {
      final file = io.File('./test/agpl.ja.md.jis').openRead();
      final s = jcombu.convertJisStream(file);
      final r = io.File('./test/agpl.ja.md').readAsStringSync();
      expect(s, r);
    });
  });
}
