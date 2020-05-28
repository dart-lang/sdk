// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /*1:main*/ test();
}

@pragma('dart2js:noInline')
test() {
  try {
    /*2:test*/ throw '>ExceptionMarker<';
    // ignore: UNUSED_CATCH_CLAUSE
  } on String catch (e) {
    rethrow;
  }
}
