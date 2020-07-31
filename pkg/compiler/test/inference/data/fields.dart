// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  fieldGetUnset();
  fieldGetUnsetInitialized();
  fieldSet();
  fieldSetReturn();
}

////////////////////////////////////////////////////////////////////////////////
/// Get an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  var /*member: Class1.field:[null]*/ field;
}

/*member: fieldGetUnset:[null]*/
fieldGetUnset() => new Class1(). /*[exact=Class1]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Get a field initialized to `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4]*/
class Class4 {
  var /*member: Class4.field:[null]*/ field = null;
}

/*member: fieldGetUnsetInitialized:[null]*/
fieldGetUnsetInitialized() => new Class4(). /*[exact=Class4]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Set an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2]*/
class Class2 {
  var /*member: Class2.field:[null|exact=JSUInt31]*/ field;
}

/*member: fieldSet:[null]*/
fieldSet() {
  new Class2(). /*update: [exact=Class2]*/ field = 0;
}

////////////////////////////////////////////////////////////////////////////////
/// Return the setting of an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3]*/
class Class3 {
  var /*member: Class3.field:[null|exact=JSUInt31]*/ field;
}

/*member: fieldSetReturn:[exact=JSUInt31]*/
fieldSetReturn() {
  return new Class3(). /*update: [exact=Class3]*/ field = 0;
}
