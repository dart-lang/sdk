// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that we don't crash on computing js-interop classes when metadata
// constants contain implicit casts.
//
// We need the class hierarchy to perform the evaluation the implicit casts but
// we also change the class hierarchy when we discover that a class is a
// js-interop class. By mixing (valid) constants that contain implicit casts
// with the @JS annotations that define classes to be js-interop, triggering
// the use of the class hierarchy before all js-interop classes have been
// registered, this test causes dart2js to crash with an assertion failure.

@Constant(4)
@JS()
@Constant(5)
library test;

import 'package:js/js.dart';

@Constant(-1)
method() {}

@Constant(0)
@JS()
@anonymous
@Constant(1)
class ClassA {
  external factory ClassA();

  @Constant(2)
  external method();
}

class Constant {
  final int field;

  const Constant(dynamic value) : field = value;
}

@Constant(0)
@JS()
@anonymous
@Constant(1)
class ClassB {
  external factory ClassB();

  @Constant(2)
  external method();
}

class ClassC {
  method() {}
}

main() {
  method();
  dynamic c = new ClassC();
  c.method();
  new ClassA();
  new ClassB();
}
