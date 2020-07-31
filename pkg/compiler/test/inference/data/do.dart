// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  simpleDo();
  doNull();
  doNotNull();
  doNullFalse();
  doNotNullTrue();
  doUnion();
}

////////////////////////////////////////////////////////////////////////////////
/// Simple int based do-while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: simpleDo:[null]*/
simpleDo() {
  var i = 0;
  do {
    i = i /*invoke: [subclass=JSPositiveInt]*/ + 1;
  } while (i /*invoke: [subclass=JSPositiveInt]*/ < 10);
  i. /*invoke: [subclass=JSPositiveInt]*/ abs();
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with null test.
////////////////////////////////////////////////////////////////////////////////

/*member: doNull:[exact=JSString]*/
doNull() {
  var o;
  do {
    o = o. /*invoke: [null|exact=JSString]*/ toString();
  } while (o == null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test.
////////////////////////////////////////////////////////////////////////////////

/*member: doNotNull:[exact=JSString]*/
doNotNull() {
  var o = '';
  do {
    o = o. /*invoke: [exact=JSString]*/ toString();
  } while (o /*invoke: [null|exact=JSString]*/ != null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with null test known to be false.
////////////////////////////////////////////////////////////////////////////////

/*member: doNullFalse:[exact=JSString]*/
doNullFalse() {
  var o = '';
  do {
    o = o. /*invoke: [exact=JSString]*/ toString();
  } while (o /*invoke: [null|exact=JSString]*/ == null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test known to be true.
////////////////////////////////////////////////////////////////////////////////

/*member: doNotNullTrue:[exact=JSString]*/
doNotNullTrue() {
  var o = null;
  do {
    o = o. /*invoke: [null|exact=JSString]*/ toString();
  } while (o != null);
  return o;
}

////////////////////////////////////////////////////////////////////////////////
/// Do-while loop with not-null test that mixes field accesses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.field:[null|exact=Class2]*/
  var field;
}

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.field:[null|exact=Class1]*/
  var field;
}

/*member: _doUnion:Union(null, [exact=Class1], [exact=Class2])*/
_doUnion(/*[exact=Class1]*/ o) {
  do {
    o = o. /*Union(null, [exact=Class1], [exact=Class2])*/ field;
  } while (o != null);
  return o;
}

/*member: doUnion:[null]*/
doUnion() {
  var c1 = new Class1();
  var c2 = new Class2();
  c1. /*update: [exact=Class1]*/ field = c2;
  c2. /*update: [exact=Class2]*/ field = c1;
  _doUnion(c1);
}
