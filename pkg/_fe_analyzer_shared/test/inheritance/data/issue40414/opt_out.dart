// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

import "opt_in.dart";

/*class: A:A,NONNULLABLE,NULLABLE,Object*/
class A extends NULLABLE implements NONNULLABLE {
  /*member: A.i:int**/
  /*member: A.i=:int**/
}
