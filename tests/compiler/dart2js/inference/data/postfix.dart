// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: localPostfixInc:[exact=JSUInt31]*/
localPostfixInc() {
  var local;
  if (local == null) {
    local = 0;
  }
  return local /*invoke: [null|exact=JSUInt31]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on local variable.
////////////////////////////////////////////////////////////////////////////////

/*element: localPostfixDec:[exact=JSUInt31]*/
localPostfixDec() {
  var local;
  if (local == null) {
    local = 0;
  }
  return local /*invoke: [null|exact=JSUInt31]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on static field.
////////////////////////////////////////////////////////////////////////////////

/*element: _staticField1:[null|subclass=JSPositiveInt]*/
var _staticField1;

/*element: staticFieldPostfixInc:[subclass=JSPositiveInt]*/
staticFieldPostfixInc() {
  if (_staticField1 == null) {
    _staticField1 = 0;
  }
  return _staticField1 /*invoke: [null|subclass=JSPositiveInt]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on static field.
////////////////////////////////////////////////////////////////////////////////

/*element: _staticField2:[null|subclass=JSInt]*/
var _staticField2;

/*element: staticFieldPostfixDec:[subclass=JSInt]*/
staticFieldPostfixDec() {
  if (_staticField2 == null) {
    _staticField2 = 0;
  }
  return _staticField2 /*invoke: [null|subclass=JSInt]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.field1:[null|subclass=JSPositiveInt]*/
  var field1;
}

/*element: instanceFieldPostfixInc:[subclass=JSPositiveInt]*/
instanceFieldPostfixInc() {
  var c = new Class1();
  if (c. /*[exact=Class1]*/ field1 == null) {
    c. /*update: [exact=Class1]*/ field1 = 0;
  }
  return c.
      /*[exact=Class1]*/
      /*update: [exact=Class1]*/
      field1 /*invoke: [null|subclass=JSPositiveInt]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Postfix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.field2:[null|subclass=JSInt]*/
  var field2;
}

/*element: instanceFieldPostfixDec:[subclass=JSInt]*/
instanceFieldPostfixDec() {
  var c = new Class2();
  if (c. /*[exact=Class2]*/ field2 == null) {
    c. /*update: [exact=Class2]*/ field2 = 0;
  }
  return c.
      /*[exact=Class2]*/
      /*update: [exact=Class2]*/
      field2 /*invoke: [null|subclass=JSInt]*/ --;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional postfix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  /*element: Class3.field3:[null|subclass=JSPositiveInt]*/
  var field3;
}

/*element: conditionalInstanceFieldPostfixInc:[null|subclass=JSPositiveInt]*/
conditionalInstanceFieldPostfixInc() {
  var c = new Class3();
  if (c. /*[exact=Class3]*/ field3 == null) {
    c. /*update: [exact=Class3]*/ field3 = 0;
  }
  return c?.
      /*[exact=Class3]*/
      /*update: [exact=Class3]*/
      field3 /*invoke: [null|subclass=JSPositiveInt]*/ ++;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional postfix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:[exact=Class4]*/
class Class4 {
  /*element: Class4.field4:[null|subclass=JSInt]*/
  var field4;
}

/*element: conditionalInstanceFieldPostfixDec:[null|subclass=JSInt]*/
conditionalInstanceFieldPostfixDec() {
  var c = new Class4();
  if (c. /*[exact=Class4]*/ field4 == null) {
    c. /*update: [exact=Class4]*/ field4 = 0;
  }
  return c?.
      /*[exact=Class4]*/
      /*update: [exact=Class4]*/
      field4 /*invoke: [null|subclass=JSInt]*/ --;
}
