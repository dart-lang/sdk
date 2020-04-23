// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {}

class B {}

mixin M<T> on A<T> {}

// No matching class from which to infer the type parameter of M
class C extends Object with M {} //# 01: compile-time error

class C = Object with M; //# 02: compile-time error

// Satisfying the constraint with an "implements" clause is not sufficient
class C extends Object with M implements A<B> {} //# 03: compile-time error

class C = Object with M implements A<B>; //# 04: compile-time error

// Mixin works when used correctly.
class D = A<B> with M<B>;

main() {}
