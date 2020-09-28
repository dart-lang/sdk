// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: A.:OutputUnit(1, {lib})*/
class A {}

/*class: I:none, type=OutputUnit(1, {lib})*/
class I<T> {}

/*class: J:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: J.:OutputUnit(1, {lib})*/
class J<T> {}

// C needs to include "N", otherwise checking for `is I<A>` will likely cause
// problems
/*class: C:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: C.:OutputUnit(1, {lib})*/
class C extends A implements I<N> {}

/*class: C1:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: C1.:OutputUnit(1, {lib})*/
class C1 extends J<M> implements A {}

/*class: C2:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: C2.:OutputUnit(1, {lib})*/
class C2 extends J<M> implements I<N> {}

/*class: N:none, type=OutputUnit(1, {lib})*/
class N extends A {}

/*class: M:none, type=OutputUnit(1, {lib})*/
class M extends A {}

/*member: doCheck1:OutputUnit(1, {lib})*/
doCheck1(x) => x is I<A>;
/*member: doCheck2:OutputUnit(1, {lib})*/
doCheck2(x) => x is J<A>;
