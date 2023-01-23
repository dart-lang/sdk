// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(int _foo,) foo1() => throw 0; // Error.
({int _foo}) foo2() => throw 0; // Error.
foo3() => (_foo: 1); // Error.

main() {}
