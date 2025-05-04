// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that dart:ffi Struct is erased whenever possible and all
// of accessors are inlined.

import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'package:vm/testing/il_matchers.dart';

final class S extends Struct {
  @Array<Uint8>(8)
  external Array<Uint8> magic;

  @Int64()
  external int f;

  @Int64()
  external int g;

  external InnerS inner;
}

final class InnerS extends Struct {
  @Int64()
  external int x;

  @Int64()
  external int y;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testAccessors1(S a, S b) {
  for (var i = 0; i < 8; i++) {
    a.magic[i] = b.magic[i];
  }
  a.f = b.inner.x;
  a.g = b.inner.y;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testAccessors2(Pointer<S> arrA, Pointer<S> arrB, int n) {
  for (var j = 0; j < n; j++) {
    final a = arrA[j];
    final b = arrB[j];
    for (var i = 0; i < 8; i++) {
      a.magic[i] = b.magic[i];
    }
    a.f = b.inner.x;
    a.g = b.inner.y;
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
S testCreation() {
  return Struct.create<S>();
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
S testCreation2(Uint8List list) {
  return Struct.create<S>(list);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testCreationAndUse(Uint8List list) {
  final s = Struct.create<S>(list);
  for (var i = 0; i < 8; i++) {
    s.magic[i] = i;
  }
  s.f = 1;
  s.g = 2;
  s.inner.x = 3;
  s.inner.y = 4;
}

void main() {
  final a = Struct.create<S>();
  final b = Struct.create<S>();
  testAccessors1(a, b);
  final arrN = 2;
  final arrA = calloc<S>(arrN);
  final arrB = calloc<S>(arrN);
  testAccessors2(arrA, arrB, arrN);
  calloc.free(arrA);
  calloc.free(arrB);
  testCreation();
  testCreation2(Uint8List(sizeOf<S>()));
  testCreationAndUse(Uint8List(sizeOf<S>()));
}

void _checkNoCallsInGraph(FlowGraph graph) {
  for (var block in graph.blocks()) {
    for (var instr in block['is']) {
      final op = instr['o'] as String;
      if (op.endsWith('Call') && instr['d'].first != 'new RangeError.range') {
        throw 'Found unexpected call: $instr';
      }
    }
  }
}

void _checkNoAllocationInGraph(FlowGraph graph) {
  for (var block in graph.blocks()) {
    for (var instr in block['is']) {
      final op = instr['o'] as String;
      if (op == 'AllocateObject') {
        if (instr['T']['c'] != 'RangeError') {
          throw 'Found unexpected object allocation';
        }
      }
    }
  }
}

void matchIL$testAccessors1(FlowGraph graph) {
  graph.dump();
  _checkNoCallsInGraph(graph);
  _checkNoAllocationInGraph(graph);
}

void matchIL$testAccessors2(FlowGraph graph) {
  graph.dump();
  _checkNoCallsInGraph(graph);
  _checkNoAllocationInGraph(graph);
}

void matchIL$testCreation(FlowGraph graph) {
  graph.dump();
  _checkNoCallsInGraph(graph);
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'S' << match.AllocateObject(),
      'td' << match.AllocateTypedData(),
      match.StoreField('S', 'td'),
      match.DartReturn('S'),
    ]),
  ]);
}

void matchIL$testCreation2(FlowGraph graph) {
  graph.dump();
  _checkNoCallsInGraph(graph);
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'td' << match.Parameter(index: 0),
      'S' << match.AllocateObject(),
      match.StoreField('S', 'td'),
    ]),
    match.block('Target', [
      'error' << match.AllocateObject(),
      match.Throw('error'),
    ]),
    match.block('Target', [match.DartReturn('S')]),
  ]);
}

void matchIL$testCreationAndUse(FlowGraph graph) {
  graph.dump();
  _checkNoCallsInGraph(graph);
  _checkNoAllocationInGraph(graph);
}
