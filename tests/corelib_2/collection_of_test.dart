// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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
    String sourceType = elements.runtimeType.toString();
    check(sourceType, elements, new List<num>.of(elements));
    Expect.throwsTypeError(() => new List<int>.of(elements));
    check(sourceType, elements, new List<Object>.of(elements));
    check(sourceType, elements, new Queue<num>.of(elements));
    Expect.throwsTypeError(() => new Queue<int>.of(elements));
    check(sourceType, elements, new Queue<Object>.of(elements));
    check(sourceType, elements, new ListQueue<num>.of(elements));
    Expect.throwsTypeError(() => new ListQueue<int>.of(elements));
    check(sourceType, elements, new ListQueue<Object>.of(elements));
    check(sourceType, elements, new DoubleLinkedQueue<num>.of(elements));
    Expect.throwsTypeError(() => new DoubleLinkedQueue<int>.of(elements));
    check(sourceType, elements, new DoubleLinkedQueue<Object>.of(elements));
    check(sourceType, elements, new Set<num>.of(elements));
    Expect.throwsTypeError(() => new Set<int>.of(elements));
    check(sourceType, elements, new Set<Object>.of(elements));
    check(sourceType, elements, new HashSet<num>.of(elements));
    Expect.throwsTypeError(() => new HashSet<int>.of(elements));
    check(sourceType, elements, new HashSet<Object>.of(elements));
    check(sourceType, elements, new LinkedHashSet<num>.of(elements));
    Expect.throwsTypeError(() => new LinkedHashSet<int>.of(elements));
    check(sourceType, elements, new LinkedHashSet<Object>.of(elements));
    check(sourceType, elements, new SplayTreeSet<num>.of(elements));
    Expect.throwsTypeError(() => new SplayTreeSet<int>.of(elements));
    check(sourceType, elements, new SplayTreeSet<Object>.of(elements));

    // Inference applies to the `of` constructor, unlike the `from` constructor.
    Expect.isTrue(new List.of(elements) is Iterable<num>);
    Expect.isTrue(new Queue.of(elements) is Iterable<num>);
    Expect.isTrue(new ListQueue.of(elements) is Iterable<num>);
    Expect.isTrue(new DoubleLinkedQueue.of(elements) is Iterable<num>);
    Expect.isTrue(new Set.of(elements) is Iterable<num>);
    Expect.isTrue(new HashSet.of(elements) is Iterable<num>);
    Expect.isTrue(new LinkedHashSet.of(elements) is Iterable<num>);
    Expect.isTrue(new SplayTreeSet.of(elements) is Iterable<num>);

    Expect.isTrue(new List.of(elements) is! Iterable<int>);
    Expect.isTrue(new Queue.of(elements) is! Iterable<int>);
    Expect.isTrue(new ListQueue.of(elements) is! Iterable<int>);
    Expect.isTrue(new DoubleLinkedQueue.of(elements) is! Iterable<int>);
    Expect.isTrue(new Set.of(elements) is! Iterable<int>);
    Expect.isTrue(new HashSet.of(elements) is! Iterable<int>);
    Expect.isTrue(new LinkedHashSet.of(elements) is! Iterable<int>);
    Expect.isTrue(new SplayTreeSet.of(elements) is! Iterable<int>);
  }
}

void check(String sourceType, Iterable<num> source, Iterable target) {
  String targetType = target.runtimeType.toString();
  String name = "$sourceType->$targetType";
  Expect.equals(source.length, target.length, "$name.length");

  for (var element in target) {
    Expect.isTrue(source.contains(element), "$name:$element in source");
  }

  for (var element in source) {
    Expect.isTrue(target.contains(element), "$name:$element in target");
  }
}
