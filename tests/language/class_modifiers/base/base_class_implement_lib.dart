// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base classes to be implemented by multiple classes in the same library.

base class BaseClass {
  int foo = 0;
}

base class ClassForEnum {}

abstract base class A implements BaseClass {}

base class AImpl implements A {
  int foo = 1;
}

base class B implements BaseClass {
  int foo = 1;
}

enum EnumInside implements ClassForEnum { x }
