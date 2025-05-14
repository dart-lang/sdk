// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  int method1();
}

class Child extends Base {
  @override
  int method1() => 1;
}

dynamic getChild(bool x) {
  if (x) {
    return Child();
  }
  return 5;
}

bool getOpaqueTrue() => 5 < 20;

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  final x = getChild(getOpaqueTrue());
  if (x is Base) {
    return x.method1();
  }
  return 0;
}
