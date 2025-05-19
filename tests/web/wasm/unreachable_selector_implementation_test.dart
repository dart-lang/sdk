// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  final l = <Base>[Sub1(), Sub2()];
  for (final x in l) print(x.foo());
  print(Sub3);
}

abstract class Base {
  String foo();
}

class Sub1 extends Base {
  String foo() => 'Sub1.foo()';
}

class Sub2 extends Base {
  String foo() => 'Sub2.foo()';
}

// This class is never allocated, TFA will make it abstract.
class Sub3 extends Base {
  // This member is not callable (since the class is never allocated) but the
  // entrypoint annotation keps it alive. TFA will mark it as abstract and
  // set the `VariableDeclaration.initializer` of `a` to `null`.
  //
  // We should not take this member into account when creatin dispatch table
  // selector parameter info or signature.
  @pragma('wasm:entry-point')
  String foo({int a = 4}) => 'Sub3.foo($a)';
}
