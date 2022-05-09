// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash when it sees untyped function
// invocation (FunctionAccessKind.Function) but receiver has a known
// function type.

import "package:expect/expect.dart";

bool ok = false;
bool _defaultCheck([dynamic _]) => true;

void foo<T>(bool Function(T error)? check, Object e) {
  // Function call on the result of 'check ?? _defaultCheck' is untyped
  // (assumes static type Function). However, AOT compiler can eliminate
  // null test and might be able to reduce the expression to 'check' with
  // known function type.
  if (e is T && (check ?? _defaultCheck)(e)) {
    ok = true;
  }
}

void main() {
  foo<String>((_) => true, 'hi');
  Expect.isTrue(ok);
}
