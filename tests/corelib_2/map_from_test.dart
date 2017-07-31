// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map.from.test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  testWithConstMap();
  testWithNonConstMap();
  testWithHashMap();
  testWithLinkedMap();
}

testWithConstMap() {
  var map = const {'b': 42, 'a': 43};
  var otherMap = new Map.from(map);
  Expect.isTrue(otherMap is Map);
  Expect.isTrue(otherMap is HashMap);
  Expect.isTrue(otherMap is LinkedHashMap);

  Expect.equals(2, otherMap.length);
  Expect.equals(2, otherMap.keys.length);
  Expect.equals(2, otherMap.values.length);

  var count = (map) {
    int cnt = 0;
    map.forEach((a, b) {
      cnt += b;
    });
    return cnt;
  };

  Expect.equals(42 + 43, count(map));
  Expect.equals(count(map), count(otherMap));
}

testWithNonConstMap() {
  var map = {'b': 42, 'a': 43};
  var otherMap = new Map.from(map);
  Expect.isTrue(otherMap is Map);
  Expect.isTrue(otherMap is HashMap);
  Expect.isTrue(otherMap is LinkedHashMap);

  Expect.equals(2, otherMap.length);
  Expect.equals(2, otherMap.keys.length);
  Expect.equals(2, otherMap.values.length);

  int count(map) {
    int count = 0;
    map.forEach((a, b) {
      count += b;
    });
    return count;
  }

  ;

  Expect.equals(42 + 43, count(map));
  Expect.equals(count(map), count(otherMap));

  // Test that adding to the original map does not change otherMap.
  map['c'] = 44;
  Expect.equals(3, map.length);
  Expect.equals(2, otherMap.length);
  Expect.equals(2, otherMap.keys.length);
  Expect.equals(2, otherMap.values.length);

  // Test that adding to otherMap does not change the original map.
  otherMap['c'] = 44;
  Expect.equals(3, map.length);
  Expect.equals(3, otherMap.length);
  Expect.equals(3, otherMap.keys.length);
  Expect.equals(3, otherMap.values.length);
}

testWithHashMap() {
  var map = const {'b': 1, 'a': 2, 'c': 3};
  var otherMap = new HashMap.from(map);
  Expect.isTrue(otherMap is Map);
  Expect.isTrue(otherMap is HashMap);
  Expect.isTrue(otherMap is! LinkedHashMap);
  var i = 1;
  for (var val in map.values) {
    Expect.equals(i++, val);
  }
}

testWithLinkedMap() {
  var map = const {'b': 1, 'a': 2, 'c': 3};
  var otherMap = new LinkedHashMap.from(map);
  Expect.isTrue(otherMap is Map);
  Expect.isTrue(otherMap is HashMap);
  Expect.isTrue(otherMap is LinkedHashMap);
  var i = 1;
  for (var val in map.values) {
    Expect.equals(i++, val);
  }
}
