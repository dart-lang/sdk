// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(int hashCode,) foo1() => throw 0; // Error.
(int runtimeType,) foo2() => throw 0; // Error.
(int noSuchMethod,) foo3() => throw 0; // Error.
(int toString,) foo4() => throw 0; // Error.
({int hashCode}) foo5() => throw 0; // Error.
({int runtimeType}) foo6() => throw 0; // Error.
({int noSuchMethod}) foo7() => throw 0; // Error.
({int toString}) foo8() => throw 0; // Error.
foo9() => (hashCode: 1); // Error.
foo10() => (runtimeType: 1); // Error.
foo11() => (noSuchMethod: 1); // Error.
foo12() => (toString: 1); // Error.

main() {}
