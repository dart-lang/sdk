// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--omit-implicit-checks --lax-runtime-type-to-string --experiment-new-rti

import 'package:expect/expect.dart';

class Class1<T> {
  Class1();

  T method() => throw 'unreachable';
}

class Class2<T> {
  Class2();
}

main() {
  Class1<int> cls1 = Class1<int>();
  Expect.equals("() => erased", cls1.method.runtimeType.toString());
  Class2<int>();
}
