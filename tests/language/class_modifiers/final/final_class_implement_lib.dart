// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow final classes to be implemented in the same library.

final class FinalClass {
  int foo = 0;
}

abstract class A implements FinalClass {}

class B implements FinalClass {
  @override
  int foo = 1;
}
