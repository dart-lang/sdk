// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test re-entrant initializer - calls throw CyclicInitializationError.

var trace;

final foo = bar;

get bar {
  trace.add('bar');
  try {
    return foo ?? 1;
  } catch (e) {
    trace.add(e is CyclicInitializationError);
  }
  try {
    return foo ?? 2;
  } catch (e) {
    trace.add(e is CyclicInitializationError);
  }
  return 42;
}

void testTopLevel() {
  trace = [];
  var result = foo;
  Expect.equals(42, result);
  Expect.equals('bar,true,true', trace.join(','));
  trace = [];
  result = foo;
  Expect.equals(42, result);
  Expect.equals('', trace.join(','));
}

class X {
  static final foo = X.bar;

  static get bar {
    trace.add('X.bar');
    try {
      return foo ?? 1;
    } catch (e) {
      trace.add(e is CyclicInitializationError);
    }
    try {
      return foo ?? 2;
    } catch (e) {
      trace.add(e is CyclicInitializationError);
    }
    return 49;
  }
}

void testClassStatic() {
  trace = [];
  var result = X.foo;
  Expect.equals(49, result);
  Expect.equals('X.bar,true,true', trace.join(','));
  trace = [];
  result = X.foo;
  Expect.equals(49, result);
  Expect.equals('', trace.join(','));
}

main() {
  testTopLevel();
  testClassStatic();
}
