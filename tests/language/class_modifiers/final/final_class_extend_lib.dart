// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow final classes to be extended by multiple classes in the same
// library.

final class FinalClass {
  int foo = 0;
}

abstract final class A extends FinalClass {}

final class AImpl extends A {}

final class B extends FinalClass {}
