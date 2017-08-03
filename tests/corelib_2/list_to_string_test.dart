// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';

class MyList extends ListBase {
  final list;
  MyList(this.list);

  get length => list.length;
  set length(val) {
    list.length = val;
  }

  operator [](index) => list[index];
  operator []=(index, val) => list[index] = val;
}

main() {
  Expect.equals("[]", [].toString());
  Expect.equals("[1]", [1].toString());
  Expect.equals("[1, 2]", [1, 2].toString());
  Expect.equals("[]", const [].toString());
  Expect.equals("[1]", const [1].toString());
  Expect.equals("[1, 2]", const [1, 2].toString());
  Expect.equals("[]", new MyList([]).toString());
  Expect.equals("[1]", new MyList([1]).toString());
  Expect.equals("[1, 2]", new MyList([1, 2]).toString());
}
