// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

var global = 0;

class A {
  A() {
    global += 10;
    try {} catch(e) {} // no inline
  }
}
