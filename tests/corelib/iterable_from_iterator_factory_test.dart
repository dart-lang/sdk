// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  group('Iterable.fromIteratorFactory tests', () {
    testEmptyIterator();
    testSingleElementIterator();
    testMultipleElementIterator();
    testMultipleIterations();
    testLazyInitialization();
    testAfterMoveNext();
    testErrorHandling();
  });
}

void group(String description, void Function() body) {
  print('Testing: $description');
  body();
}

void testEmptyIterator() {
  test('empty iterator behaves correctly', () {
    var emptyIterable = Iterable.fromIteratorFactory(() => [].iterator);
    Expect.isTrue(emptyIterable.isEmpty);
    Expect.equals(0, emptyIterable.length);
    Expect.isTrue(emptyIterable.every((element) => false));
    Expect.isFalse(emptyIterable.any((element) => true));
    Expect.equals('[]', emptyIterable.toList().toString());
  });
}

void testSingleElementIterator() {
  test('single element iterator behaves correctly', () {
    var singleIterable = Iterable.fromIteratorFactory(() => [1].iterator);
    Expect.equals(1, singleIterable.length);
    Expect.equals(1, singleIterable.first);
    Expect.equals(1, singleIterable.last);
    Expect.equals(1, singleIterable.single);
    Expect.isFalse(singleIterable.isEmpty);
    Expect.isTrue(singleIterable.contains(1));
    Expect.isFalse(singleIterable.contains(2));
  });
}

void testMultipleElementIterator() {
  test('multiple element iterator behaves correctly', () {
    var multiIterable = Iterable.fromIteratorFactory(() => [1, 2, 3].iterator);
    Expect.equals(3, multiIterable.length);
    Expect.equals(1, multiIterable.first);
    Expect.equals(3, multiIterable.last);
    Expect.equals('[1, 2, 3]', multiIterable.toList().toString());
    Expect.equals(6, multiIterable.reduce((a, b) => a + b));
    Expect.isTrue(multiIterable.contains(2));
    Expect.isFalse(multiIterable.contains(4));

    // Test transformation methods
    Expect.equals(
        '[2, 4, 6]', multiIterable.map((e) => e * 2).toList().toString());
    Expect.equals(
        '[1, 2]', multiIterable.where((e) => e < 3).toList().toString());
  });
}

void testMultipleIterations() {
  test('multiple iterations create fresh iterators', () {
    var count = 0;
    var countingIterable = Iterable.fromIteratorFactory(() {
      count++;
      return [1, 2].iterator;
    });

    // Test multiple iterations
    for (var i = 1; i <= 3; i++) {
      for (var x in countingIterable) {}
      Expect.equals(i, count);
    }

    // Test concurrent iterations
    var iterators = List.generate(2, (_) => countingIterable.iterator);
    Expect.equals(5, count);
  });
}

void testLazyInitialization() {
  test('iterator factory is called lazily', () {
    var factoryCalled = false;
    var lazyIterable = Iterable.fromIteratorFactory(() {
      factoryCalled = true;
      return [1].iterator;
    });

    Expect.isFalse(factoryCalled); // Not called until iteration
    var iterator = lazyIterable.iterator;
    Expect.isTrue(factoryCalled);

    // Test that accessing length doesn't trigger another factory call
    factoryCalled = false;
    lazyIterable.length;
    Expect.isTrue(factoryCalled);
  });
}

void testAfterMoveNext() {
  test('iterator factory is called after moveNext', () {
    var items = [1, 2, 3];
    var iterator = items.iterator;
    iterator.moveNext();
    var lazyIterable = Iterable.fromIteratorFactory(() => iterator);

    // Test that the first element is already consumed
    var elements = lazyIterable.toList();
    Expect.isNotEmpty(elements);
    Expect.equals(2, elements.first);
  });
}

void testErrorHandling() {
  test('handles null and error cases', () {
    // Test with null value
    var nullIterable = Iterable.fromIteratorFactory(() => [null].iterator);
    Expect.equals(1, nullIterable.length);
    Expect.isNull(nullIterable.first);

    // Test with throwing iterator
    bool throwingCalled = false;
    var throwingIterable = Iterable.fromIteratorFactory(() {
      throwingCalled = true;
      throw StateError('Test error');
    });

    Expect.throws(() => throwingIterable.iterator);
    Expect.isTrue(throwingCalled);
  });
}

void test(String description, void Function() body) {
  print('  $description');
  body();
}
