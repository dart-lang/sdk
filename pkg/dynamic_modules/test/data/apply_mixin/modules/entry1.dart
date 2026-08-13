// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class RealA implements A {
  @override
  int method1() => 3;
}

class Child extends RealA with M {
  @override
  String method2() => '*${super.method2()}';
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  M3().method3();
  return Child();
}
