// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test has a resource identifier referred to from two loading units.

import 'loading_units_multiple_helper_shared.dart';

import 'loading_units_multiple_helper.dart' deferred as helper;

void main() async {
  SomeClass.someStaticMethod(42);

  await helper.loadLibrary();

  helper.invokeDeferred();
}
