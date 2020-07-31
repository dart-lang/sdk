// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' as collection;

class Foo extends Object with collection.ListMixin {
  int get length => 0;
  operator [](int index) => null;
  void operator []=(int index, value) => null;
  set length(int newLength) => null;
}

main() {
  new Foo();
}
