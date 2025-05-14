// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: field1:[null|exact=JSUInt31|powerset=1]*/
var field1;

/*member: setTopLevelFieldUninitialized:[exact=JSUInt31|powerset=0]*/
setTopLevelFieldUninitialized() => field1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*member: Class1.field:[null|exact=JSUInt31|powerset=1]*/
  static var field;
}

/*member: setStaticFieldUninitialized:[exact=JSUInt31|powerset=0]*/
setStaticFieldUninitialized() => Class1.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: field2:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
dynamic field2 = '';

/*member: setTopLevelFieldInitialized:[exact=JSUInt31|powerset=0]*/
setTopLevelFieldInitialized() => field2 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of an initialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  static dynamic field = '';
}

/*member: setStaticFieldInitialized:[exact=JSUInt31|powerset=0]*/
setStaticFieldInitialized() => Class2.field = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static set of a top level setter.
////////////////////////////////////////////////////////////////////////////////

set _setter1(/*[exact=JSUInt31|powerset=0]*/ value) {}

/*member: setTopLevelSetter:[exact=JSUInt31|powerset=0]*/
setTopLevelSetter() => _setter1 = 42;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  static set setter(/*[exact=JSUInt31|powerset=0]*/ value) {}
}

/*member: setStaticSetter:[exact=JSUInt31|powerset=0]*/
setStaticSetter() => Class3.setter = 42;
