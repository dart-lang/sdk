// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow interface classes to be implemented by multiple classes in the same
// library.

interface class InterfaceClass {
  int foo = 0;
}

interface class ClassForEnum {}

abstract class A implements InterfaceClass {}

class B implements InterfaceClass {
  int foo = 1;
}

enum EnumInside implements ClassForEnum { x }
