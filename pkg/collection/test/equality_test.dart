// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests equality utilities.

import "dart:collection";
import "package:collection/collection.dart";
import "package:unittest/unittest.dart";

main() {
  test("IterableEquality - List", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 2.0, 3.0, 4.0, 5.0];
    expect(const IterableEquality().equals(l1, l2), isTrue);
    Equality iterId = const IterableEquality(const IdentityEquality());
    expect(iterId.equals(l1, l2), isFalse);  /// 01: ok
  });

  test("IterableEquality - LinkedSet", () {
    var l1 = new LinkedHashSet.from([1, 2, 3, 4, 5]);
    var l2 = new LinkedHashSet.from([1.0, 2.0, 3.0, 4.0, 5.0]);
    expect(const IterableEquality().equals(l1, l2), isTrue);
    Equality iterId = const IterableEquality(const IdentityEquality());
    expect(iterId.equals(l1, l2), isFalse);  /// 02: ok
  });

  test("ListEquality", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 2.0, 3.0, 4.0, 5.0];
    expect(const ListEquality().equals(l1, l2),
           isTrue);
    Equality listId = const ListEquality(const IdentityEquality());
    expect(listId.equals(l1, l2), isFalse);  /// 03: ok
  });

  test("ListInequality length", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    expect(const ListEquality().equals(l1, l2),
           isFalse);
    expect(const ListEquality(const IdentityEquality()).equals(l1, l2),
           isFalse);
  });

  test("ListInequality value", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 2.0, 3.0, 4.0, 6.0];
    expect(const ListEquality().equals(l1, l2),
           isFalse);
    expect(const ListEquality(const IdentityEquality()).equals(l1, l2),
           isFalse);
  });

  test("UnorderedIterableEquality", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 3.0, 5.0, 4.0, 2.0];
    expect(const UnorderedIterableEquality().equals(l1, l2),
           isTrue);
    Equality uniterId =
        const UnorderedIterableEquality(const IdentityEquality());
    expect(uniterId.equals(l1, l2), isFalse);  /// 04: ok
  });

  test("UnorderedIterableInequality length", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 3.0, 5.0, 4.0, 2.0, 1.0];
    expect(const UnorderedIterableEquality().equals(l1, l2),
           isFalse);
    expect(const UnorderedIterableEquality(const IdentityEquality())
               .equals(l1, l2),
           isFalse);
  });

  test("UnorderedIterableInequality values", () {
    var l1 = [1, 2, 3, 4, 5];
    var l2 = [1.0, 3.0, 5.0, 4.0, 6.0];
    expect(const UnorderedIterableEquality().equals(l1, l2),
           isFalse);
    expect(const UnorderedIterableEquality(const IdentityEquality())
               .equals(l1, l2),
           isFalse);
  });

  test("SetEquality", () {
    var l1 = new HashSet.from([1, 2, 3, 4, 5]);
    var l2 = new LinkedHashSet.from([1.0, 3.0, 5.0, 4.0, 2.0]);
    expect(const SetEquality().equals(l1, l2),
           isTrue);
    Equality setId = const SetEquality(const IdentityEquality());
    expect(setId.equals(l1, l2), isFalse);  /// 05: ok
  });

  test("SetInequality length", () {
    var l1 = new HashSet.from([1, 2, 3, 4, 5]);
    var l2 = new LinkedHashSet.from([1.0, 3.0, 5.0, 4.0, 2.0, 6.0]);
    expect(const SetEquality().equals(l1, l2),
           isFalse);
    expect(const SetEquality(const IdentityEquality()).equals(l1, l2),
           isFalse);
  });

  test("SetInequality value", () {
    var l1 = new HashSet.from([1, 2, 3, 4, 5]);
    var l2 = new LinkedHashSet.from([1.0, 3.0, 5.0, 4.0, 6.0]);
    expect(const SetEquality().equals(l1, l2),
           isFalse);
    expect(const SetEquality(const IdentityEquality()).equals(l1, l2),
           isFalse);
  });

  var map1a = {"x": [1, 2, 3], "y": [true, false, null]};
  var map1b = {"x": [4.0, 5.0, 6.0], "y": [false, true, null]};
  var map2a = {"x": [3.0, 2.0, 1.0], "y": [false, true, null]};
  var map2b = {"x": [6, 5, 4], "y": [null, false, true]};
  var l1 = [map1a, map1b];
  var l2 = [map2a, map2b];
  var s1 = new Set.from(l1);
  var s2 = new Set.from([map2b, map2a]);

  test("RecursiveEquality", () {
    const unordered = const UnorderedIterableEquality();
    expect(unordered.equals(map1a["x"], map2a["x"]),
        isTrue);
    expect(unordered.equals(map1a["y"], map2a["y"]),
        isTrue);
    expect(unordered.equals(map1b["x"], map2b["x"]),
        isTrue);
    expect(unordered.equals(map1b["y"], map2b["y"]),
        isTrue);
    const mapval = const MapEquality(values: unordered);
    expect(
        mapval.equals(map1a, map2a),
        isTrue);
    expect(mapval.equals(map1b, map2b),
        isTrue);
    const listmapval = const ListEquality(mapval);
    expect(listmapval.equals(l1, l2),
        isTrue);
    const setmapval = const SetEquality(mapval);
    expect(setmapval.equals(s1, s2),
        isTrue);
  });

  test("DeepEquality", () {
    var colleq = const DeepCollectionEquality.unordered();
    expect(colleq.equals(map1a["x"], map2a["x"]),
        isTrue);
    expect(colleq.equals(map1a["y"], map2a["y"]),
        isTrue);
    expect(colleq.equals(map1b["x"], map2b["x"]),
        isTrue);
    expect(colleq.equals(map1b["y"], map2b["y"]),
        isTrue);
    expect(colleq.equals(map1a, map2a),
        isTrue);
    expect(colleq.equals(map1b, map2b),
        isTrue);
    expect(colleq.equals(l1, l2),
        isTrue);
    expect(colleq.equals(s1, s2),
        isTrue);
  });
}
