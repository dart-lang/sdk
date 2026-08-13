// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base classes to be extended by multiple classes in the same library.

base class BaseClass {
  int foo = 0;
}

abstract base class A extends BaseClass {}

base class B extends BaseClass {}
