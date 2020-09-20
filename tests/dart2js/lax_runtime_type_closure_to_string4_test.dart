// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

class Class1 {
  Class1();

  T method<T>() => throw 'unreachable';
}

class Class2<T> {
  Class2();
}

main() {
  Class1 cls1 = Class1();
  Expect.equals("<T1>() => T1", cls1.method.runtimeType.toString());
  Class2<int>();
}
