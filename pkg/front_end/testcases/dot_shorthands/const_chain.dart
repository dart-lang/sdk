// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  final int x;
  C get field => C(1);
  C(this.x);
  const C.constNamed(this.x);
  C method() => C(1);
}

void main() {
  C field = const .constNamed(1).field;
  C method = const .constNamed(1).method();
}
