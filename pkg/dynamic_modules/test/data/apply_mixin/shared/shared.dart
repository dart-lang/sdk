// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'shared_old.dart';

abstract interface class A {
  int method1();
}

mixin M on A {
  String method2() => '${super.method1()} 2';
}
