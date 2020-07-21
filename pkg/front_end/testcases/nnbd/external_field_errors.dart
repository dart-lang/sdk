// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

external int topLevelField = 0;

external final int finalTopLevelField = 0;

external const int constField = 0;

abstract class A {
  external int fieldWithInitializer = 0;

  external int initializedField1;

  external int initializedField2;

  A(this.initializedField1) : this.initializedField2 = 0;

  external static int staticField = 0;

  external static final int finalStaticField = 0;
}

mixin B {
  external static int staticField = 0;

  external static final int finalStaticField = 0;
}

extension Extension on A {
  external int extensionInstanceField = 0;
  external final int finalExtensionInstanceField = 0;
  external static int extensionStaticField = 0;
  external static final int finalExtensionStaticField = 0;
}

main() {}
