// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

abstract class C<T> {
  T get t;
  void set t(T x);

  factory C(T t) = CImpl<T>;
}

class CImpl<T> implements C<T> {
  T t;
  CImpl._(this.t);
  factory CImpl(T t) => new CImpl._(t);
}

main() {
  var x = new C(42);
}
