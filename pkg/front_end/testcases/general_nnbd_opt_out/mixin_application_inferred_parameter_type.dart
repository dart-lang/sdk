// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Mixin {}

class Super {
  var field = 42;

  Super(this.field);
}

class Class = Super with Mixin;

main() {
  new Class(0);
}

error() {
  new Class('');
}
