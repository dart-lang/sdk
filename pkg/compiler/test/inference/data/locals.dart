// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: uninitializedLocal:[null|powerset={null}]*/
uninitializedLocal() {
  var local;
  return local;
}

/*member: initializedLocal:[exact=JSUInt31|powerset={I}{O}]*/
initializedLocal() {
  var local = 0;
  return local;
}

/*member: updatedLocal:[exact=JSUInt31|powerset={I}{O}]*/
updatedLocal() {
  var local2;
  local2 = 0;
  return local2;
}

/*member: invokeLocal:[null|powerset={null}]*/
invokeLocal() {
  var local2 = 0;
  local2. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ toString();
  return null;
}

/*member: postfixLocal:[null|powerset={null}]*/
postfixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  local2 /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ ++;
  return null;
}

/*member: postfixLocalUsed:[exact=JSUInt31|powerset={I}{O}]*/
postfixLocalUsed() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ ++;
}

/*member: prefixLocal:[null|powerset={null}]*/
prefixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  /*invoke: [exact=JSUInt31|powerset={I}{O}]*/
  ++local2;
  return null;
}

/*member: prefixLocalUsed:[subclass=JSUInt32|powerset={I}{O}]*/
prefixLocalUsed() {
  var local2 = 0;
  return /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ ++local2;
}

/*member: complexAssignmentLocal:[subclass=JSUInt32|powerset={I}{O}]*/
complexAssignmentLocal() {
  var local2 = 0;
  return local2 /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ += 42;
}
