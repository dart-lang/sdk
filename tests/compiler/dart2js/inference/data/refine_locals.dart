// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  refineToClass();
}

////////////////////////////////////////////////////////////////////////////////
// Refine the type of a non-captured local variable through a sequence of
// accesses and updates.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.method0:[null]*/
  method0() {}
  /*element: Class1.method1:[null]*/
  method1() {}
  /*element: Class1.field0:[null|exact=JSUInt31]*/
  var field0;
  /*element: Class1.field1:[null|exact=JSUInt31]*/
  var field1;
}

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.method0:[null]*/
  method0() {}
  /*element: Class2.method2:[null]*/
  method2() {}
  /*element: Class2.field0:[null|exact=JSUInt31]*/
  var field0;
  /*element: Class2.field2:[null|exact=JSUInt31]*/
  var field2;
}

/*element: _refineToClass1Invoke:[empty]*/
_refineToClass1Invoke(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*invoke: Union of [[exact=Class1], [exact=Class2]]*/ method1();
  o. /*invoke: [exact=Class1]*/ method0();
  o. /*invoke: [exact=Class1]*/ method2();
  return o;
}

/*element: _refineToClass2Invoke:[empty]*/
_refineToClass2Invoke(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*invoke: Union of [[exact=Class1], [exact=Class2]]*/ method2();
  o. /*invoke: [exact=Class2]*/ method0();
  o. /*invoke: [exact=Class2]*/ method1();
  return o;
}

/*element: _refineToEmptyInvoke:[empty]*/
_refineToEmptyInvoke(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*invoke: Union of [[exact=Class1], [exact=Class2]]*/ method1();
  o. /*invoke: [exact=Class1]*/ method2();
  o. /*invoke: [empty]*/ method0();
  return o;
}

/*element: _refineToClass1Get:[empty]*/
_refineToClass1Get(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*Union of [[exact=Class1], [exact=Class2]]*/ field0;
  o. /*Union of [[exact=Class1], [exact=Class2]]*/ field1;
  o. /*[exact=Class1]*/ field2;
  return o;
}

/*element: _refineToClass2Get:[empty]*/
_refineToClass2Get(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*Union of [[exact=Class1], [exact=Class2]]*/ field0;
  o. /*Union of [[exact=Class1], [exact=Class2]]*/ field2;
  o. /*[exact=Class2]*/ field1;
  return o;
}

/*element: _refineToEmptyGet:[empty]*/
_refineToEmptyGet(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*Union of [[exact=Class1], [exact=Class2]]*/ field1;
  o. /*[exact=Class1]*/ field2;
  o. /*[empty]*/ field0;
  return o;
}

/*element: _refineToClass1Set:[empty]*/
_refineToClass1Set(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*update: Union of [[exact=Class1], [exact=Class2]]*/ field0 = 0;
  o. /*update: Union of [[exact=Class1], [exact=Class2]]*/ field1 = 0;
  o. /*update: [exact=Class1]*/ field2 = 0;
  return o;
}

/*element: _refineToClass2Set:[empty]*/
_refineToClass2Set(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*update: Union of [[exact=Class1], [exact=Class2]]*/ field0 = 0;
  o. /*update: Union of [[exact=Class1], [exact=Class2]]*/ field2 = 0;
  o. /*update: [exact=Class2]*/ field1 = 0;
  return o;
}

/*element: _refineToEmptySet:[empty]*/
_refineToEmptySet(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*update: Union of [[exact=Class1], [exact=Class2]]*/ field1 = 0;
  o. /*update: [exact=Class1]*/ field2 = 0;
  o. /*update: [empty]*/ field0 = 0;
  return o;
}

/*element: _refineToClass1InvokeIfNotNull:[null]*/
_refineToClass1InvokeIfNotNull(
    /*Union of [[exact=Class2], [null|exact=Class1]]*/ o) {
  o?. /*ast.invoke: Union of [[exact=Class2], [null|exact=Class1]]*/ /*kernel.invoke: Union of [[exact=Class1], [exact=Class2]]*/ method1();
  o?. /*ast.invoke: [null|exact=Class1]*/ /*kernel.invoke: [exact=Class1]*/ method0();
  o?. /*ast.invoke: [null|exact=Class1]*/ /*kernel.invoke: [exact=Class1]*/ method2();
  return o;
}

// TODO(redemption): Test conditional access.

/*element: refineToClass:[null]*/
refineToClass() {
  _refineToClass1Invoke(new Class1());
  _refineToClass1Invoke(new Class2());
  _refineToClass2Invoke(new Class1());
  _refineToClass2Invoke(new Class2());
  _refineToEmptyInvoke(new Class1());
  _refineToEmptyInvoke(new Class2());

  _refineToClass1Get(new Class1());
  _refineToClass1Get(new Class2());
  _refineToClass2Get(new Class1());
  _refineToClass2Get(new Class2());
  _refineToEmptyGet(new Class1());
  _refineToEmptyGet(new Class2());

  _refineToClass1Set(new Class1());
  _refineToClass1Set(new Class2());
  _refineToClass2Set(new Class1());
  _refineToClass2Set(new Class2());
  _refineToEmptySet(new Class1());
  _refineToEmptySet(new Class2());

  _refineToClass1InvokeIfNotNull(null);
  _refineToClass1InvokeIfNotNull(new Class1());
  _refineToClass1InvokeIfNotNull(new Class2());
}
