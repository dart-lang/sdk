// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

class Class<T> {
  Class();
}

method1<T>() {}

method2<T>(t) => t;

main() {
  Expect.equals("<T1>() => dynamic", '${method1.runtimeType}');
  method2(0);
  new Class();
}
