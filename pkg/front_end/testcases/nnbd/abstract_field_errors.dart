// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract int topLevelField;

abstract final int finalTopLevelField = 0;

abstract const int constField = 0;

abstract class A {
  abstract int fieldWithInitializer = 0;

  abstract int initializedField1;

  abstract int initializedField2;

  A(this.initializedField1) : this.initializedField2 = 0;

  abstract static int staticField;

  abstract static final int finalStaticField;

  abstract late int lateInstanceField;

  external abstract int externalInstanceField;

  external abstract final int externalFinalInstanceField;

  external abstract covariant num externalCovariantInstanceField;

  abstract external int externalInstanceField;

  abstract external final int externalFinalInstanceField;

  abstract external covariant num externalCovariantInstanceField;

  external abstract late int externalLateInstanceField;
}

mixin B {
  abstract static int staticField;

  abstract static final int finalStaticField;

  external abstract int externalInstanceField;

  external abstract final int externalFinalInstanceField;

  external abstract covariant num externalCovariantInstanceField;

}

extension Extension on A {
  abstract int extensionInstanceField;
  abstract final int finalExtensionInstanceField;
  abstract static int extensionStaticField;
  abstract static final int finalExtensionStaticField;
}

main() {}
