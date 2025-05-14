// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: simpleWhile:[null|powerset=1]*/
simpleWhile() {
  var i = 0;
  while (i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ < 10) {
    i = i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ + 1;
  }
  i. /*invoke: [subclass=JSPositiveInt|powerset=0]*/ abs();
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNull:Value([null|exact=JSString|powerset=1], value: "null", powerset: 1)*/
whileNull() {
  var o;
  while (o == null) {
    o = o. /*invoke: [null|powerset=1]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNotNull:[exact=JSString|powerset=0]*/
whileNotNull() {
  var o = '';
  while (o /*invoke: [exact=JSString|powerset=0]*/ != null) {
    o = o. /*invoke: [exact=JSString|powerset=0]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNullUnreachable:Value([exact=JSString|powerset=0], value: "", powerset: 0)*/
whileNullUnreachable() {
  var o = '';
  while (o /*invoke: [exact=JSString|powerset=0]*/ == null) {
    o = o. /*invoke: [empty|powerset=0]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*member: whileNotNullUnreachable:[null|powerset=1]*/
whileNotNullUnreachable() {
  var o = null;
  while (o != null) {
    o = o. /*invoke: [empty|powerset=0]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the first
/// object to the [_whileUnion1] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.field:[null|exact=Class2|powerset=1]*/
  var field;
}

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.field:[null|exact=Class1|powerset=1]*/
  var field;
}

/*member: _whileUnion1:Union(null, [exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 1)*/
_whileUnion1(/*[exact=Class1|powerset=0]*/ o) {
  while (o != null) {
    o = o. /*Union([exact=Class1|powerset=0], [exact=Class2|powerset=0], powerset: 0)*/ field;
  }
  return o;
}

/*member: whileUnion1:[null|powerset=1]*/
whileUnion1() {
  var c1 = Class1();
  var c2 = Class2();
  c1. /*update: [exact=Class1|powerset=0]*/ field = c2;
  c2. /*update: [exact=Class2|powerset=0]*/ field = c1;
  _whileUnion1(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the second
/// object to the [_whileUnion2] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  /*member: Class3.field:[null|exact=Class4|powerset=1]*/
  var field;
}

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {
  /*member: Class4.field:[null|exact=Class3|powerset=1]*/
  var field;
}

/*member: _whileUnion2:Union(null, [exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 1)*/
_whileUnion2(/*[exact=Class4|powerset=0]*/ o) {
  while (o != null) {
    o = o. /*Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/ field;
  }
  return o;
}

/*member: whileUnion2:[null|powerset=1]*/
whileUnion2() {
  var c1 = Class3();
  var c2 = Class4();
  c1. /*update: [exact=Class3|powerset=0]*/ field = c2;
  c2. /*update: [exact=Class4|powerset=0]*/ field = c1;
  _whileUnion2(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing both
/// objects to the [_whileUnion3] method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset=0]*/
class Class5 {
  /*member: Class5.field:[null|exact=Class6|powerset=1]*/
  var field;
}

/*member: Class6.:[exact=Class6|powerset=0]*/
class Class6 {
  /*member: Class6.field:[null|exact=Class5|powerset=1]*/
  var field;
}

/*member: _whileUnion3:Union(null, [exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 1)*/
_whileUnion3(
  /*Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/ o,
) {
  while (o != null) {
    o = o. /*Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/ field;
  }
  return o;
}

/*member: whileUnion3:[null|powerset=1]*/
whileUnion3() {
  var c1 = Class5();
  var c2 = Class6();
  c1. /*update: [exact=Class5|powerset=0]*/ field = c2;
  c2. /*update: [exact=Class6|powerset=0]*/ field = c1;
  _whileUnion3(c1);
  _whileUnion3(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset=0]*/
class Class7 {
  /*member: Class7.field:[null|exact=Class8|powerset=1]*/
  var field;
}

/*member: Class8.:[exact=Class8|powerset=0]*/
class Class8 {
  /*member: Class8.field:[null|exact=Class7|powerset=1]*/
  var field;
}

/*member: _whileIs:Union(null, [exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 1)*/
_whileIs(/*[exact=Class7|powerset=0]*/ o) {
  while (o is Class7) {
    o = o. /*[exact=Class7|powerset=0]*/ field;
  }
  return o;
}

/*member: whileIs:[null|powerset=1]*/
whileIs() {
  var c1 = Class7();
  var c2 = Class8();
  c1. /*update: [exact=Class7|powerset=0]*/ field = c2;
  c2. /*update: [exact=Class8|powerset=0]*/ field = c1;
  _whileIs(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is-not test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class9.:[exact=Class9|powerset=0]*/
class Class9 {
  /*member: Class9.field:[null|exact=Class10|powerset=1]*/
  var field;
}

/*member: Class10.:[exact=Class10|powerset=0]*/
class Class10 {
  /*member: Class10.field:[null|exact=Class9|powerset=1]*/
  var field;
}

/*member: _whileIsNot:Union(null, [exact=Class10|powerset=0], [exact=Class9|powerset=0], powerset: 1)*/
_whileIsNot(/*[exact=Class9|powerset=0]*/ o) {
  while (o is! Class10) {
    o = o. /*Union(null, [exact=Class10|powerset=0], [exact=Class9|powerset=0], powerset: 1)*/ field;
  }
  return o;
}

/*member: whileIsNot:[null|powerset=1]*/
whileIsNot() {
  var c1 = Class9();
  var c2 = Class10();
  c1. /*update: [exact=Class9|powerset=0]*/ field = c2;
  c2. /*update: [exact=Class10|powerset=0]*/ field = c1;
  _whileIsNot(c1);
}
