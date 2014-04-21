// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_lib.bar;

import 'test_lib.dart';
import 'test_lib_foo.dart';

/*
 * Normal comment for class C.
 */
class C {
}

/// Processes an [input] of type [C] instance for testing.
///
/// To eliminate import warnings for [A] and to test typedefs.
///
/// It's important that the [List<A>] for param [listOfA] is not empty.
A testMethod(C input, List<A> listOfA, B aBee) {
  throw 'noop';
}

/// Processes an [input] of type [C] instance for testing.
///
/// To eliminate import warnings for [A] and to test typedefs.
///
/// It's important that the [List<A>] for param [listOfA] is not empty.
typedef A testTypedef(C other, List<A> listOfA, B aBee);
