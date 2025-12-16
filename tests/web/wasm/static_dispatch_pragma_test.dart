// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  final list = <Base>[A1(), A2()];
  for (final entry in list) {
    // The polymorphic dispatcher for `doit()` will be inlined as there's only
    // one method marked with `@pragma('wasm:static-dispatch')`.
    //
    // This inlining used to trigger a bug, this is a regression test for
    // this bug.
    entry.doit();
  }
}

class Base {
  void doit() {
    print('Base.doit()');
  }
}

class A1 extends Base {
  void doit() {
    print('A1.doit()');
  }
}

class A2 extends Base {
  @pragma('wasm:static-dispatch')
  void doit() {
    print('A2.doit()');
  }
}
