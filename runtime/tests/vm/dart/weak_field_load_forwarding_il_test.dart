// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that load forwarding doesn't happen for weak fields
// (values of weak fields can be set to null by the GC).
// Regression test for https://github.com/dart-lang/sdk/issues/55518.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

class StrongRef {
  Object? target;
  StrongRef(this.target);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool loadLoadStrongRef(StrongRef obj) {
  var v1 = obj.target;
  var v2 = obj.target;
  return identical(v1, v2);
}

void matchIL$loadLoadStrongRef(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'true' << match.Constant(value: true),
    ]),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.DartReturn('true'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool loadLoadWeakReference(WeakReference obj) {
  var v1 = obj.target;
  var v2 = obj.target;
  return identical(v1, v2);
}

void matchIL$loadLoadWeakReference(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      'v1' << match.LoadField('obj', slot: 'WeakReference.target'),
      'v2' << match.LoadField('obj', slot: 'WeakReference.target'),
      'res' << match.StrictCompare('v1', 'v2', kind: '==='),
      match.DartReturn('res'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool storeLoadStrongRef(Object v1) {
  final obj = StrongRef(v1);
  var v2 = obj.target;
  return identical(v1, v2);
}

void matchIL$storeLoadStrongRef(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'true' << match.Constant(value: true),
    ]),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.DartReturn('true'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool storeLoadWeakReference(Object v1) {
  final obj = WeakReference(v1);
  var v2 = obj.target;
  return identical(v1, v2);
}

void matchIL$storeLoadWeakReference(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'v1' << match.Parameter(index: 0),
      'obj' << match.AllocateObject(),
      match.StoreField('obj', 'v1', slot: 'WeakReference.target'),
      'v2' << match.LoadField('obj', slot: 'WeakReference.target'),
      'res' << match.StrictCompare('v1', 'v2', kind: '==='),
      match.DartReturn('res'),
    ]),
  ]);
}

void main(List<String> args) {
  loadLoadStrongRef(StrongRef(Object()));
  loadLoadWeakReference(WeakReference(Object()));
  storeLoadStrongRef(Object());
  storeLoadWeakReference(Object());
}
