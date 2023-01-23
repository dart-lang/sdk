// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'class_members.dart';

class Class2 {
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
