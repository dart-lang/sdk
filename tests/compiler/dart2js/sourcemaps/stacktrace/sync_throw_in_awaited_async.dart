// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  // This call is on the stack when the error is thrown.
  /*1:main*/ test1();
}

// TODO(34942): Step 3 should point to the body block.
@pragma('dart2js:noInline')
test1 /*3:test1*/ () async {
  // This call is on the stack when the error is thrown.
  await /*5:test1*/ test2();
}

// TODO(34942): Step 7 should point to the body block.
@pragma('dart2js:noInline')
test2 /*7:test2*/ () async {
  /*9:test2*/ throw '>ExceptionMarker<';
}
