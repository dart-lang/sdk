// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  /*ddc.1:main*/ Class. /*ddk.1:main*/ test();
}

class Class {
  static void test() {
    /*2:Function.test*/ throw '>ExceptionMarker<';
  }
}
