// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'dart:collection';
import 'cache_lookups.dart';

class CustomList<E> with ListMixin<E> {
  final List<E> list;

  CustomList(this.list);

  int get length {
    counter++;
    return list.length;
  }

  void set length(int value) {
    list.length = value;
  }

  E operator [](int index) => list[index];

  void operator []=(int index, E value) {
    list[index] = value;
  }
}
