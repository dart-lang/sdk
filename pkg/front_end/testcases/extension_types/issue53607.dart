// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E._(int i) {
  E.foo(int i) : this._(i);
  int get value => i;
  int get foo => i;
}

void main() {
  E e = E.foo(1);
  print(e.value);
  print(e.foo);
}