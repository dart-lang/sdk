// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S<T> {
  num n;
  T t;
  S(this.n, this.t);
  S.named(this.t, this.n);
}

class C<T> extends S<T> {
  C.constr1(super.n, String s, super.t);
  C.constr2(int i, super.n, String s, super.t) : super();
  C.constr3(int i, super.t, String s, super.n) : super.named();
}

main() {}
