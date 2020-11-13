// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  // Growable lists. Initial length 0.
  testConcurrentModification(<int>[].toList());
  testConcurrentModification(new List.filled(0, 0, growable: true));
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
}

void testConcurrentModification(List<int> list) {
  // add, removeLast.
  list.clear();
  list.addAll([1, 2, 3, 2, 7, 9, 9, 7, 2, 3, 2, 1]);

  // Operations that change the length cause ConcurrentModificationError.
  void testModification(action()) {
    testIterator(int when) {
      list.clear();
      list.addAll([0, 1, 2, 3]);
      Expect.throws(() {
        for (var element in list) {
          if (element == when) action();
        }
      }, (e) => e is ConcurrentModificationError);
    }

    testForEach(int when) {
      list.clear();
      list.addAll([0, 1, 2, 3]);
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

class MyList<E> extends ListBase<E> {
  // TODO(42496): Use a nullable list because insert() is implemented in terms
  // of length=. Change this back to `E` and remove the `as E` below when that
  // issue is fixed.
  List<E?> _source;
  MyList(this._source);
  int get length => _source.length;
  void set length(int length) {
    _source.length = length;
  }

  void add(E element) {
    _source.add(element);
  }

  E operator [](int index) => _source[index] as E;
  void operator []=(int index, E value) {
    _source[index] = value;
  }
}
