// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class C1 extends Base1 {}

class C2 extends Base2 {}

class C3 extends Base1 {}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return (int arg) => switch (arg) {
    1 => C1(),
    2 => C2(),
    3 => C3(),
    _ => throw 'Unexpected $arg',
  };
}
