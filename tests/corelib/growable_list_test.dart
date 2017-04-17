// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Sanity check on the growing behavior of a growable list.

import "package:expect/expect.dart";

void main() {
  testConstructor();

  bool checked = false;
  assert((checked = true));
  // Concurrent modification checks are only guaranteed in checked mode.
  if (checked) testConcurrentModification();
}

// Iterable generating numbers in range [0..count).
// May perform callback at some point underways.
class TestIterableBase extends Iterable<int> {
  final int length;
  final int count;
  // call [callback] if generating callbackIndex.
  final int callbackIndex;
  final Function callback;
  TestIterableBase(this.length, this.count, this.callbackIndex, this.callback);
  Iterator<int> get iterator => new CallbackIterator(this);
}

class TestIterable extends TestIterableBase {
  TestIterable(count, [callbackIndex = -1, callback])
      : super(-1, count, callbackIndex, callback);
  int get length => throw "SHOULD NOT BE CALLED";
}

// Implement Set for private EfficientLengthIterable interface.
class EfficientTestIterable extends TestIterableBase implements Set<int> {
  EfficientTestIterable(length, count, [callbackIndex = -1, callback])
      : super(length, count, callbackIndex, callback);
  // Avoid warnings because we don't actually implement Set.
  noSuchMethod(i) => super.noSuchMethod(i);
}

class CallbackIterator implements Iterator<int> {
  TestIterableBase _iterable;
  int _current = null;
  int _nextIndex = 0;
  CallbackIterator(this._iterable);
  bool moveNext() {
    if (_nextIndex >= _iterable.count) {
      _current = null;
      return false;
    }
    _current = _nextIndex;
    _nextIndex++;
    if (_current == _iterable.callbackIndex) {
      _iterable.callback();
    }
    return true;
  }

  int get current => _current;
}

void testConstructor() {
  // Constructor can make both growable and fixed-length lists.
  testGrowable(list) {
    Expect.isTrue(list is List<int>);
    Expect.isFalse(list is List<String>);
    int length = list.length;
    list.add(42);
    Expect.equals(list.length, length + 1);
  }

  testFixedLength(list) {
    Expect.isTrue(list is List<int>);
    int length = list.length;
    Expect.throws(() {
      list.add(42);
    }, null, "adding to fixed-length list");
    Expect.equals(length, list.length);
  }

  bool checked = false;
  assert((checked = true));
  testThrowsOrTypeError(fn, test, [name]) {
    Expect.throws(
        fn, checked ? null : test, checked ? name : "$name w/ TypeError");
  }

  testFixedLength(new List<int>(0));
  testFixedLength(new List<int>(5));
  testFixedLength(new List<int>.filled(5, null)); // default growable: false.
  testGrowable(new List<int>());
  testGrowable(new List<int>()..length = 5);
  testGrowable(new List<int>.filled(5, null, growable: true));
  Expect.throws(() => new List<int>(-1), (e) => e is ArgumentError, "-1");
  // There must be limits. Fix this test if we ever allow 10^30 elements.
  Expect.throws(() => new List<int>(0x1000000000000000000000000000000),
      (e) => e is ArgumentError, "bignum");
  Expect.throws(() => new List<int>(null), (e) => e is ArgumentError, "null");
  testThrowsOrTypeError(
      () => new List([] as Object), // Cast to avoid warning.
      (e) => e is ArgumentError,
      'list');
  testThrowsOrTypeError(
      () => new List([42] as Object), (e) => e is ArgumentError, "list2");
}

void testConcurrentModification() {
  // Without EfficientLengthIterable interface
  {
    // Change length of list after 200 additions.
    var l = [];
    var ci = new TestIterable(257, 200, () {
      l.add("X");
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError, "cm1");
  }

  {
    // Change length of list after 200 additions.
    var l = [];
    var ci = new TestIterable(257, 200, () {
      l.length = 0;
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError, "cm2");
  }

  // With EfficientLengthIterable interface (uses length).
  {
    // Change length of list after 20 additions.
    var l = [];
    var ci = new EfficientTestIterable(257, 257, 20, () {
      l.add("X");
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError, "cm3");
  }

  {
    var l = [];
    var ci = new EfficientTestIterable(257, 257, 20, () {
      l.length = 0;
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError, "cm4");
  }

  {
    // Length 500, only 250 elements.
    var l = [];
    var ci = new EfficientTestIterable(500, 250);
    l.addAll(ci);
    Expect.listEquals(new List.generate(250, (x) => x), l, "cm5");
  }

  {
    // Length 250, but 500 elements.
    var l = [];
    var ci = new EfficientTestIterable(250, 500);
    l.addAll(ci);
    Expect.listEquals(new List.generate(500, (x) => x), l, "cm6");
  }

  {
    // Adding to yourself.
    var l = [1];
    Expect.throws(() {
      l.addAll(l);
    }, (e) => e is ConcurrentModificationError, "cm7");
  }

  {
    // Adding to yourself.
    var l = [1, 2, 3];
    Expect.throws(() {
      l.addAll(l);
    }, (e) => e is ConcurrentModificationError, "cm8");
  }
}
