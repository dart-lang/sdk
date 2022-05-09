// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment class Class {
  augment void augmentedMethod() {
    print('augmentedMethod');
  }
  void existingMethod() {
    print('existingMethod-duplicate');
  }
  void injectedMethod() {
    print('injectedMethod');
  }
  augment void orphanedMethod() {
    print('orphanedMethod');
  }
  augment void set augmentedSetter(_) {
    print('augmentedSetter');
  }
  void set existingSetter(_) {
    print('existingSetter-duplicate');
  }
  void set injectedSetter(_) {
    print('injectedSetter');
  }
  augment void set orphanedSetter(_) {
    print('orphanedSetter');
  }
}

void augmentTest(Class c) {
  c.orphanedMethod();
  c.orphanedMethod();
  c.orphanedSetter = 0;
}

void injectedMethod(Class c) {
  c.augmentedMethod();
  c.injectedMethod();
  c.existingMethod();

  c.augmentedSetter = 0;
  c.injectedSetter = 0;
  c.existingSetter = 0;
}