# jcombu (Japanese charset converter)

Japanese charset converter from SJIS/EUC-JP/JIS(ISO-2022-JP) to Dart String.


## Usage

```dart
import 'package:jcombu/jcombu.dart' as jcombu;

void main() {
  final s = jcombu.convertJis([0x1b, 0x24, 0x40, 0x30, 0x21]);
  print(s);
}
// 亜
```

See [test](https://github.com/moonsightz/jcombu/blob/main/test/jcombu_test.dart) for more examples.


## Notice

Some glyphs are different from the examples in their standards, but human-readable.


## Source code

https://github.com/moonsightz/jcombu/
