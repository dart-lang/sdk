// https://github.com/dart-lang/sdk/issues/44379

int x1;
late int x2;
late List<int> x3;
late final int x4;
late x5;
; // Meant to confuse so `.next`-ing makes it look like the end of a field.
late;
; // Meant to confuse so `.next`-ing makes it look like the end of a field.

main(List<String> args) {
  int y1;
  late int y2;
  late List<int> y3;
  late final int y4;
  late y5;
  ; // Meant to confuse so `.next`-ing makes it look like the end of a field.
  late;
  ; // Meant to confuse so `.next`-ing makes it look like the end of a field.
}

class Foo {
  int z1;
  late int z2;
  late List<int> x3;
  late final int z4;
  late z5;
  ; // Meant to confuse so `.next`-ing makes it look like the end of a field.
  late;
  ; // Meant to confuse so `.next`-ing makes it look like the end of a field.
}