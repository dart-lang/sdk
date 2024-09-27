// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:typed_data';

// This test checks that AOT compiler tries to keep loop blocks together and
// sinks cold code to the end of the function.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph', 'ReorderBlocks')
int loop(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    if (list[i] == 1) {
      return i;
    }
  }
  return -1;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph', 'ReorderBlocks')
int loop2(Uint8List list) {
  int sum = 0;
  for (var i = 0; i < list.length; i++) {
    for (var j = 0; j < list.length; j++) {
      if (list[j] == 1) {
        break;
      }
      sum += list[j];
    }
  }
  return sum;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph', 'ReorderBlocks')
int bodyAlwaysThrows(Uint8List list) {
  try {
    throw 'Yay';
  } catch (e) {
    return list.length;
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph', 'ReorderBlocks')
int throwInALoop(Uint8List list) {
  for (var i = 0; i < list.length; i++) {
    if (list[i] == 1) {
      return i;
    }
    if (list[i] == 2) {
      throw 'Unexpected value';
    }
  }
  return -1;
}

void main(List<String> args) {
  final input = args.contains('foo')
      ? (Uint8List(10)..[5] = 1)
      : (Uint8List(100)..[50] = 1);

  Expect.equals(50, loop(input));
  Expect.equals(0, loop2(input));
  Expect.equals(100, bodyAlwaysThrows(input));
  Expect.equals(50, throwInALoop(input));
}

void matchIL$loop(FlowGraph graph) {
  graph.match(inCodegenBlockOrder: true, [
    match.block('Graph'),
    match.block('Function', [
      match.Goto('loop_header'),
    ]),
    'loop_header' <<
        match.block('Join', [
          match.Branch(match.any, ifTrue: 'loop_body'),
        ]),
    'loop_body' <<
        match.block('Target', [
          match.Branch(match.any, ifFalse: 'loop_inc'),
        ]),
    'loop_inc' <<
        match.block('Target', [
          match.Goto('loop_header'),
        ]),
  ]);
}

void matchIL$loop2(FlowGraph graph) {
  graph.match(inCodegenBlockOrder: true, [
    match.block('Graph'),
    match.block('Function', [
      match.Goto('loop_header_1'),
    ]),
    'loop_header_1' <<
        match.block('Join', [
          match.Branch(match.any, ifTrue: 'loop_body_1'),
        ]),
    'loop_body_1' <<
        match.block('Target', [
          match.Goto('loop_header_2'),
        ]),
    'loop_header_2' <<
        match.block('Join', [
          match.Branch(match.any,
              ifTrue: 'loop_body_2', ifFalse: 'loop_body_2_exit_1'),
        ]),
    'loop_body_2' <<
        match.block('Target', [
          match.Branch(match.any,
              ifTrue: 'loop_body_2_exit_2', ifFalse: 'loop_inc_2'),
        ]),
    'loop_inc_2' <<
        match.block('Target', [
          match.Goto('loop_header_2'),
        ]),
    'loop_body_2_exit_2' <<
        match.block('Target', [
          match.Goto('loop_inc_1'),
        ]),
    'loop_body_2_exit_1' <<
        match.block('Target', [
          match.Goto('loop_inc_1'),
        ]),
    'loop_inc_1' <<
        match.block('Join', [
          match.Goto('loop_header_1'),
        ]),
  ]);
}

void matchIL$bodyAlwaysThrows(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function'),
    match.block('CatchBlock'),
    match.block('Join'),
  ], inCodegenBlockOrder: true);
}

void matchIL$throwInALoop(FlowGraph graph) {
  graph.match(inCodegenBlockOrder: true, [
    match.block('Graph'),
    match.block('Function', [
      match.Goto('loop_header'),
    ]),
    'loop_header' <<
        match.block('Join', [
          'i' << match.Phi(match.any, 'inc_i'),
          match.Branch(match.any, ifTrue: 'loop_body', ifFalse: 'return_fail'),
        ]),
    'loop_body' <<
        match.block('Target', [
          match.Branch(match.any,
              ifTrue: 'return_found', ifFalse: 'loop_body_cont'),
        ]),
    'loop_body_cont' <<
        match.block('Target', [
          match.Branch(match.any, ifTrue: 'throw', ifFalse: 'loop_inc'),
        ]),
    'loop_inc' <<
        match.block('Target', [
          if (is32BitConfiguration) ...[
            'i_32' << match.IntConverter('i', from: 'int64', to: 'int32'),
            'inc_i_32' << match.BinaryInt32Op('i_32', match.any),
            'inc_i' <<
                match.IntConverter('inc_i_32', from: 'int32', to: 'int64'),
          ] else ...[
            'inc_i' << match.BinaryInt64Op('i', match.any),
          ],
          match.Goto('loop_header'),
        ]),
    'return_found' <<
        match.block('Target', [
          match.DartReturn('i'),
        ]),
    'return_fail' <<
        match.block('Target', [
          match.DartReturn(match.any),
        ]),
    'throw' <<
        match.block('Target', [
          match.Throw(match.any),
        ]),
  ]);
}
