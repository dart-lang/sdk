// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: uninitializedLocal:[null|powerset=1]*/
uninitializedLocal() {
  var local;
  return local;
}

/*member: initializedLocal:[exact=JSUInt31|powerset=0]*/
initializedLocal() {
  var local = 0;
  return local;
}

/*member: updatedLocal:[exact=JSUInt31|powerset=0]*/
updatedLocal() {
  var local2;
  local2 = 0;
  return local2;
}

/*member: invokeLocal:[null|powerset=1]*/
invokeLocal() {
  var local2 = 0;
  local2. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  return null;
}

/*member: postfixLocal:[null|powerset=1]*/
postfixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  local2 /*invoke: [exact=JSUInt31|powerset=0]*/ ++;
  return null;
}

/*member: postfixLocalUsed:[exact=JSUInt31|powerset=0]*/
postfixLocalUsed() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31|powerset=0]*/ ++;
}

/*member: prefixLocal:[null|powerset=1]*/
prefixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  /*invoke: [exact=JSUInt31|powerset=0]*/
  ++local2;
  return null;
}

/*member: prefixLocalUsed:[subclass=JSUInt32|powerset=0]*/
prefixLocalUsed() {
  var local2 = 0;
  return /*invoke: [exact=JSUInt31|powerset=0]*/ ++local2;
}

/*member: complexAssignmentLocal:[subclass=JSUInt32|powerset=0]*/
complexAssignmentLocal() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31|powerset=0]*/ += 42;
}
