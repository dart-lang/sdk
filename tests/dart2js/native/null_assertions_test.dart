// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak
// dart2jsOptions=--null-assertions

// @dart=2.8

// Test that `--null-assertions` injects null-checks on the returned value of
// native methods with a non-nullable return type in an opt-in library.

import 'native_testing.dart';
import 'null_assertions_opt_in_lib.dart' as lib;

// The 'Interface' version of the code is passed both native and Dart objects,
// so there will be an interceptor dispatch to the method. This tests that the
// null-check exists in the forwarding method.
//
// The 'AAA' version of the code is passed only objects of a single native
// class, so the native method can be inlined (which happens in the optimizer).
// This tests that the null-check exists in the 'inlined' code.

@pragma('dart2js:noInline')
String describeInterface(lib.Interface o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
String describeAAA(lib.AAA o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
void checkOptNameInterface(lib.Interface o, dynamic expected) {
  Expect.equals(expected, o.optName);
}

@pragma('dart2js:noInline')
void checkOptNameAAA(lib.AAA o, dynamic expected) {
  Expect.equals(expected, o.optName);
}

const expectedA = 'Albert amazing! 100 200';
const expectedB = 'Brenda brilliant! 300 400';

void main() {
  nativeTesting();
  lib.setup();
  lib.AAA a = lib.makeA();
  lib.BBB b = lib.BBB();

  Expect.equals(expectedA, describeInterface(a));
  Expect.equals(expectedB, describeInterface(b));

  Expect.equals(expectedA, describeAAA(a));

  lib.AAA x = lib.makeAX(); // This object returns `null`!
  Expect.throws(() => describeInterface(x));
  Expect.throws(() => describeAAA(x));

  Expect.throws(() => x.name);
  Expect.throws(() => x.size);
  Expect.throws(() => x.method1());
  Expect.throws(() => x.method2());

  // Now test that a nullable return type does not have a check.
  checkOptNameInterface(a, 'Albert');
  checkOptNameInterface(b, 'Brenda');
  checkOptNameInterface(x, null);

  checkOptNameAAA(a, 'Albert');
  checkOptNameAAA(x, null);
}
