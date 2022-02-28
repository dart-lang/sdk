// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'class_members_lib.dart';

class Class {
  void existingMethod() {
    print('existingMethod-origin');
  }

  external void augmentedMethod();

  void set existingSetter(_) {
    print('existingSetter-origin');
  }

  external void set augmentedSetter(_);
}

test(Class c) {
  c.orphanedMethod();
  c.orphanedSetter = 0;
}

main() {
  Class c = new Class();
  c.augmentedMethod();
  c.injectedMethod();
  c.existingMethod();

  c.augmentedSetter = 0;
  c.injectedSetter = 0;
  c.existingSetter = 0;

  injectedMethod(c);
}