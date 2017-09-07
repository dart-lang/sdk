// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  uninitializedLocal();
  initializedLocal();
  updatedLocal();
  invokeLocal();
  postfixLocal();
}

/*element: uninitializedLocal:[null]*/
uninitializedLocal() {
  var local;
  return local;
}

/*element: initializedLocal:[exact=JSUInt31]*/
initializedLocal() {
  var local = 0;
  return local;
}

/*element: updatedLocal:[exact=JSUInt31]*/
updatedLocal() {
  var local2;
  local2 = 0;
  return local2;
}

/*element: invokeLocal:[null]*/
invokeLocal() {
  var local2 = 0;
  local2. /*invoke: [exact=JSUInt31]*/ toString();
  return null;
}

/*element: postfixLocal:[null]*/
postfixLocal() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var local2 = 0;
  local2 /*invoke: [exact=JSUInt31]*/ ++;
  return null;
}
