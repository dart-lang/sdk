// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  var c = Class();
  c. /*1:main*/ test();
}

class Class {
  void test() {
    /*2:Class.new.test*/ throw '>ExceptionMarker<';
  }
}
