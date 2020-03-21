// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  // This call is no longer on the stack when the error is thrown.
  /*:main*/ test();
}

test() async {
  await null;
  // ignore: UNUSED_LOCAL_VARIABLE
  var c = new /*1:test*/ Class();
}

class Class {
  @pragma('dart2js:noInline')
  Class() {
    /*2:Class*/ throw '>ExceptionMarker<';
  }
}
