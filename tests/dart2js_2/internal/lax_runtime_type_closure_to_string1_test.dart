// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';
import 'dart:_foreign_helper' show JS_GET_FLAG;

class Class<T> {
  Class();
}

main() {
  local1() {}
  local2(int i) => i;

  var toString = '${local1.runtimeType}';
  if ('$Object' == 'Object') {
    // `true` if non-minified.
    Expect.equals("Closure", toString);
  }
  print(toString);
  local2(0);
  new Class();
}
