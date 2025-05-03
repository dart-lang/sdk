// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/110715.
// Verifies that compiler doesn't elide null check for a parameter in
// a catch block in async/async* methods.

import 'dart:async';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
Stream<Object> bug1(void Function()? f, void Function() g) async* {
  try {
    g();
    throw 'error';
  } catch (e) {
    // Should not crash when 'f' is null.
    f?.call();
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
Future<Object> bug2(void Function()? f, void Function() g) async {
  try {
    g();
    throw 'error';
  } catch (e) {
    // Should not crash when 'f' is null.
    f?.call();
  }
  return '';
}

void main() async {
  print(await bug1(null, () {}).toList());
  print(await bug1(() {}, () {}).toList());
  print(await bug2(null, () {}));
  print(await bug2(() {}, () {}));
}

void matchIL$bug1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['cnull' << match.Constant(value: null)]),
    match.block('Function'),
    match.block('Try'),
    match.block('Join'),
    match.block('CatchBlock', [
      match.Branch(
        match.StrictCompare(match.any, 'cnull', kind: '==='),
        ifTrue: 'B7',
        ifFalse: 'B8',
      ),
    ]),
    'B7' << match.block('Target', [match.Goto('B5')]),
    'B8' << match.block('Target', [match.ClosureCall(), match.Goto('B5')]),
    'B5' << match.block('Join', [match.DartReturn()]),
  ]);
}

void matchIL$bug2(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', ['cnull' << match.Constant(value: null)]),
    match.block('Function'),
    match.tryBlock(),
    match.block('Join'),
    match.block('CatchBlock', [
      match.Branch(
        match.StrictCompare(match.any, 'cnull', kind: '==='),
        ifTrue: 'B7',
        ifFalse: 'B8',
      ),
    ]),
    'B7' << match.block('Target', [match.Goto('B5')]),
    'B8' << match.block('Target', [match.ClosureCall(), match.Goto('B5')]),
    'B5' << match.block('Join', [match.DartReturn()]),
  ]);
}
