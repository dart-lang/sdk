// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  A(f);
}

class B<T> extends A<T> {
  B() : super((T param) => 42);
}

main() {
  var t = new B<int>();
}
