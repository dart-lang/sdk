// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class Child extends Base {
  @override
  int method2() => 2;
}

@pragma('dyn-module:entrypoint')
Object? dynamicModuleEntrypoint() => Child();
