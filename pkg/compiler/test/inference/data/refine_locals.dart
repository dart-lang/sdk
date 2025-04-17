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

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 {
  /*member: Class1.method0:[null|powerset={null}]*/
  method0() {}
  /*member: Class1.method1:[null|powerset={null}]*/
  method1() {}
  /*member: Class1.field0:[null|exact=JSUInt31|powerset={null}{I}]*/
  var field0;
  /*member: Class1.field1:[null|exact=JSUInt31|powerset={null}{I}]*/
  var field1;
}

/*member: Class2.:[exact=Class2|powerset={N}]*/
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

/*member: _refineUnion:Union([exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {N})*/
_refineUnion(
  /*Union(null, [exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {null}{N})*/ o,
) {
  o. /*invoke: Union(null, [exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {null}{N})*/ method0();
  o. /*invoke: Union([exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {N})*/ method1();
  o. /*invoke: Union([exact=Class1|powerset={N}], [exact=Class2|powerset={N}], powerset: {N})*/ method2();
  return o;
}

/*member: _refineFromMethod:[exact=Class1|powerset={N}]*/
_refineFromMethod(/*[null|exact=Class1|powerset={null}{N}]*/ o) {
  o. /*invoke: [null|exact=Class1|powerset={null}{N}]*/ method0();
  o. /*invoke: [exact=Class1|powerset={N}]*/ method1();
  return o;
}

/*member: _refineFromGetter:[exact=Class2|powerset={N}]*/
_refineFromGetter(/*[null|exact=Class2|powerset={null}{N}]*/ o) {
  o. /*[null|exact=Class2|powerset={null}{N}]*/ field0;
  o. /*[exact=Class2|powerset={N}]*/ field2;
  return o;
}

/*member: _refineFromSetter:[exact=Class1|powerset={N}]*/
_refineFromSetter(/*[null|exact=Class1|powerset={null}{N}]*/ o) {
  o. /*update: [null|exact=Class1|powerset={null}{N}]*/ field0 = 0;
  o. /*update: [exact=Class1|powerset={N}]*/ field1 = 0;
  return o;
}

/*member: _noRefinementNullAware:[null|exact=Class1|powerset={null}{N}]*/
_noRefinementNullAware(/*[null|exact=Class1|powerset={null}{N}]*/ o) {
  o
      ?.
      /*invoke: [exact=Class1|powerset={N}]*/
      method1();
  return o;
}

/*member: _noRefinementNullSelectors:[exact=Class2|powerset={N}]*/
_noRefinementNullSelectors(/*[null|exact=Class2|powerset={null}{N}]*/ o) {
  o /*invoke: [null|exact=Class2|powerset={null}{N}]*/ == 2;
  o. /*[null|exact=Class2|powerset={null}{N}]*/ hashCode;
  o. /*[null|exact=Class2|powerset={null}{N}]*/ runtimeType;
  o. /*[null|exact=Class2|powerset={null}{N}]*/ toString;
  o. /*[null|exact=Class2|powerset={null}{N}]*/ noSuchMethod;
  o. /*invoke: [null|exact=Class2|powerset={null}{N}]*/ toString();
  o. /*invoke: [null|exact=Class2|powerset={null}{N}]*/ noSuchMethod(
    null as dynamic,
  ); // assumed to throw.
  o. /*[exact=Class2|powerset={N}]*/ toString;
  return o;
}

/*member: _noRefinementUpdatedVariable:[null|exact=Class1|powerset={null}{N}]*/
_noRefinementUpdatedVariable(/*[null|exact=Class1|powerset={null}{N}]*/ o) {
  (o = o). /*invoke: [null|exact=Class1|powerset={null}{N}]*/ method1();
  (o = o). /*invoke: [null|exact=Class1|powerset={null}{N}]*/ method0();
  return o;
}

/*member: _condition:Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/
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

/*member: _refineToClosureLocal:[subclass=Closure|powerset={N}]*/
_refineToClosureLocal() {
  var f = /*[null|powerset={null}]*/ ({/*[exact=JSUInt31|powerset={I}]*/ a}) {};
  f(a: 0);
  return f;
}

/*member: _refineToClosureLocalCall:[subclass=Closure|powerset={N}]*/
_refineToClosureLocalCall() {
  var f = /*[null|powerset={null}]*/ ({/*[exact=JSUInt31|powerset={I}]*/ b}) {};
  f.call(b: 0);
  return f;
}

/*member: refineToClosure:[null|powerset={null}]*/
refineToClosure() {
  _refineToClosureLocal();
  _refineToClosureLocalCall();
}
