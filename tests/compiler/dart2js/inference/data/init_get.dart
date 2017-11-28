// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: getter:[exact=JSUInt31]*/
get getter => 42;

/*element: main:[null]*/
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

/*element: getGetter:[exact=JSUInt31]*/
getGetter() => getter;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final instance field initializer.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.field:[exact=JSUInt31]*/
  final field = getter;
}

/*element: getGetterInFinalField:[exact=JSUInt31]*/
getGetterInFinalField() => new Class1(). /*[exact=Class1]*/ field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final instance field initializer.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.field:[exact=JSUInt31]*/
  var field = getter;
}

/*element: getGetterInField:[exact=JSUInt31]*/
getGetterInField() => new Class2(). /*[exact=Class2]*/ field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final top level field initializer.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[null|exact=JSUInt31]*/
final _field1 = getter;

/*element: getGetterInFinalTopLevelField:[null|exact=JSUInt31]*/
getGetterInFinalTopLevelField() => _field1;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final top level field initializer.
////////////////////////////////////////////////////////////////////////////////

/*element: _field2:[null|exact=JSUInt31]*/
var _field2 = getter;

/*element: getGetterInTopLevelField:[null|exact=JSUInt31]*/
getGetterInTopLevelField() => _field2;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a final static field initializer.
////////////////////////////////////////////////////////////////////////////////

abstract class Class3 {
  /*element: Class3.field:[null|exact=JSUInt31]*/
  static final field = getter;
}

/*element: getGetterInFinalStaticField:[null|exact=JSUInt31]*/
getGetterInFinalStaticField() => Class3.field;

////////////////////////////////////////////////////////////////////////////////
// Access a top level getter in a non-final static field initializer.
////////////////////////////////////////////////////////////////////////////////

abstract class Class4 {
  /*element: Class4.field:[null|exact=JSUInt31]*/
  static var field = getter;
}

/*element: getGetterInStaticField:[null|exact=JSUInt31]*/
getGetterInStaticField() => Class4.field;
