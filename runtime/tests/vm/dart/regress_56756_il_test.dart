// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that 'is' test is not removed due to an incorrect
// inferred range of LoadClassId of a nullable value.

import 'package:vm/testing/il_matchers.dart';

import 'dart:math';

@pragma('vm:never-inline')
void myprint(Object o) {
  print(o);
}

class RandomValue {
  final bool shouldReturnValue;
  const RandomValue(this.shouldReturnValue);

  @pragma('vm:never-inline')
  String randomString() => Random().nextInt(42).toString();

  @pragma('vm:prefer-inline')
  String? get valueOrNull {
    return shouldReturnValue ? randomString() : null;
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void doTest(RandomValue value) {
  if (value.valueOrNull case final String aString) {
    myprint(aString);
  }
}

void main() {
  doTest(RandomValue(true));
  doTest(RandomValue(false));
}

void matchIL$doTest(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'c_null' << match.Constant(value: null),
      'c_true' << match.Constant(value: true),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'condition' << match.LoadField('value', slot: 'shouldReturnValue'),
      match.Branch(match.StrictCompare('condition', 'c_true', kind: '==='),
          ifTrue: 'B8', ifFalse: 'B9'),
    ]),
    'B8' <<
        match.block('Target', [
          'v19' << match.StaticCall(),
          match.Goto('B10'),
        ]),
    'B9' <<
        match.block('Target', [
          match.Goto('B10'),
        ]),
    'B10' <<
        match.block('Join', [
          'v15' << match.Phi('v19', 'c_null'),
          'v8' << match.LoadClassId('v15'),
          match.Branch(match.TestRange('v8', kind: 'is'),
              ifTrue: 'B3', ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          match.StaticCall('v15'),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' <<
        match.block('Join', [
          match.DartReturn('c_null'),
        ]),
  ]);
}
