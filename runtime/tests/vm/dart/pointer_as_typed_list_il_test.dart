// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that we don't generate intermediate external TypedData views when
// using setRange to copy between Pointers.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void copyPointerContents(Pointer<Uint8>? dest, Pointer<Uint8>? src, int n) {
  if (dest == null || src == null) return;
  dest.asTypedList(n).setRange(0, n, src.asTypedList(n));
}

void matchIL$copyPointerContents(FlowGraph graph) {
  graph.dump();
  // Since we only call it with n == 100, the third argument will get optimized
  // away. The element_size starts as 1, but canonicalization will turn it into
  // 4, the length to 100 / 4 == 25, and the starting offsets to 0 / 4 == 0.
  //
  // We could change the definition of n in main to:
  //
  //  final n = args.isEmpty ? 100 : int.parse(args.first);
  //
  // but then we'd have to wade through the generated bounds checks here.
  graph.match([
    match.block('Graph', [
      'cnull' << match.Constant(value: null),
      'c0' << match.Constant(value: 0),
      'c25' << match.Constant(value: 25),
    ]),
    match.block('Function', [
      'dest' << match.Parameter(index: 0),
      'src' << match.Parameter(index: 1),
      match.Branch(match.StrictCompare('dest', 'cnull'),
          ifTrue: 'B4', ifFalse: 'B96'),
    ]),
    'B4' <<
        match.block('Target', [
          match.Return('cnull'),
        ]),
    'B96' <<
        match.block('Target', [
          'dest.data' << match.LoadField('dest', slot: 'PointerBase.data'),
          'src.data' << match.LoadField('src', slot: 'PointerBase.data'),
          match.MemoryCopy('src.data', 'dest.data', 'c0', 'c0', 'c25',
              element_size: 4),
          match.Return('cnull'),
        ]),
  ]);
}

void main(List<String> args) {
  final n = 100;
  if (isSimulator) {
    // malloc/calloc aren't defined for simulators, so pass null instead.
    copyPointerContents(null, null, n);
  } else {
    using((arena) {
      final src = arena.allocate<Uint8>(n);
      for (int i = 0; i < n; i++) {
        src[i] = n - i;
      }
      final dest = arena.allocate<Uint8>(n);
      copyPointerContents(dest, src, n);
      Expect.listEquals(src.asTypedList(n), dest.asTypedList(n));
    });
  }
}
