// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:expect/expect.dart';

main() {
  // Regression test for https://github.com/dart-lang/sdk/issues/36052.
  // JS compilers shouldn't produce `undefined` when a Map/Set key is not found.
  testMap({});
  testMap(Map.identity());
  testMap(LinkedHashMap(
      equals: (x, y) => x == y,
      hashCode: (x) => x.hashCode,
      isValidKey: (_) => true));

  testSet(Set());
  testSet(Set.identity());
  testSet(LinkedHashSet(
      equals: (x, y) => x == y,
      hashCode: (x) => x.hashCode,
      isValidKey: (_) => true));
}

testMap(Map<Object, Object> map) {
  var t = map.runtimeType.toString();
  var s = ' (length ${map.length})';
  checkUndefined('$t.[]$s', map['hi']);
  checkUndefined('$t.putIfAbsent$s', map.putIfAbsent('hi', () {}));
  checkUndefined('$t.remove$s', map.remove('hi'));
  if (map.isEmpty) {
    map['hello'] = 'there';
    testMap(map);
  }
}

testSet(Set<Object> set) {
  var t = set.runtimeType.toString();
  var s = ' (length ${set.length})';
  checkUndefined('$t.lookup$s', set.lookup('hi'));
  if (set.isEmpty) {
    set.add('hello');
    testSet(set);
  }
}

/// Fails if [x] incorrectly uses the default argument instead of being `null`
/// (i.e. because `x` is undefined).
checkUndefined(String method, [Object x = 'error']) {
  // TODO(jmesserly): this check is specific to implementation details of DDC's
  // current calling conventions. These conventions may change.
  // Ideally we'd have an `undefined` constant in "package:js" and use that
  // here instead.
  Expect.isNull(x,
      'error in $method: result treated as missing argument (JS undefined?)');
}
