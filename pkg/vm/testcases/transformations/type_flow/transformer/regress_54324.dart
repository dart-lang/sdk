// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/54324.
// Verifies that tree shaker can maintain connectivity of import graph
// when removing libraries.

import 'regress_54324_a.lib.dart';

void main() {
  c.run();
}
