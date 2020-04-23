// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "package:expect/expect.dart";

testRemove(base) {
  int length = base.length;
  for (int i = 0; i < length; i++) {
    Expect.isFalse(base.isEmpty);
    base.remove(base.first);
  }
  Expect.isTrue(base.isEmpty);
}

testRemoveAll(base, Iterable removes) {
  Set retained = new Set();
  for (var element in base) {
    if (!removes.contains(element)) {
      retained.add(element);
    }
  }
  String name = "$base.removeAll($removes) -> $retained";
  base.removeAll(removes);
  for (var value in base) {
    Expect.isFalse(removes.contains(value), "$name: Found $value");
  }
  for (var value in retained) {
    Expect.isTrue(base.contains(value), "$name: Found $value");
  }
}

testRetainAll(base, Iterable retains) {
  Set retained = new Set();
  for (var element in base) {
    if (retains.contains(element)) {
      retained.add(element);
    }
  }
  String name = "$base.retainAll($retains) -> $retained";
  base.retainAll(retains);
  for (var value in base) {
    Expect.isTrue(retains.contains(value), "$name: Found $value");
  }
  for (var value in retained) {
    Expect.isTrue(base.contains(value), "$name: Found $value");
  }
}

testRemoveWhere(base, bool test(value)) {
  Set retained = new Set();
  for (var element in base) {
    if (!test(element)) {
      retained.add(element);
    }
  }
  String name = "$base.removeWhere(...) -> $retained";
  base.removeWhere(test);
  for (var value in base) {
    Expect.isFalse(test(value), "$name: Found $value");
  }
  for (var value in retained) {
    Expect.isTrue(base.contains(value), "$name: Found $value");
  }
}

testRetainWhere(base, bool test(value)) {
  Set retained = new Set();
  for (var element in base) {
    if (test(element)) {
      retained.add(element);
    }
  }
  String name = "$base.retainWhere(...) -> $retained";
  base.retainWhere(test);
  for (var value in base) {
    Expect.isTrue(test(value), "$name: Found $value");
  }
  for (var value in retained) {
    Expect.isTrue(base.contains(value), "$name: Found $value");
  }
}

void main() {
  var collections = [
    [],
    [1],
    [2],
    [1, 2],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    [1, 3, 5, 7, 9],
    [2, 4, 6, 8, 10]
  ];
  for (var base in collections) {
    for (var delta in collections) {
      testRemove(base.toList());
      testRemove(base.toSet());

      var deltaSet = delta.toSet();
      testRemoveWhere(base.toList(), deltaSet.contains);
      testRetainWhere(base.toList(), (e) => !deltaSet.contains(e));

      testRemoveAll(base.toSet(), delta);
      testRemoveAll(base.toSet(), deltaSet);
      testRetainAll(base.toSet(), delta);
      testRetainAll(base.toSet(), deltaSet);
      testRemoveWhere(base.toSet(), deltaSet.contains);
      testRetainWhere(base.toSet(), (e) => !deltaSet.contains(e));

      // Test the ListBase class's List implementation.
      testRemoveWhere(new MyList(base.toList()), deltaSet.contains);
      testRetainWhere(new MyList(base.toList()), (e) => !deltaSet.contains(e));
    }
  }
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
