// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

@pragma('vm:never-inline')
int foo(Uint8List list) {
  var result = 0;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:align-loops')
int alignedFunction1(Uint8List list) {
  var result = 0;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  return result;
}

@pragma('vm:never-inline')
int baz(Uint8List list) {
  var result = 1;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:align-loops')
int alignedFunction2(Uint8List list) {
  var result = 2;
  for (var i = 0; i < list.length; i++) {
    result ^= list[i];
  }
  return result;
}

@pragma('vm:never-inline')
int benchmark(String name, int Function(Uint8List) f, Uint8List list) {
  final sw = Stopwatch()..start();
  int result = 0;
  int n = 0;
  while (sw.elapsedMilliseconds < 2000) {
    result ^= f(list);
    n++;
  }
  print('$name: ${sw.elapsedMilliseconds / n}');
  return result;
}

void main() {
  final v = Uint8List(1024 * 1024 * 10);
  // Note: we don't use tear-offs for alignedFunctionX because that would
  // lead to two symbols both called alignedFunctionX in the resulting ELF:
  // one for tear-off and one for the actual function. This would make it
  // harder to verify that alignedFunction1 itself is correctly aligned.
  benchmark('foo', foo, v);
  benchmark('alignedFunction1', (list) => alignedFunction1(list), v);
  benchmark('baz', baz, v);
  benchmark('alignedFunction2', (list) => alignedFunction2(list), v);
}
