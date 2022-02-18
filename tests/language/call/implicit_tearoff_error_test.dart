// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises a corner case of implicit `.call` tearoffs that is
// easiest to see through its effect on erroneous code.

// NOTICE: This test checks the currently implemented behavior, even though the
// implemented behavior does not match the language specification.  Until an
// official decision has been made about whether to change the implementation to
// match the specification, or vice versa, this regression test is intended to
// protect against inadvertent implementation changes.

import '../static_type_helper.dart';

class A {}

class C extends A {
  void call() {}
}

class D extends A {
  void call() {}
}

void testConditionalExpressionWithUnrelatedClasses(bool b, C c, D d) {
  // Verify that `b ? c : d` is not interpreted as `(b ? c.call : d.call)` by
  // confirming that it's an error to use it in a function context (because
  // `b ? c : d` has static type `A`).
  context<void Function()>(b ? c : d);
  //                       ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                         ^
  // [cfe] The argument type 'A' can't be assigned to the parameter type 'void Function()'.
}
