// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
// Tests runtime type semantics for functions with required named parameters
// in strong mode.
import 'package:expect/expect.dart';
import 'required_named_args_lib.dart';

main() {
  dynamic f = func;

  // Invalid: Subtype may not redeclare optional parameters as required.
  Expect.throwsTypeError(() {
    Function(
      String p0, {
      required int p1,
      String p2,
    }) t2 = f;
  });

  // Invalid: Subtype may not declare new required named parameters.
  Expect.throwsTypeError(() {
    Function(
      String p0, {
      required int p1,
    }) t3 = f;
  });

  // Invalid: Invocation with explicit null required named argument.
  Expect.throwsTypeError(() {
    f("", p1: null, p2: null);
  });
  Expect.throwsTypeError(() {
    Function.apply(f, [""], {#p1: null, #p2: null});
  });

  // Invalid: Invocation that omits a required named argument.
  Expect.throwsNoSuchMethodError(() {
    f("", p1: 100);
  });
  Expect.throwsNoSuchMethodError(() {
    Function.apply(f, [""], {#p1: 100});
  });
}
