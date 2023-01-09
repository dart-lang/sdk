// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow base classes to be implemented by multiple classes in the same library.

base class BaseClass {
  int foo = 0;
}

abstract class A implements BaseClass {}

class B implements BaseClass {
  @override
  int foo = 1;
}
