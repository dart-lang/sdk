// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void topLevelMethod() {
  augment super();
  print('topLevelMethod augmentation 2');
  augment super();
}

augment class Class {
  augment void instanceMethod() {
    augment super();
    print('instanceMethod augmentation 2');
    augment super();
  }

  augment static void staticMethod() {
    augment super();
    print('staticMethod augmentation 2');
    augment super();
  }

  augment void externalInstanceMethod() {
    print('externalInstanceMethod augmentation 2');
  }
}