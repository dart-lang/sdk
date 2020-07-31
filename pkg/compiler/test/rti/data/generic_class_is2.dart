// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: A:implicit=[List<A<C*>*>,List<A<C2*>*>]*/
class A<T> {}

/*spec.class: A1:implicit=[A1]*/
class A1 implements A<C1> {}

/*class: B:direct,explicit=[B.T*],needsArgs*/
class B<T> {
  @pragma('dart2js:noInline')
  method(var t) => t is T;
}

/*class: C:implicit=[List<A<C*>*>]*/
class C {}

class C1 implements C {}

/*class: C2:implicit=[List<A<C2*>*>]*/
class C2 implements C {}

main() {
  Expect.isTrue(new B<List<A<C>>>().method(new List<A1>()));
  Expect.isFalse(new B<List<A<C2>>>().method(new List<A1>()));
}
