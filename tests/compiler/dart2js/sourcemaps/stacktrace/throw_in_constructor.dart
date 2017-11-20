// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var c = /*1:main*/ new Class();
}

class Class {
  @NoInline()
  /*2:Class*/ Class() {
    /*3:Class*/ throw '>ExceptionMarker<';
  }
}
