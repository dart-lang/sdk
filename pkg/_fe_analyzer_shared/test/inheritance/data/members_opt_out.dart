// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

abstract class /*class: A1:A1,Object*/ A1 {
  void /*member: A1.close:void Function()**/ close();
}

abstract class /*class: B1:B1,Object*/ B1 {
  Object /*member: B1.close:Object* Function()**/ close();
}

abstract class /*class: C1a:A1,B1,C1a,Object*/ C1a implements A1, B1 {
  Object /*member: C1a.close:Object* Function()**/ close();
}

abstract class /*class: C1b:A1,B1,C1b,Object*/ C1b implements B1, A1 {
  Object /*member: C1b.close:Object* Function()**/ close();
}

abstract class /*class: A2:A2<T*>,Object*/ A2<T> {
  void /*member: A2.close:void Function()**/ close();
}

abstract class /*class: B2a:B2a<T*>,Object*/ B2a<T> {
  Object /*member: B2a.close:Object* Function()**/ close();
}

abstract class /*class: B2b:B2a<dynamic>,B2b<T*>,Object*/ B2b<T>
    implements B2a {
  Object /*member: B2b.close:Object* Function()**/ close();
}

abstract class /*class: C2a:A2<T*>,B2a<dynamic>,B2b<T*>,C2a<T*>,Object*/ C2a<T>
    implements A2<T>, B2b<T> {
  Object /*member: C2a.close:Object* Function()**/ close();
}

abstract class /*class: C2b:A2<T*>,B2a<dynamic>,B2b<T*>,C2b<T*>,Object*/ C2b<T>
    implements B2b<T>, A2<T> {
  Object /*member: C2b.close:Object* Function()**/ close();
}

abstract class /*class: A3a:A3a<T*>,Object*/ A3a<T> {
  void /*member: A3a.close:void Function()**/ close();
}

abstract class /*class: A3b:A3a<T*>,A3b<T*>,Object*/ A3b<T> implements A3a<T> {
  void /*member: A3b.close:void Function()**/ close();
}

abstract class /*class: B3:B3<T*>,Object*/ B3<T> {
  Object /*member: B3.close:Object* Function()**/ close();
}

abstract class /*class: C3a:A3a<T*>,A3b<T*>,B3<T*>,C3a<T*>,Object*/ C3a<T>
    implements A3b<T>, B3<T> {
  Object /*member: C3a.close:Object* Function()**/ close();
}

abstract class /*class: C3b:A3a<T*>,A3b<T*>,B3<T*>,C3b<T*>,Object*/ C3b<T>
    implements B3<T>, A3b<T> {
  Object /*member: C3b.close:Object* Function()**/ close();
}
