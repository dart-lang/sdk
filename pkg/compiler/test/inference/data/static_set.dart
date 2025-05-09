// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: field1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
var field1;

/*member: setTopLevelFieldUninitialized:[exact=JSUInt31|powerset={I}{O}{N}]*/
setTopLevelFieldUninitialized() => field1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*member: Class1.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  static var field;
}

/*member: setStaticFieldUninitialized:[exact=JSUInt31|powerset={I}{O}{N}]*/
setStaticFieldUninitialized() => Class1.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: field2:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
dynamic field2 = '';

/*member: setTopLevelFieldInitialized:[exact=JSUInt31|powerset={I}{O}{N}]*/
setTopLevelFieldInitialized() => field2 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
  static dynamic field = '';
}

/*member: setStaticFieldInitialized:[exact=JSUInt31|powerset={I}{O}{N}]*/
setStaticFieldInitialized() => Class2.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of a top level setter.
////////////////////////////////////////////////////////////////////////////////

set _setter1(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) {}

/*member: setTopLevelSetter:[exact=JSUInt31|powerset={I}{O}{N}]*/
setTopLevelSetter() => _setter1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  static set setter(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) {}
}

/*member: setStaticSetter:[exact=JSUInt31|powerset={I}{O}{N}]*/
setStaticSetter() => Class3.setter = 42;
