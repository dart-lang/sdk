// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;
import 'token_leak_test_helper.dart' as self;

core.String field = '';

void main() {
  core.String value = field;
  method(value);
}

@annotation
void method(@annotation core.String value) {
  core.print(value);
  void local(@annotation int i) {}
  local(0);
}

const annotation = const Object();

class Class {
  Class();
  Class.named();
  factory Class.fact1() = Class;
  factory Class.fact2() = Class.named;
  factory Class.fact3() = self.Class;
  factory Class.fact4() = self.Class.named;
}

enum E {
  a(0),
  b(1),
  ;

  final int value;

  const E(this.value);
}
