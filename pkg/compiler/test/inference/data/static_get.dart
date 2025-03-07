// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: _field1:[null|powerset=1]*/
var _field1;

/*member: getTopLevelFieldUninitialized:[null|powerset=1]*/
getTopLevelFieldUninitialized() => _field1;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an uninitialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*member: Class1.field:[null|powerset=1]*/
  static var field;
}

/*member: getStaticFieldUninitialized:[null|powerset=1]*/
getStaticFieldUninitialized() => Class1.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an initialized top level field.
////////////////////////////////////////////////////////////////////////////////

/*member: _field2:[exact=JSUInt31|powerset=0]*/
var _field2 = 42;

/*member: getTopLevelFieldInitialized:[exact=JSUInt31|powerset=0]*/
getTopLevelFieldInitialized() => _field2;

////////////////////////////////////////////////////////////////////////////////
/// Static get of an initialized static field.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field:[exact=JSUInt31|powerset=0]*/
  static var field = 42;
}

/*member: getStaticFieldInitialized:[exact=JSUInt31|powerset=0]*/
getStaticFieldInitialized() => Class2.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level field with an initializer that is potentially
/// null.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[exact=JSUInt31|powerset=0]*/
_method3() => 42;

/*member: _field3:[null|exact=JSUInt31|powerset=1]*/
var _field3 = _method3();

/*member: getTopLevelFieldInitializedPotentiallyNull:[null|exact=JSUInt31|powerset=1]*/
getTopLevelFieldInitializedPotentiallyNull() => _field3;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static field with an initializer that is potentially null.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.method:[exact=JSUInt31|powerset=0]*/
  static method() => 42;

  /*member: Class3.field:[null|exact=JSUInt31|powerset=1]*/
  static var field = method();
}

/*member: getStaticFieldInitializedPotentiallyNull:[null|exact=JSUInt31|powerset=1]*/
getStaticFieldInitializedPotentiallyNull() => Class3.field;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level method.
////////////////////////////////////////////////////////////////////////////////

/*member: _method4:[exact=JSUInt31|powerset=0]*/
_method4() => 42;

/*member: getTopLevelMethod:[subclass=Closure|powerset=0]*/
getTopLevelMethod() => _method4;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static method.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*member: Class4.method:[exact=JSUInt31|powerset=0]*/
  static method() => 42;
}

/*member: getStaticMethod:[subclass=Closure|powerset=0]*/
getStaticMethod() => Class4.method;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a top level getter.
////////////////////////////////////////////////////////////////////////////////

/*member: _getter1:[exact=JSUInt31|powerset=0]*/
get _getter1 => 42;

/*member: getTopLevelGetter:[exact=JSUInt31|powerset=0]*/
getTopLevelGetter() => _getter1;

////////////////////////////////////////////////////////////////////////////////
/// Static get of a static getter.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*member: Class5.getter:[exact=JSUInt31|powerset=0]*/
  static get getter => 42;
}

/*member: getStaticGetter:[exact=JSUInt31|powerset=0]*/
getStaticGetter() => Class5.getter;
