// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart';

class DynA1 extends A {
  @override
  String foo() => 'DynA1.foo, super: ${super.foo()}';
}

class DynA2 extends A with M3 {}

@pragma('dyn-module:entry-point')
List<A> dynamicModuleEntrypoint() {
  return <A>[DynA1(), DynA2()];
}
