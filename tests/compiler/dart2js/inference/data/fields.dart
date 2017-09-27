// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  fieldGetUnset();
  fieldGetUnsetInitialized();
  fieldSet();
  fieldSetReturn();
}

////////////////////////////////////////////////////////////////////////////////
/// Get an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  var /*element: Class1.field:[null]*/ field;
}

/*element: fieldGetUnset:[null]*/
fieldGetUnset() => new Class1(). /*[exact=Class1]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Get a field initialized to `null`.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:[exact=Class4]*/
class Class4 {
  var /*element: Class4.field:[null]*/ field = null;
}

/*element: fieldGetUnsetInitialized:[null]*/
fieldGetUnsetInitialized() => new Class4(). /*[exact=Class4]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Set an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  var /*element: Class2.field:[null|exact=JSUInt31]*/ field;
}

/*element: fieldSet:[null]*/
fieldSet() {
  new Class2(). /*update: [exact=Class2]*/ field = 0;
}

////////////////////////////////////////////////////////////////////////////////
/// Return the setting of an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  var /*element: Class3.field:[null|exact=JSUInt31]*/ field;
}

/*element: fieldSetReturn:[exact=JSUInt31]*/
fieldSetReturn() {
  return new Class3(). /*update: [exact=Class3]*/ field = 0;
}
