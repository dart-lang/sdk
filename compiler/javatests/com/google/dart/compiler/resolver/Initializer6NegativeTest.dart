// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that in a class without a supertype referencing super in the initializer expression is an
// error.

class A {
  A() : super(1) {}
}
