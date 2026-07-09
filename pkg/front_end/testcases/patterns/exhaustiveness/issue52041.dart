// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class B {}

class C extends B {
  final int _i;

  C(this._i);
}

f(B b) {
  switch (b) {
    case C(:var _i):
      print('C($_i)');
  }
}

main() {
  f(C(0));
}
