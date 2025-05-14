// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that TFA does not remove a field initializer of a late final
// field with initializer as that would add an extra implicit setter.
// Regression test for b/404559785.

class Foo {
  int v;
  Foo(this.v);

  @pragma('vm:entry-point')
  late final int hashCode = int.parse('1');
}

void main() {
  print(Foo);
}
