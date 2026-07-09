// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'package:expect/expect.dart';

main() {
  // Check 'Object' switch expression types.
  final Object se1 = int.parse('1') == 1 ? Foo() : Bar();
  switch (se1) {
    case Object:
      print('match');
      Expect.fail('Should not use custom ==.');
      break;
    default:
      print('no match');
      break;
  }

  final Object se2 = int.parse('1') == 1 ? List<int> : Bar();
  switch (se2) {
    case List<int>:
      print('match');
      break;
    default:
      print('no match');
      Expect.fail('Should use built-in Type.==.');
      break;
  }

  // Check 'dynamic' switch expression type.
  final dynamic se3 = int.parse('1') == 1 ? Foo() : Bar();
  switch (se2) {
    case Object:
      print('match');
      Expect.fail('Should not use custom ==.');
      break;
    default:
      print('no match');
      break;
  }

  final dynamic se4 = int.parse('1') == 1 ? List<String> : Foo();
  switch (se4) {
    case List<String>:
      print('match');
      break;
    default:
      print('no match');
      Expect.fail('Should use built-in Type.==.');
      break;
  }

  final Type se5 = int.parse('1') == 1 ? List<Object> : int;
  switch (se5) {
    case List<Object>:
      print('match');
      break;
    default:
      print('no match');
      Expect.fail('Should use built-in Type.==.');
      break;
  }
}

class Foo {
  const Foo();
  bool operator ==(other) {
    print('Foo.==($other)');
    return true;
  }
}

class Bar {
  const Bar();
  bool operator ==(other) {
    print('Bar.==($other)');
    return true;
  }
}
