// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: simpleWhile:[null]*/
simpleWhile() {
  var i = 0;
  while (i /*invoke: [subclass=JSPositiveInt]*/ < 10) {
    i = i /*invoke: [subclass=JSPositiveInt]*/ + 1;
  }
  i. /*invoke: [subclass=JSPositiveInt]*/ abs();
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*element: whileNull:Value mask: ["null"] type: [null|exact=JSString]*/
whileNull() {
  var o;
  while (o == null) {
    o = o. /*invoke: [null]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*element: whileNotNull:[exact=JSString]*/
whileNotNull() {
  var o = '';
  while (o != null) {
    o = o. /*invoke: [exact=JSString]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*element: whileNullUnreachable:[exact=JSString]*/
whileNullUnreachable() {
  var o = '';
  while (o == null) {
    o = o. /*invoke: [null]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test with an unreachable body.
////////////////////////////////////////////////////////////////////////////////

/*element: whileNotNullUnreachable:[null]*/
whileNotNullUnreachable() {
  var o = null;
  while (o != null) {
    o = o. /*invoke: [empty]*/ toString();
  }
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the first
/// object to the [_whileUnion1] method.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.field:[null|exact=Class2]*/
  var field;
}

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.field:[null|exact=Class1]*/
  var field;
}

/*element: _whileUnion1:Union of [[exact=Class1], [null|exact=Class2]]*/
_whileUnion1(/*[exact=Class1]*/ o) {
  while (o != null) {
    o = o. /*Union of [[exact=Class1], [exact=Class2]]*/ field;
  }
  return o;
}

/*element: whileUnion1:[null]*/
whileUnion1() {
  var c1 = new Class1();
  var c2 = new Class2();
  c1. /*update: [exact=Class1]*/ field = c2;
  c2. /*update: [exact=Class2]*/ field = c1;
  _whileUnion1(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing the second
/// object to the [_whileUnion2] method.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  /*element: Class3.field:[null|exact=Class4]*/
  var field;
}

/*element: Class4.:[exact=Class4]*/
class Class4 {
  /*element: Class4.field:[null|exact=Class3]*/
  var field;
}

/*element: _whileUnion2:Union of [[exact=Class4], [null|exact=Class3]]*/
_whileUnion2(/*[exact=Class4]*/ o) {
  while (o != null) {
    o = o. /*Union of [[exact=Class3], [exact=Class4]]*/ field;
  }
  return o;
}

/*element: whileUnion2:[null]*/
whileUnion2() {
  var c1 = new Class3();
  var c2 = new Class4();
  c1. /*update: [exact=Class3]*/ field = c2;
  c2. /*update: [exact=Class4]*/ field = c1;
  _whileUnion2(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with not-null test that mixes field accesses, passing both
/// objects to the [_whileUnion3] method.
////////////////////////////////////////////////////////////////////////////////

/*element: Class5.:[exact=Class5]*/
class Class5 {
  /*element: Class5.field:[null|exact=Class6]*/
  var field;
}

/*element: Class6.:[exact=Class6]*/
class Class6 {
  /*element: Class6.field:[null|exact=Class5]*/
  var field;
}

/*element: _whileUnion3:Union of [[null|exact=Class5], [null|exact=Class6]]*/
_whileUnion3(/*Union of [[exact=Class5], [exact=Class6]]*/ o) {
  while (o != null) {
    o = o. /*Union of [[exact=Class5], [exact=Class6]]*/ field;
  }
  return o;
}

/*element: whileUnion3:[null]*/
whileUnion3() {
  var c1 = new Class5();
  var c2 = new Class6();
  c1. /*update: [exact=Class5]*/ field = c2;
  c2. /*update: [exact=Class6]*/ field = c1;
  _whileUnion3(c1);
  _whileUnion3(c2);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*element: Class7.:[exact=Class7]*/
class Class7 {
  /*element: Class7.field:[null|exact=Class8]*/
  var field;
}

/*element: Class8.:[exact=Class8]*/
class Class8 {
  /*element: Class8.field:[null|exact=Class7]*/
  var field;
}

/*element: _whileIs:Union of [[exact=Class7], [null|exact=Class8]]*/
_whileIs(/*[exact=Class7]*/ o) {
  while (o is Class7) {
    o = o. /*[exact=Class7]*/ field;
  }
  return o;
}

/*element: whileIs:[null]*/
whileIs() {
  var c1 = new Class7();
  var c2 = new Class8();
  c1. /*update: [exact=Class7]*/ field = c2;
  c2. /*update: [exact=Class8]*/ field = c1;
  _whileIs(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// While loop with is-not test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*element: Class9.:[exact=Class9]*/
class Class9 {
  /*element: Class9.field:[null|exact=Class10]*/
  var field;
}

/*element: Class10.:[exact=Class10]*/
class Class10 {
  /*element: Class10.field:[null|exact=Class9]*/
  var field;
}

/*element: _whileIsNot:Union of [[exact=Class9], [null|exact=Class10]]*/
_whileIsNot(/*[exact=Class9]*/ o) {
  while (o is! Class10) {
    o = o. /*Union of [[exact=Class9], [null|exact=Class10]]*/ field;
  }
  return o;
}

/*element: whileIsNot:[null]*/
whileIsNot() {
  var c1 = new Class9();
  var c2 = new Class10();
  c1. /*update: [exact=Class9]*/ field = c2;
  c2. /*update: [exact=Class10]*/ field = c1;
  _whileIsNot(c1);
}
