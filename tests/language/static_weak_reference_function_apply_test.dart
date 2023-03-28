// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test 'weak-tearoff-reference' pragma on tear-offs,
// which results are passed to Function.apply.

import "package:expect/expect.dart";

typedef FF = int Function({int x, int y});

typedef GG = FF Function();

@pragma('weak-tearoff-reference')
GG? weakRef(GG? x) => x;

FF foo1() => ({int x = 100, int y = 10}) => 1000 + x + y;
FF foo2() => ({int x = 200, int y = 20}) => 2000 + x + y;
FF foo3() => ({int x = 300, int y = 30}) => 3000 + x + y;

main() {
  print(foo1()());
  print(foo2()());
  // No call to foo3(), should be removed.

  final f1 = foo1;
  Expect.isNotNull(f1);
  Expect.equals(101010, Function.apply(f1(), [], {#x: 100000}));

  final f2 = weakRef(foo2);
  Expect.isNotNull(f2);
  Expect.equals(202020, Function.apply(f2!(), [], {#x: 200000}));

  final f3 = weakRef(foo3);
  Expect.isNull(f3);
  if (f3 != null) print(Function.apply(f3(), [], {#x: 300000}));
}
