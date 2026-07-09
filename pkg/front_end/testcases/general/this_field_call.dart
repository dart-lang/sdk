// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  void Function(T) f;
  A(this.f);

  foo(T x) => this.f(x);
}

main() {
  A<int>((int x) {}).foo(3);
}
