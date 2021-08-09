// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  print('inSoundMode: $inSoundMode');
  testGeneric();
  testBounded();
}

class Class1<T> {
  Class1._();
  factory Class1() => new Class1<T>._();
}

testGeneric() {
  var f1a = Class1.new;
  var c1a = f1a();
  expect(true, c1a is Class1<dynamic>);
  expect(false, c1a is Class1<int>);
  var c1b = f1a<int>();
  expect(true, c1b is Class1<int>);
  expect(false, c1b is Class1<String>);
  () {
    f1a<int, String>(); // error
  };

  var f1b = f1a<int>;
  var c1c = f1b();
  expect(true, c1c is Class1<int>);
  expect(false, c1c is Class1<String>);
  () {
    f1b<int>(); // error
  };

  dynamic f1c = Class1.new;
  var c1d = f1c();
  expect(true, c1a is Class1<dynamic>);
  expect(false, c1a is Class1<int>);
  throws(() => f1c<int, String>());
}

class Class2<T extends num> {
  Class2._();
  factory Class2() => new Class2<T>._();
}

class Class3<T extends S, S> {
  Class3._();
  factory Class3() => new Class3<T, S>._();
}

class Class4<T extends Class4<T>> {
  Class4._();
  factory Class4() => new Class4<T>._();
}

class Class4int extends Class4<Class4int> {
  Class4int._() : super._();
  factory Class4int() => new Class4int._();
}

testBounded() {
  var f2a = Class2.new;
  var c2a = f2a();
  expect(true, c2a is Class2<num>);
  expect(false, c2a is Class2<int>);
  var c2b = f2a<int>();
  expect(true, c2b is Class2<int>);
  expect(false, c2b is Class2<double>);
  () {
    f2a<String>(); // error
    f2a<int, String>(); // error
  };

  dynamic f2b = Class2.new;
  var c2c = f2b();
  expect(true, c2c is Class2<num>);
  expect(false, c2c is Class2<int>);
  var c2d = f2b<int>();
  expect(true, c2d is Class2<int>);
  expect(false, c2d is Class2<double>);
  throws(() => f2b<String>());
  throws(() => f2b<int, String>());

  var f3a = Class3.new;
  var c3a = f3a();
  expect(true, c3a is Class3<dynamic, dynamic>);
  expect(false, c3a is Class3<int, num>);
  var c3b = f3a<int, num>();
  expect(true, c3b is Class3<int, num>);
  expect(false, c3b is Class3<double, num>);
  () {
    f3a<num, int>(); // error
  };

  dynamic f3b = Class3.new;
  var c3c = f3b();
  expect(true, c3c is Class3<dynamic, dynamic>);
  expect(false, c3c is Class3<int, num>);
  var c3d = f3b<int, num>();
  expect(true, c3d is Class3<int, num>);
  expect(false, c3d is Class3<double, num>);
  throws(() => f3b<num, int>());

  var f4a = Class4.new;
  () {
    var c4a = f4a(); // error
  };

  dynamic f4b = Class4.new;
  throws(() => f4b());
  var c4b = f4b<Class4int>();
  expect(true, c4b is Class4<Class4int>);
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