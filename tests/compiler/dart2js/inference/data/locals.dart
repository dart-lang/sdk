// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  uninitializedLocal();
  initializedLocal();
  updatedLocal();
  invokeLocal();
  postfixLocal();
  postfixLocalUsed();
  prefixLocal();
  prefixLocalUsed();
  complexAssignmentLocal();
}

/*member: uninitializedLocal:[null]*/
uninitializedLocal() {
  var local;
  return local;
}

/*member: initializedLocal:[exact=JSUInt31]*/
initializedLocal() {
  var local = 0;
  return local;
}

/*member: updatedLocal:[exact=JSUInt31]*/
updatedLocal() {
  var local2;
  local2 = 0;
  return local2;
}

/*member: invokeLocal:[null]*/
invokeLocal() {
  var local2 = 0;
  local2. /*invoke: [exact=JSUInt31]*/ toString();
  return null;
}

/*member: postfixLocal:[null]*/
postfixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  local2 /*invoke: [exact=JSUInt31]*/ ++;
  return null;
}

/*member: postfixLocalUsed:[exact=JSUInt31]*/
postfixLocalUsed() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31]*/ ++;
}

/*member: prefixLocal:[null]*/
prefixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  /*invoke: [exact=JSUInt31]*/ ++local2;
  return null;
}

/*member: prefixLocalUsed:[subclass=JSUInt32]*/
prefixLocalUsed() {
  var local2 = 0;
  return /*invoke: [exact=JSUInt31]*/ ++local2;
}

/*member: complexAssignmentLocal:[subclass=JSUInt32]*/
complexAssignmentLocal() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31]*/ += 42;
}
