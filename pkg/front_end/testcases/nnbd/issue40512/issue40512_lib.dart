// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6
library baz2;

mixin A {
  String toString({String s = "hello"}) => s;
}

class B extends Object {}
