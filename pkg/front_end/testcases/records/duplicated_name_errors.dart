// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(int x, int x) foo1() => throw 0; // Error.
(int x, String x) foo2() => throw 0; // Error.
(int x, {int x}) foo3() => throw 0; // Error.
(int x, {String x}) foo4() => throw 0; // Error.
({int x, int x}) foo5() => throw 0; // Error.
({int x, String x}) foo6() => throw 0; // Error.
(int x, int x, int x) foo7() => throw 0; // Triplicated name. Error.

main() {}
