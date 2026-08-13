// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class Child3 extends Base {
  @override
  int method1(int i) => i + 3;
}

class Child4 extends Base {
  @override
  int method1(int i) => i + 4;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  Base.x = Child3();
  final x = Base.x;
  if (x is Base) {
    return x.method1(0);
  }
  throw 'bad';
}
