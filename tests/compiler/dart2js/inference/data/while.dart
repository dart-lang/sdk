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
  whileUnion();
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
/// While loop with not-null test that mixes field accesses.
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

/*element: _whileUnion:Union of [[exact=Class1], [null|exact=Class2]]*/
_whileUnion(/*[exact=Class1]*/ o) {
  while (o != null) {
    o = o. /*Union of [[exact=Class1], [exact=Class2]]*/ field;
  }
  return o;
}

/*element: whileUnion:[null]*/
whileUnion() {
  var c1 = new Class1();
  var c2 = new Class2();
  c1. /*update: [exact=Class1]*/ field = c2;
  c2. /*update: [exact=Class2]*/ field = c1;
  _whileUnion(c1);
}
