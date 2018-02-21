// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var c = /*ddc.1:main*/ new /*ddk.1:main*/ Class();
}

class Class {
  Class() {
    /*2:Class.new*/ throw '>ExceptionMarker<';
  }
}
