// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  fieldGetUnset();
  fieldGetUnsetInitialized();
  fieldSet();
  fieldSetReturn();
}

////////////////////////////////////////////////////////////////////////////////
/// Get an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  var /*member: Class1.field:[null|powerset=1]*/ field;
}

/*member: fieldGetUnset:[null|powerset=1]*/
fieldGetUnset() => Class1(). /*[exact=Class1|powerset=0]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Get a field initialized to `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {
  var /*member: Class4.field:[null|powerset=1]*/ field = null;
}

/*member: fieldGetUnsetInitialized:[null|powerset=1]*/
fieldGetUnsetInitialized() => Class4(). /*[exact=Class4|powerset=0]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Set an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  var /*member: Class2.field:[null|exact=JSUInt31|powerset=1]*/ field;
}

/*member: fieldSet:[null|powerset=1]*/
fieldSet() {
  Class2(). /*update: [exact=Class2|powerset=0]*/ field = 0;
}

////////////////////////////////////////////////////////////////////////////////
/// Return the setting of an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  var /*member: Class3.field:[null|exact=JSUInt31|powerset=1]*/ field;
}

/*member: fieldSetReturn:[exact=JSUInt31|powerset=0]*/
fieldSetReturn() {
  return Class3(). /*update: [exact=Class3|powerset=0]*/ field = 0;
}
