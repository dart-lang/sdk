// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart=2.6

// The test checks that dependencies of type arguments of targets of redirecting
// factories on type parameters of the corresponding classes are respected in
// the resulting type arguments of redirecting factories invocations.

import 'package:expect/expect.dart';

abstract class A<T> {
  factory A() = B<T, List<T>>;
  A.empty();
}

abstract class B<U, W> extends A<U> {
  factory B() = C<U, W, Map<U, W>>;
  B.empty() : super.empty();
}

class C<V, S, R> extends B<V, S> {
  C() : super.empty();
  toString() => "${V},${S},${R}";
}

main() {
  Expect.equals("${new A<int>()}", "int,List<int>,Map<int, List<int>>");
}
