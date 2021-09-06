// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  print('inSoundMode: $inSoundMode');
  testDefaultValues();
}

class Class1 {
  final int field1;
  final int field2;

  Class1.positional([this.field1 = 1, this.field2 = 2]);

  factory Class1.redirectPositionalSame([int field1, int field2]) =
      Class1.positional;

  factory Class1.redirectPositionalFewer1([int field1]) = Class1.positional;

  factory Class1.redirectPositionalFewer2() = Class1.positional;

  Class1.named({this.field1 = 1, this.field2 = 2});

  factory Class1.redirectNamedSame({int field1, int field2}) = Class1.named;

  factory Class1.redirectNamedReorder({int field2, int field1}) = Class1.named;

  factory Class1.redirectNamedFewer1({int field1}) = Class1.named;

  factory Class1.redirectNamedFewer2({int field2}) = Class1.named;

  factory Class1.redirectNamedFewer3() = Class1.named;
}

testDefaultValues() {
  var f1a = Class1.redirectPositionalSame;
  var c1a = f1a();
  expect(1, c1a.field1);
  expect(2, c1a.field2);
  var c1b = f1a(42);
  expect(42, c1b.field1);
  expect(2, c1b.field2);
  var c1c = f1a(42, 87);
  expect(42, c1c.field1);
  expect(87, c1c.field2);

  var f1b = Class1.redirectPositionalFewer1;
  var c1d = f1b();
  expect(1, c1d.field1);
  expect(2, c1d.field2);
  var c1e = f1b(42);
  expect(42, c1e.field1);
  expect(2, c1e.field2);
  () {
    f1b(42, 87); // error
  };

  var f1c = Class1.redirectPositionalFewer2;
  var c1f = f1c();
  expect(1, c1f.field1);
  expect(2, c1f.field2);
  () {
    f1c(42); // error
    f1c(42, 87); // error
  };

  var f2a = Class1.redirectNamedSame;
  var c2a = f2a();
  expect(1, c2a.field1);
  expect(2, c2a.field2);
  var c2b = f2a(field1: 42);
  expect(42, c2b.field1);
  expect(2, c2b.field2);
  var c2c = f2a(field1: 42, field2: 87);
  expect(42, c2c.field1);
  expect(87, c2c.field2);
  var c2d = f2a(field2: 87);
  expect(1, c2d.field1);
  expect(87, c2d.field2);
  var c2e = f2a(field2: 87, field1: 42);
  expect(42, c2e.field1);
  expect(87, c2e.field2);

  var f2b = Class1.redirectNamedReorder;
  var c3a = f2b();
  expect(1, c3a.field1);
  expect(2, c3a.field2);
  var c3b = f2b(field1: 42);
  expect(42, c3b.field1);
  expect(2, c3b.field2);
  var c3c = f2b(field1: 42, field2: 87);
  expect(42, c3c.field1);
  expect(87, c3c.field2);
  var c3d = f2b(field2: 87);
  expect(1, c3d.field1);
  expect(87, c3d.field2);
  var c3e = f2b(field2: 87, field1: 42);
  expect(42, c3e.field1);
  expect(87, c3e.field2);

  var f2c = Class1.redirectNamedFewer1;
  var c4a = f2c();
  expect(1, c4a.field1);
  expect(2, c4a.field2);
  var c4b = f2c(field1: 42);
  expect(42, c4b.field1);
  expect(2, c4b.field2);
  () {
    f2c(field1: 42, field2: 87); // error
  };

  var f2d = Class1.redirectNamedFewer2;
  var c5a = f2d();
  expect(1, c5a.field1);
  expect(2, c5a.field2);
  var c5b = f2d(field2: 87);
  expect(1, c5b.field1);
  expect(87, c5b.field2);
  () {
    f2d(field1: 42, field2: 87); // error
  };

  var f2e = Class1.redirectNamedFewer3;
  var c6a = f2e();
  expect(1, c6a.field1);
  expect(2, c6a.field2);
  () {
    f2e(field1: 42); // error
    f2e(field2: 87); // error
    f2e(field1: 42, field2: 87); // error
  };
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(Function() f, {bool inSoundModeOnly: false}) {
  try {
    f();
  } catch (e) {
    print('Thrown: $e');
    return;
  }
  if (!inSoundMode && inSoundModeOnly) {
    return;
  }
  throw 'Expected exception';
}
