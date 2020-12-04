// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: A.:member_unit=1{lib}*/
class A {}

/*class: I:
 class_unit=none,
 type_unit=1{lib}
*/
class I<T> {}

/*class: J:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: J.:member_unit=1{lib}*/
class J<T> {}

// C needs to include "N", otherwise checking for `is I<A>` will likely cause
// problems
/*class: C:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: C.:member_unit=1{lib}*/
class C extends A implements I<N> {}

/*class: C1:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: C1.:member_unit=1{lib}*/
class C1 extends J<M> implements A {}

/*class: C2:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: C2.:member_unit=1{lib}*/
class C2 extends J<M> implements I<N> {}

/*class: N:
 class_unit=none,
 type_unit=1{lib}
*/
class N extends A {}

/*class: M:
 class_unit=none,
 type_unit=1{lib}
*/
class M extends A {}

/*member: doCheck1:member_unit=1{lib}*/
doCheck1(x) => x is I<A>;
/*member: doCheck2:member_unit=1{lib}*/
doCheck2(x) => x is J<A>;
