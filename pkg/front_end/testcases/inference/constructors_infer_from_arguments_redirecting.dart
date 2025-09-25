// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  T t;
  C(this.t);
  C.named(List<T> t) : this(t[0]);
}

main() {
  var x = new C.named(<int>[42]);
}
