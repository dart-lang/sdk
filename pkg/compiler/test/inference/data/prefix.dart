// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: localPrefixInc:[subclass=JSUInt32]*/
localPrefixInc() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [null|exact=JSUInt31]*/ ++local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: localPrefixDec:[subclass=JSInt]*/
localPrefixDec() {
  var local;
  if (local == null) {
    local = 0;
  }
  return /*invoke: [null|exact=JSUInt31]*/ --local;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField1:[null|subclass=JSPositiveInt]*/
var _staticField1;

/*member: staticFieldPrefixInc:[subclass=JSPositiveInt]*/
staticFieldPrefixInc() {
  if (_staticField1 == null) {
    _staticField1 = 0;
  }
  return /*invoke: [null|subclass=JSPositiveInt]*/ ++_staticField1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on static field.
////////////////////////////////////////////////////////////////////////////////

/*member: _staticField2:[null|subclass=JSInt]*/
var _staticField2;

/*member: staticFieldPrefixDec:[subclass=JSInt]*/
staticFieldPrefixDec() {
  if (_staticField2 == null) {
    _staticField2 = 0;
  }
  return /*invoke: [null|subclass=JSInt]*/ --_staticField2;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.field1:[null|subclass=JSPositiveInt]*/
  var field1;
}

/*member: instanceFieldPrefixInc:[subclass=JSPositiveInt]*/
instanceFieldPrefixInc() {
  var c = new Class1();
  if (c. /*[exact=Class1]*/ field1 == null) {
    c. /*update: [exact=Class1]*/ field1 = 0;
  }
  return
      /*invoke: [null|subclass=JSPositiveInt]*/ ++c.
          /*[exact=Class1]*/
          /*update: [exact=Class1]*/
          field1;
}

////////////////////////////////////////////////////////////////////////////////
// Prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.field2:[null|subclass=JSInt]*/
  var field2;
}

/*member: instanceFieldPrefixDec:[subclass=JSInt]*/
instanceFieldPrefixDec() {
  var c = new Class2();
  if (c. /*[exact=Class2]*/ field2 == null) {
    c. /*update: [exact=Class2]*/ field2 = 0;
  }
  return
      /*invoke: [null|subclass=JSInt]*/ --c.
          /*[exact=Class2]*/
          /*update: [exact=Class2]*/
          field2;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix increment on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3]*/
class Class3 {
  /*member: Class3.field3:[null|subclass=JSPositiveInt]*/
  var field3;
}

/*member: conditionalInstanceFieldPrefixInc:[null|subclass=JSPositiveInt]*/
conditionalInstanceFieldPrefixInc() {
  var c = new Class3();
  if (c. /*[exact=Class3]*/ field3 == null) {
    c. /*update: [exact=Class3]*/ field3 = 0;
  }
  return
      /*invoke: [null|subclass=JSPositiveInt]*/ ++c?.
          /*[exact=Class3]*/
          /*update: [exact=Class3]*/
          field3;
}

////////////////////////////////////////////////////////////////////////////////
// Conditional prefix decrement on instance field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4]*/
class Class4 {
  /*member: Class4.field4:[null|subclass=JSInt]*/
  var field4;
}

/*member: conditionalInstanceFieldPrefixDec:[null|subclass=JSInt]*/
conditionalInstanceFieldPrefixDec() {
  var c = new Class4();
  if (c. /*[exact=Class4]*/ field4 == null) {
    c. /*update: [exact=Class4]*/ field4 = 0;
  }
  return
      /*invoke: [null|subclass=JSInt]*/ --c?.
          /*[exact=Class4]*/
          /*update: [exact=Class4]*/
          field4;
}
