// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'library_members.dart';

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
