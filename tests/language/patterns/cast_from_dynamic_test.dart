// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test various places that implicit casts from dynamic can be inserted in
/// patterns and what happens when those casts succeed and fail.

import "package:expect/expect.dart";

main() {
  testRelational();
  testTypedVariable();
  testListPattern();
  testMapPattern();
  testObjectPattern();
  testListDestructure();
  testMapDestructure();
  testObjectDestructure();
}

class C {
  int get knownInt => 123;
  dynamic get dynamicInt => 123;
  dynamic get dynamicString => 'wrong type';
}

void testRelational() {
  // Test casts from dynamic on the right operand to a relational operator.
  const dynamic big = 234;

  // Matches in refutable context if type matches and operation is true.
  if (123 case < big) {
    // OK.
  } else {
    Expect.fail('Should have matched.');
  }
}

void testTypedVariable() {
  // Succeeds if cast succeeds.
  var (int x) = 123 as dynamic;
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var (int x) = 'wrong type' as dynamic;
  });

  // Matches in refutable context if type matches.
  if (123 as dynamic case int x) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if ('wrong type' as dynamic case int x) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testListPattern() {
  // Succeeds if cast to List succeeds.
  var [x] = [123] as dynamic;
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var [x] = 'wrong type' as dynamic;
  });

  // Matches in refutable context if type matches.
  if ([123] as dynamic case [var x]) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if ('wrong type' as dynamic case [var x]) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testMapPattern() {
  // Succeeds if cast to Map succeeds.
  var {'x': x} = {'x': 123} as dynamic;
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var {'x': x} = 'wrong type' as dynamic;
  });

  // Matches in refutable context if type matches.
  if ({'x': 123} as dynamic case {'x': var x}) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if ('wrong type' as dynamic case {'x': var x}) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testObjectPattern() {
  // Succeeds if cast to C succeeds.
  var C(knownInt: x) = C() as dynamic;
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var C(knownInt: x) = 'wrong type' as dynamic;
  });

  // Matches in refutable context if type matches.
  if (C() as dynamic case C(knownInt: var x)) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if ('wrong type' as dynamic case C(knownInt: var x)) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testListDestructure() {
  // Test when a destructured list element of type dynamic is matched by a
  // subpattern that expects a type.

  // Succeeds if cast succeeds.
  var [int x] = <dynamic>[123];
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var [int x] = <dynamic>['wrong type'];
  });

  // Matches in refutable context if type matches.
  if (<dynamic>[123] case [int x]) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if (<dynamic>['wrong type'] case [int x]) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testMapDestructure() {
  // Test when a destructured map value of type dynamic is matched by a
  // subpattern that expects a type.

  // Succeeds if cast succeeds.
  var {'x': int x} = <String, dynamic>{'x': 123};
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var {'x': int x} = <String, dynamic>{'x': 'wrong type'};
  });

  // Matches in refutable context if type matches.
  if (<String, dynamic>{'x': 123} case {'x': int x}) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if (<String, dynamic>{'x': 'wrong type'} case {'x': int x}) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}

void testObjectDestructure() {
  // Test when a destructured object getter of type dynamic is matched by a
  // subpattern that expects a type.

  // Succeeds if cast succeeds.
  var C(dynamicInt: int x) = C();
  Expect.equals(123, x);

  // Throws in irrefutable context if cast fails.
  Expect.throws(() {
    var C(dynamicString: int x) = C();
  });

  // Matches in refutable context if type matches.
  if (C() case C(dynamicInt: int x)) {
    Expect.equals(123, x);
  } else {
    Expect.fail('Should have matched.');
  }

  // Refuted in refutable context if type doesn't match.
  if (C() case C(dynamicString: int x)) {
    Expect.fail('Should not have matched.');
  } else {
    // OK.
  }
}
