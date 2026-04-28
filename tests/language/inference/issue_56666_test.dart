// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is based on the repro for
// https://github.com/dart-lang/sdk/issues/56666. It illustrates that the types
// that arise from a type coercion need to be accounted for in type inference.
//
// Specifically, these tests verify that, after type inference has finished
// visiting all the arguments of an invocation, made a preliminary assignment of
// types to type parameters, and then performed assignability checks on each of
// the arguments, if any of those assignability checks resulted in the insertion
// of a coercion, then the static type of the coerced expression is then used to
// generate additional type constraints.
//
// For example, in the invocation `var g = f(C());` below, the assignability
// check to see if `C()` is usable as an argument to `f` results in a coercion,
// causing `C()` to be treated as `C().call`. After this coercion is generated,
// type inference needs to then use the static type of `C().call` to generate
// additional type constraints. This results in a constraint that the type
// argument to `f` must be a supertype of `String`, which in turn ensures that
// the type of `f(C())` is `String Function(String)`. Without this extra
// constraint generation step, the type of `f(C())` would be `dynamic
// Function(String)`.

import 'package:expect/expect.dart';
import '../static_type_helper.dart';

class C {
  T call<T>(T t) => t;
}

X Function(String) f<X>(X Function(String) g) => g;

void main() {
  var g = f(C());
  g.expectStaticType<Exactly<String Function(String)>>();
  Expect.equals('s', g('s'));
}
