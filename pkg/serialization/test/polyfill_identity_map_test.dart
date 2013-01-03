// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provide a trivial test for identity based hashed collections, which we
 * provide here until an implementation is available in the regular libraries.
 */
// TODO(alanknight): Remove once identity-hashed collections are available.
// Issue 4161.
library identity_set_test;

import 'package:unittest/unittest.dart';
import 'package:serialization/src/serialization_helpers.dart';

class Foo {
  var x;
  Foo(this.x);
  int get hashCode => x.hashCode;
  bool operator ==(a) => a.x == x;
}

main() {
  test('basic', () {
    var one = new Foo(3);
    var two = new Foo(3);
    var map = new Map();
    var identityMap = new IdentityMap();
    map[one] = one;
    map[two] = two;
    identityMap[one] = one;
    identityMap[two] = two;
    expect(map.length, 1);
    expect(identityMap.length, 2);
    for (var each in identityMap.values) {
      expect(each, one);
    }
  });

  test('uniquing primitives', () {
    var map = new IdentityMap();
    var one = 'one';
    var two = new String.fromCharCodes(one.charCodes);
    map[one] = 1;
    expect(map[two], 1);
    expect(map[one], 1);
  });
}