// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'class_members_lib.dart';

part 'class_members_part.dart';

class Class1 {
  void existingMethod() {
    print('existingMethod-origin');
  }

  external void augmentedMethod();

  void set existingSetter(_) {
    print('existingSetter-origin');
  }

  external void set augmentedSetter(_);

  static void staticExistingMethod() {
    print('staticExistingMethod-origin');
  }

  external static void staticAugmentedMethod();

  static void set staticExistingSetter(_) {
    print('staticExistingSetter-origin');
  }

  external static void set staticAugmentedSetter(_);
}

test(Class1 c1, Class2 c2) {
  c1.orphanedMethod();
  c1.orphanedSetter = 0;
  c2.orphanedMethod();
  c2.orphanedSetter = 0;
  Class1.staticOrphanedMethod();
  Class1.staticOrphanedSetter = 0;
  Class2.staticOrphanedMethod();
  Class2.staticOrphanedSetter = 0;
}

main() {
  Class1 c1 = new Class1();
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

  Class2 c2 = new Class2();
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

  injectedMethod(c1, c2);
}