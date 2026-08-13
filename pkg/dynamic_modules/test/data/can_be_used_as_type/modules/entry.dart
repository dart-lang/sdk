// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';
import '../shared/shared2.dart';

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  Object o1 = C1();
  Object o2 = C2();
  Object o1b = C1();
  Object o2b = C2();
  return {
    'type-literal': [L1A, L1B, L1C, L1D, L2A, L2B],
    'type-param': [<L1A>[], <L1B>[], <L1C>[], <L1D>[], <L2A>[], <L2B>[]],
    '1-is': [1 is L1A, 1 is L1B, 1 is L1C, 1 is L1D, 1 is L2A, 1 is L2B],
    'o-is': [o1 is L1A, o1 is L1B, o1 is L1C, o2 is L2A],
    'as': [o1b as L1A, o1b as L1B, o1b as L1C, 3 as L1D, o2b as L2A, 3 as L2B],
    'list-of-l1ec': <L1Ec>[],
    'list-of-l1fc': <L1Fc>[],
    'list-of-l1gc': <L1Gc>[],
  };
}
