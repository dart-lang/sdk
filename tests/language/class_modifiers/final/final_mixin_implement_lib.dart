// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow final mixins to be implemented by multiple classes in the same library.

final mixin FinalMixin {
  int foo = 0;
}

abstract class A implements FinalMixin {}

class B implements FinalMixin {
  @override
  int foo = 1;
}
