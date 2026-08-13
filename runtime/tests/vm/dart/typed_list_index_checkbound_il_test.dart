// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that we perform any necessary bounds checking in typed data
// indexing methods using GenericCheckBound instead of branching Dart code.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int retrieveFromView(Int8List src, int n) => src[n];

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int retrieveFromInternal(Int8List src, int n) => src[n];

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int retrieveFromExternal(Int8List src, int n) => src[n];

void matchILRetrieveFromNonInternal(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'src' << match.Parameter(index: 0),
      'n' << match.Parameter(index: 1),
      'len' << match.LoadField('src', slot: 'TypedDataBase.length'),
      if (is32BitConfiguration) ...[
        'boxed_n' << match.BoxInt64('n'),
        match.GenericCheckBound('len', 'boxed_n'),
      ] else ...[
        'unboxed_len' << match.UnboxInt64('len'),
        match.GenericCheckBound('unboxed_len', 'n'),
      ],
      'data' << match.LoadField('src', slot: 'PointerBase.data'),
      if (is32BitConfiguration) ...[
        'retval32' << match.LoadIndexed('data', 'boxed_n'),
        'retval' << match.IntConverter('retval32', from: 'int32', to: 'int64'),
      ] else ...[
        'retval' << match.LoadIndexed('data', 'n'),
      ],
      match.DartReturn('retval'),
    ]),
  ]);
}

void matchIL$retrieveFromView(FlowGraph graph) {
  matchILRetrieveFromNonInternal(graph);
}

void matchIL$retrieveFromExternal(FlowGraph graph) {
  matchILRetrieveFromNonInternal(graph);
}

void matchIL$retrieveFromInternal(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'src' << match.Parameter(index: 0),
      'n' << match.Parameter(index: 1),
      'len' << match.LoadField('src', slot: 'TypedDataBase.length'),
      if (is32BitConfiguration) ...[
        'boxed_n' << match.BoxInt64('n'),
        match.GenericCheckBound('len', 'boxed_n'),
        'retval32' << match.LoadIndexed('src', 'boxed_n'),
        'retval' << match.IntConverter('retval32', from: 'int32', to: 'int64'),
      ] else ...[
        'unboxed_len' << match.UnboxInt64('len'),
        match.GenericCheckBound('unboxed_len', 'n'),
        'retval' << match.LoadIndexed('src', 'n'),
      ],
      match.DartReturn('retval'),
    ]),
  ]);
}

void main(List<String> args) {
  final n = args.isEmpty ? 0 : int.parse(args.first);
  final list = Int8List.fromList([1, 2, 3, 4]);
  print(retrieveFromInternal(list, n));
  print(retrieveFromView(Int8List.sublistView(list), n));
  if (!isSimulator) {
    using((arena) {
      final p = arena.allocate<Int8>(list.length);
      final external = p.asTypedList(list.length);
      external.setRange(0, list.length, list);
      print(retrieveFromExternal(external, n));
    });
  }
}
