// https://github.com/dart-lang/sdk/issues/43855
// https://github.com/dart-lang/sdk/issues/43856
// https://github.com/dart-lang/sdk/issues/43857

abstract class C {
  final abstract int i1;
  final abstract i2;
  covariant abstract num i3;
  covariant abstract var i4;
  final abstract i5;
  var abstract i6;
  C abstract i7;
}

// This currently give 2 errors which is hardly ideal.
var abstract foo;

abstract class Bar {
  // This currently give 2 errors which is hardly ideal.
  covariant required x;
}