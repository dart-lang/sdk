// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  assignPlus();
  assignAnd();
  assignIndexPlus();
  assignIndexAnd();
  assignIndexInc();
  assignIndexDec();
}

/*element: assignPlus:[subclass=JSUInt32]*/
assignPlus() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31]*/ += 42;
}

/*element: assignAnd:[exact=JSUInt31]*/
assignAnd() {
  var i = 87;
  return i /*invoke: [exact=JSUInt31]*/ &= 42;
}

/*element: assignIndexPlus:[subclass=JSPositiveInt]*/
assignIndexPlus() {
  var i = [87];
  return i
      /*Container mask: [subclass=JSPositiveInt] length: 1 type: [exact=JSExtendableArray]*/
      /*update: Container mask: [subclass=JSPositiveInt] length: 1 type: [exact=JSExtendableArray]*/
      [0] /*invoke: [subclass=JSPositiveInt]*/ += 42;
}

/*element: assignIndexAnd:[exact=JSUInt31]*/
assignIndexAnd() {
  var i = [87];
  return i
      /*Container mask: [exact=JSUInt31] length: 1 type: [exact=JSExtendableArray]*/
      /*update: Container mask: [exact=JSUInt31] length: 1 type: [exact=JSExtendableArray]*/
      [0] /*invoke: [exact=JSUInt31]*/ &= 42;
}

/*element: assignIndexInc:[subclass=JSPositiveInt]*/
assignIndexInc() {
  var i = [87];
  return i
      /*Container mask: [subclass=JSPositiveInt] length: 1 type: [exact=JSExtendableArray]*/
      /*update: Container mask: [subclass=JSPositiveInt] length: 1 type: [exact=JSExtendableArray]*/
      [0] /*invoke: [subclass=JSPositiveInt]*/ ++;
}

/*element: assignIndexDec:[subclass=JSInt]*/
assignIndexDec() {
  var i = [87];
  return
      /*invoke: [subclass=JSInt]*/ --i
          /*Container mask: [subclass=JSInt] length: 1 type: [exact=JSExtendableArray]*/
          /*update: Container mask: [subclass=JSInt] length: 1 type: [exact=JSExtendableArray]*/
          [0];
}
