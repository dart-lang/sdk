// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  simpleFor();
  forNull();
  forNotNull();
  forNullFalse();
  forNotNullTrue();
  forUnion();
  forIs();
  forIsNot();
}

////////////////////////////////////////////////////////////////////////////////
/// Simple int based for loop.
////////////////////////////////////////////////////////////////////////////////

/*element: simpleFor:[null]*/
simpleFor() {
  for (var i = 0;
      i /*invoke: [subclass=JSPositiveInt]*/ < 10;
      i = i /*invoke: [subclass=JSPositiveInt]*/ + 1) {
    i. /*invoke: [subclass=JSPositiveInt]*/ abs();
  }
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*element: forNull:[null]*/
forNull() {
  var local;
  for (var o; o == null; o = o. /*invoke: [null]*/ toString()) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*element: forNotNull:[null|exact=JSString]*/
forNotNull() {
  var local;
  for (var o = ''; o != null; o = o. /*invoke: [exact=JSString]*/ toString()) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with null test known to be false.
////////////////////////////////////////////////////////////////////////////////

/*element: forNullFalse:[null]*/
forNullFalse() {
  var local;
  for (var o = ''; o == null; o = o. /*invoke: [null]*/ toString()) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test known to be true.
////////////////////////////////////////////////////////////////////////////////

/*element: forNotNullTrue:[null]*/
forNotNullTrue() {
  var local;
  for (var o = null; o != null; o = o. /*invoke: [empty]*/ toString()) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test that mixes field accesses.
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

/*element: _forUnion:Union of [[exact=Class1], [null|exact=Class2]]*/
_forUnion(/*[exact=Class1]*/ o) {
  for (;
      o = o. /*Union of [[exact=Class1], [null|exact=Class2]]*/ field;
      o != null) {}
  return o;
}

/*element: forUnion:[null]*/
forUnion() {
  var c1 = new Class1();
  var c2 = new Class2();
  c1. /*update: [exact=Class1]*/ field = c2;
  c2. /*update: [exact=Class2]*/ field = c1;
  _forUnion(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with is test that mixes field accesses.
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

/*element: _forIs:Union of [[exact=Class3], [null|exact=Class4]]*/
_forIs(/*[exact=Class3]*/ o) {
  for (; o is Class3; o = o. /*[exact=Class3]*/ field) {}
  return o;
}

/*element: forIs:[null]*/
forIs() {
  var c1 = new Class3();
  var c2 = new Class4();
  c1. /*update: [exact=Class3]*/ field = c2;
  c2. /*update: [exact=Class4]*/ field = c1;
  _forIs(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with is-not test that mixes field accesses.
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

/*element: _forIsNot:Union of [[exact=Class5], [null|exact=Class6]]*/
_forIsNot(/*[exact=Class5]*/ o) {
  for (;
      o is! Class6;
      o = o. /*Union of [[exact=Class5], [null|exact=Class6]]*/ field) {}
  return o;
}

/*element: forIsNot:[null]*/
forIsNot() {
  var c1 = new Class5();
  var c2 = new Class6();
  c1. /*update: [exact=Class5]*/ field = c2;
  c2. /*update: [exact=Class6]*/ field = c1;
  _forIsNot(c1);
}
