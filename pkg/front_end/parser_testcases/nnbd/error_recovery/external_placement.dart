// https://github.com/dart-lang/sdk/issues/43851
// https://github.com/dart-lang/sdk/issues/43858
// https://github.com/dart-lang/sdk/issues/43859

final external int i1;
var external i2;

class C {
  covariant external num i3;
  final external int i4;
  final external i5;
  static external final i6;
  static final external i7;
  final static external i8;
}