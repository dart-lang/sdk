// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for issue https://github.com/dart-lang/sdk/issues/31306.
///
/// When 1 constant was imported in two libraries by using the same exact
/// deferred import URI, the deferred-constant initializer was incorrectly moved
/// to the main output unit.

import 'shared_constant_a.dart';
import 'shared_constant_b.dart';

main() async {
  (await doA()).method();
  await doB();
}
