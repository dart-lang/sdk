// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // This call is no longer on the stack when the error is thrown.
  /*1:main*/ test();
}

void /*2:test*/ test() async {
  // ignore: UNUSED_LOCAL_VARIABLE
  var /*3*/ c = Class();
}

class Class {
  Class() {
    // Some comment
    /*4:Class.new*/ throw '>ExceptionMarker<';
  }
}
