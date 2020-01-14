// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate the following spec text from section 16.32 (Identifier Reference):
//     Evaluation of an identifier expression e of the form id proceeds as
//   follows:
//     Let d be the innermost declaration in the enclosing lexical scope whose
//   name is id or id=.  If no such declaration exists in the lexical scope,
//   d be the declaration of the inherited member named id if it exists.
//     - If d is a prefix p, a compile-time error occurs unless the token
//       immediately following d is '.'.

import "package:expect/expect.dart";
import "empty_library.dart" as p;

void f(x) {}

main() {
  f(p); //        //# 01: compile-time error
  var x = p; //   //# 02: compile-time error
  var x = p[0]; //# 03: compile-time error
  p[0] = null; // //# 04: compile-time error
  p += 0; //      //# 05: compile-time error
}
