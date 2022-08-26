// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment class Class1 {
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
  augment static void staticAugmentedMethod() {
    print('staticAugmentedMethod');
  }
  static void staticExistingMethod() {
    print('staticExistingMethod-duplicate');
  }
  static void staticInjectedMethod() {
    print('staticInjectedMethod');
  }
  augment static void staticOrphanedMethod() {
    print('staticOrphanedMethod');
  }
  augment static void set staticAugmentedSetter(_) {
    print('staticAugmentedSetter');
  }
  static void set staticExistingSetter(_) {
    print('staticExistingSetter-duplicate');
  }
  static void set staticInjectedSetter(_) {
    print('staticInjectedSetter');
  }
  augment static void set staticOrphanedSetter(_) {
    print('staticOrphanedSetter');
  }
}

augment class Class2 {
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
  augment static void staticAugmentedMethod() {
    print('staticAugmentedMethod');
  }
  static void staticExistingMethod() {
    print('staticExistingMethod-duplicate');
  }
  static void staticInjectedMethod() {
    print('staticInjectedMethod');
  }
  augment static void staticOrphanedMethod() {
    print('staticOrphanedMethod');
  }
  augment static void set staticAugmentedSetter(_) {
    print('staticAugmentedSetter');
  }
  static void set staticExistingSetter(_) {
    print('staticExistingSetter-duplicate');
  }
  static void set staticInjectedSetter(_) {
    print('staticInjectedSetter');
  }
  augment static void set staticOrphanedSetter(_) {
    print('staticOrphanedSetter');
  }
}

void augmentTest(Class1 c1, Class2 c2) {
  c1.orphanedMethod();
  c1.orphanedSetter = 0;
  c2.orphanedMethod();
  c2.orphanedSetter = 0;
  Class1.staticOrphanedMethod();
  Class1.staticOrphanedSetter = 0;
  Class2.staticOrphanedMethod();
  Class2.staticOrphanedSetter = 0;
}

void injectedMethod(Class1 c1, Class2 c2) {
  c1.augmentedMethod();
  c1.injectedMethod();
  c1.existingMethod();
  Class1.staticAugmentedMethod();
  Class1.staticInjectedMethod();
  Class1.staticExistingMethod();

  c1.augmentedSetter = 0;
  c1.injectedSetter = 0;
  c1.existingSetter = 0;
  Class1.staticAugmentedSetter = 0;
  Class1.staticInjectedSetter = 0;
  Class1.staticExistingSetter = 0;

  c2.augmentedMethod();
  c2.injectedMethod();
  c2.existingMethod();
  Class2.staticAugmentedMethod();
  Class2.staticInjectedMethod();
  Class2.staticExistingMethod();

  c2.augmentedSetter = 0;
  c2.injectedSetter = 0;
  c2.existingSetter = 0;
  Class2.staticAugmentedSetter = 0;
  Class2.staticInjectedSetter = 0;
  Class2.staticExistingSetter = 0;
}