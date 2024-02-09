// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that CreateArray has a proper type (with type arguments) attached
// to it.

import 'dart:async';
import 'package:vm/testing/il_matchers.dart';

final class A {}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void createAndIterate() {
  final List<Object?> array = List<A>.filled(100, A());
  for (var e in array) {
    e as A;
  }
}

void main() async {
  createAndIterate();
}

void matchIL$createAndIterate(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.CreateArray(T: match.CompileType(type: '_List<A>')),
    ]),
    match.block('Join'),
    match.block('Target'),
    match.block('Target'),
    'loop' <<
        match.block(
            'Join',
            // We want to make sure that `e as A` and all iterator
            // related code was entirely eliminated - thus no wildcards
            // when matching.
            [
              'i' << match.Phi('i+1', match.any),
              match.CheckStackOverflow(),
              match.Branch(match.RelationalOp(match.any, match.any, kind: '>='),
                  ifTrue: 'loop_exit', ifFalse: 'loop_body'),
            ].withoutWildcards),
    'loop_exit' <<
        match.block('Target', [
          match.Return(match.any),
        ]),
    'loop_body' <<
        match.block(
            'Target',
            // We want to make sure that `e as A` and all iterator
            // related code was entirely eliminated - thus no wildcards
            // when matching.
            [
              'i+1' << match.BinaryInt64Op('i', match.any),
              match.Goto('loop'),
            ].withoutWildcards),
  ]);
}
