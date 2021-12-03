// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.12

import "package:expect/expect.dart";
import 'dart:collection';
import 'package:compiler/src/util/setlet.dart';

void main() {
  for (int i = 1; i <= 32; i++) {
    test(i);
  }

  testAllLikeSet();
}

void test(int size) {
  final setlet = Setlet<int?>();
  for (int i = 0; i < size; i++) {
    Expect.isTrue(setlet.isEmpty == (i == 0));
    setlet.add(i);
    Expect.equals(i + 1, setlet.length);
    Expect.isFalse(setlet.isEmpty);
    for (int j = 0; j < size + size; j++) {
      Expect.isTrue(setlet.contains(j) == (j <= i));
    }
    Expect.isTrue(setlet.remove(i));
    Expect.isFalse(setlet.remove(i + 1));
    setlet.add(i);

    List expectedElements = [];
    for (int j = 0; j <= i; j++) expectedElements.add(j);

    List actualElements = [];
    setlet.forEach((each) => actualElements.add(each));
    Expect.listEquals(expectedElements, actualElements);

    actualElements = [];
    for (var each in setlet) actualElements.add(each);
    Expect.listEquals(expectedElements, actualElements);
  }

  for (int i = 0; i < size; i++) {
    Expect.equals(size, setlet.length);

    // Try removing all possible ranges one by one and re-add them.
    for (int k = size; k > i; --k) {
      for (int j = i; j < k; j++) {
        Expect.isTrue(setlet.remove(j));
        int expectedSize = size - (j - i + 1);
        Expect.equals(expectedSize, setlet.length);
        Expect.isFalse(setlet.remove(j));
        Expect.isFalse(setlet.contains(j));

        Expect.isFalse(setlet.contains(null));
        setlet.add(null);
        Expect.equals(expectedSize + 1, setlet.length);
        Expect.isTrue(setlet.contains(null));
        Expect.isTrue(setlet.remove(null));
        Expect.equals(expectedSize, setlet.length);
        Expect.isFalse(setlet.remove(null));
      }

      for (int j = i; j < k; j++) {
        setlet.add(j);
      }
    }

    Expect.equals(size, setlet.length);
    Expect.isTrue(setlet.contains(i));
  }
}

void testAllLikeSet() {
  // For a variety of inputs and operations, test that Setlet behaves just like
  // Set.
  final List<List<int>> samples = [
    [],
    [1],
    [1, 2],
    [2, 1],
    [1, 3],
    [3, 1],
    [1, 2, 3],
    [3, 1, 2],
    [1, 2, 3, 4, 5, 6, 7],
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    [1, 2, 3, 4, 5, 6, 7, 8, 9],
    [6, 7, 8, 9, 10, 11],
    [7, 8, 6, 5],
  ];

  for (var a in samples) {
    for (var b in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
      testSetXElement('add', (s, e) => s.add(e), a, b);
      testSetXElement('remove', (s, e) => s.remove(e), a, b);
      testSetXElement('contains', (s, e) => s.contains(e), a, b);
      testSetXElement('lookup', (s, e) => s.lookup(e), a, b);
    }
  }

  for (var a in samples) {
    for (var b in samples) {
      testSetXSet('addAll', (s, t) => s.addAll(t), a, b);
      testSetXSet('removeAll', (s, t) => s.removeAll(t), a, b);
      testSetXSet('retainAll', (s, t) => s.retainAll(t), a, b);
      testSetXSet('containsAll', (s, t) => s.containsAll(t), a, b);
      testSetXSet('union', (s, t) => s.union(t), a, b);
      testSetXSet('intersection', (s, t) => s.intersection(t), a, b);
      testSetXSet('difference', (s, t) => s.difference(t), a, b);
    }
  }
}

void testSetXElement<E, R>(
    String name, R Function(Set<E>, E) fn, Iterable<E> a, E b) {
  final set1 = LinkedHashSet.of(a);
  final setlet1 = Setlet.of(a);

  final setResult = fn(set1, b);
  final setletResult = fn(setlet1, b);

  final operationName = '$name $a $b';
  checkResult(operationName, setResult, setletResult);
  checkModifications(operationName, set1, setlet1);
}

void testSetXSet<E, R>(
    String name, R Function(Set<E>, Set<E>) fn, Iterable<E> a, Iterable<E> b) {
  final set1 = LinkedHashSet.of(a);
  final set2 = LinkedHashSet.of(b);
  final setlet1 = Setlet.of(a);
  final setlet2 = Setlet.of(b);

  final setResult = fn(set1, set2);
  final setletResult = fn(setlet1, setlet2);

  final operationName = '$name $a $b';
  checkResult(operationName, setResult, setletResult);
  checkModifications(operationName, set1, setlet1);
}

void checkResult(
    String operationName, dynamic setResult, dynamic setletResult) {
  if (setResult == null || setResult is bool || setResult is num) {
    Expect.equals(setResult, setletResult, '$operationName');
  } else if (setResult is Iterable) {
    Expect.isTrue(setletResult is Iterable, '$operationName: returns Iterable');
    Expect.equals(setResult.isEmpty, setletResult.isEmpty,
        '$operationName: same isEmpty');
    Expect.equals(
        setResult.length, setletResult.length, '$operationName: same length');
    Expect.listEquals(setResult.toList(), setletResult.toList(),
        '$operationName: same toList() result');
    Expect.listEquals([...setResult], [...setletResult],
        '$operationName: same spread result');
  } else {
    Expect.isFalse(true, '$operationName: unexpected result type');
  }
}

void checkModifications<E>(
    String operationName, Set<E> setReceiver, Set<E> setletReceiver) {
  Expect.equals(setReceiver.length, setletReceiver.length,
      '$operationName: same post-operation receiver length');
  Expect.listEquals(setReceiver.toList(), setletReceiver.toList(),
      '$operationName: same post-operation receiver contents');
}
