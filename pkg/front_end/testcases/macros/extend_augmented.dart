// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'extend_augmented_lib.dart';

class Class {
  void augmentedMethod() {}
}

class Subclass implements Class {
  void augmentedMethod() {}
}

main() {
  new Class().augmentedMethod();
  new Subclass().augmentedMethod();
}