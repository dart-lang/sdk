// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  refineToClass();
  refineToClosure();
}

////////////////////////////////////////////////////////////////////////////////
// Refine nullability of a non-captured local variable through a sequence of
// accesses and updates.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.method0:[null]*/
  method0() {}
  /*member: Class1.method1:[null]*/
  method1() {}
  /*member: Class1.field0:[null|exact=JSUInt31]*/
  var field0;
  /*member: Class1.field1:[null|exact=JSUInt31]*/
  var field1;
}

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.method0:[null]*/
  method0() {}
  /*member: Class2.method2:[null]*/
  method2() {}
  /*member: Class2.field0:[null]*/
  var field0;
  /*member: Class2.field2:[null]*/
  var field2;
}

/*member: _refineUnion:Union([exact=Class1], [exact=Class2])*/
_refineUnion(/*Union(null, [exact=Class1], [exact=Class2])*/ o) {
  o. /*invoke: Union(null, [exact=Class1], [exact=Class2])*/ method0();
  o. /*invoke: Union([exact=Class1], [exact=Class2])*/ method1();
  o. /*invoke: Union([exact=Class1], [exact=Class2])*/ method2();
  return o;
}

/*member: _refineFromMethod:[exact=Class1]*/
_refineFromMethod(/*[null|exact=Class1]*/ o) {
  o. /*invoke: [null|exact=Class1]*/ method0();
  o. /*invoke: [exact=Class1]*/ method1();
  return o;
}

/*member: _refineFromGetter:[exact=Class2]*/
_refineFromGetter(/*[null|exact=Class2]*/ o) {
  o. /*[null|exact=Class2]*/ field0;
  o. /*[exact=Class2]*/ field2;
  return o;
}

/*member: _refineFromSetter:[exact=Class1]*/
_refineFromSetter(/*[null|exact=Class1]*/ o) {
  o. /*update: [null|exact=Class1]*/ field0 = 0;
  o. /*update: [exact=Class1]*/ field1 = 0;
  return o;
}

/*member: _noRefinementNullAware:[null|exact=Class1]*/
_noRefinementNullAware(/*[null|exact=Class1]*/ o) {
  o
      ?.
      /*invoke: [exact=Class1]*/
      method1();
  return o;
}

/*member: _noRefinementNullSelectors:[exact=Class2]*/
_noRefinementNullSelectors(/*[null|exact=Class2]*/ o) {
  o /*invoke: [null|exact=Class2]*/ == 2;
  o. /*[null|exact=Class2]*/ hashCode;
  o. /*[null|exact=Class2]*/ runtimeType;
  o. /*[null|exact=Class2]*/ toString;
  o. /*[null|exact=Class2]*/ noSuchMethod;
  o. /*invoke: [null|exact=Class2]*/ toString();
  o. /*invoke: [null|exact=Class2]*/ noSuchMethod(null); // assumed to throw.
  o. /*[exact=Class2]*/ toString;
  return o;
}

/*member: _noRefinementUpdatedVariable:[null|exact=Class1]*/
_noRefinementUpdatedVariable(/*[null|exact=Class1]*/ o) {
  (o = o). /*invoke: [null|exact=Class1]*/ method1();
  (o = o). /*invoke: [null|exact=Class1]*/ method0();
  return o;
}

/*member: _condition:Value([exact=JSBool], value: false)*/
@pragma('dart2js:assumeDynamic')
get _condition => false;

/*member: refineToClass:[null]*/
refineToClass() {
  var nullOrClass1 = _condition ? null : new Class1();
  var nullOrClass2 = _condition ? null : new Class2();
  _refineUnion(nullOrClass1);
  _refineUnion(nullOrClass2);

  _refineFromMethod(nullOrClass1);
  _refineFromGetter(nullOrClass2);
  _refineFromSetter(nullOrClass1);
  _noRefinementNullAware(nullOrClass1);
  _noRefinementNullSelectors(nullOrClass2);
  _noRefinementUpdatedVariable(nullOrClass1);
}

////////////////////////////////////////////////////////////////////////////////
// Refine the type of a local variable through a sequence of invocations.
////////////////////////////////////////////////////////////////////////////////

/*member: _refineToClosureLocal:[subclass=Closure]*/
_refineToClosureLocal() {
  var f = /*[null]*/ ({/*[exact=JSUInt31]*/ a}) {};
  f(a: 0);
  return f;
}

/*member: _refineToClosureLocalCall:[subclass=Closure]*/
_refineToClosureLocalCall() {
  var f = /*[null]*/ ({/*[exact=JSUInt31]*/ b}) {};
  f.call(b: 0);
  return f;
}

/*member: refineToClosure:[null]*/
refineToClosure() {
  _refineToClosureLocal();
  _refineToClosureLocalCall();
}
