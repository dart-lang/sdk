// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A light-weight replacement for package:unittest.  This library runs tests
/// synchronously, and avoids using reflection.
library light_unittest;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import '../pkg/expect/lib/expect.dart';

test(name, f) {
  print('Testing $name');
  try {
    f();
    print('PASS: $name');
  } catch (e, trace) {
    print('FAIL: $name.');
    print(e);
    print(trace);
    asyncStart();
    Timer.run(() {
      throw new StateError('FAILED: $name.\n$e\n$trace');
    });
  }
}

expect(actual, expected) {
  if (expected is Expectation) {
    expected.check(actual);
  } else {
    Expect.equals(expected, actual);
  }
}

class Expectation {
  final check;
  Expectation(this.check);
}

equals(expected) {
  if (expected is List) {
    return new Expectation((actual) => Expect.listEquals(expected, actual));
  } else if (expected is Map) {
    return new Expectation((actual) => Expect.mapEquals(expected, actual));
  } else if (expected is Set) {
    return new Expectation((actual) => Expect.setEquals(expected, actual));
  } else if (expected is String) {
    return new Expectation((actual) => Expect.stringEquals(expected, actual));
  } else {
    return new Expectation((actual) => Expect.equals(expected, actual));
  }
}

get throws => new Expectation((actual) => Expect.throws(actual));

get isTrue => new Expectation((actual) => Expect.isTrue(actual));
