// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void foo<T extends num>(T x) {}
void bar<T extends num>(num x) {}

typedef F = Function<T extends num>(T x);

void main() {
  Expect.isTrue(foo is F);
  Expect.isTrue(bar is F);
}
