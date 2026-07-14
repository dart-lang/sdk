// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Thing {
  int value = 0;
}

bool get alwaysTrue => DateTime.now().millisecondsSinceEpoch > 42;

void test1() {
  final t1 = Thing();
  final t2 = Thing();
  final t3 = alwaysTrue ? t1 : t2;
  t3.value++;

  Expect.equals('[1, 0, 1]', [t1.value, t2.value, t3.value].toString());
}

void test2() {
  final t1 = Thing();
  final t2 = Thing();
  final t3 = alwaysTrue ? t1 : t2;
  escape(t3);

  Expect.equals('[1, 0, 1]', [t1.value, t2.value, t3.value].toString());
}

@pragma('dart2js:never-inline')
void escape(Thing thing) {
  thing.value++;
}

void main() {
  for (final test in [test1, test2]) {
    test();
  }
}
