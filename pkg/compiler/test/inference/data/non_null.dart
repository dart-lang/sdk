// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  nonNullStaticField();
  nonNullInstanceField1();
  nonNullInstanceField2();
  nonNullLocal();
}

/*member: staticField:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
var staticField;

/*member: nonNullStaticField:[exact=JSUInt31|powerset={I}{O}{N}]*/
nonNullStaticField() => staticField ??= 42;

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;
}

/*member: nonNullInstanceField1:[exact=JSUInt31|powerset={I}{O}{N}]*/
nonNullInstanceField1() {
  return Class1()
          . /*[exact=Class1|powerset={N}{O}{N}]*/ /*update: [exact=Class1|powerset={N}{O}{N}]*/ field ??=
      42;
}

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class2.method:[exact=JSUInt31|powerset={I}{O}{N}]*/
  method() {
    return /*[exact=Class2|powerset={N}{O}{N}]*/ /*update: [exact=Class2|powerset={N}{O}{N}]*/ field ??=
        42;
  }
}

/*member: nonNullInstanceField2:[exact=JSUInt31|powerset={I}{O}{N}]*/
nonNullInstanceField2() {
  return Class2(). /*invoke: [exact=Class2|powerset={N}{O}{N}]*/ method();
}

/*member: nonNullLocal:[exact=JSUInt31|powerset={I}{O}{N}]*/
nonNullLocal() {
  var local = null;
  return local ??= 42;
}
