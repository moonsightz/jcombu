# jcombu (Japanese charset convertor)

Japanese charset convertor from SJIS/EUC/JIS(ISO-2022-JP) to Dart String.


## Usage

```dart
import 'package:jcombu/jcombu.dart' as jcombu;

main() {
  final s = jcombu.convertJis([0x1b, 0x24, 0x40, 0x30, 0x21]);
  print(s);
}
// 亜
```

See test for more example.


## Notice

There are some glyphs different from examples in their standard, but they are human-readable.


## Source code

https://github.com/moonsightz/jcombu/
