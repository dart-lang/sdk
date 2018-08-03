// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test cyclic export and re-export.

/**
 * export_cyclic_test re-exports export_cyclic_helper1 which declares B
 * export_cyclic_helper1 re-exports export_cyclic_helper2 which declares C
 * export_cyclic_helper2 re-exports export_cyclic_test which declares A
 * export_cyclic_helper2 re-exports export_cyclic_helper3 which declares D
 */

library export_cyclic_test;

import 'export_cyclic_helper1.dart';
export 'export_cyclic_helper1.dart';

class A {}

void main() {
  print(new A());
  print(new B());
  print(new C());
  print(new D());
}
