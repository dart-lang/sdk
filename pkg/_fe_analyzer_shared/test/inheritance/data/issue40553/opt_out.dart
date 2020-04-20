// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/
import "dart:async";

/*class: A:A<T*>,Object*/
class A<T> {
  /*member: A.getType:Type* Function()**/
  Type getType() => T;
}

/*class: B:A<FutureOr<int*>*>,B,Object*/
class B extends A<FutureOr<int>> {
  /*member: B.getType:Type* Function()**/
}
