// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:expect/expect.dart';

class OverrideFirstGetter {
  get first => 9999;
}

class ListMock extends ListBase with OverrideFirstGetter {
  final _list = [];
  int get length => _list.length;
  void set length(int x) {
    _list.length = x;
  }

  operator [](x) => _list[x];
  void operator []=(x, y) {
    _list[x] = y;
  }
}

// Regression test for
// https://github.com/dart-lang/sdk/issues/29273#issuecomment-292384130
main() {
  List x = new ListMock();
  x.add(42);
  Expect.equals(x[0], 42);
  Expect.equals(x.first, 9999);
}
