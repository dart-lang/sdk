// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test which verifies that we don't accidentally eliminate
// runtimeType invocation which flows into a catch block entry parameter.

import 'package:expect/expect.dart';

class A {}

@pragma('vm:never-inline')
void foo(Object? v) {
  Type t = String;
  try {
    t = v.runtimeType;
    if (v is A) {
      throw 'goto catch';
    }
  } catch (e) {
    Expect.equals(A, t);
    return;
  }
}

void main() {
  foo('hi');
  foo(A());
}
