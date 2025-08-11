// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test based on language/call_method_function_typed_value_test/04

import "package:expect/expect.dart";

/*member: f:[subclass=JSInt|powerset={I}{O}{N}]*/
int f(
  int
  /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
  i,
) => 2 /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ * i;

typedef int IntToInt(int x);

/*member: test:[null|powerset={null}]*/
test(
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ a,
  /*[subclass=Closure|powerset={N}{O}{N}]*/ b,
) => Expect.identical(a, b);

/*member: main:[null|powerset={null}]*/
main() {
  // It is possible to use `.call` on a function-typed value (even though it is
  // redundant).  Similarly, it is possible to tear off `.call` on a
  // function-typed value (but it is a no-op).
  IntToInt f2 = f;

  test(f2. /*[subclass=Closure|powerset={N}{O}{N}]*/ call, f);
}
