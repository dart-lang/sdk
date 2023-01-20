// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow interface classes to be extended by multiple classes in the same
// library.

interface class InterfaceClass {
  int foo = 0;
}

abstract class A extends InterfaceClass {}

class B extends InterfaceClass {}
