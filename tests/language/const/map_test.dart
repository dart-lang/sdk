// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// Returns its argument.
///
/// Prevents static optimizations and inlining.
@pragma('vm:never-inline')
@pragma('dart2js:noInline')
dynamic getValueNonOptimized(dynamic x) {
  // DateTime.now() cannot be predicted statically, never equal to 42.
  if (DateTime.now().millisecondsSinceEpoch == 42) {
    return getValueNonOptimized(2);
  }
  return x;
}

main() {
  // TODO(terry): Should check:
  //   - simple expressions are const e.g., 2 + 3, true && !false, etc.
  //   - const with final and/or static with same const attributes
  //     Additionally new class instances with a static const same identity
  //   - const for all types (int, num, double, String, boolean, and objects)
  //   - canonicalization - const created only once same identity e.g.,
  //
  //     getConstMap() => const [1, 2];
  //     var a = getConstMap();
  //     var b = getConstMap();
  //     Expect.equals(a.hashCode, b.hashCode);

  // Make sure that const maps use the == operator and not object identity. The
  // specification does not explicitly require it, otherwise ints and Strings
  // wouldn't make much sense as keys.
  final map = const {1: 42, 'foo': 499, 2: 'bar'};
  Expect.equals(42, map[getValueNonOptimized(1.0)]);
  Expect.equals(
      499, map[getValueNonOptimized(new String.fromCharCodes('foo'.runes))]);
  Expect.equals('bar', map[getValueNonOptimized(2)]);

  void testThrowsNoModification(void Function() f) {
    Expect.throws(f, (e) {
      return e is UnsupportedError;
    });

    Expect.equals(42, map[getValueNonOptimized(1.0)]);
    Expect.equals(
        499, map[getValueNonOptimized(new String.fromCharCodes('foo'.runes))]);
    Expect.equals('bar', map[getValueNonOptimized(2)]);
    Expect.isNull(map[1024]);
  }

  testThrowsNoModification(() {
    map[1024] = 'something';
  });

  testThrowsNoModification(() {
    map.addAll({1024: 'something'});
  });

  testThrowsNoModification(() {
    map.putIfAbsent(1024, () => 'something');
  });

  testThrowsNoModification(() {
    map.putIfAbsent(1, () => 1024);
  });

  testThrowsNoModification(() {
    map.clear();
  });

  testThrowsNoModification(() {
    map.remove(1024);
  });

  testThrowsNoModification(() {
    map.remove(1);
  });

  testThrowsNoModification(() {
    map.addEntries([MapEntry(1024, 'something')]);
  });

  testThrowsNoModification(() {
    map.update(2, (Object value) => 42);
  });

  testThrowsNoModification(() {
    map.updateAll((Object? key, Object? value) => '123');
  });

  testThrowsNoModification(() {
    map.removeWhere((Object? key, Object? value) => true);
  });
}
