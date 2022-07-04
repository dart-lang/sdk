// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void topLevelMethod() {
  augment super();
  print('topLevelMethod augmentation 1');
  augment super();
}

augment void externalTopLevelMethod() {
  print('externalTopLevelMethod augmentation 1');
}

augment class Class {
  augment void instanceMethod() {
    augment super();
    print('instanceMethod augmentation 1');
    augment super();
  }

  augment static void staticMethod() {
    augment super();
    print('staticMethod augmentation 1');
    augment super();
  }
}