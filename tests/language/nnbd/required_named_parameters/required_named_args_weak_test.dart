// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak
// Tests runtime type semantics for functions with required named parameters
// in weak mode.
import 'package:expect/expect.dart';
import 'required_named_args_lib.dart';

main() {
  dynamic f = func;

  // Valid: Subtype may redeclare optional parameters as required in weak mode.
  Function(
    String p0, {
    required int p1,
    String p2,
  }) t2 = f;

  // Valid: Subtype may declare new required named parameters in weak mode.
  Function(
    String p0, {
    required int p1,
  }) t3 = f;

  // Valid: Invocation may pass null as a required named argument in weak mode.
  f("", p1: null, p2: null);
  Function.apply(f, [""], {#p1: null, #p2: null});

  // Valid: Invocation may omit a required named argument in weak mode.
  f("", p1: 100);
  Function.apply(f, [""], {#p1: 100});
}
