// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test for type inference and ?? operator.

String? foo() => null;

String bar() => "bar";

main() {
  // The inferred type for s should be String.
  var s = foo() ?? bar();
  print(s);
}
