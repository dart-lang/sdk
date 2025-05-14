// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class Child extends Base {
  @override
  int method1(int i, [int? j]) => i + (j ?? 0);

  @override
  int method2(int i, {int? j, String? a}) => i + (j ?? 0) + (a?.length ?? 0);

  @override
  int method3<T>(int i, {int? j, T? a}) => i + (j ?? 0);
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => Child();
