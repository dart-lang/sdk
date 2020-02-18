// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: A:A<T*>,Object*/
class A<T> {
  /*member: A.getType:Type* Function()**/
  Type getType() => T;
}

/*class: out_int:A<int*>,Object,out_int*/
class out_int extends A<int> {
  /*member: out_int.getType:Type* Function()**/
}
