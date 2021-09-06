// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  print('inSoundMode: $inSoundMode');
  testNoArgs();
  testArgs();
}

class Class1 {
  Class1._();
  factory Class1() => new Class1._();
}

class Class2 {
  Class2._();
  factory Class2.named() => new Class2._();
}

testNoArgs() {
  var f1a = Class1.new;
  var c1a = f1a();
  expect(true, c1a is Class1);

  dynamic f1b = Class1.new;
  var c1b = f1b();
  expect(true, c1b is Class1);

  expect(true, identical(f1a, f1b));

  var f2a = Class2.named;
  var c2a = f2a();
  expect(true, c2a is Class2);

  dynamic f2b = Class2.named;
  var c2b = f2b();
  expect(true, c2b is Class2);

  expect(true, identical(f2a, f2b));
}

class Class3 {
  final int field;

  Class3._(this.field);
  factory Class3(int field) => new Class3._(field);
}

class Class4 {
  final int? field;

  Class4._([this.field]);
  factory Class4([int? field]) => new Class4._(field);
}

class Class5 {
  final int field1;
  final int? field2;

  Class5._(this.field1, [this.field2]);
  factory Class5(int field1, [int? field2]) => new Class5._(field1, field2);
}

class Class6 {
  final int field1;
  final int? field2;
  final int field3;

  Class6._(this.field1, {this.field2, required this.field3});
  factory Class6(int field1, {int? field2, required int field3}) =>
      new Class6._(field1, field2: field2, field3: field3);
}

testArgs() {
  var f3a = Class3.new;
  var c3a = f3a(42);
  expect(42, c3a.field);
  () {
    f3a(); // error
    f3a(42, 87); // error
  };

  dynamic f3b = Class3.new;
  var c3b = f3b(87);
  expect(87, c3b.field);
  throws(() => f3b());
  throws(() => f3b(42, 87));

  var f4a = Class4.new;
  var c4a = f4a();
  expect(null, c4a.field);
  var c4b = f4a(42);
  expect(42, c4b.field);
  () {
    f4a(42, 87); // error
  };
  dynamic f4b = Class4.new;
  throws(() => f4b(42, 87));


  var f5a = Class5.new;
  var c5a = f5a(42);
  expect(42, c5a.field1);
  expect(null, c5a.field2);
  var c5b = f5a(87, 42);
  expect(87, c5b.field1);
  expect(42, c5b.field2);
  () {
    f5a(); // error
    f5a(42, 87, 123); // error
  };
  dynamic f5b = Class5.new;
  throws(() => f5b());
  throws(() => f5b(42, 87, 123));

  var f6a = Class6.new;
  var c6a = f6a(42, field3: 87);
  expect(42, c6a.field1);
  expect(null, c6a.field2);
  expect(87, c6a.field3);
  () {
    f6a(); // error
    f6a(42); // error
    f6a(42, 87); // error
    f6a(field1: 87, field2: 87); // error
  };

  var c6b = f6a(42, field2: 123, field3: 87);
  expect(42, c6b.field1);
  expect(123, c6b.field2);
  expect(87, c6b.field3);

  var c6c = f6a(87, field3: 42, field2: 123);
  expect(87, c6c.field1);
  expect(123, c6c.field2);
  expect(42, c6c.field3);

  dynamic f6b = Class6.new;
  throws(() => f6b());
  throws(() => f6b(42), inSoundModeOnly: true);
  throws(() => f6b(42, 87), inSoundModeOnly: true);
  throws(() => f6b(field1: 87, field2: 87));
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
