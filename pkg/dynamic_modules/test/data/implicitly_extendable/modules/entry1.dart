// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class DynamicBase {
  int method3() => 100;
}

class Child extends DynamicBase implements Sub1 {
  @override
  int method1() => 5;

  @override
  int method2() => 6;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => Child();
