// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int and(int x) {
  return x & x;
}

void matchIL$and(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int and0(int x) {
  return x & 0;
}

void matchIL$and0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_zero' << match.UnboxedConstant(value: 0)]),
    match.block('Function', [match.DartReturn('c_zero')]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int and_1(int x) {
  return x & -1;
}

void matchIL$and_1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int or(int x) {
  return x | x;
}

void matchIL$or(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int or0(int x) {
  return x | 0;
}

void matchIL$or0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int or_1(int x) {
  return x | -1;
}

void matchIL$or_1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_minus_one' << match.UnboxedConstant(value: -1)]),
    match.block('Function', [match.DartReturn('c_minus_one')]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int xor(int x) {
  return x ^ x;
}

void matchIL$xor(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_zero' << match.UnboxedConstant(value: 0)]),
    match.block('Function', [match.DartReturn('c_zero')]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int xor0(int x) {
  return x ^ 0;
}

void matchIL$xor0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int add0(int x) {
  return x + 0;
}

void matchIL$add0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sub(int x) {
  return x - x;
}

void matchIL$sub(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_zero' << match.UnboxedConstant(value: 0)]),
    match.block('Function', [match.DartReturn('c_zero')]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sub0(int x) {
  return x - 0;
}

void matchIL$sub0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int mul0(int x) {
  return x * 0;
}

void matchIL$mul0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_zero' << match.UnboxedConstant(value: 0)]),
    match.block('Function', [match.DartReturn('c_zero')]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int mul1(int x) {
  return x * 1;
}

void matchIL$mul1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int div1(int x) {
  return x ~/ 1;
}

void matchIL$div1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sll0(int x) {
  return x << 0;
}

void matchIL$sll0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sra0(int x) {
  return x >> 0;
}

void matchIL$sra0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int srl0(int x) {
  return x >>> 0;
}

void matchIL$srl0(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      match.DartReturn('x'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int srl64(int x) {
  return x >>> 64;
}

void matchIL$srl64(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['c_zero' << match.UnboxedConstant(value: 0)]),
    match.block('Function', [match.DartReturn('c_zero')]),
  ]);
}

main() {
  Expect.equals(1, and(1));
  Expect.equals(2, and(2));
  Expect.equals(0, and0(1));
  Expect.equals(0, and0(2));
  Expect.equals(1, and_1(1));
  Expect.equals(2, and_1(2));
  Expect.equals(1, or(1));
  Expect.equals(2, or(2));
  Expect.equals(1, or0(1));
  Expect.equals(2, or0(2));
  Expect.equals(-1, or_1(1));
  Expect.equals(-1, or_1(2));
  Expect.equals(0, xor(1));
  Expect.equals(0, xor(2));
  Expect.equals(1, xor0(1));
  Expect.equals(2, xor0(2));
  Expect.equals(1, add0(1));
  Expect.equals(2, add0(2));
  Expect.equals(0, sub(1));
  Expect.equals(0, sub(2));
  Expect.equals(1, sub0(1));
  Expect.equals(2, sub0(2));
  Expect.equals(0, mul0(1));
  Expect.equals(0, mul0(2));
  Expect.equals(1, mul1(1));
  Expect.equals(2, mul1(2));
  Expect.equals(1, div1(1));
  Expect.equals(2, div1(2));
  Expect.equals(1, sll0(1));
  Expect.equals(2, sll0(2));
  Expect.equals(1, sra0(1));
  Expect.equals(2, sra0(2));
  Expect.equals(1, srl0(1));
  Expect.equals(2, srl0(2));
  Expect.equals(0, srl64(1));
  Expect.equals(0, srl64(2));
}
