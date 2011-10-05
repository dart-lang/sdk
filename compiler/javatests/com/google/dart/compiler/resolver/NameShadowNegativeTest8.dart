// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// expect failure - setter shadows another setter.

class A {
  set foo(x) { }
  get foo() { }
  set foo(x) { }
}
