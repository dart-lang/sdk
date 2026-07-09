// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred_constant_use_under_load_guard_def1.dart' deferred as D1;
import 'deferred_constant_use_under_load_guard_def2.dart' deferred as D2;

Future runTest() async {
  await D1.loadLibrary();
  await D2.loadLibrary();

  // Access of `foo` under load guard D1.
  D1.printValue(foo);

  // Access of `foo` under load guard D2.
  D2.printValue(foo);

  // To prevent signature shaking from removing parameter and pushing `foo` to
  // callee.
  D1.printValue('a');
  D2.printValue('b');
}

class FooConst {
  final String value;
  const FooConst(this.value);
}

const foo = FooConst('foo');
