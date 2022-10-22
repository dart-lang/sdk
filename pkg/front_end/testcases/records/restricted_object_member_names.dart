// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'Object' member names are allowed as the names of the positional fields in
// record types because they don't introduce getters with those names.
(int hashCode,) foo1() => throw 0; // Ok.
(int runtimeType,) foo2() => throw 0; // Ok.
(int noSuchMethod,) foo3() => throw 0; // Ok.
(int toString,) foo4() => throw 0; // Ok.

// 'Object' member names are forbidden as names of the named record fields in
// both record types and literals.
({int hashCode}) foo5() => throw 0; // Error.
({int runtimeType}) foo6() => throw 0; // Error.
({int noSuchMethod}) foo7() => throw 0; // Error.
({int toString}) foo8() => throw 0; // Error.
foo9() => (hashCode: 1); // Error.
foo10() => (runtimeType: 1); // Error.
foo11() => (noSuchMethod: 1); // Error.
foo12() => (toString: 1); // Error.

main() {}
