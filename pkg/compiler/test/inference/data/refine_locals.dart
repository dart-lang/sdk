// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  refineToClass();
  refineToClosure();
}

////////////////////////////////////////////////////////////////////////////////
// Refine nullability of a non-captured local variable through a sequence of
// accesses and updates.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 {
  /*member: Class1.method0:[null|powerset={null}]*/
  method0() {}
  /*member: Class1.method1:[null|powerset={null}]*/
  method1() {}
  /*member: Class1.field0:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field0;
  /*member: Class1.field1:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
  var field1;
}

/*member: Class2.:[exact=Class2|powerset={N}{O}]*/
class Class2 {
  /*member: Class2.method0:[null|powerset={null}]*/
  method0() {}
  /*member: Class2.method2:[null|powerset={null}]*/
  method2() {}
  /*member: Class2.field0:[null|powerset={null}]*/
  var field0;
  /*member: Class2.field2:[null|powerset={null}]*/
  var field2;
}

/*member: _refineUnion:Union([exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {N}{O})*/
_refineUnion(
  /*Union(null, [exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {null}{N}{O})*/ o,
) {
  o. /*invoke: Union(null, [exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {null}{N}{O})*/ method0();
  o. /*invoke: Union([exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {N}{O})*/ method1();
  o. /*invoke: Union([exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {N}{O})*/ method2();
  return o;
}

/*member: _refineFromMethod:[exact=Class1|powerset={N}{O}]*/
_refineFromMethod(/*[null|exact=Class1|powerset={null}{N}{O}]*/ o) {
  o. /*invoke: [null|exact=Class1|powerset={null}{N}{O}]*/ method0();
  o. /*invoke: [exact=Class1|powerset={N}{O}]*/ method1();
  return o;
}

/*member: _refineFromGetter:[exact=Class2|powerset={N}{O}]*/
_refineFromGetter(/*[null|exact=Class2|powerset={null}{N}{O}]*/ o) {
  o. /*[null|exact=Class2|powerset={null}{N}{O}]*/ field0;
  o. /*[exact=Class2|powerset={N}{O}]*/ field2;
  return o;
}

/*member: _refineFromSetter:[exact=Class1|powerset={N}{O}]*/
_refineFromSetter(/*[null|exact=Class1|powerset={null}{N}{O}]*/ o) {
  o. /*update: [null|exact=Class1|powerset={null}{N}{O}]*/ field0 = 0;
  o. /*update: [exact=Class1|powerset={N}{O}]*/ field1 = 0;
  return o;
}

/*member: _noRefinementNullAware:[null|exact=Class1|powerset={null}{N}{O}]*/
_noRefinementNullAware(/*[null|exact=Class1|powerset={null}{N}{O}]*/ o) {
  o
      ?.
      /*invoke: [exact=Class1|powerset={N}{O}]*/
      method1();
  return o;
}

/*member: _noRefinementNullSelectors:[exact=Class2|powerset={N}{O}]*/
_noRefinementNullSelectors(/*[null|exact=Class2|powerset={null}{N}{O}]*/ o) {
  o /*invoke: [null|exact=Class2|powerset={null}{N}{O}]*/ == 2;
  o. /*[null|exact=Class2|powerset={null}{N}{O}]*/ hashCode;
  o. /*[null|exact=Class2|powerset={null}{N}{O}]*/ runtimeType;
  o. /*[null|exact=Class2|powerset={null}{N}{O}]*/ toString;
  o. /*[null|exact=Class2|powerset={null}{N}{O}]*/ noSuchMethod;
  o. /*invoke: [null|exact=Class2|powerset={null}{N}{O}]*/ toString();
  o. /*invoke: [null|exact=Class2|powerset={null}{N}{O}]*/ noSuchMethod(
    null as dynamic,
  ); // assumed to throw.
  o. /*[exact=Class2|powerset={N}{O}]*/ toString;
  return o;
}

/*member: _noRefinementUpdatedVariable:[null|exact=Class1|powerset={null}{N}{O}]*/
_noRefinementUpdatedVariable(/*[null|exact=Class1|powerset={null}{N}{O}]*/ o) {
  (o = o). /*invoke: [null|exact=Class1|powerset={null}{N}{O}]*/ method1();
  (o = o). /*invoke: [null|exact=Class1|powerset={null}{N}{O}]*/ method0();
  return o;
}

/*member: _condition:Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
get _condition => false;

/*member: refineToClass:[null|powerset={null}]*/
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

/*member: _refineToClosureLocal:[subclass=Closure|powerset={N}{O}]*/
_refineToClosureLocal() {
  var f = /*[null|powerset={null}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ a}) {};
  f(a: 0);
  return f;
}

/*member: _refineToClosureLocalCall:[subclass=Closure|powerset={N}{O}]*/
_refineToClosureLocalCall() {
  var f = /*[null|powerset={null}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ b}) {};
  f.call(b: 0);
  return f;
}

/*member: refineToClosure:[null|powerset={null}]*/
refineToClosure() {
  _refineToClosureLocal();
  _refineToClosureLocalCall();
}
