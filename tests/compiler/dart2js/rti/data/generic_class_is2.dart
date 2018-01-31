// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

// TODO(johnniwinther): A, C and C2 should be checked or A1, C1, and C2 should
// have checks againts A, C and C, respectively.
/*class: A:arg,checks=[A],implicit=[List<A<C2>>,List<A<C>>]*/
class A<T> {}

/*class: A1:arg,checks=[A]*/
class A1 implements A<C1> {}

/*class: B:direct,explicit=[B.T],needsArgs*/
class B<T> {
  @noInline
  method(var t) => t is T;
}

/*class: C:arg,checks=[C],implicit=[List<A<C>>]*/
class C {}

/*class: C1:arg*/
class C1 implements C {}

/*class: C2:arg,checks=[C,C2],implicit=[List<A<C2>>]*/
class C2 implements C {}

main() {
  Expect.isTrue(new B<List<A<C>>>().method(new List<A1>()));
  Expect.isFalse(new B<List<A<C2>>>().method(new List<A1>()));
}
