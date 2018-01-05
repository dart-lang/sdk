// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  testIterable();
  testList();
}

final elements = <C>[c, d, e, f, null];

void testIterable() {
  var iterable = new Iterable<C>.generate(elements.length, (n) => elements[n]);
  // Down-cast
  {
    // An iterable that (likely) can do direct access.
    var dIterable = Iterable.castTo<C, D>(iterable);

    Expect.throws(() => dIterable.first, null, "1.first");
    Expect.equals(d, dIterable.elementAt(1));
    Expect.throws(() => dIterable.elementAt(2), null, "1.2"); // E is not D.
    Expect.equals(f, dIterable.skip(3).first); // Skip does not access element.
    Expect.equals(null, dIterable.skip(3).elementAt(1));

    Expect.throws(() => dIterable.toList(), null, "1.toList");
  }

  {
    // An iterable that cannot do direct access.
    var dIterable2 = Iterable.castTo<C, D>(iterable.where((_) => true));

    Expect.throws(() => dIterable2.first, null, "2.first");
    Expect.equals(d, dIterable2.elementAt(1));
    Expect.throws(() => dIterable2.elementAt(2), null, "2.2"); // E is not D.
    Expect.equals(f, dIterable2.skip(3).first); // Skip does not access element.
    Expect.equals(null, dIterable2.skip(3).elementAt(1));

    Expect.throws(() => dIterable2.toList(), null, "2.toList");
  }

  {
    // Iterable that definitely won't survive accessing element 2.
    var iterable3 = new Iterable<C>.generate(
        elements.length, (n) => n == 3 ? throw "untouchable" : elements[n]);
    var dIterable3 = Iterable.castTo<C, D>(iterable3);

    Expect.throws(() => dIterable3.first, null, "3.first");
    Expect.equals(d, dIterable3.elementAt(1));
    Expect.throws(() => dIterable3.elementAt(3), null, "3.3");
    // Skip does not access element.
    Expect.equals(null, dIterable3.skip(4).first);
    Expect.equals(null, dIterable3.skip(3).elementAt(1));

    Expect.throws(() => dIterable3.toList(), null, "3.toList");
  }

  // Up-cast.
  {
    var oIterable4 = Iterable.castTo<C, Object>(iterable);
    Expect.listEquals(elements, oIterable4.toList());
  }
}

void testList() {
  // Down-cast.
  var list = new List<C>.from(elements);
  var dList = List.castTo<C, D>(list);

  Expect.throws(() => dList.first); // C is not D.
  Expect.equals(d, dList[1]);
  Expect.throws(() => dList[2]); // E is not D.
  Expect.equals(f, dList[3]);
  Expect.equals(null, dList.last);

  Expect.throws(() => dList.toList());

  dList[2] = d;
  Expect.equals(d, dList[2]); // Setting works.

  // Up-cast.
  var list2 = new List<C>.from(elements);
  var dList2 = List.castTo<C, Object>(list2);
  Expect.listEquals(elements, dList2);
  Expect.throws(() => dList2[2] = new Object()); // Cannot set non-C.
  Expect.listEquals(elements, dList2);
}

void testSet() {
  var set = new Set<C>.from(elements); // Linked HashSet.
  Expect.listEquals(elements, set.toList()); // Preserves order.

  var dSet = Set.castTo<C, D>(set);

  // Preserves order.
  Expect.throws(() => dSet.first); // C is not D.
  Expect.equals(d, dSet.elementAt(1));
  Expect.throws(() => dSet.elementAt(2)); // E is not D.

  Expect.throws(() => dSet.toList());

  // Contains is not typed.
  var newC = new C();
  Expect.isFalse(dSet.contains(newC));
  dSet.add(newC);
  Expect.isTrue(dSet.contains(newC));

  Expect.equals(5, dSet.length);
  dSet.remove(newC);
  Expect.equals(5, dSet.length);
  dSet.remove(c); // Success, no type checks.
  Expect.equals(4, dSet.length);

  // Up-cast
  var set2 = new Set<C>.from(elements);
  var dSet2 = Set.castTo<C, Object>(set2);

  var newObject = new Object();
  Expect.throws(() => dSet2.add(newObject));
  Expect.isFalse(dSet.contains(newObject));

  var toSet2 = dSet2.toSet();
  Expect.isTrue(toSet2 is LinkedHashSet<Object>);
  Expect.isTrue(toSet2 is! LinkedHashSet<C>);

  // Custom emptySet.

  var set3 = new Set<C>.from(elements);
  var dSet3 = Set.castTo<C, Object>(set3, newSet: <T>() => new HashSet<T>());

  var toSet3 = dSet3.toSet();
  Expect.isTrue(toSet3 is HashSet<Object>);
  Expect.isTrue(toSet3 is HashSet<C>);
  Expect.isTrue(toSet3 is! LinkedHashSet<Object>);
}

void testMap() {
  var map = new Map.fromIterables(elements, elements);

  var dMap = Map.castTo<C, C, D, D>(map);

  Expect.isTrue(dMap is Map<D, D>);

  Expect.equals(null, dMap[new C()]);
  Expect.throws(() => dMap[c]);
  Expect.isTrue(dMap.containsKey(c));
  Expect.equals(d, dMap[d]);
  Expect.throws(() => dMap[e]);
  Expect.equals(null, dMap[null]);

  Expect.equals(5, dMap.length);
  dMap.remove(c); // Success, no type checks along the way.
  Expect.equals(4, dMap.length);
  Expect.equals(null, dMap[c]);

  Expect.throws(() => dMap[c] = d);
  Expect.throws(() => dMap[d] = c);
  Expect.equals(4, dMap.length);

  Expect.isTrue(dMap.keys is Iterable<D>);
  Expect.isTrue(dMap.values is Iterable<D>);
  Expect.throws(() => dMap.keys.toList());
  Expect.throws(() => dMap.values.toList());
}

class C {}

class D extends C {}

class E extends C {}

class F implements D, E {}

final c = new C();
final d = new D();
final e = new E();
final f = new F();
