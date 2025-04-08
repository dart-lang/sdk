// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  localPrefixInc();
  localPrefixDec();
  staticFieldPrefixInc();
  staticFieldPrefixDec();
  instanceFieldPrefixInc();
  instanceFieldPrefixDec();
  conditionalInstanceFieldPrefixInc();
  conditionalInstanceFieldPrefixDec();
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPrefixInc:[subclass=JSUInt32|powerset=0]*/
localPrefixInc() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [exact=JSUInt31|powerset=0]*/ ++local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPrefixDec:[subclass=JSInt|powerset=0]*/
localPrefixDec() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [exact=JSUInt31|powerset=0]*/ --local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField1:[null|subclass=JSPositiveInt|powerset=1]*/
var _staticField1;

/*member: staticFieldPrefixInc:[subclass=JSPositiveInt|powerset=0]*/
staticFieldPrefixInc() {
  if (_staticField1 == null) {
    _staticField1 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset=1]*/ ++_staticField1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField2:[null|subclass=JSInt|powerset=1]*/
var _staticField2;

/*member: staticFieldPrefixDec:[subclass=JSInt|powerset=0]*/
staticFieldPrefixDec() {
  if (_staticField2 == null) {
    _staticField2 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset=1]*/ --_staticField2;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.field1:[null|subclass=JSPositiveInt|powerset=1]*/
  var field1;
}

/*member: instanceFieldPrefixInc:[subclass=JSPositiveInt|powerset=0]*/
instanceFieldPrefixInc() {
  var c = Class1();
  if (c. /*[exact=Class1|powerset=0]*/ field1 == null) {
    c. /*update: [exact=Class1|powerset=0]*/ field1 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset=1]*/ ++c
      .
      /*[exact=Class1|powerset=0]*/
      /*update: [exact=Class1|powerset=0]*/
      field1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.field2:[null|subclass=JSInt|powerset=1]*/
  var field2;
}

/*member: instanceFieldPrefixDec:[subclass=JSInt|powerset=0]*/
instanceFieldPrefixDec() {
  var c = Class2();
  if (c. /*[exact=Class2|powerset=0]*/ field2 == null) {
    c. /*update: [exact=Class2|powerset=0]*/ field2 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset=1]*/ --c
      .
      /*[exact=Class2|powerset=0]*/
      /*update: [exact=Class2|powerset=0]*/
      field2;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  /*member: Class3.field3:[null|subclass=JSPositiveInt|powerset=1]*/
  var field3;
}

/*member: conditionalInstanceFieldPrefixInc:[null|subclass=JSPositiveInt|powerset=1]*/
conditionalInstanceFieldPrefixInc() {
  var c = Class3();
  if (c. /*[exact=Class3|powerset=0]*/ field3 == null) {
    c. /*update: [exact=Class3|powerset=0]*/ field3 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset=1]*/ ++c
      ?.
      /*[exact=Class3|powerset=0]*/
      /*update: [exact=Class3|powerset=0]*/
      field3;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {
  /*member: Class4.field4:[null|subclass=JSInt|powerset=1]*/
  var field4;
}

/*member: conditionalInstanceFieldPrefixDec:[null|subclass=JSInt|powerset=1]*/
conditionalInstanceFieldPrefixDec() {
  var c = Class4();
  if (c. /*[exact=Class4|powerset=0]*/ field4 == null) {
    c. /*update: [exact=Class4|powerset=0]*/ field4 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset=1]*/ --c
      ?.
      /*[exact=Class4|powerset=0]*/
      /*update: [exact=Class4|powerset=0]*/
      field4;
}
