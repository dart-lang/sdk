// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void topLevelMethod() {
  print('topLevelMethod augmentation 2');
}

augment class Class {
  augment void instanceMethod() {
    print('instanceMethod augmentation 2');
  }

  augment static void staticMethod() {
    print('staticMethod augmentation 2');
  }

  augment void externalInstanceMethod() {
    print('externalInstanceMethod augmentation 2');
  }
}