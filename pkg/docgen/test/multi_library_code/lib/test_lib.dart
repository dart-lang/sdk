// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_lib;

import 'test_lib_foo.dart';
import 'test_lib_bar.dart';
export 'test_lib_foo.dart';
export 'test_lib_bar.dart';

/**
 * Doc comment for class [A].
 *
 * Multiline Test
 */
/*
 * Normal comment for class A.
 */
class A {

  int _someNumber;

  A() {
    _someNumber = 12;
  }

  A.customConstructor();

  /**
   * Test for linking to parameter [A]
   */
  void doThis(int A) {
    print(A);
  }
}

// A trivial use of `B` and `C` to eliminate import warnings
B sampleMethod(C cInstance) {
  throw new UnimplementedError();
}

int positionalDefaultValues([
    int intConst = 42,
    bool boolConst = true,
    List listConst = const [true, 42, 'Shanna', null, 3.14, const []],
    String stringConst = 'Shanna',
    Map mapConst = const {'a':1, 2: true, 'c': const [1,null,true]},
    Map emptyMap = const {},
    int referencedConst = INT_CONST,
    ConstClass constructedConstant1 = const ConstClass<int>(0, true),
    ConstClass constructedConstant2 = const ConstClass(1, false, str: "str")]) {
  throw new UnimplementedError();
}

const int INT_CONST = 42;

class ConstClass<T> {
  final bool boolField;
  final int intField;
  final String stringField;

  const ConstClass(this.intField, this.boolField, {String str: 'default'})
      : this.stringField = str;
}
