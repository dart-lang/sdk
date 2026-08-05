// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can inline generic functions with optional
// parameters.

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void foo(int x) {
  print(x);
}

@pragma('vm:prefer-inline')
void callee1<T>() {
  foo(10);
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void test1() {
  callee1<String>();
}

void matchCallFoo(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['v0' << match.Constant(value: null)]),
    match.block('Function', [
      match.CheckStackOverflow(),
      match.StaticCall(function: 'foo'),
      match.DartReturn('v0'),
    ]),
  ]);
}

void matchIL$test1(FlowGraph graph) {
  matchCallFoo(graph);
}

@pragma('vm:prefer-inline')
void callee2<T>(int a0, [int a1 = 0]) {
  foo(a0 + a1);
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void test2a() {
  callee2<int>(10);
}

void matchIL$test2a(FlowGraph graph) {
  matchCallFoo(graph);
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void test2b() {
  callee2<double>(20, 30);
}

void matchIL$test2b(FlowGraph graph) {
  matchCallFoo(graph);
}

@pragma('vm:prefer-inline')
void callee3<T>(int a0, {int a1 = 0}) {
  foo(a0 + a1);
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void test3a() {
  callee3<int>(10);
}

void matchIL$test3a(FlowGraph graph) {
  matchCallFoo(graph);
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void test3b() {
  callee3<double>(20, a1: 30);
}

void matchIL$test3b(FlowGraph graph) {
  matchCallFoo(graph);
}

void main() {
  test1();
  test2a();
  test2b();
  test3a();
  test3b();
}
