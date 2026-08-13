// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M {
  int foo() => 42;
}

class Base {}

class C1 extends Base with M {}

class C2 extends Base with M {}
