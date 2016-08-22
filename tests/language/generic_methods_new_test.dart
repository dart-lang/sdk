// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=--generic-method-syntax
// VMOptions=--generic-method-syntax

/// Dart test on the usage of method type arguments in object creation. With
/// '--generic-method-syntax', the type argument is available at runtime,
/// but erased to `dynamic`.

library generic_methods_new_test;

import "package:expect/expect.dart";

class C<E> {
  E e;
  C(this.e);
}

C<T> f1<T>(T t) => new C<T>(t);

List<T> f2<T>(T t) => <T>[t];

main() {
  C c = f1<int>(42);
  List i = f2<String>("Hello!");
  Expect.isTrue(c is C<int> && c is C<String>); // C<dynamic>.
  Expect.isTrue(i is List<String> && i is List<int>); // List<dynamic>.
  Expect.equals(c.e, 42);
  Expect.equals(i[0], "Hello!");
}
