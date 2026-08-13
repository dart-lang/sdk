// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This has historically crashed with target vm, but not target none.

mixin M {
  final c = 1;
  void set c(int _) {}
}

class MA = Object with M;

void hello() {
  MA().c = 42;
}
