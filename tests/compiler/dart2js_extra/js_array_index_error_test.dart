// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that optimized JSArray indexers enerate the same error as dynamically
// dispatched calls.

import 'package:expect/expect.dart';

@NoInline()
@AssumeDynamic()
confuse(x) => x;

Error getError(action(), name, part) {
  try {
    action();
  } catch (e) {
    return e;
  }
  Expect.fail('must throw: $name: $part');
}

indexErrorContainsIndex() {
  makeFault(i) => () => confuse([])[i];

  var name = 'index error contains index';
  var e1 = getError(makeFault(1234), name, 'small');
  var e2 = getError(makeFault(1234000), name, 'medium');
  var e3 = getError(makeFault(1234000000000), name, 'large');

  Expect.equals('$e1', '$e2'.replaceAll('000', ''));
  Expect.equals('$e1', '$e3'.replaceAll('000', ''));
  Expect.equals('$e1'.length + 3, '$e2'.length);
  Expect.equals('$e1'.length + 9, '$e3'.length);
}

compare(name, fault1(), fault2(), fault3()) {
  var e1 = getError(fault1, name, 'fault1');
  var e2 = getError(fault2, name, 'fault2');
  var e3 = getError(fault3, name, 'fault3');

  Expect.equals('$e1', '$e2', '$name: fault1 vs fault2');
  Expect.equals('$e1', '$e3', '$name: fault1 vs fault3');
}

// These tests are a bit tedious and avoid common helpers with higher order
// functions to keep the type inference for each test independent from the
// others.
//
// The 'constant' tests have a constant index which might permit different
// optimizations to a variable index.  e.g. the compiler might determine HUGE is
// always out of range since the maximum JavaScript Array length is 2^32.
//
// The 'variable' forms take the index as an argument.

const int HUGE = 1000000000000;

constantIndexEmpty() {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([])[0];

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    return a[0];
  }

  fault3() {
    var a = confuse([]);
    // Multiple indexing might go via shared interceptor.
    return [a[0], a[1], a[2]];
  }

  compare('constant index on empty list', fault1, fault2, fault3);
}

constantIndexHugeEmpty() {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([])[HUGE];

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    return a[HUGE];
  }

  fault3() {
    var a = confuse([]);
    return [a[HUGE], a[1], a[2]];
  }

  compare(
      'constant index on empty list with huge index', fault1, fault2, fault3);
}

constantIndexNonempty() {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([1])[1];

  fault2() {
    var a = [1];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    return a[1];
  }

  fault3() {
    var a = confuse([1]);
    // Multiple indexing might go via shared interceptor.
    return [a[1], a[2], a[3]];
  }

  compare('constant index on non-empty list', fault1, fault2, fault3);
}

constantIndexHugeNonempty() {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([1])[HUGE];

  fault2() {
    var a = [1];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    return a[HUGE];
  }

  fault3() {
    var a = confuse([1]);
    // Multiple indexing might go via shared interceptor.
    return [a[HUGE], a[1], a[2]];
  }

  compare('constant index on non-empty list with huge index', fault1, fault2,
      fault3);
}

constantIndexSetEmpty() {
  fault1() {
    // Single dynamic receiver indexing might go via one-shot interceptor that
    // might have an accelerated path.
    confuse([])[0] = 0;
  }

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    a[0] = 0;
    return a;
  }

  fault3() {
    var a = confuse([]);
    // Multiple indexing might go via shared interceptor.
    a[0] = 0;
    a[1] = 0;
    a[2] = 0;
    return a;
  }

  compare('coinstant index-set on empty list', fault1, fault2, fault3);
}

constantIndexSetNonempty() {
  fault1() {
    // Single dynamic receiver indexing might go via one-shot interceptor that
    // might have an accelerated path.
    confuse([1])[1] = 0;
  }

  fault2() {
    var a = [1];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    a[1] = 0;
    return a;
  }

  fault3() {
    var a = confuse([1]);
    // Multiple indexing might go via shared interceptor.
    a[0] = 0;
    a[1] = 0;
    a[2] = 0;
    return a;
  }

  compare('constant index-set on non-empty list', fault1, fault2, fault3);
}

variableIndexEmpty(index, qualifier) {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([])[index];

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    return a[index];
  }

  fault3() {
    var a = confuse([]);
    // Multiple indexing might go via shared interceptor.
    return [a[index], a[1], a[2]];
  }

  compare('general index on empty list $qualifier', fault1, fault2, fault3);
}

variableIndexNonempty(index, qualifier) {
  // Single dynamic receiver indexing might go via one-shot interceptor that
  // might have an accelerated path.
  fault1() => confuse([1])[index];

  fault2() {
    var a = [1];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    return a[index];
  }

  fault3() {
    var a = confuse([1]);
    // Multiple indexing might go via shared interceptor.
    return [a[index], a[1], a[2]];
  }

  compare(
      'variable index on non-empty list $qualifier', fault1, fault2, fault3);
}

variableIndexSetEmpty(index, qualifier) {
  fault1() {
    var a = confuse([]);
    // Single dynamic receiver indexing might go via one-shot interceptor that
    // might have an accelerated path.
    a[index] = 1;
    return a;
  }

  fault2() {
    var a = [];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    a[index] = 1;
    return a;
  }

  fault3() {
    var a = confuse([]);
    // Multiple indexing might go via shared interceptor.
    a[index] = 1;
    a[2] = 2;
    a[3] = 3;
    return a;
  }

  compare(
      'variable index-set on empty list $qualifier', fault1, fault2, fault3);
}

variableIndexSetNonempty(index, qualifier) {
  fault1() {
    var a = confuse([1]);
    // Single dynamic receiver indexing might go via one-shot interceptor that
    // might have an accelerated path.
    a[index] = 1;
    return a;
  }

  fault2() {
    var a = [1];
    while (confuse(false)) a.add(1);
    // Easily inferred type and open coded indexer.
    a[index] = 1;
    return a;
  }

  fault3() {
    var a = confuse([1]);
    // Multiple indexing might go via shared interceptor.
    a[index] = 1;
    a[2] = 2;
    a[3] = 3;
    return a;
  }

  compare('variable index-set on non-empty list $qualifier', fault1, fault2,
      fault3);
}

main() {
  indexErrorContainsIndex();

  constantIndexEmpty();
  constantIndexHugeEmpty();
  constantIndexNonempty();
  constantIndexHugeNonempty();
  constantIndexSetEmpty();
  constantIndexSetNonempty();

  variableIndexEmpty(0, 'zero index');
  variableIndexEmpty(10, 'small index');
  variableIndexEmpty(-1, 'negative index');
  variableIndexEmpty(HUGE, 'huge index');

  variableIndexNonempty(10, 'small index');
  variableIndexNonempty(-1, 'negative index');
  variableIndexNonempty(HUGE, 'huge index');

  variableIndexSetEmpty(0, 'zero index');
  variableIndexSetEmpty(10, 'small index');
  variableIndexSetEmpty(-1, 'negative index');
  variableIndexSetEmpty(HUGE, 'huge index');

  variableIndexSetNonempty(10, 'small index');
  variableIndexSetNonempty(-1, 'negative index');
  variableIndexSetNonempty(HUGE, 'huge index');
}
