// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  getTopLevelFieldUninitialized();
  getStaticFieldUninitialized();
  getTopLevelFieldInitialized();
  getStaticFieldInitialized();
  getTopLevelFieldInitializedPotentiallyNull();
  getStaticFieldInitializedPotentiallyNull();

  getTopLevelMethod();
  getStaticMethod();

  getTopLevelGetter();
  getStaticGetter();
}

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[null]*/
var _field1;

/*element: getTopLevelFieldUninitialized:[null]*/
getTopLevelFieldUninitialized() => _field1;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*element: Class1.field:[null]*/
  static var field;
}

/*element: getStaticFieldUninitialized:[null]*/
getStaticFieldUninitialized() => Class1.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an initialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*element: _field2:[exact=JSUInt31]*/
var _field2 = 42;

/*element: getTopLevelFieldInitialized:[exact=JSUInt31]*/
getTopLevelFieldInitialized() => _field2;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an initialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.field:[exact=JSUInt31]*/
  static var field = 42;
}

/*element: getStaticFieldInitialized:[exact=JSUInt31]*/
getStaticFieldInitialized() => Class2.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level field with an initializer that is potentially
/// null.
////////////////////////////////////////////////////////////////////////////////

/*element: _method3:[exact=JSUInt31]*/
_method3() => 42;

/*element: _field3:[null|exact=JSUInt31]*/
var _field3 = _method3();

/*element: getTopLevelFieldInitializedPotentiallyNull:[null|exact=JSUInt31]*/
getTopLevelFieldInitializedPotentiallyNull() => _field3;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static field with an initializer that is potentially null.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*element: Class3.method:[exact=JSUInt31]*/
  static method() => 42;

  /*element: Class3.field:[null|exact=JSUInt31]*/
  static var field = method();
}

/*element: getStaticFieldInitializedPotentiallyNull:[null|exact=JSUInt31]*/
getStaticFieldInitializedPotentiallyNull() => Class3.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*element: _method4:[exact=JSUInt31]*/
_method4() => 42;

/*element: getTopLevelMethod:[subclass=Closure]*/
getTopLevelMethod() => _method4;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static method.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*element: Class4.method:[exact=JSUInt31]*/
  static method() => 42;
}

/*element: getStaticMethod:[subclass=Closure]*/
getStaticMethod() => Class4.method;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level getter.
////////////////////////////////////////////////////////////////////////////////

/*element: _getter1:[exact=JSUInt31]*/
get _getter1 => 42;

/*element: getTopLevelGetter:[exact=JSUInt31]*/
getTopLevelGetter() => _getter1;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static getter.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*element: Class5.getter:[exact=JSUInt31]*/
  static get getter => 42;
}

/*element: getStaticGetter:[exact=JSUInt31]*/
getStaticGetter() => Class5.getter;
