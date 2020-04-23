// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

/*class: A1:A1,Object*/
abstract class A1 {
  /*member: A1.close:void Function()**/
  void close();
}

/*class: B1:B1,Object*/
abstract class B1 {
  /*member: B1.close:Object* Function()**/
  Object close();
}

/*class: C1a:A1,B1,C1a,Object*/
abstract class C1a implements A1, B1 {
  /*member: C1a.close:Object* Function()**/
  Object close();
}

/*class: C1b:A1,B1,C1b,Object*/
abstract class C1b implements B1, A1 {
  /*member: C1b.close:Object* Function()**/
  Object close();
}

/*class: A2:A2<T*>,Object*/
abstract class A2<T> {
  /*member: A2.close:void Function()**/
  void close();
}

/*class: B2a:B2a<T*>,Object*/
abstract class B2a<T> {
  /*member: B2a.close:Object* Function()**/
  Object close();
}

/*class: B2b:B2a<dynamic>,B2b<T*>,Object*/
abstract class B2b<T> implements B2a {
  /*member: B2b.close:Object* Function()**/
  Object close();
}

/*class: C2a:A2<T*>,B2a<dynamic>,B2b<T*>,C2a<T*>,Object*/
abstract class C2a<T> implements A2<T>, B2b<T> {
  /*member: C2a.close:Object* Function()**/
  Object close();
}

/*class: C2b:A2<T*>,B2a<dynamic>,B2b<T*>,C2b<T*>,Object*/
abstract class C2b<T> implements B2b<T>, A2<T> {
  /*member: C2b.close:Object* Function()**/
  Object close();
}

/*class: A3a:A3a<T*>,Object*/
abstract class A3a<T> {
  /*member: A3a.close:void Function()**/
  void close();
}

/*class: A3b:A3a<T*>,A3b<T*>,Object*/
abstract class A3b<T> implements A3a<T> {
  /*member: A3b.close:void Function()**/
  void close();
}

/*class: B3:B3<T*>,Object*/
abstract class B3<T> {
  /*member: B3.close:Object* Function()**/
  Object close();
}

/*class: C3a:A3a<T*>,A3b<T*>,B3<T*>,C3a<T*>,Object*/
abstract class C3a<T> implements A3b<T>, B3<T> {
  /*member: C3a.close:Object* Function()**/
  Object close();
}

/*class: C3b:A3a<T*>,A3b<T*>,B3<T*>,C3b<T*>,Object*/
abstract class C3b<T> implements B3<T>, A3b<T> {
  /*member: C3b.close:Object* Function()**/
  Object close();
}
