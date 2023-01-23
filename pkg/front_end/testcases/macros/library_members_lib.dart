// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment void augmentedMethod() {
  print('augmentedMethod');
}
void existingMethod() {
  print('existingMethod-duplicate');
}
void existingMethod2() {
  print('existingMethod2-duplicate');
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

class ExistingClass {}
class ExistingClass2 {}
augment class AugmentedClass {}
class InjectedClass {}
augment class OrphanedClass {}

void augmentTest() {
  orphanedMethod();
  orphanedMethod();
  orphanedSetter = 0;
  new OrphanedClass();
}

void augmentMain() {
  augmentedMethod();
  injectedMethod();
  existingMethod();

  augmentedSetter = 0;
  injectedSetter = 0;
  existingSetter = 0;

  new ExistingClass();
  new AugmentedClass();
  new InjectedClass();
}