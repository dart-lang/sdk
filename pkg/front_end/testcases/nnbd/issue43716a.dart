// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool b = true;

class C<X extends C<X, X>?, Y extends C<Y, Y>?> {
  X x;
  C(this.x);
  Object m(X x, Y y) {
    // UP(X extends C<X, X>?, Y extends C<Y, Y>?) ==
    // C<Object, Object>?.
    var z = b ? x : y;
    if (z == null) throw 0;
    return z.x; // Error.
  }
}

main() {}
