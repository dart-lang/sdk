// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  refineToClass();
  refineToClosure();
}

////////////////////////////////////////////////////////////////////////////////
// Refine nullability of a non-captured local variable through a sequence of
// accesses and updates.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.method0:[null|powerset=1]*/
  method0() {}
  /*member: Class1.method1:[null|powerset=1]*/
  method1() {}
  /*member: Class1.field0:[null|exact=JSUInt31|powerset=1]*/
  var field0;
  /*member: Class1.field1:[null|exact=JSUInt31|powerset=1]*/
  var field1;
}

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.method0:[null|powerset=1]*/
  method0() {}
  /*member: Class2.method2:[null|powerset=1]*/
  method2() {}
  /*member: Class2.field0:[null|powerset=1]*/
  var field0;
  /*member: Class2.field2:[null|powerset=1]*/
  var field2;
}

/*member: _refineUnion:Union([exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 0)*/
_refineUnion(
  /*Union(null, [exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 1)*/ o,
) {
  o. /*invoke: Union(null, [exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 1)*/ method0();
  o. /*invoke: Union([exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 0)*/ method1();
  o. /*invoke: Union([exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 0)*/ method2();
  return o;
}

/*member: _refineFromMethod:[exact=Class1|powerset=0]*/
_refineFromMethod(/*[null|exact=Class1|powerset=1]*/ o) {
  o. /*invoke: [null|exact=Class1|powerset=1]*/ method0();
  o. /*invoke: [exact=Class1|powerset=0]*/ method1();
  return o;
}

/*member: _refineFromGetter:[exact=Class2|powerset=0]*/
_refineFromGetter(/*[null|exact=Class2|powerset=1]*/ o) {
  o. /*[null|exact=Class2|powerset=1]*/ field0;
  o. /*[exact=Class2|powerset=0]*/ field2;
  return o;
}

/*member: _refineFromSetter:[exact=Class1|powerset=0]*/
_refineFromSetter(/*[null|exact=Class1|powerset=1]*/ o) {
  o. /*update: [null|exact=Class1|powerset=1]*/ field0 = 0;
  o. /*update: [exact=Class1|powerset=0]*/ field1 = 0;
  return o;
}

/*member: _noRefinementNullAware:[null|exact=Class1|powerset=1]*/
_noRefinementNullAware(/*[null|exact=Class1|powerset=1]*/ o) {
  o
      ?.
      /*invoke: [exact=Class1|powerset=0]*/
      method1();
  return o;
}

/*member: _noRefinementNullSelectors:[exact=Class2|powerset=0]*/
_noRefinementNullSelectors(/*[null|exact=Class2|powerset=1]*/ o) {
  o /*invoke: [null|exact=Class2|powerset=1]*/ == 2;
  o. /*[null|exact=Class2|powerset=1]*/ hashCode;
  o. /*[null|exact=Class2|powerset=1]*/ runtimeType;
  o. /*[null|exact=Class2|powerset=1]*/ toString;
  o. /*[null|exact=Class2|powerset=1]*/ noSuchMethod;
  o. /*invoke: [null|exact=Class2|powerset=1]*/ toString();
  o. /*invoke: [null|exact=Class2|powerset=1]*/ noSuchMethod(
    null as dynamic,
  ); // assumed to throw.
  o. /*[exact=Class2|powerset=0]*/ toString;
  return o;
}

/*member: _noRefinementUpdatedVariable:[null|exact=Class1|powerset=1]*/
_noRefinementUpdatedVariable(/*[null|exact=Class1|powerset=1]*/ o) {
  (o = o). /*invoke: [null|exact=Class1|powerset=1]*/ method1();
  (o = o). /*invoke: [null|exact=Class1|powerset=1]*/ method0();
  return o;
}

/*member: _condition:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
get _condition => false;

/*member: refineToClass:[null|powerset=1]*/
refineToClass() {
  var nullOrClass1 = _condition ? null : Class1();
  var nullOrClass2 = _condition ? null : Class2();
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

/*member: _refineToClosureLocal:[subclass=Closure|powerset=0]*/
_refineToClosureLocal() {
  var f = /*[null|powerset=1]*/ ({/*[exact=JSUInt31|powerset=0]*/ a}) {};
  f(a: 0);
  return f;
}

/*member: _refineToClosureLocalCall:[subclass=Closure|powerset=0]*/
_refineToClosureLocalCall() {
  var f = /*[null|powerset=1]*/ ({/*[exact=JSUInt31|powerset=0]*/ b}) {};
  f.call(b: 0);
  return f;
}

/*member: refineToClosure:[null|powerset=1]*/
refineToClosure() {
  _refineToClosureLocal();
  _refineToClosureLocalCall();
}
