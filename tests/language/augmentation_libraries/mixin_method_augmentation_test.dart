// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import augment 'mixin_method_augmentation.dart';

class C with M {}

mixin M {
  int answer();
}

void main() {
  Expect.equals(7, C().answer());
}
