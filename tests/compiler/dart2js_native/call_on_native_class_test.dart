// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_helper';

@Native('*A')
class A {
}

class B extends A {
  call() => 42;
}

main() {
  new B()();
}
