// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Meta({})
import 'dart:core';

@Meta({})
void f(@Meta({}) int foo) {}

@Meta({})
class A<@Meta({}) T> {
  @Meta({})
  String x, y;

  @Meta({})
  A();

  @Meta({})
  void m() {
    @Meta({})
    int z;
  }
}

@Meta({})
enum E {
  @Meta({})
  v
}

class Meta {
  final Set<int> value;

  const Meta(this.value);
}

main() {}
