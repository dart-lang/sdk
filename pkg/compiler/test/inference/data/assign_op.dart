// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: assignPlus:[subclass=JSUInt32|powerset=0]*/
assignPlus() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset=0]*/ += 42;
}

/*member: assignAnd:[exact=JSUInt31|powerset=0]*/
assignAnd() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset=0]*/ &= 42;
}

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.field:[subclass=JSPositiveInt|powerset=0]*/
  var field = 87;
}

/*member: instanceAssignPlus:[subclass=JSPositiveInt|powerset=0]*/
instanceAssignPlus() {
  var c = Class1();
  return c. /*[exact=Class1|powerset=0]*/ /*update: [exact=Class1|powerset=0]*/ field /*invoke: [subclass=JSPositiveInt|powerset=0]*/ +=
      42;
}

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.field:[exact=JSUInt31|powerset=0]*/
  var field = 87;
}

/*member: instanceAssignAnd:[exact=JSUInt31|powerset=0]*/
instanceAssignAnd() {
  var c = Class2();
  return c. /*[exact=Class2|powerset=0]*/ /*update: [exact=Class2|powerset=0]*/ field /*invoke: [exact=JSUInt31|powerset=0]*/ &=
      42;
}

/*member: assignIndexPlus:[subclass=JSPositiveInt|powerset=0]*/
assignIndexPlus() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
      /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
      [0] /*invoke: [subclass=JSPositiveInt|powerset=0]*/ +=
      42;
}

/*member: assignIndexAnd:[exact=JSUInt31|powerset=0]*/
assignIndexAnd() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
      /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
      [0] /*invoke: [exact=JSUInt31|powerset=0]*/ &=
      42;
}

/*member: assignIndexInc:[subclass=JSPositiveInt|powerset=0]*/
assignIndexInc() {
  var i = [87];
  return i
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
  /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSPositiveInt|powerset=0], length: 1, powerset: 0)*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++;
}

/*member: assignIndexDec:[subclass=JSInt|powerset=0]*/
assignIndexDec() {
  var i = [87];
  return /*invoke: [subclass=JSInt|powerset=0]*/ --i
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: 1, powerset: 0)*/
  /*update: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: 1, powerset: 0)*/
  [0];
}
