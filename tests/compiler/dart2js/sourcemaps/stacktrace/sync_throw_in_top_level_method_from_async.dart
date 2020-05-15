// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /*1:main*/ test1();
}

// TODO(34942): Step 2 should point to the body block.
@pragma('dart2js:noInline')
test1 /*2:test1*/ () async {
  /*9:test1*/ test2();
}

@pragma('dart2js:noInline')
test2() {
  /*10:test2*/ throw '>ExceptionMarker<';
}
