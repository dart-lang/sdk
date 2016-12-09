// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that MirrorsUsed without usage of the static field does not crash
// dart2js.

@MirrorsUsed(targets: const ["NON_EXISTING_STATIC"])
import 'dart:mirrors';

Bar foo = new Bar();

typedef int FunctionTypeDef();

class Bar {
  final FunctionTypeDef gee;
  Bar() : gee = (() => 499);
}

main() {
  // Don't do anything.
}
