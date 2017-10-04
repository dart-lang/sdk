// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  setTopLevelFieldUninitialized();
  setStaticFieldUninitialized();
  setTopLevelFieldInitialized();
  setStaticFieldInitialized();

  setTopLevelSetter();
  setStaticSetter();
}

////////////////////////////////////////////////////////////////////////////////
/// Static set of an uninitialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[null|exact=JSUInt31]*/
var _field1;

/*element: setTopLevelFieldUninitialized:[exact=JSUInt31]*/
setTopLevelFieldUninitialized() => _field1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*element: Class1.field:[null|exact=JSUInt31]*/
  static var field;
}

/*element: setStaticFieldUninitialized:[exact=JSUInt31]*/
setStaticFieldUninitialized() => Class1.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*element: _field2:Union of [[exact=JSString], [exact=JSUInt31]]*/
dynamic _field2 = '';

/*element: setTopLevelFieldInitialized:[exact=JSUInt31]*/
setTopLevelFieldInitialized() => _field2 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.field:Union of [[exact=JSString], [exact=JSUInt31]]*/
  static dynamic field = '';
}

/*element: setStaticFieldInitialized:[exact=JSUInt31]*/
setStaticFieldInitialized() => Class2.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of a top level setter.
////////////////////////////////////////////////////////////////////////////////

set _setter1(/*[exact=JSUInt31]*/ value) {}

/*element: setTopLevelSetter:[exact=JSUInt31]*/
setTopLevelSetter() => _setter1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  static set setter(/*[exact=JSUInt31]*/ value) {}
}

/*element: setStaticSetter:[exact=JSUInt31]*/
setStaticSetter() => Class3.setter = 42;
