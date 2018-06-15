// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

class Class<T> {
  Class();
}

main() {
  local1<T>() {}
  local2<T>(t) => t;

  var toString = '${local1.runtimeType}';
  if ('$Object' == 'Object') {
    // `true` if non-minified.
    Expect.equals("main_local1", toString);
  }
  print(toString);
  local2(0);
  new Class();
}
