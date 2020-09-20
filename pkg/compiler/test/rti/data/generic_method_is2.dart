// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A1:implicit=[A1]*/
class A1 {}

/*spec.class: A2:implicit=[A2]*/
class A2 {}

/*class: B1:implicit=[B1]*/
class B1 {}

/*spec.class: B2:implicit=[B2]*/
class B2 {}

/*class: C1:implicit=[C1]*/
class C1 {}

/*spec.class: C2:implicit=[C2]*/
class C2 {}

/*class: C3:implicit=[C3]*/
class C3 {}

/*class: D1:implicit=[D1]*/
class D1 {}

/*spec.class: D2:implicit=[D2]*/
class D2 {}

/*class: E1:implicit=[E1]*/
class E1 {}

/*spec.class: E2:implicit=[E2]*/
class E2 {}

/*class: F1:implicit=[F1]*/
class F1 {}

/*spec.class: F2:implicit=[F2]*/
class F2 {}

/*class: F3:implicit=[F3]*/
class F3 {}

// Calls to this imply a check of the passed type arguments.
/*member: topLevelMethod1:direct,explicit=[topLevelMethod1.T*],needsArgs,selectors=[Selector(call, call, arity=2, named=[a1], types=1)]*/
bool topLevelMethod1<T>(T t, {a1}) => t is T;

// Calls to this does _not_ imply a check of the passed type arguments.
/*spec.member: topLevelMethod2:direct,explicit=[topLevelMethod2.T*],needsArgs,selectors=[Selector(call, call, arity=2, named=[a2], types=1)]*/
T topLevelMethod2<T>(T t, {a2}) => t;

class Class {
  // Calls to this imply a check of the passed type arguments.
  /*member: Class.instanceMethod1:direct,explicit=[instanceMethod1.S*],needsArgs,selectors=[Selector(call, call, arity=2, named=[b1], types=1),Selector(call, instanceMethod1, arity=2, named=[b1], types=1)]*/
  bool instanceMethod1<S>(S s, {b1}) => s is S;

  // Calls to this does _not_ imply a check of the passed type arguments.
  /*spec.member: Class.instanceMethod2:direct,explicit=[instanceMethod2.S*],needsArgs,selectors=[Selector(call, call, arity=2, named=[b2], types=1),Selector(call, instanceMethod2, arity=2, named=[b2], types=1)]*/
  S instanceMethod2<S>(S s, {b2}) => s;
}

main() {
  // Calls to this imply a check of the passed type arguments.
  /*direct,explicit=[localFunction1.U*],needsArgs,selectors=[Selector(call, call, arity=2, named=[c1], types=1)]*/
  bool localFunction1<U>(U u, {c1}) => u is U;

  // Calls to this does _not_ imply a check of the passed type arguments.
  /*spec.direct,explicit=[localFunction2.U*],needsArgs,selectors=[Selector(call, call, arity=2, named=[c2], types=1)]*/
  U localFunction2<U>(U u, {c2}) => u;

  // Calls to this does _not_ imply a check of the passed type arguments. A
  // call to the .call function on this will, though, since it has the same
  // signature as [localFunction1] which needs its type arguments.
  /*spec.direct,explicit=[localFunction3.U*],needsArgs,selectors=[Selector(call, call, arity=2, named=[c1], types=1)]*/
  localFunction3<U>(U u, {c1}) => u;

  var c = new Class();

  var local1 = localFunction1;
  var local2 = localFunction2;
  var local3 = localFunction3;
  var staticTearOff1 = topLevelMethod1;
  var staticTearOff2 = topLevelMethod2;
  var instanceTearOff1 = c.instanceMethod1;
  var instanceTearOff2 = c.instanceMethod2;

  topLevelMethod1<A1>(new A1(), a1: 0);
  topLevelMethod2<A2>(new A2(), a2: 0);
  c.instanceMethod1<B1>(new B1(), b1: 0);
  c.instanceMethod2<B2>(new B2(), b2: 0);
  localFunction1<C1>(new C1(), c1: 0);
  localFunction2<C2>(new C2(), c2: 0);
  localFunction3<C3>(new C3(), c1: 0);

  staticTearOff1<D1>(new D1(), a1: 0);
  staticTearOff2<D2>(new D2(), a2: 0);
  instanceTearOff1<E1>(new E1(), b1: 0);
  instanceTearOff2<E2>(new E2(), b2: 0);
  local1<F1>(new F1(), c1: 0);
  local2<F2>(new F2(), c2: 0);
  local3<F3>(new F3(), c1: 0);
}
