// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  // Growable lists. Initial length 0.
  testConcurrentModification(new List());
  testConcurrentModification(new List<int>().toList());
  testConcurrentModification(new List<int>(0).toList());
  testConcurrentModification(new List.filled(0, null, growable: true));
  testConcurrentModification([]);
  testConcurrentModification(new List.from(const []));
  testConcurrentModification(new MyList([]));
  testConcurrentModification(new MyList<int>([]).toList());

  testConcurrentModification(new Uint8List(0).toList());
  testConcurrentModification(new Int8List(0).toList());
  testConcurrentModification(new Uint16List(0).toList());
  testConcurrentModification(new Int16List(0).toList());
  testConcurrentModification(new Uint32List(0).toList());
  testConcurrentModification(new Int32List(0).toList());

  testConcurrentAddSelf([]);
  testConcurrentAddSelf([1, 2, 3]);
}

void testConcurrentModification(List<int> list) {
  // add, removeLast.
  list.clear();
  list.addAll([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1]);

  // Operations that change the length cause ConcurrentModificationError.
  void testModification(action()) {
    testIterator(int when) {
      list.length = 4;
      list.setAll(0, [0, 1, 2, 3]);
      Expect.throws(() {
        for (var element in list) {
          if (element == when) action();
        }
      }, (e) => e is ConcurrentModificationError);
    }

    testForEach(int when) {
      list.length = 4;
      list.setAll(0, [0, 1, 2, 3]);
      Expect.throws(() {
        list.forEach((var element) {
          if (element == when) action();
        });
      }, (e) => e is ConcurrentModificationError);
    }

    // Test the change at different points of the iteration.
    testIterator(0);
    testIterator(1);
    testIterator(3);
    testForEach(0);
    testForEach(1);
    testForEach(3);
  }

  testModification(() => list.add(5));
  testModification(() => list.addAll([5, 6]));
  testModification(() => list.removeLast());
  for (int i = 0; i < 4; i++) {
    testModification(() => list.remove(i));
    testModification(() => list.removeAt(i));
    testModification(() => list.removeWhere((x) => x == i));
    testModification(() => list.retainWhere((x) => x != i));
    testModification(() => list.insert(i, 5));
    testModification(() => list.insertAll(i, [5, 6]));
    testModification(() => list.removeRange(i, i + 1));
    testModification(() => list.replaceRange(i, i + 1, [5, 6]));
  }
}

testConcurrentAddSelf(List list) {
  Expect.throws(() {
    list.addAll(list);
  }, (e) => e is ConcurrentModificationError, "testConcurrentAddSelf($list)");
}

class MyList<E> extends ListBase<E> {
  List<E> _source;
  MyList(this._source);
  int get length => _source.length;
  void set length(int length) {
    _source.length = length;
  }

  E operator [](int index) => _source[index];
  void operator []=(int index, E value) {
    _source[index] = value;
  }
}
