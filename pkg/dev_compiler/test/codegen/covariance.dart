// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  T _t;
  add(T t) {
    _t = t;
  }

  forEach(void fn(T t)) {
    // No check needed for `fn`
    fn(_t);
  }
}

class Bar extends Foo<int> {
  add(int x) {
    print('Bar.add got $x');
    super.add(x);
  }
}

main() {
  Foo<Object> foo = new Bar();
  foo.add('hi'); // should throw
}
