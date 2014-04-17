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

int positionalDefaultValues([int intConst = INT_CONST,
    bool boolConst = BOOL_CONST, List listConst = LIST_CONST,
    String stringConst = STRING_CONST, Map mapConst = MAP_CONST,
    Map emptyMap = EMPTY_MAP_CONST]) {
  throw new UnimplementedError();
}

const int INT_CONST = 42;

const bool BOOL_CONST = true;

const LIST_CONST = const [true, 42, 'Shanna', null, 3.14, const []];

const STRING_CONST = 'Shanna';

const MAP_CONST = const {'a':1, 2: true, 'c': const [1,null,true]};

const EMPTY_MAP_CONST = const {};
