// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js's inferrer and code optimizers know a double
// literal might become an int at runtime.

import "package:expect/expect.dart";
import '../language/compiler_annotations.dart';

@DontInline()
callWithStringAndDouble(value) {
  () => 42;
  if (value is! int) throw new ArgumentError(value);
  return 42;
}

@DontInline()
callWithDouble(value) {
  () => 42;
  if (value is! int) throw new ArgumentError(value);
  return 42;
}

main() {
  Expect.throws(
      () => callWithStringAndDouble('foo'), (e) => e is ArgumentError);
  Expect.equals(42, callWithStringAndDouble(0.0));
  Expect.equals(42, callWithDouble(0.0));
}
