// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class B {
  call<T>();
}

/*member: C.:[exact=C|powerset=0]*/
class C implements B {
  /*member: C.call:[null|powerset=1]*/
  call<T>() => print(T);
}

abstract class A {}

class Wrapper {
  /*member: Wrapper.:[exact=Wrapper|powerset=0]*/
  Wrapper(
    this. /*[exact=C|powerset=0]*/ b,
    this. /*[exact=C|powerset=0]*/ call,
  );
  /*member: Wrapper.b:[exact=C|powerset=0]*/
  final B b;
  /*member: Wrapper.call:[exact=C|powerset=0]*/
  final B call;
}

/*member: main:[null|powerset=1]*/
void main() {
  B b = C();
  b/*invoke: [exact=C|powerset=0]*/ <A>();
  Wrapper(b, b).b<A> /*invoke: [exact=Wrapper|powerset=0]*/ ();
  (Wrapper(
    b,
    b,
  ). /*[exact=Wrapper|powerset=0]*/ b)<A> /*invoke: [exact=C|powerset=0]*/ ();
  Wrapper(b, b).call<A> /*invoke: [exact=Wrapper|powerset=0]*/ ();
  (Wrapper(b, b). /*[exact=Wrapper|powerset=0]*/ call)<
    A
  > /*invoke: [exact=C|powerset=0]*/ ();
}
