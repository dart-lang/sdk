// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void augmentedTopLevelMethod() {
  print('augmentedTopLevelMethod#1');
}

augment void augmentedTopLevelMethod() {
  print('augmentedTopLevelMethod#2');
}

augment class AugmentedClass {
  augment void augmentedInstanceMethod() {
    print('augmentedInstanceMethod#1');
  }
  augment static void augmentedStaticMethod() {
    print('augmentedStaticMethod#1');
  }
}

augment class AugmentedClass {
  augment void augmentedInstanceMethod() {
    print('augmentedInstanceMethod#2');
  }
  augment static void augmentedStaticMethod() {
    print('augmentedStaticMethod#2');
  }
}