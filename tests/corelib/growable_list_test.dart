// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Sanity check on the growing behavior of a growable list.

import "package:expect/expect.dart";
import "dart:collection" show IterableBase;

// Iterable generating numbers in range [0..count).
// May perform callback at some point underways.
class TestIterableBase<E> extends IterableBase<E> {
  final int length;
  final int count;
  // call [callback] if generating callbackIndex.
  final int callbackIndex;
  final Function callback;
  TestIterableBase(this.length, this.count,
                   this.callbackIndex, this.callback);
  Iterator<E> get iterator => new CallbackIterator(this);
}

class TestIterable<E> extends TestIterableBase<E> {
  TestIterable(count, [callbackIndex = -1, callback])
      : super(-1, count, callbackIndex, callback);
  int get length => throw "SHOULD NOT BE CALLED";
}

// Implement Set for private EfficientLength interface.
@proxy  // Avoid warnings because we don't actually implement Set.
class EfficientTestIterable<E> extends TestIterableBase<E>
                               implements Set<E> {
  EfficientTestIterable(length, count, [callbackIndex = -1, callback])
      : super(length, count, callbackIndex, callback);
}

class CallbackIterator<E> implements Iterator<E> {
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


void main() {
  // Without EfficientLength interface
  {
    // Change length of list after 20 additions.
    var l = [];
    var ci = new TestIterable<E>(257, 200, () {
      l.add("X");
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError);
  }

  {
    // Change length of list after 20 additions.
    var l = [];
    var ci = new TestIterable<E>(257, 200, () {
      l.length = 0;
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError);
  }

  // With EfficientLength interface (uses length).
  {
    // Change length of list after 20 additions.
    var l = [];
    var ci = new EfficientTestIterable<E>(257, 257, 20, () {
      l.add("X");
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError);
  }

  {
    var l = [];
    var ci = new EfficientTestIterable<E>(257, 257, 20, () {
      l.length = 0;
    });
    Expect.throws(() {
      l.addAll(ci);
    }, (e) => e is ConcurrentModificationError);
  }

  {
    // Length 50, only 25 elements.
    var l = [];
    var ci = new EfficientTestIterable<E>(500, 250);
    l.addAll(ci);
    Expect.listEquals(new List.generate(250, (x)=>x), l);
  }

  {
    // Length 25, but 50 elements.
    var l = [];
    var ci = new EfficientTestIterable<E>(250, 500);
    l.addAll(ci);
    Expect.listEquals(new List.generate(500, (x)=>x), l);
  }

  {
    // Adding to yourself.
    var l = [1];
    Expect.throws(() { l.addAll(l); }, (e) => e is ConcurrentModificationError);
  }

  {
    // Adding to yourself.
    var l = [1, 2, 3];
    Expect.throws(() { l.addAll(l); }, (e) => e is ConcurrentModificationError);
  }
}

