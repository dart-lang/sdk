// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  var c = Class();
  // NOTE: The following line should not be formatted because spaces are
  // inserted around the comment that throw off the expected column.
  c/*1:main*/.test();
}

class Class {
  void test() {
    /*2:Class.new.test*/ throw '>ExceptionMarker<';
  }
}
