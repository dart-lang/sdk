// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that we don't leave in binary int operations that do not throw and
// have a calculated range of a single value, but instead replace the operation
// with that constant value.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testUnsignedTruncatingDivision(Iterable i) => i.length ~/ 32;

void matchIL$testUnsignedTruncatingDivision(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      if (is32BitConfiguration) ...[
        'c5' << match.UnboxedConstant(value: 5, representation: 'int32'),
      ] else ...[
        'c32' << match.UnboxedConstant(value: 32, representation: 'int64'),
      ],
    ]),
    match.block('Function', [
      'it' << match.Parameter(index: 0),
      'len' << match.LoadField('it', slot: 'GrowableObjectArray.length'),
      if (is32BitConfiguration) ...[
        // 32-bit architectures don't handle 64-bit truncated division natively.
        // However, for powers of two, the runtime call
        //   m ~/ 2^n
        // gets replaced with
        //   (m + ((m >> 63) & (2^n - 1))) >> n
        // which works for both signed and unsigned values.
        //
        // In this specific case, with m = len and 2^n = 32,
        //   (len + ((len >> 63) & 31)) >> 5
        // However, the numerator len has a non-negative range since it's
        // retrieved from the length slot of an Iterable. This means (len >> 63)
        // is guaranteed to be 0, and the compiler should simplify this to
        //   len >> 5
        'unboxed_len' << match.UnboxInt32('len'),
        'retval_32' << match.BinaryInt32Op('unboxed_len', 'c5', op_kind: '>>'),
        'retval' << match.IntConverter('retval_32', from: 'int32', to: 'int64'),
      ] else ...[
        // 64-bit architectures do handle 64-bit truncated division natively,
        // so it's just a single operation there.
        'unboxed_len' << match.UnboxInt64('len'),
        'retval' << match.BinaryInt64Op('unboxed_len', 'c32', op_kind: '~/'),
      ],
      match.Return('retval'),
    ]),
  ]);
}

void main(List<String> args) {
  final len = args.isEmpty ? 100 : int.parse(args.first);
  final list = List.generate(len, (i) => len - i);
  Expect.equals(len ~/ 32, testUnsignedTruncatingDivision(list));
}
