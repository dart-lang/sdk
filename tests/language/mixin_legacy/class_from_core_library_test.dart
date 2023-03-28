// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'dart:collection';

class MyList extends Object with ListMixin {
  int length = 0;
  operator [](index) => null;
  void operator []=(index, value) {}
}

main() {
  new MyList().length;
}
