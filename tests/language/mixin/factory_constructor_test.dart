// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Base {
  var y;
  Base._() {
    y = "world";
  }
}

abstract class Mixin implements Base {
  final x = "hello";
  factory Mixin() => new _MixinAndBase._();
}

// TODO(jmesserly): according to the spec, this does not appear to be a valid
// mixin (because it declares a constructor), however it is supported by Dart
// implementations.
class _MixinAndBase = Base with Mixin;

void main() {
  var val = new Mixin();
  Expect.equals(val.x, "hello");
  Expect.equals(val.y, "world");
}
