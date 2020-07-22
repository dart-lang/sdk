// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test re-entrant initializer - calls throw StackOverflowError.

var trace;

var foo = bar;

var recursionDepth = 0;

get bar {
  if (recursionDepth > 3) throw "recursed";
  recursionDepth++;

  trace.add(recursionDepth);
  try {
    return foo ?? 1;
  } catch (e) {
    trace.add(e);
  }

  return 42;
}

void testTopLevel() {
  trace = [];
  recursionDepth = 0;
  var result = foo;
  Expect.equals(42, result);
  Expect.equals('1,2,3,4,recursed', trace.join(','));
  trace = [];
  recursionDepth = 0;
  result = foo;
  Expect.equals(42, result);
  Expect.equals('', trace.join(','));
}

class X {
  static var foo = X.bar;

  static get bar {
    if (recursionDepth > 3) throw "recursed";
    recursionDepth++;

    trace.add(recursionDepth);
    try {
      return foo ?? 1;
    } catch (e) {
      trace.add(e);
    }

    return 49;
  }
}

void testClassStatic() {
  trace = [];
  recursionDepth = 0;
  var result = X.foo;
  Expect.equals(49, result);
  Expect.equals('1,2,3,4,recursed', trace.join(','));
  trace = [];
  recursionDepth = 0;
  result = X.foo;
  Expect.equals(49, result);
  Expect.equals('', trace.join(','));
}

main() {
  testTopLevel();
  testClassStatic();
}
