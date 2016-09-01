// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib2;

import "deferred_mixin_shared.dart";

class A extends Object with SharedMixin {
  foo() {
    return "lib2.A with " + super.foo();
  }
}