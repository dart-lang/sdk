// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is based on the repro for
// https://github.com/dart-lang/sdk/issues/33298. It illustrates that the types
// that arise from a type coercion need to be accounted for in type inference.
//
// Specifically, these tests verify that, after type inference has finished
// visiting all the arguments of an invocation, made a preliminary assignment of
// types to type parameters, and then performed assignability checks on each of
// the arguments, if any of those assignability checks resulted in the insertion
// of a coercion, then the static type of the coerced expression is then used to
// generate additional type constraints.
//
// For example, in the invocation `List<String> list2 = ['a', 'b',
// 'c'].map(a).toList()` below, the assignability check to see if `a` is usable
// as an argument to `map` results in a coercion, causing `a` to be treated as
// `a.call`. After this coercion is generated, type inference needs to then use
// the static type of `a.call` to generate additional type constraints. This
// results in a constraint that the type argument to `map` must be a supertype
// of `String`, which in turn ensures that the type of `['a', 'b', 'c'].map(a)`
// is `Iterable<String>`. Without this extra constraint generation step, the
// type of `['a', 'b', 'c']` would be `Iterable<dynamic>`.

import 'package:expect/expect.dart';

class A {
  String call(String s) => '$s$s';
}

class B<T> {
  T call(T t) => t;
}

class C {
  T call<T>(T t) => t;
}

main() {
  A a = A();
  List<String> list1 = ['a', 'b', 'c'].map(a.call).toList();
  Expect.listEquals(['aa', 'bb', 'cc'], list1);
  List<String> list2 = ['a', 'b', 'c'].map(a).toList();
  Expect.listEquals(['aa', 'bb', 'cc'], list2);

  B<String> b = B();
  List<String> list3 = ['a', 'b', 'c'].map(b.call).toList();
  Expect.listEquals(['a', 'b', 'c'], list3);
  List<String> list4 = ['a', 'b', 'c'].map(b).toList();
  Expect.listEquals(['a', 'b', 'c'], list4);

  C c = C();
  List<String> list5 = ['a', 'b', 'c'].map(c.call).toList();
  Expect.listEquals(['a', 'b', 'c'], list5);
  List<String> list6 = ['a', 'b', 'c'].map(c).toList();
  Expect.listEquals(['a', 'b', 'c'], list6);
}
