// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  localPostfixInc();
  localPostfixDec();
  staticFieldPostfixInc();
  staticFieldPostfixDec();
  instanceFieldPostfixInc();
  instanceFieldPostfixDec();
  conditionalInstanceFieldPostfixInc();
  conditionalInstanceFieldPostfixDec();
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPostfixInc:[exact=JSUInt31|powerset={I}{O}{N}]*/
localPostfixInc() {
  var local;
  if (local == null) {
    local = 0;
  }
  return local /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPostfixDec:[exact=JSUInt31|powerset={I}{O}{N}]*/
localPostfixDec() {
  var local;
  if (local == null) {
    local = 0;
  }
  return local /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField1:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
var _staticField1;

/*member: staticFieldPostfixInc:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
staticFieldPostfixInc() {
  if (_staticField1 == null) {
    _staticField1 = 0;
  }
  return _staticField1 /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField2:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
var _staticField2;

/*member: staticFieldPostfixDec:[subclass=JSInt|powerset={I}{O}{N}]*/
staticFieldPostfixDec() {
  if (_staticField2 == null) {
    _staticField2 = 0;
  }
  return _staticField2 /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.field1:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
  var field1;
}

/*member: instanceFieldPostfixInc:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
instanceFieldPostfixInc() {
  var c = Class1();
  if (c. /*[exact=Class1|powerset={N}{O}{N}]*/ field1 == null) {
    c. /*update: [exact=Class1|powerset={N}{O}{N}]*/ field1 = 0;
  }
  return c
      .
      /*[exact=Class1|powerset={N}{O}{N}]*/
      /*update: [exact=Class1|powerset={N}{O}{N}]*/
      field1 /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.field2:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
  var field2;
}

/*member: instanceFieldPostfixDec:[subclass=JSInt|powerset={I}{O}{N}]*/
instanceFieldPostfixDec() {
  var c = Class2();
  if (c. /*[exact=Class2|powerset={N}{O}{N}]*/ field2 == null) {
    c. /*update: [exact=Class2|powerset={N}{O}{N}]*/ field2 = 0;
  }
  return c
      .
      /*[exact=Class2|powerset={N}{O}{N}]*/
      /*update: [exact=Class2|powerset={N}{O}{N}]*/
      field2 /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional postfix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  /*member: Class3.field3:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
  var field3;
}

/*member: conditionalInstanceFieldPostfixInc:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
conditionalInstanceFieldPostfixInc() {
  var c = Class3();
  if (c. /*[exact=Class3|powerset={N}{O}{N}]*/ field3 == null) {
    c. /*update: [exact=Class3|powerset={N}{O}{N}]*/ field3 = 0;
  }
  return c
      ?.
      /*[exact=Class3|powerset={N}{O}{N}]*/
      /*update: [exact=Class3|powerset={N}{O}{N}]*/
      field3 /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional postfix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {
  /*member: Class4.field4:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
  var field4;
}

/*member: conditionalInstanceFieldPostfixDec:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
conditionalInstanceFieldPostfixDec() {
  var c = Class4();
  if (c. /*[exact=Class4|powerset={N}{O}{N}]*/ field4 == null) {
    c. /*update: [exact=Class4|powerset={N}{O}{N}]*/ field4 = 0;
  }
  return c
      ?.
      /*[exact=Class4|powerset={N}{O}{N}]*/
      /*update: [exact=Class4|powerset={N}{O}{N}]*/
      field4 /*invoke: [null|subclass=JSInt|powerset={null}{I}{O}{N}]*/ --;
}
