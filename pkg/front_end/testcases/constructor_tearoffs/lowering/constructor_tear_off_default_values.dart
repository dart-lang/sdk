// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  print('inSoundMode: $inSoundMode');
  testDefaultValues();
}

class Class1 {
  final int field;

  Class1([this.field = 42]);
}

class Class2 {
  final int field;

  Class2({this.field: 42});
}

void testDefaultValues() {
  var f1a = Class1.new;
  var c1a = f1a();
  expect(42, c1a.field);
  var c1b = f1a(87);
  expect(87, c1b.field);
  () {
    f1a(42, 87); // error
  };

  dynamic f1b = Class1.new;
  var c1c = f1b();
  expect(42, c1c.field);
  var c1d = f1b(87);
  expect(87, c1d.field);
  throws(() => f1b(42, 87));

  var f2a = Class2.new;
  var c2a = f2a();
  expect(42, c2a.field);
  var c2b = f2a(field: 87);
  expect(87, c2b.field);
  () {
    f2a(87); // error
  };

  dynamic f2b = Class2.new;
  var c2c = f2b();
  expect(42, c2c.field);
  var c2d = f2b(field: 87);
  expect(87, c2d.field);
  throws(() => f2b(87));
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