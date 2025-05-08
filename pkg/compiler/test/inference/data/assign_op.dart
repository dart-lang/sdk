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

/*member: assignPlus:[subclass=JSUInt32|powerset={I}{O}]*/
assignPlus() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ += 42;
}

/*member: assignAnd:[exact=JSUInt31|powerset={I}{O}]*/
assignAnd() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ &= 42;
}

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 {
  /*member: Class1.field:[subclass=JSPositiveInt|powerset={I}{O}]*/
  var field = 87;
}

/*member: instanceAssignPlus:[subclass=JSPositiveInt|powerset={I}{O}]*/
instanceAssignPlus() {
  var c = Class1();
  return c. /*[exact=Class1|powerset={N}{O}]*/ /*update: [exact=Class1|powerset={N}{O}]*/ field /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ +=
      42;
}

/*member: Class2.:[exact=Class2|powerset={N}{O}]*/
class Class2 {
  /*member: Class2.field:[exact=JSUInt31|powerset={I}{O}]*/
  var field = 87;
}

/*member: instanceAssignAnd:[exact=JSUInt31|powerset={I}{O}]*/
instanceAssignAnd() {
  var c = Class2();
  return c. /*[exact=Class2|powerset={N}{O}]*/ /*update: [exact=Class2|powerset={N}{O}]*/ field /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ &=
      42;
}

/*member: assignIndexPlus:[subclass=JSPositiveInt|powerset={I}{O}]*/
assignIndexPlus() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      [0] /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ +=
      42;
}

/*member: assignIndexAnd:[exact=JSUInt31|powerset={I}{O}]*/
assignIndexAnd() {
  var i = [87];
  return i
      /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      [0] /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ &=
      42;
}

/*member: assignIndexInc:[subclass=JSPositiveInt|powerset={I}{O}]*/
assignIndexInc() {
  var i = [87];
  return i
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSPositiveInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  [0] /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ ++;
}

/*member: assignIndexDec:[subclass=JSInt|powerset={I}{O}]*/
assignIndexDec() {
  var i = [87];
  return /*invoke: [subclass=JSInt|powerset={I}{O}]*/ --i
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  [0];
}
