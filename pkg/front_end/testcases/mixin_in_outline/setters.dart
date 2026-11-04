// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void set topLevelSetter(int value) {
  print('topLevelSetter');
}

class Class {
  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}

mixin class MixinClass {
  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}

mixin Mixin {
  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}

enum Enum {
  a;

  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}

extension Extension on int {
  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}

extension type ExtensionType(int it) {
  void set instanceSetter(int value) {
    print('instanceSetter');
  }

  static void set staticSetter(int value) {
    print('staticSetter');
  }
}
