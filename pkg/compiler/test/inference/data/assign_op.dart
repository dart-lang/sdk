// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: assignPlus:[subclass=JSUInt32|powerset={I}]*/
assignPlus() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset={I}]*/ += 42;
}

/*member: assignAnd:[exact=JSUInt31|powerset={I}]*/
assignAnd() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset={I}]*/ &= 42;
}

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 {
  /*member: Class1.field:[subclass=JSPositiveInt|powerset={I}]*/
  var field = 87;
}

/*member: instanceAssignPlus:[subclass=JSPositiveInt|powerset={I}]*/
instanceAssignPlus() {
  var c = Class1();
  return c. /*[exact=Class1|powerset={N}]*/ /*update: [exact=Class1|powerset={N}]*/ field /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ +=
      42;
}

/*member: Class2.:[exact=Class2|powerset={N}]*/
class Class2 {
  /*member: Class2.field:[exact=JSUInt31|powerset={I}]*/
  var field = 87;
}

/*member: instanceAssignAnd:[exact=JSUInt31|powerset={I}]*/
instanceAssignAnd() {
  var c = Class2();
  return c. /*[exact=Class2|powerset={N}]*/ /*update: [exact=Class2|powerset={N}]*/ field /*invoke: [exact=JSUInt31|powerset={I}]*/ &=
      42;
}

/*member: assignIndexPlus:[subclass=JSPositiveInt|powerset={I}]*/
assignIndexPlus() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
      [0] /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ +=
      42;
}

/*member: assignIndexAnd:[exact=JSUInt31|powerset={I}]*/
assignIndexAnd() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
      [0] /*invoke: [exact=JSUInt31|powerset={I}]*/ &=
      42;
}

/*member: assignIndexInc:[subclass=JSPositiveInt|powerset={I}]*/
assignIndexInc() {
  var i = [87];
  return i
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSPositiveInt|powerset={I}], length: 1, powerset: {I})*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ ++;
}

/*member: assignIndexDec:[subclass=JSInt|powerset={I}]*/
assignIndexDec() {
  var i = [87];
  return /*invoke: [subclass=JSInt|powerset={I}]*/ --i
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: 1, powerset: {I})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=JSInt|powerset={I}], length: 1, powerset: {I})*/
  [0];
}
