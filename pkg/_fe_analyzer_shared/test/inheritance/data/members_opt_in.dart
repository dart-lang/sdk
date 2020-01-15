// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

abstract class /*class: A1:A1,Object*/ A1 {
  void /*member: A1.close:void Function()!*/ close();
}

abstract class /*class: B1:B1,Object*/ B1 {
  Object /*member: B1.close:Object! Function()!*/ close();
}

abstract class /*class: C1a:A1,B1,C1a,Object*/ C1a implements A1, B1 {
  Object /*member: C1a.close:Object! Function()!*/ close();
}

abstract class /*class: C1b:A1,B1,C1b,Object*/ C1b implements B1, A1 {
  Object /*member: C1b.close:Object! Function()!*/ close();
}

abstract class /*class: A2:A2<T>,Object*/ A2<T> {
  void /*member: A2.close:void Function()!*/ close();
}

abstract class /*class: B2:B2<T>,Object*/ B2<T> {
  Object /*member: B2.close:Object! Function()!*/ close();
}

abstract class /*class: C2a:A2<T>,B2<T>,C2a<T>,Object*/ C2a<T>
    implements A2<T>, B2<T> {
  Object /*member: C2a.close:Object! Function()!*/ close();
}

abstract class /*class: C2b:A2<T>,B2<T>,C2b<T>,Object*/ C2b<T>
    implements B2<T>, A2<T> {
  Object /*member: C2b.close:Object! Function()!*/ close();
}
