// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionType(int it) {
  ExtensionType.named(int it) : it = it + 1;
  ExtensionType.redirectingGenerative(int it) : this(it + 2);
  factory ExtensionType.fact(int it) => ExtensionType(it + 3);
  factory ExtensionType.redirectingFactory(int it) = ExtensionType.new;
  static int staticField = 123;
  int instanceMethod() => it;
  int operator +(int i) => it + i;
  int get instanceGetter => it;
  void set instanceSetter(int value) {}
  static int staticMethod() => 87;
  static int get staticGetter => staticField;
  static void set staticSetter(int value) {
    staticField = value;
  }
}