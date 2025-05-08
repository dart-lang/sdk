// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  fieldGetUnset();
  fieldGetUnsetInitialized();
  fieldSet();
  fieldSetReturn();
}

////////////////////////////////////////////////////////////////////////////////
/// Get an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  var /*member: Class1.field:[null|powerset={null}]*/ field;
}

/*member: fieldGetUnset:[null|powerset={null}]*/
fieldGetUnset() => Class1(). /*[exact=Class1|powerset={N}{O}{N}]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Get a field initialized to `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {
  var /*member: Class4.field:[null|powerset={null}]*/ field = null;
}

/*member: fieldGetUnsetInitialized:[null|powerset={null}]*/
fieldGetUnsetInitialized() =>
    Class4(). /*[exact=Class4|powerset={N}{O}{N}]*/ field;

////////////////////////////////////////////////////////////////////////////////
/// Set an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  var /*member: Class2.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ field;
}

/*member: fieldSet:[null|powerset={null}]*/
fieldSet() {
  Class2(). /*update: [exact=Class2|powerset={N}{O}{N}]*/ field = 0;
}

////////////////////////////////////////////////////////////////////////////////
/// Return the setting of an uninitialized field.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  var /*member: Class3.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ field;
}

/*member: fieldSetReturn:[exact=JSUInt31|powerset={I}{O}{N}]*/
fieldSetReturn() {
  return Class3(). /*update: [exact=Class3|powerset={N}{O}{N}]*/ field = 0;
}
