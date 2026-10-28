// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void topLevelMethod() {
  print('topLevelMethod');
}

class Class {
  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}

mixin class MixinClass {
  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}

mixin Mixin {
  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}

enum Enum {
  a;

  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}

extension Extension on int {
  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}

extension type ExtensionType(int it) {
  void instanceMethod() {
    print('instanceMethod');
  }

  static void staticMethod() {
    print('staticMethod');
  }
}
