// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: foo:[exact=JSUInt31]*/
foo() {
  var a = [1, 2, 3];
  return a
      . /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
      first;
}

/*member: main:[null]*/
main() {
  foo();
}
