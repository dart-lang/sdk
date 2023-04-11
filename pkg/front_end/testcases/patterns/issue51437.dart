// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  final X x;
  A(this.x);
}

extension<X> on A<X> {
  X get g => x;
}

void foo<X>(A<X> it) {
  switch (it) {
    case A<X>(g: var x):
      x.arglebargle; // Error
  }
}
