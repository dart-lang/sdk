// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

int f3(int i, int j) =>
    c1(i) +
    c2(i, j: i + 10) +
    c2(j, k: j + 10) +
    c2(i, j: j + 10, k: j + 10) +
    3;

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => f3;
