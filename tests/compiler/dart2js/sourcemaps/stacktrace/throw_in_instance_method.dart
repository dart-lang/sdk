// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var c = new Class();
  c. /*1:main*/ test();
}

class Class {
  @NoInline()
  test() {
    /*2:Class.test*/ throw '>ExceptionMarker<';
  }
}
