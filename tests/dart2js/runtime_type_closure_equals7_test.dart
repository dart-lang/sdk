// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

T method1a<T>() => throw 'unreachable';

T method1b<T>() => throw 'unreachable';

T method2<T>(T t, String s) => t;

class Class<T> {
  Class();
}

main() {
  Expect.isTrue(method1a.runtimeType == method1b.runtimeType);
  Expect.isFalse(method1a.runtimeType == method2.runtimeType);
  Class<int>();
}
