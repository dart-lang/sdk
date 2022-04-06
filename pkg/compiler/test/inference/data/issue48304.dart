// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.15

abstract class B {
  call<T>();
}

/*member: C.:[exact=C]*/
class C implements B {
  /*member: C.call:[null]*/
  call<T>() => print(T);
}

abstract class A {}

class Wrapper {
  /*member: Wrapper.:[exact=Wrapper]*/
  Wrapper(this. /*[exact=C]*/ b, this. /*[exact=C]*/ call);
  /*member: Wrapper.b:[exact=C]*/
  final B b;
  /*member: Wrapper.call:[exact=C]*/
  final B call;
}

/*member: main:[null]*/
void main() {
  B b = C();
  b/*invoke: [exact=C]*/ <A>();
  Wrapper(b, b).b<A> /*invoke: [exact=Wrapper]*/ ();
  (Wrapper(b, b). /*[exact=Wrapper]*/ b)<A> /*invoke: [exact=C]*/ ();
  Wrapper(b, b).call<A> /*invoke: [exact=Wrapper]*/ ();
  (Wrapper(b, b). /*[exact=Wrapper]*/ call)<A> /*invoke: [exact=C]*/ ();
}
