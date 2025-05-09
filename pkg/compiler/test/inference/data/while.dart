// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  simpleWhile();
  whileNull();
  whileNotNull();
  whileNullUnreachable();
  whileNotNullUnreachable();
  whileUnion1();
  whileUnion2();
  whileUnion3();
  whileIs();
  whileIsNot();
}

////////////////////////////////////////////////////////////////////////////////
/// Simple int based while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleWhile:[null|powerset={null}]*/
simpleWhile() {
  var i = 0;
  while (i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ < 10) {
    i = i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ + 1;
  }
  i. /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ abs();
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNull:Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "null", powerset: {null}{I}{O}{I})*/
whileNull() {
  var o;
  while (o == null) {
    o = o. /*invoke: [null|powerset={null}]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNotNull:[exact=JSString|powerset={I}{O}{I}]*/
whileNotNull() {
  var o = '';
  while (o /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ != null) {
    o = o. /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNullUnreachable:Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/
whileNullUnreachable() {
  var o = '';
  while (o /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ == null) {
    o = o. /*invoke: [empty|powerset=empty]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNotNullUnreachable:[null|powerset={null}]*/
whileNotNullUnreachable() {
  var o = null;
  while (o != null) {
    o = o. /*invoke: [empty|powerset=empty]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the first
/// object to the [_whileUnion1] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.field:[null|exact=Class2|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.field:[null|exact=Class1|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: _whileUnion1:Union(null, [exact=Class1|powerset={N}{O}{N}], [exact=Class2|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/
_whileUnion1(/*[exact=Class1|powerset={N}{O}{N}]*/ o) {
  while (o != null) {
    o = o
        . /*Union([exact=Class1|powerset={N}{O}{N}], [exact=Class2|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ field;
  }
  return o;
}

/*member: whileUnion1:[null|powerset={null}]*/
whileUnion1() {
  var c1 = Class1();
  var c2 = Class2();
  c1. /*update: [exact=Class1|powerset={N}{O}{N}]*/ field = c2;
  c2. /*update: [exact=Class2|powerset={N}{O}{N}]*/ field = c1;
  _whileUnion1(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the second
/// object to the [_whileUnion2] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  /*member: Class3.field:[null|exact=Class4|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {
  /*member: Class4.field:[null|exact=Class3|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: _whileUnion2:Union(null, [exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/
_whileUnion2(/*[exact=Class4|powerset={N}{O}{N}]*/ o) {
  while (o != null) {
    o = o
        . /*Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ field;
  }
  return o;
}

/*member: whileUnion2:[null|powerset={null}]*/
whileUnion2() {
  var c1 = Class3();
  var c2 = Class4();
  c1. /*update: [exact=Class3|powerset={N}{O}{N}]*/ field = c2;
  c2. /*update: [exact=Class4|powerset={N}{O}{N}]*/ field = c1;
  _whileUnion2(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing both
/// objects to the [_whileUnion3] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
class Class5 {
  /*member: Class5.field:[null|exact=Class6|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
class Class6 {
  /*member: Class6.field:[null|exact=Class5|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: _whileUnion3:Union(null, [exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/
_whileUnion3(
  /*Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ o,
) {
  while (o != null) {
    o = o
        . /*Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ field;
  }
  return o;
}

/*member: whileUnion3:[null|powerset={null}]*/
whileUnion3() {
  var c1 = Class5();
  var c2 = Class6();
  c1. /*update: [exact=Class5|powerset={N}{O}{N}]*/ field = c2;
  c2. /*update: [exact=Class6|powerset={N}{O}{N}]*/ field = c1;
  _whileUnion3(c1);
  _whileUnion3(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
class Class7 {
  /*member: Class7.field:[null|exact=Class8|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: Class8.:[exact=Class8|powerset={N}{O}{N}]*/
class Class8 {
  /*member: Class8.field:[null|exact=Class7|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: _whileIs:Union(null, [exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/
_whileIs(/*[exact=Class7|powerset={N}{O}{N}]*/ o) {
  while (o is Class7) {
    o = o. /*[exact=Class7|powerset={N}{O}{N}]*/ field;
  }
  return o;
}

/*member: whileIs:[null|powerset={null}]*/
whileIs() {
  var c1 = Class7();
  var c2 = Class8();
  c1. /*update: [exact=Class7|powerset={N}{O}{N}]*/ field = c2;
  c2. /*update: [exact=Class8|powerset={N}{O}{N}]*/ field = c1;
  _whileIs(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is-not test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class9.:[exact=Class9|powerset={N}{O}{N}]*/
class Class9 {
  /*member: Class9.field:[null|exact=Class10|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: Class10.:[exact=Class10|powerset={N}{O}{N}]*/
class Class10 {
  /*member: Class10.field:[null|exact=Class9|powerset={null}{N}{O}{N}]*/
  var field;
}

/*member: _whileIsNot:Union(null, [exact=Class10|powerset={N}{O}{N}], [exact=Class9|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/
_whileIsNot(/*[exact=Class9|powerset={N}{O}{N}]*/ o) {
  while (o is! Class10) {
    o = o
        . /*Union(null, [exact=Class10|powerset={N}{O}{N}], [exact=Class9|powerset={N}{O}{N}], powerset: {null}{N}{O}{N})*/ field;
  }
  return o;
}

/*member: whileIsNot:[null|powerset={null}]*/
whileIsNot() {
  var c1 = Class9();
  var c2 = Class10();
  c1. /*update: [exact=Class9|powerset={N}{O}{N}]*/ field = c2;
  c2. /*update: [exact=Class10|powerset={N}{O}{N}]*/ field = c1;
  _whileIsNot(c1);
}
