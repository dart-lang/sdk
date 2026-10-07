// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T tearOffGeneric<T>(T x) => x;
int tearOffNonGeneric(int x) => x * 2;

class Box {
  final int Function(int) contents;
  const Box(this.contents);

  @pragma("vm:never-inline")
  int Function(int) get contentsNoInline => contents;
}

const Box boxGeneric = const Box(tearOffGeneric);
const Box boxNonGeneric = const Box(tearOffNonGeneric);

main() {
  if (boxGeneric.contents(42) != 42) throw "Fail1";
  if (boxNonGeneric.contents(42) != 84) throw "Fail2";
}
