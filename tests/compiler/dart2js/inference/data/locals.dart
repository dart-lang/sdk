// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  uninitializedLocal();
  initializedLocal();
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
