// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'library_members_lib.dart';

void existingMethod() {
  print('existingMethod-origin');
}

external void augmentedMethod();

void set existingSetter(_) {
  print('existingSetter-origin');
}

external void set augmentedSetter(_);

class ExistingClass {}
class AugmentedClass {}

class existingMethod2 {}
void ExistingClass2() {}

test() {
  orphanedMethod();
  orphanedSetter = 0;
  new OrphanedClass();
}

main() {
  augmentedMethod();
  injectedMethod();
  existingMethod();
  ExistingClass2();

  augmentedSetter = 0;
  injectedSetter = 0;
  existingSetter = 0;

  new ExistingClass();
  new AugmentedClass();
  new InjectedClass();
  new existingMethod2();

  augmentMain();
}
