// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  Class. /*1:main*/ field;
}

class Class {
  static dynamic field = /*2:Class.field*/ test();
  @pragma('dart2js:noInline')
  static test() {
    /*3:Class.test*/ throw '>ExceptionMarker<';
  }
}
