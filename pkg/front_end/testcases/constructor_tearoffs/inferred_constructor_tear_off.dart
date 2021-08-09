// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  print('inSoundMode: $inSoundMode');
  testInferred();
}

class Class1 {
  int field;

  Class1(this.field);
}

abstract class Interface2 {
  int get field;
}

class Class2 implements Interface2 {
  final field;

  Class2(this.field);
}

var Class1_new = Class1.new;
var Class2_new = Class2.new;

testInferred() {
  var f1a = Class1.new;
  expect(true, f1a is Class1 Function(int));
  expect(false, f1a is Class1 Function(String));
  var c1a = f1a(0);
  expect(true, c1a is Class1);
  () {
    f1a(''); // error
  };

  dynamic f1b = Class1.new;
  var c1b = f1b(0);
  expect(true, c1b is Class1);
  throws(() => f1b(''));

  var f2a = Class2.new;
  expect(true, f2a is Class2 Function(int));
  expect(false, f2a is Class2 Function(String));
  var c2a = f2a(0);
  expect(true, c2a is Class2);
  () {
    f2a(''); // error
  };

  dynamic f2b = Class2.new;
  var c2b = f2b(0);
  expect(true, c2b is Class2);
  throws(() => f2b(''));
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
