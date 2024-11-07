// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

/// Bug in dev-compiler's [putIfAbsent](https://dartbug.com/47852).
void originalError() {
  final map = {};
  final key = DateTime.now(); // Overrides Object.==/hashCode
  bool wasAbsent = false;
  map.putIfAbsent(key, () {
    wasAbsent = true;
    Expect.isFalse(
        map.containsKey(key), 'containsKey should be false in putIfAbsent');
    return key;
  });
  Expect.isTrue(wasAbsent);
}

enum AnEnum { element1, element2 }

class Dumb {
  final Object field;
  Dumb(this.field);

  // Dumb hashCode to stress same-bucket paths.
  int get hashCode => 0;
  bool operator ==(Object other) => other is Dumb && this.field == other.field;

  String toString() => 'Dumb($field)';
}

// Test keys. These instances of classes that do and don't override `==` and
// `hashCode`, and a variety of primitive values since we generally don't know
// whether they have overrides.
final keys = [
  123,
  3.14,
  10.0,  // int or double depending on platform.
  'aString',
  #someSymbol,
  true,
  false,
  null,
  AnEnum.element1,
  AnEnum.element2,
  DateTime.now(),
  Dumb(1),
  Dumb(2),
  Dumb(3),
  Object(),
  const [1],
  const {1},
  const {'x'},
  // const maps have different implementation types depending on keys.
  const {'x': 1},
  const {123: 1},
  const {AnEnum.element1: 1, #foo: 2},
];

void testMap(Map<Object?, Object?> map) {
  for (final key in keys) {
    bool wasAbsent = false;
    map.putIfAbsent(key, () {
      wasAbsent = true;
      Expect.isFalse(map.containsKey(key),
          'containsKey should be false in putIfAbsent. key = $key');
      return key;
    });
    Expect.isTrue(wasAbsent);
    Expect.isTrue(map.containsKey(key), 'Key was not added. key = $key');
  }
}

void main() {
  originalError();

  testMap({});
  testMap(Map()); // Should be same as `{}`.
  testMap(HashMap());
  testMap(LinkedHashMap()); // Should be same as `{}`.

  testMap(Map.identity());
  testMap(HashMap.identity());
  testMap(LinkedHashMap.identity()); // Should be same as `Map.identity()`.

  // Custom maps:
  testMap(HashMap(
      equals: (k1, k2) => k2 == k1,
      hashCode: (key) => key.hashCode + 1,
      isValidKey: (_) => true));
  testMap(LinkedHashMap(
      equals: (k1, k2) => k2 == k1,
      hashCode: (key) => key.hashCode + 1,
      isValidKey: (_) => true));
}
