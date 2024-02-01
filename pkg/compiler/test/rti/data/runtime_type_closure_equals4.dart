// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

class Class1<T> {
  Class1();

  // TODO(johnniwinther): Currently only methods that use class type variables
  // in their signature are marked as 'needs signature'. Change this to mark
  // all methods that need to support access to their function type at runtime.

  method1a() => null;

  method1b() => null;

  method2(t, s) => t;
}

class Class2<T> {
  Class2();
}

main() {
  var c = Class1<int>();

  makeLive(c.method1a.runtimeType == c.method1b.runtimeType);
  makeLive(c.method1a.runtimeType == c.method2.runtimeType);
  Class2<int>();
}
