// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests runtime type semantics for functions with required named parameters
// in strong and weak mode.
import 'package:expect/expect.dart';
import 'required_named_args_lib.dart';

main() {
  dynamic f = func;

  // Valid: Subtype may contain additional named optional parameters.
  Function(String p0, {required int p1, required String p2}) t0 = f;

  // Valid: Subtype may redeclare required named parameters as optional.
  Function(String p0, {required int p1, required String p2, required bool p3})
      t1 = f;

  // Valid: Invocation with all arguments provided.
  f("", p1: 100, p2: "", p3: true);
  Function.apply(f, [""], {#p1: 100, #p2: "", #p3: true});

  // Valid: Invocation that omits non-required named arguments.
  f("", p1: 100, p2: "");
  Function.apply(f, [""], {#p1: 100, #p2: ""});
}
