// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

typedef F<T>(T x);

class B<T> {
  void f(F<T> x) {}
}

abstract class I<U> {
  void f(U x);
}

class C<V> extends B<V> implements I<F<V>> {}

void acceptsObject(Object o) {}

void acceptsNum(num n) {}

void g(I<F<num>> i) {
  i.f(acceptsObject);
  // i.f has static type (F<num>)->void, or ((num)->void)->void.  Which means we
  // are statically allowed to pass acceptsNum to it.  However, if i's runtime
  // type is C<Object>, then it extends B<Object>, so its f function requires
  // its argument to be F<Object>.  This means that passing acceptsNum to f
  // would violate soundness (since acceptsNum has type F<num>, and F<num> is a
  // supertype of F<Object>).  So we expect a type error here.
  Expect.throwsTypeError(() => i.f(acceptsNum));
}

void main() {
  g(new C<Object>());
}
