// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

final bool inSoundMode = <int?>[] is! List<int>;

main() {
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

  var f2c = Class2.redirect;
  var c2c = f2c();
  expect(true, c2c is Class2);

  dynamic f2d = Class2.redirect;
  var c2d = f2d();
  expect(true, c2d is Class2);

  expect(true, identical(f2c, f2d));

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
  expect(true, c4a is Class4<dynamic>);
  expect(false, c4a is Class4<int>);
  var c4b = f4a<int>();
  expect(true, c4b is Class4<int>);
  expect(false, c4b is Class4<String>);
  () {
    f4a<int, String>(); // error
  };

  var f4b = f4a<int>;
  var c4c = f4b();
  expect(true, c4c is Class4<int>);
  expect(false, c4c is Class4<String>);
  () {
    f4b<int>(); // error
  };

  dynamic f4c = Class4.new;
  var c4d = f4c();
  expect(true, c4d is Class4<dynamic>);
  expect(false, c4d is Class4<int>);
  throws(() => f4c<int, String>());

  var f4d = Class4.redirect;
  var c4e = f4d();
  expect(true, c4e is Class4<dynamic>);
  expect(false, c4e is Class4<int>);
  var c4f = f4d<int>();
  expect(true, c4f is Class4<int>);
  expect(false, c4f is Class4<String>);
  () {
    f4d<int, String>(); // error
  };

  var f4e = f4d<int>;
  var c4g = f4e();
  expect(true, c4g is Class4<int>);
  expect(false, c4g is Class4<String>);
  () {
    f4e<int>(); // error
  };

  dynamic f4f = Class4.redirect;
  var c4h = f4f();
  expect(true, c4h is Class4<dynamic>);
  expect(false, c4h is Class4<int>);
  throws(() => f4f<int, String>());

  var f5a = Class5.new;
  var c5a = f5a();
  expect(true, c5a is Class5<num>);
  expect(false, c5a is Class5<int>);
  var c5b = f5a<int>();
  expect(true, c5b is Class5<int>);
  expect(false, c5b is Class5<double>);
  () {
    f5a<String>(); // error
    f5a<int, String>(); // error
  };

  dynamic f5b = Class5.new;
  var c5c = f5b();
  expect(true, c5c is Class5<num>);
  expect(false, c5c is Class5<int>);
  var c5d = f5b<int>();
  expect(true, c5d is Class5<int>);
  expect(false, c5d is Class5<double>);
  throws(() => f5b<String>());
  throws(() => f5b<int, String>());
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
