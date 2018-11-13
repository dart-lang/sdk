// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library collection.from.test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  for (Iterable<num> elements in [
    new Set<num>(),
    <num>[],
    const <num>[],
    const <num, int>{}.keys,
    const <int, num>{}.values,
    new Iterable<num>.generate(0),
    new Set<num>()..add(1)..add(2)..add(4),
    <num>[1, 2, 4],
    new Iterable<num>.generate(3, (i) => [1, 2, 4][i]),
    const <num>[1, 2, 4],
    const <num, int>{1: 0, 2: 0, 4: 0}.keys,
    const <int, num>{1: 1, 2: 2, 4: 4}.values,
  ]) {
    int elementCount = elements.length;
    check(elements, new List<num>.from(elements));
    check(elements, new List<int>.from(elements));
    check(elements, new List<Object>.from(elements));
    check(elements, new List<num>.from(elements, growable: true));
    check(elements, new List<int>.from(elements, growable: true));
    check(elements, new List<Object>.from(elements, growable: true));
    check(elements, new List<num>.from(elements, growable: false));
    check(elements, new List<int>.from(elements, growable: false));
    check(elements, new List<Object>.from(elements, growable: false));
    check(elements, new Queue<num>.from(elements));
    check(elements, new Queue<int>.from(elements));
    check(elements, new Queue<Object>.from(elements));
    check(elements, new ListQueue<num>.from(elements));
    check(elements, new ListQueue<int>.from(elements));
    check(elements, new ListQueue<Object>.from(elements));
    check(elements, new DoubleLinkedQueue<num>.from(elements));
    check(elements, new DoubleLinkedQueue<int>.from(elements));
    check(elements, new DoubleLinkedQueue<Object>.from(elements));
    check(elements, new Set<num>.from(elements));
    check(elements, new Set<int>.from(elements));
    check(elements, new Set<Object>.from(elements));
    check(elements, new HashSet<num>.from(elements));
    check(elements, new HashSet<int>.from(elements));
    check(elements, new HashSet<Object>.from(elements));
    check(elements, new LinkedHashSet<num>.from(elements));
    check(elements, new LinkedHashSet<int>.from(elements));
    check(elements, new LinkedHashSet<Object>.from(elements));
    check(elements, new SplayTreeSet<num>.from(elements));
    check(elements, new SplayTreeSet<int>.from(elements));
    check(elements, new SplayTreeSet<Object>.from(elements));
    // Sanity check that elements didn't change.
    Expect.equals(elementCount, elements.length);

    // Lists may be growable or not growable.
    {
      var list = new List<num>.from(elements, growable: true);
      Expect.equals(elementCount, list.length);
      list.add(42);
      Expect.equals(elementCount + 1, list.length);
    }
    {
      var list = new List<num>.from(elements);
      Expect.equals(elementCount, list.length);
      list.add(42);
      Expect.equals(elementCount + 1, list.length);
    }
    {
      var list = new List<num>.from(elements, growable: false);
      Expect.equals(elementCount, list.length);
      Expect.throwsUnsupportedError(() {
        list.add(42);
      });
      Expect.equals(elementCount, list.length);
    }
  }
}

void check(Iterable<num> initial, Iterable other) {
  Expect.equals(initial.length, other.length);

  for (var element in other) {
    initial.contains(element);
  }

  for (var element in initial) {
    other.contains(element);
  }
}
