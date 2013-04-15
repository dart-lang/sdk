// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";

class A extends IterableBase {
  int count;
  A(this.count);

  Iterator get iterator {
    return new AIterator(count);
  }
}

class AIterator implements Iterator {
  int _count;
  int _current;

  AIterator(this._count);

  bool moveNext() {
    if (_count > 0) {
      _current = _count;
      _count--;
      return true;
    }
    _current = null;
    return false;
  }

  get current => _current;
}

main() {
  var a = new A(10);
  Expect.equals(10, a.length);
  a = new A(0);
  Expect.equals(0, a.length);
  a = new A(5);
  Expect.equals(5, a.map((e) => e + 1).length);
  Expect.equals(3, a.where((e) => e >= 3).length);
}
