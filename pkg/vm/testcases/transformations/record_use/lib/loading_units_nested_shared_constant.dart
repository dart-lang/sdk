// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'loading_units_nested_shared_constant_helper_a.dart' deferred as a;
import 'loading_units_nested_shared_constant_helper_b.dart' deferred as b;

void main() async {
  await a.loadLibrary();
  a.runA();
  await b.loadLibrary();
  b.runB();
}
