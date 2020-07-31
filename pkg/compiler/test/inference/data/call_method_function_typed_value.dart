// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test based on language_2/call_method_function_typed_value_test/04

import "package:expect/expect.dart";

/*member: f:[subclass=JSInt]*/
int f(
        int
            /*spec.[null|subclass=Object]*/
            /*prod.[null|subclass=JSInt]*/
            i) =>
    2 /*invoke: [exact=JSUInt31]*/ * i;

typedef int IntToInt(int x);

/*member: test:[null]*/
test(/*[null|subclass=Object]*/ a, /*[subclass=Closure]*/ b) =>
    Expect.identical(a, b);

/*member: main:[null]*/
main() {
  // It is possible to use `.call` on a function-typed value (even though it is
  // redundant).  Similarly, it is possible to tear off `.call` on a
  // function-typed value (but it is a no-op).
  IntToInt f2 = f;

  test(f2. /*[subclass=Closure]*/ call, f);
}
