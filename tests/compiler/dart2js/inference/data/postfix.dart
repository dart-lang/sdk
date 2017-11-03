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
}

////////////////////////////////////////////////////////////////////////////////
// Postfix increment on local variable.
////////////////////////////////////////////////////////////////////////////////

// TODO(johnniwinther): Update ast inference to detect non-nullness of postfix
// results.
/*ast.element: localPostfixInc:[null|exact=JSUInt31]*/
/*kernel.element: localPostfixInc:[exact=JSUInt31]*/
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

/*ast.element: localPostfixDec:[null|exact=JSUInt31]*/
/*kernel.element: localPostfixDec:[exact=JSUInt31]*/
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

/*ast.element: staticFieldPostfixInc:[null|subclass=JSPositiveInt]*/
/*kernel.element: staticFieldPostfixInc:[subclass=JSPositiveInt]*/
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

/*ast.element: staticFieldPostfixDec:[null|subclass=JSInt]*/
/*kernel.element: staticFieldPostfixDec:[subclass=JSInt]*/
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

/*ast.element: instanceFieldPostfixInc:[null|subclass=JSPositiveInt]*/
/*kernel.element: instanceFieldPostfixInc:[subclass=JSPositiveInt]*/
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

/*ast.element: instanceFieldPostfixDec:[null|subclass=JSInt]*/
/*kernel.element: instanceFieldPostfixDec:[subclass=JSInt]*/
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
