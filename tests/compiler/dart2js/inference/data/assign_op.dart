// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  assignPlus();
  assignAnd();
  instanceAssignPlus();
  instanceAssignAnd();
  assignIndexPlus();
  assignIndexAnd();
  assignIndexInc();
  assignIndexDec();
}

////////////////////////////////////////////////////////////////////////////////

/*member: assignPlus:[subclass=JSUInt32]*/
assignPlus() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31]*/ += 42;
}

/*member: assignAnd:[exact=JSUInt31]*/
assignAnd() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31]*/ &= 42;
}

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.field:[subclass=JSPositiveInt]*/
  var field = 87;
}

/*member: instanceAssignPlus:[subclass=JSPositiveInt]*/
instanceAssignPlus() {
  var c = new Class1();
  return c.
          /*[exact=Class1]*/ /*update: [exact=Class1]*/ field
      /*invoke: [subclass=JSPositiveInt]*/ += 42;
}

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.field:[exact=JSUInt31]*/
  var field = 87;
}

/*member: instanceAssignAnd:[exact=JSUInt31]*/
instanceAssignAnd() {
  var c = new Class2();
  return c.
          /*[exact=Class2]*/ /*update: [exact=Class2]*/ field
      /*invoke: [exact=JSUInt31]*/ &= 42;
}

/*member: assignIndexPlus:[subclass=JSPositiveInt]*/
assignIndexPlus() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
      /*update: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
      [0] /*invoke: [subclass=JSPositiveInt]*/ += 42;
}

/*member: assignIndexAnd:[exact=JSUInt31]*/
assignIndexAnd() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
      [0] /*invoke: [exact=JSUInt31]*/ &= 42;
}

/*member: assignIndexInc:[subclass=JSPositiveInt]*/
assignIndexInc() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
      /*update: Container([exact=JSExtendableArray], element: [subclass=JSPositiveInt], length: 1)*/
      [0] /*invoke: [subclass=JSPositiveInt]*/ ++;
}

/*member: assignIndexDec:[subclass=JSInt]*/
assignIndexDec() {
  var i = [87];
  return
      /*invoke: [subclass=JSInt]*/ --i
          /*Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          /*update: Container([exact=JSExtendableArray], element: [subclass=JSInt], length: 1)*/
          [0];
}
