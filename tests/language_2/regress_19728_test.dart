// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 19728.

class C<T extends dynamic> {
  T field;

  test() {
    field = 0; /*@compile-error=unspecified*/
    int i = field; /*@compile-error=unspecified*/
  }
}

void main() {
  new C().test();
}
