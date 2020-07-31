// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Requirements=nnbd-weak
// Tests runtime type semantics for functions with required named parameters
// imported into a legacy library from an opted-in library.
import 'package:expect/expect.dart';
import 'required_named_args_lib.dart';

main() {
  dynamic f = func;

  // Valid: Invocation with all arguments provided.
  f("", p1: 100, p2: "", p3: true);
  Function.apply(f, [""], {#p1: 100, #p2: "", #p3: true});

  // Valid: Invocation that omits non-required named arguments.
  f("", p1: 100, p2: "");
  Function.apply(f, [""], {#p1: 100, #p2: ""});

  // Valid: Invocation may pass null as a required named argument.
  f("", p1: null, p2: null);
  Function.apply(f, [""], {#p1: null, #p2: null});

  // Valid: Invocation may omit a required named argument.
  f("", p1: 100);
  Function.apply(f, [""], {#p1: 100});
}
