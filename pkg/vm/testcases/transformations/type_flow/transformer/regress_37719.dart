// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/37719
// Verifies that TFA can infer types from native methods with generic
// return type (_GrowableList.[]).

foo(List<int> x) => 1 + x[0];

main() => print(foo(<int>[1]));
