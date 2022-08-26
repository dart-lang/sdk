// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'augment_concrete_lib1.dart';
import augment 'augment_concrete_lib2.dart';

void topLevelMethod() {
  print('topLevelMethod original');
}

external void externalTopLevelMethod();

class Class {
  void instanceMethod() {
    print('instanceMethod original');
  }

  static void staticMethod() {
    print('staticMethod original');
  }

  external void externalInstanceMethod();
}

main() {
  topLevelMethod();
  new Class().instanceMethod();
  Class.staticMethod();
  externalTopLevelMethod();
  new Class().externalInstanceMethod();
}