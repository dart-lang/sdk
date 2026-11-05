// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for register allocator crash on 32-bit architectures when an
// unboxed 64-bit integer (pair representation) is only used inside a
// MaterializeObject instruction across basic blocks (e.g. a sunk ListIterator's
// _length field across an await).

@pragma('vm:never-inline')
Future<void> asyncNoop() async {}

@pragma('vm:never-inline')
Future<void> test(List<String> input) async {
  final list = <String>[input.first];
  for (final x in input) {
    list.add(x);
  }
  for (final _ in list) {
    await asyncNoop();
  }
}

Future<void> main() async {
  await test(['a', 'b']);
}
