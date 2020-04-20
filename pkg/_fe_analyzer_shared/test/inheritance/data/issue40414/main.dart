// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";

/*class: B:A,B,NONNULLABLE,NULLABLE,Object*/
class B extends A {
  /*member: B.i:int**/
  /*member: B.i=:int**/
}

/// TODO: Solve CFE / analyzer difference.
/// I suspect that this is a bug in analyzer.
/// We check `i` against separate signatures from `NULLABLE` and `NONNULLABLE`.
/*class: C:A,C,NONNULLABLE,NULLABLE,Object*/
class C extends A {
  /*member: C.i:int?*/
  /*member: C.i=:int?*/
  int? /*analyzer.error: CompileTimeErrorCode.INVALID_OVERRIDE*/ i;
}
