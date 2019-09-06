// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// The test checks that type arguments of the target of redirection factory
// constructors are preserved throughout the chain of redirections.

import 'package:expect/expect.dart';

class A<T> {
  factory A() = B<T, num>;
  A.empty();
}

class B<U, W> extends A<U> {
  factory B() = C<U, W, String>;
  B.empty() : super.empty();
}

class C<V, S, R> extends B<V, S> {
  C() : super.empty();
  toString() => "${V},${S},${R}";
}

main() {
  Expect.equals("${new A<int>()}", "int,num,String");
}
