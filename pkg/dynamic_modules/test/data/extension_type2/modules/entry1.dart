// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => [
  method(value),
  methodBB(valueBB),
  const C.foo42(),
  const C.foo43(),
  const CC.foo42(),
  const CC.foo43(),
];

int method(B b) => b.foo();
int methodBB(BB b) => b.foo();
