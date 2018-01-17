// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/object_graph.dart';
import 'package:unittest/unittest.dart';

dynamic confuse() {
  if (true) {
    return "5";
  }
  return 5;
}

main() {
  var map = new AddressMapper(42);

  expect(map.get(1, 2, 3), isNull);
  expect(map.put(1, 2, 3, 4), equals(4));
  expect(map.get(1, 2, 3), equals(4));

  expect(map.get(2, 3, 1), isNull);
  expect(map.get(3, 1, 2), isNull);

  bool exceptionThrown = false;
  try {
    expect(exceptionThrown, isFalse);
    map.put(1, 2, 3, 44);
    expect(true, isFalse);
  } catch (e) {
    exceptionThrown = true;
  }
  expect(exceptionThrown, isTrue);

  exceptionThrown = false;
  try {
    expect(exceptionThrown, isFalse);
    map.put(5, 6, 7, 0);
    expect(true, isFalse);
  } catch (e) {
    exceptionThrown = true;
  }
  expect(exceptionThrown, isTrue);

  exceptionThrown = false;
  try {
    expect(exceptionThrown, isFalse);
    map.put(confuse(), 6, 7, 0);
    expect(true, isFalse);
  } catch (e) {
    exceptionThrown = true;
  }
  expect(exceptionThrown, isTrue);
}
