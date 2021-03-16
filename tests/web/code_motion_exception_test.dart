// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--no-minify

import "package:expect/expect.dart";

// Test for correct order of exceptions in code with checks that could be moved
// merged from successors into a dominator.

get never => new DateTime.now().millisecondsSinceEpoch == 42;
get always => new DateTime.now().millisecondsSinceEpoch > 42;

// gA and gB have type [null|num], so they compile to a receiver check, and
// argument check and then the operation.
var gA; // [null|num]
var gB; // [null|num]

foo1(a, b) {
  // The checks on a and b are not equivalent, so can't be merged.
  if (never) {
    return a ^ b;
  } else {
    return b ^ a;
  }
}

call1() {
  return foo1(gA, gB);
}

test1() {
  gA = 1;
  gB = 2;
  Expect.equals(3, call1());

  gA = null;
  gB = null;
  Expect.throws(call1, (e) => e is NoSuchMethodError, 'foo1($gA, $gB) NSME');

  gA = 1;
  gB = null;
  Expect.throws(call1, (e) => e is NoSuchMethodError, 'foo1($gA, $gB) NSME');

  gA = null;
  gB = 2;
  Expect.throws(call1, (e) => e is ArgumentError, 'foo1($gA, $gB) AE');
}

foo2a(a, b) {
  // The common receiver check on [a] cannot be merged because the operation
  // (selector) is different.
  // The common argument check on [b] cannot be merged because it must happen
  // after the receiver check.
  if (never) {
    return a ^ b;
  } else {
    return a & b;
  }
}

foo2b(a, b) {
  // Same a foo2a except which branch dynamically taken.
  if (always) {
    return a ^ b;
  } else {
    return a & b;
  }
}

call2a() {
  return foo2a(gA, gB);
}

call2b() {
  return foo2b(gA, gB);
}

checkNSME(text) {
  return (e) {
    Expect.isTrue(e is NoSuchMethodError,
        'expecting NoSuchMethodError, got "${e.runtimeType}"');
    Expect.isTrue('$e'.contains(text), '"$e".contains("$text")');
    return e is NoSuchMethodError;
  };
}

test2() {
  gA = 1;
  gB = 2;
  Expect.equals(0, call2a());
  Expect.equals(3, call2b());

  gA = null;
  gB = null;
  Expect.throws(call2a, checkNSME(r'$and'), 'foo2($gA, $gB) NSME');
  Expect.throws(call2b, checkNSME(r'$xor'), 'foo2($gA, $gB) NSME');

  gA = 1;
  gB = null;
  Expect.throws(call2a, (e) => e is ArgumentError, 'foo2($gA, $gB) AE');
  Expect.throws(call2b, (e) => e is ArgumentError, 'foo2($gA, $gB) AE');

  gA = null;
  gB = 2;
  Expect.throws(call2a, checkNSME(r'$and'), 'foo2($gA, $gB) NSME');
  Expect.throws(call2b, checkNSME(r'$xor'), 'foo2($gA, $gB) NSME');
}

main() {
  test1();
  test2();
}
