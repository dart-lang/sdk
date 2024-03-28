// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler correctly unboxes parameters, return values and
// fields.

import 'package:vm/testing/il_matchers.dart';

bool shouldPrint = false;

@pragma('vm:never-inline')
void sinkhole(Object v) {
  if (shouldPrint) {
    print(v);
  }
}

class C {
  final int i;
  final double d;

  C(this.i, this.d);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int unboxed1(int x, double y, C v, int z, double w) {
  sinkhole(x);
  sinkhole(y);
  sinkhole(v);
  sinkhole(v.i);
  sinkhole(v.d);
  sinkhole(z);
  sinkhole(w);
  return x + z;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
double unboxed2(int x, double y, C v, int z, double w) {
  sinkhole(x);
  sinkhole(y);
  sinkhole(v);
  sinkhole(v.i);
  sinkhole(v.d);
  sinkhole(z);
  sinkhole(w);
  return y + w;
}

void matchIL$unboxed1(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'y' << match.Parameter(index: 1),
      'v' << match.Parameter(index: 2),
      'z' << match.Parameter(index: 3),
      'w' << match.Parameter(index: 4),
      'box_x' << match.BoxInt64('x'),
      match.StaticCall('box_x'),
      'box_y' << match.Box('y'),
      match.StaticCall('box_y'),
      match.StaticCall('v'),
      'i' << match.LoadField('v', slot: 'i'),
      'box_i' << match.BoxInt64('i'),
      match.StaticCall('box_i'),
      'd' << match.LoadField('v', slot: 'd'),
      'box_d' << match.Box('d'),
      match.StaticCall('box_d'),
      'box_z' << match.BoxInt64('z'),
      match.StaticCall('box_z'),
      'box_w' << match.Box('w'),
      match.StaticCall('box_w'),
      'result' << match.BinaryInt64Op('x', 'z'),
      match.DartReturn('result'),
    ]),
  ]);
}

void matchIL$unboxed2(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'y' << match.Parameter(index: 1),
      'v' << match.Parameter(index: 2),
      'z' << match.Parameter(index: 3),
      'w' << match.Parameter(index: 4),
      'box_x' << match.BoxInt64('x'),
      match.StaticCall('box_x'),
      'box_y' << match.Box('y'),
      match.StaticCall('box_y'),
      match.StaticCall('v'),
      'i' << match.LoadField('v', slot: 'i'),
      'box_i' << match.BoxInt64('i'),
      match.StaticCall('box_i'),
      'd' << match.LoadField('v', slot: 'd'),
      'box_d' << match.Box('d'),
      match.StaticCall('box_d'),
      'box_z' << match.BoxInt64('z'),
      match.StaticCall('box_z'),
      'box_w' << match.Box('w'),
      match.StaticCall('box_w'),
      'result' << match.BinaryDoubleOp('y', 'w'),
      match.DartReturn('result'),
    ]),
  ]);
}

void main(List<String> args) {
  shouldPrint = args.length > 22;
  // intValue should not be a known constant or a smi.
  final intValue = args.length > 50 ? (1 << 53) : 1;
  final doubleValue = args.length > 50 ? 42.5 : 24.5;
  final cValue = C(intValue, doubleValue);
  sinkhole(unboxed1(intValue, doubleValue, cValue, intValue, doubleValue));
  sinkhole(unboxed2(intValue, doubleValue, cValue, intValue, doubleValue));
}
