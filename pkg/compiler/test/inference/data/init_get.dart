// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: getter:[exact=JSUInt31|powerset={I}]*/
get getter => 42;

/*member: main:[null|powerset={null}]*/
main() {
  getGetter();
  getGetterInFinalField();
  getGetterInField();
  getGetterInFinalTopLevelField();
  getGetterInTopLevelField();
  getGetterInFinalStaticField();
  getGetterInStaticField();
}

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter directly.
////////////////////////////////////////////////////////////////////////////////

/*member: getGetter:[exact=JSUInt31|powerset={I}]*/
getGetter() => getter;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final instance field initializer.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 {
  /*member: Class1.field:[exact=JSUInt31|powerset={I}]*/
  final field = getter;
}

/*member: getGetterInFinalField:[exact=JSUInt31|powerset={I}]*/
getGetterInFinalField() => Class1(). /*[exact=Class1|powerset={N}]*/ field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final instance field initializer.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}]*/
class Class2 {
  /*member: Class2.field:[exact=JSUInt31|powerset={I}]*/
  var field = getter;
}

/*member: getGetterInField:[exact=JSUInt31|powerset={I}]*/
getGetterInField() => Class2(). /*[exact=Class2|powerset={N}]*/ field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final top level field initializer.
////////////////////////////////////////////////////////////////////////////////

/*member: _field1:[null|exact=JSUInt31|powerset={null}{I}]*/
final _field1 = getter;

/*member: getGetterInFinalTopLevelField:[null|exact=JSUInt31|powerset={null}{I}]*/
getGetterInFinalTopLevelField() => _field1;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final top level field initializer.
////////////////////////////////////////////////////////////////////////////////

/*member: _field2:[null|exact=JSUInt31|powerset={null}{I}]*/
var _field2 = getter;

/*member: getGetterInTopLevelField:[null|exact=JSUInt31|powerset={null}{I}]*/
getGetterInTopLevelField() => _field2;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final static field initializer.
////////////////////////////////////////////////////////////////////////////////

abstract class Class3 {
  /*member: Class3.field:[null|exact=JSUInt31|powerset={null}{I}]*/
  static final field = getter;
}

/*member: getGetterInFinalStaticField:[null|exact=JSUInt31|powerset={null}{I}]*/
getGetterInFinalStaticField() => Class3.field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final static field initializer.
////////////////////////////////////////////////////////////////////////////////

abstract class Class4 {
  /*member: Class4.field:[null|exact=JSUInt31|powerset={null}{I}]*/
  static var field = getter;
}

/*member: getGetterInStaticField:[null|exact=JSUInt31|powerset={null}{I}]*/
getGetterInStaticField() => Class4.field;
