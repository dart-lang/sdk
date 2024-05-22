// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test has two completely separate resource identifiers.
// Both are only used in their respective loading units.
// So, no dominant loading unit logic is applied.

import 'package:meta/meta.dart' show ResourceIdentifier;

import 'loading_units_simple_helper.dart' deferred as helper;

void main() async {
  SomeClass.someStaticMethod(42);

  await helper.loadLibrary();

  helper.invokeDeferred();
}

class SomeClass {
  @ResourceIdentifier('id')
  static void someStaticMethod(int i) {}
}
