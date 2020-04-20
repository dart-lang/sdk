// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_mirror_type_variables_data;

class NoTypeParams {}

class A<T, S extends String> {}

class B<Z extends B<Z>> {}

class C<Z extends B<Z>> {}

class D<R, S, T> {
  R foo(R r) => r;
  S bar(S s) => s;
  T baz(T t) => t;
}

class Helper<S> {}

class E<R extends Map<R, Helper<String>>> {}

class F<Z extends Helper<F<Z>>> {}
