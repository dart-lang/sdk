// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: simpleFor:[null|powerset={null}]*/
simpleFor() {
  for (
    var i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ < 10;
    i = i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ + 1
  ) {
    i. /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ abs();
  }
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*member: forNull:[null|powerset={null}]*/
forNull() {
  var local;
  for (var o; o == null; o = o. /*invoke: [null|powerset={null}]*/ toString()) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*member: forNotNull:[null|exact=JSString|powerset={null}{I}{O}]*/
forNotNull() {
  var local;
  for (
    var o = '';
    o /*invoke: [exact=JSString|powerset={I}{O}]*/ != null;
    o = o. /*invoke: [exact=JSString|powerset={I}{O}]*/ toString()
  ) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with null test known to be false.
////////////////////////////////////////////////////////////////////////////////

/*member: forNullFalse:[null|powerset={null}]*/
forNullFalse() {
  var local;
  for (
    var o = '';
    o /*invoke: [exact=JSString|powerset={I}{O}]*/ == null;
    o = o. /*invoke: [empty|powerset=empty]*/ toString()
  ) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test known to be true.
////////////////////////////////////////////////////////////////////////////////

/*member: forNotNullTrue:[null|powerset={null}]*/
forNotNullTrue() {
  var local;
  for (
    var o = null;
    o != null;
    o = o. /*invoke: [empty|powerset=empty]*/ toString()
  ) {
    local = o;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with not-null test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 {
  /*member: Class1.field:[null|exact=Class2|powerset={null}{N}{O}]*/
  var field;
}

/*member: Class2.:[exact=Class2|powerset={N}{O}]*/
class Class2 {
  /*member: Class2.field:[null|exact=Class1|powerset={null}{N}{O}]*/
  var field;
}

/*member: _forUnion:Union(null, [exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {null}{N}{O})*/
_forUnion(/*[exact=Class1|powerset={N}{O}]*/ o) {
  for (
    ;
    o = o. /*Union(null, [exact=Class1|powerset={N}{O}], [exact=Class2|powerset={N}{O}], powerset: {null}{N}{O})*/ field;
    o != null
  ) {}
  return o;
}

/*member: forUnion:[null|powerset={null}]*/
forUnion() {
  var c1 = Class1();
  var c2 = Class2();
  c1. /*update: [exact=Class1|powerset={N}{O}]*/ field = c2;
  c2. /*update: [exact=Class2|powerset={N}{O}]*/ field = c1;
  _forUnion(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with is test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}]*/
class Class3 {
  /*member: Class3.field:[null|exact=Class4|powerset={null}{N}{O}]*/
  var field;
}

/*member: Class4.:[exact=Class4|powerset={N}{O}]*/
class Class4 {
  /*member: Class4.field:[null|exact=Class3|powerset={null}{N}{O}]*/
  var field;
}

/*member: _forIs:Union(null, [exact=Class3|powerset={N}{O}], [exact=Class4|powerset={N}{O}], powerset: {null}{N}{O})*/
_forIs(/*[exact=Class3|powerset={N}{O}]*/ o) {
  for (; o is Class3; o = o. /*[exact=Class3|powerset={N}{O}]*/ field) {}
  return o;
}

/*member: forIs:[null|powerset={null}]*/
forIs() {
  var c1 = Class3();
  var c2 = Class4();
  c1. /*update: [exact=Class3|powerset={N}{O}]*/ field = c2;
  c2. /*update: [exact=Class4|powerset={N}{O}]*/ field = c1;
  _forIs(c1);
}

////////////////////////////////////////////////////////////////////////////////
/// For loop with is-not test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset={N}{O}]*/
class Class5 {
  /*member: Class5.field:[null|exact=Class6|powerset={null}{N}{O}]*/
  var field;
}

/*member: Class6.:[exact=Class6|powerset={N}{O}]*/
class Class6 {
  /*member: Class6.field:[null|exact=Class5|powerset={null}{N}{O}]*/
  var field;
}

/*member: _forIsNot:Union(null, [exact=Class5|powerset={N}{O}], [exact=Class6|powerset={N}{O}], powerset: {null}{N}{O})*/
_forIsNot(/*[exact=Class5|powerset={N}{O}]*/ o) {
  for (
    ;
    o is! Class6;
    o = o. /*Union(null, [exact=Class5|powerset={N}{O}], [exact=Class6|powerset={N}{O}], powerset: {null}{N}{O})*/ field
  ) {}
  return o;
}

/*member: forIsNot:[null|powerset={null}]*/
forIsNot() {
  var c1 = Class5();
  var c2 = Class6();
  c1. /*update: [exact=Class5|powerset={N}{O}]*/ field = c2;
  c2. /*update: [exact=Class6|powerset={N}{O}]*/ field = c1;
  _forIsNot(c1);
}
