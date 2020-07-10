// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef String IntFunctionType(int _);

class Box {
  final IntFunctionType fun;
  const Box(this.fun);
}

String genericFunction<T>(T v) => '$v';

void main() {
  const list = const [const Box(genericFunction)];
  Expect.equals('42', list.first.fun(42));
}
