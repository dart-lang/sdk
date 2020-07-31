// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";
import 'cast_helper.dart';

void main() {
  testOrder();
  testDowncast();
  testUpcast();
  testNewSet();
}

void testOrder() {
  var setEls = new Set<C>.from(elements); // Linked HashSet.
  Expect.listEquals(elements, setEls.toList()); // Preserves order.
}

void testDowncast() {
  var setEls = new Set<C>.from(elements);
  var dSet = Set.castFrom<C, D>(setEls);

  // Preserves order.
  Expect.throws(() => dSet.first); // C is not D.
  Expect.equals(d, dSet.elementAt(1));
  Expect.throws(() => dSet.elementAt(2)); // E is not D.
  Expect.equals(f, dSet.elementAt(3));
  Expect.equals(null, dSet.elementAt(4));

  Expect.throws(() => dSet.toList());

  // Contains should not be typed.
  var newC = new C();
  Expect.isFalse(dSet.contains(newC));
  Expect.throws(() => dSet.add(newC));
  Expect.isFalse(dSet.contains(newC));
  Expect.isTrue(dSet.contains(c));

  // Remove and length should not be typed.
  Expect.equals(5, dSet.length);
  dSet.remove(c); // Success, no type checks.
  Expect.equals(4, dSet.length);
}

void testUpcast() {
  var setEls = new Set<C>.from(elements);
  var objectSet = Set.castFrom<C, Object>(setEls);

  Expect.listEquals(elements, objectSet.toList());

  var newObject = new Object();
  Expect.throws(() => objectSet.add(newObject));
  Expect.isFalse(objectSet.contains(newObject));

  var toSet = objectSet.toSet();
  Expect.isTrue(toSet is LinkedHashSet<Object>);
  Expect.isFalse(toSet is LinkedHashSet<C>);
}

void testNewSet() {
  // Specified custom newSet as empty HashSet.
  var setEls = new Set<C>.from(elements);
  var customNewSet;
  var objectSet2 = Set.castFrom<C, Object>(setEls,
      newSet: <T>() => customNewSet = new HashSet<T>());

  var customToSet = objectSet2.toSet();
  Expect.isTrue(customToSet is HashSet<Object>);
  Expect.isFalse(customToSet is HashSet<C>);
  Expect.identical(customToSet, customNewSet);
}
