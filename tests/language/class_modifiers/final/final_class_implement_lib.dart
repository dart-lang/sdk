// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow final classes to be implemented in the same library.

final class FinalClass {
  int foo = 0;
}

final class ClassForEnum {}

abstract final class A implements FinalClass {}

final class AImpl implements A {
  int foo = 1;
}

final class B implements FinalClass {
  int foo = 1;
}

enum EnumInside implements ClassForEnum { x }
