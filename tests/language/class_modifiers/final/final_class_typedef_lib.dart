// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

final class FinalClass {
  int foo = 0;
}

typedef FinalClassTypeDef = FinalClass;

class A extends FinalClassTypeDef {}

class B implements FinalClassTypeDef {
  @override
  int foo = 1;
}
