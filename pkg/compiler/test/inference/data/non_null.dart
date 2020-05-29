// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  nonNullStaticField();
  nonNullInstanceField1();
  nonNullInstanceField2();
  nonNullLocal();
}

/*member: staticField:[null|exact=JSUInt31]*/
var staticField;

/*member: nonNullStaticField:[exact=JSUInt31]*/
nonNullStaticField() => staticField ??= 42;

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.field:[null|exact=JSUInt31]*/
  var field;
}

/*member: nonNullInstanceField1:[exact=JSUInt31]*/
nonNullInstanceField1() {
  return new Class1(). /*[exact=Class1]*/ /*update: [exact=Class1]*/ field ??=
      42;
}

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.field:[null|exact=JSUInt31]*/
  var field;

  /*member: Class2.method:[exact=JSUInt31]*/
  method() {
    return /*[exact=Class2]*/ /*update: [exact=Class2]*/ field ??= 42;
  }
}

/*member: nonNullInstanceField2:[exact=JSUInt31]*/
nonNullInstanceField2() {
  return new Class2(). /*invoke: [exact=Class2]*/ method();
}

// TODO(johnniwinther): We should infer that the returned value cannot be null.
/*member: nonNullLocal:[null|exact=JSUInt31]*/
nonNullLocal() {
  var local = null;
  return local ??= 42;
}
