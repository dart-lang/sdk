// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "package:expect/expect.dart";

class MyList<E> extends Object with ListMixin<E> implements List<E> {
  List<E> _list;

  MyList(List<E> this._list);

  int get length => _list.length;

  void set length(int x) {
    _list.length = x;
  }

  E operator[](int idx) => _list[idx];

  void operator[]=(int idx, E value) {
    _list[idx] = value;
  }
}

void testRetainWhere() {
  List<int> list = <int>[1, 2, 3];
  list.retainWhere((x) => x % 2 == 0);
  Expect.equals(1, list.length);
  Expect.equals(2, list.first);

  list = new MyList<int>([1, 2, 3]);
  list.retainWhere((x) => x % 2 == 0);
  Expect.equals(1, list.length);
  Expect.equals(2, list.first);
}

void main() {
  testRetainWhere();
}
