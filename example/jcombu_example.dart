import 'package:jcombu/jcombu.dart' as jcombu;

void main() {
  final s = jcombu.convertJis([0x1b, 0x24, 0x40, 0x30, 0x21]);
  print(s);
}
