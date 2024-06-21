// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F = void Function<_, _ extends int, _>();

void fn(void Function<_, _>() x) {}
void fn1<_, _ extends int>(void Function<_, _>() x) {}

test() {
  void foo1(void Function<_, _ extends int>() x) {}
  void foo2<_, _ extends int>() {}
  void foo3(F x) {}
}
