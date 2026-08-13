// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class D1 extends C1 {
  int foo1() => foo() + 1;
}

class D2 extends C2 {
  int foo2() => foo() + 2;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return [D1().foo1(), D2().foo2()];
}
