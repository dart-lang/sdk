// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: foo:[exact=JSUInt31]*/
foo() {
  var a = [1, 2, 3];
  return a
      . /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
      first;
}

/*element: main:[null]*/
main() {
  foo();
}
