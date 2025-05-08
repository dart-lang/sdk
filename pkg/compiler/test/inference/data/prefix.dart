// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: localPrefixInc:[subclass=JSUInt32|powerset={I}{O}{N}]*/
localPrefixInc() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPrefixDec:[subclass=JSInt|powerset={I}{O}{N}]*/
localPrefixDec() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ --local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField1:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
var _staticField1;

/*member: staticFieldPrefixInc:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
staticFieldPrefixInc() {
  if (_staticField1 == null) {
    _staticField1 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++_staticField1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField2:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
var _staticField2;

/*member: staticFieldPrefixDec:[subclass=JSInt|powerset={I}{O}{N}]*/
staticFieldPrefixDec() {
  if (_staticField2 == null) {
    _staticField2 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --_staticField2;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.field1:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
  var field1;
}

/*member: instanceFieldPrefixInc:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
instanceFieldPrefixInc() {
  var c = Class1();
  if (c. /*[exact=Class1|powerset={N}{O}{N}]*/ field1 == null) {
    c. /*update: [exact=Class1|powerset={N}{O}{N}]*/ field1 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++c
      .
      /*[exact=Class1|powerset={N}{O}{N}]*/
      /*update: [exact=Class1|powerset={N}{O}{N}]*/
      field1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.field2:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
  var field2;
}

/*member: instanceFieldPrefixDec:[subclass=JSInt|powerset={I}{O}{N}]*/
instanceFieldPrefixDec() {
  var c = Class2();
  if (c. /*[exact=Class2|powerset={N}{O}{N}]*/ field2 == null) {
    c. /*update: [exact=Class2|powerset={N}{O}{N}]*/ field2 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --c
      .
      /*[exact=Class2|powerset={N}{O}{N}]*/
      /*update: [exact=Class2|powerset={N}{O}{N}]*/
      field2;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  /*member: Class3.field3:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
  var field3;
}

/*member: conditionalInstanceFieldPrefixInc:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
conditionalInstanceFieldPrefixInc() {
  var c = Class3();
  if (c. /*[exact=Class3|powerset={N}{O}{N}]*/ field3 == null) {
    c. /*update: [exact=Class3|powerset={N}{O}{N}]*/ field3 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++c
      ?.
      /*[exact=Class3|powerset={N}{O}{N}]*/
      /*update: [exact=Class3|powerset={N}{O}{N}]*/
      field3;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {
  /*member: Class4.field4:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
  var field4;
}

/*member: conditionalInstanceFieldPrefixDec:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
conditionalInstanceFieldPrefixDec() {
  var c = Class4();
  if (c. /*[exact=Class4|powerset={N}{O}{N}]*/ field4 == null) {
    c. /*update: [exact=Class4|powerset={N}{O}{N}]*/ field4 = 0;
  }
  return /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --c
      ?.
      /*[exact=Class4|powerset={N}{O}{N}]*/
      /*update: [exact=Class4|powerset={N}{O}{N}]*/
      field4;
}
