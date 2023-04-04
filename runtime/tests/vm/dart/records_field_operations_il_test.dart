// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can propagate static types through record fields
// and recognize int/double operations on record fields.

// SharedOptions=--enable-experiment=records,patterns

import 'package:vm/testing/il_matchers.dart';

double d(int x) => x + double.parse('1.0');

(double, double) staticFieldD = (d(1), d(2));

abstract class A {
  (double, double) instanceFieldD = (d(1), d(2));
  (double, double) instanceCallD();
}

class A1 extends A {
  @pragma('vm:never-inline')
  (double, double) instanceCallD() => (d(1), d(2));
}

class A2 extends A {
  @pragma('vm:never-inline')
  (double, double) instanceCallD() => (d(3), d(4));
}

@pragma('vm:never-inline')
(double, double) staticCallD() => (d(1), d(2));

@pragma('vm:prefer-inline')
void inlinedCallD((double, double) xy) {
  var (x, y) = xy;
  print(x - y);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testDouble(A obj, double a, double b, (double, double) param) {
  {
    var local = (a, b);
    var (x, y) = local;
    print(x + y);
  }

  {
    var (x, y) = param;
    print(x + y);
  }

  {
    var (x, y) = staticFieldD;
    print(x + y);
  }

  {
    var (x, y) = staticCallD();
    print(x + y);
  }

  {
    var (x, y) = obj.instanceFieldD;
    print(x + y);
  }

  {
    var (x, y) = obj.instanceCallD();
    print(x + y);
  }

  {
    final local = (a, b);
    inlinedCallD(local);
  }
}

void matchIL$testDouble(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      'a' << match.Parameter(index: 1),
      'b' << match.Parameter(index: 2),
      'param' << match.Parameter(index: 3),
      match.CheckStackOverflow(),
      'v1' << match.BinaryDoubleOp('a', 'b'),
      'v1_boxed' << match.Box('v1'),
      match.MoveArgument('v1_boxed'),
      match.StaticCall(),
      'x2' << match.LoadField('param'),
      'y2' << match.LoadField('param'),
      'x2_unboxed' << match.Unbox('x2'),
      'y2_unboxed' << match.Unbox('y2'),
      'v2' << match.BinaryDoubleOp('x2_unboxed', 'y2_unboxed'),
      'v2_boxed' << match.Box('v2'),
      match.MoveArgument('v2_boxed'),
      match.StaticCall(),
      'rec3' << match.LoadStaticField(),
      'x3' << match.LoadField('rec3'),
      'y3' << match.LoadField('rec3'),
      'x3_unboxed' << match.Unbox('x3'),
      'y3_unboxed' << match.Unbox('y3'),
      'v3' << match.BinaryDoubleOp('x3_unboxed', 'y3_unboxed'),
      'v3_boxed' << match.Box('v3'),
      match.MoveArgument('v3_boxed'),
      match.StaticCall(),
      'rec4' << match.StaticCall(),
      'x4' << match.ExtractNthOutput('rec4', index: 0),
      'y4' << match.ExtractNthOutput('rec4', index: 1),
      'x4_unboxed' << match.Unbox('x4'),
      'y4_unboxed' << match.Unbox('y4'),
      'v4' << match.BinaryDoubleOp('x4_unboxed', 'y4_unboxed'),
      'v4_boxed' << match.Box('v4'),
      match.MoveArgument('v4_boxed'),
      match.StaticCall(),
      'rec5' << match.LoadField('obj'),
      'x5' << match.LoadField('rec5'),
      'y5' << match.LoadField('rec5'),
      'x5_unboxed' << match.Unbox('x5'),
      'y5_unboxed' << match.Unbox('y5'),
      'v5' << match.BinaryDoubleOp('x5_unboxed', 'y5_unboxed'),
      'v5_boxed' << match.Box('v5'),
      match.MoveArgument('v5_boxed'),
      match.StaticCall(),
      'obj_cid' << match.LoadClassId('obj'),
      match.MoveArgument('obj'),
      'rec6' << match.DispatchTableCall('obj_cid'),
      'x6' << match.ExtractNthOutput('rec6', index: 0),
      'y6' << match.ExtractNthOutput('rec6', index: 1),
      'x6_unboxed' << match.Unbox('x6'),
      'y6_unboxed' << match.Unbox('y6'),
      'v6' << match.BinaryDoubleOp('x6_unboxed', 'y6_unboxed'),
      'v6_boxed' << match.Box('v6'),
      match.MoveArgument('v6_boxed'),
      match.StaticCall(),
      'v7' << match.BinaryDoubleOp('a', 'b'),
      'v7_boxed' << match.Box('v7'),
      match.MoveArgument('v7_boxed'),
      match.StaticCall(),
      match.Return(),
    ]),
  ]);
}

int i(int x) => x + int.parse('1');

(int, int) staticFieldI = (i(1), i(2));

abstract class B {
  (int, int) instanceFieldI = (i(1), i(2));
  (int, int) instanceCallI();
}

class B1 extends B {
  @pragma('vm:never-inline')
  (int, int) instanceCallI() => (i(1), i(2));
}

class B2 extends B {
  @pragma('vm:never-inline')
  (int, int) instanceCallI() => (i(3), i(4));
}

@pragma('vm:never-inline')
(int, int) staticCallI() => (i(1), i(2));

@pragma('vm:prefer-inline')
void inlinedCallI((int, int) xy) {
  var (x, y) = xy;
  print(x - y);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testInt(B obj, int a, int b, (int, int) param) {
  {
    var local = (a, b);
    var (x, y) = local;
    print(x + y);
  }

  {
    var (x, y) = param;
    print(x + y);
  }

  {
    var (x, y) = staticFieldI;
    print(x + y);
  }

  {
    var (x, y) = staticCallI();
    print(x + y);
  }

  {
    var (x, y) = obj.instanceFieldI;
    print(x + y);
  }

  {
    var (x, y) = obj.instanceCallI();
    print(x + y);
  }

  {
    final local = (a, b);
    inlinedCallI(local);
  }
}

void matchIL$testInt(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      'a' << match.Parameter(index: 1),
      'b' << match.Parameter(index: 2),
      'param' << match.Parameter(index: 3),
      match.CheckStackOverflow(),
      'v1' << match.BinaryInt64Op('a', 'b'),
      'v1_boxed' << match.BoxInt64('v1'),
      match.MoveArgument('v1_boxed'),
      match.StaticCall(),
      'x2' << match.LoadField('param'),
      'y2' << match.LoadField('param'),
      'x2_unboxed' << match.UnboxInt64('x2'),
      'y2_unboxed' << match.UnboxInt64('y2'),
      'v2' << match.BinaryInt64Op('x2_unboxed', 'y2_unboxed'),
      'v2_boxed' << match.BoxInt64('v2'),
      match.MoveArgument('v2_boxed'),
      match.StaticCall(),
      'rec3' << match.LoadStaticField(),
      'x3' << match.LoadField('rec3'),
      'y3' << match.LoadField('rec3'),
      'x3_unboxed' << match.UnboxInt64('x3'),
      'y3_unboxed' << match.UnboxInt64('y3'),
      'v3' << match.BinaryInt64Op('x3_unboxed', 'y3_unboxed'),
      'v3_boxed' << match.BoxInt64('v3'),
      match.MoveArgument('v3_boxed'),
      match.StaticCall(),
      'rec4' << match.StaticCall(),
      'x4' << match.ExtractNthOutput('rec4', index: 0),
      'y4' << match.ExtractNthOutput('rec4', index: 1),
      'x4_unboxed' << match.UnboxInt64('x4'),
      'y4_unboxed' << match.UnboxInt64('y4'),
      'v4' << match.BinaryInt64Op('x4_unboxed', 'y4_unboxed'),
      'v4_boxed' << match.BoxInt64('v4'),
      match.MoveArgument('v4_boxed'),
      match.StaticCall(),
      'rec5' << match.LoadField('obj'),
      'x5' << match.LoadField('rec5'),
      'y5' << match.LoadField('rec5'),
      'x5_unboxed' << match.UnboxInt64('x5'),
      'y5_unboxed' << match.UnboxInt64('y5'),
      'v5' << match.BinaryInt64Op('x5_unboxed', 'y5_unboxed'),
      'v5_boxed' << match.BoxInt64('v5'),
      match.MoveArgument('v5_boxed'),
      match.StaticCall(),
      'obj_cid' << match.LoadClassId('obj'),
      match.MoveArgument('obj'),
      'rec6' << match.DispatchTableCall('obj_cid'),
      'x6' << match.ExtractNthOutput('rec6', index: 0),
      'y6' << match.ExtractNthOutput('rec6', index: 1),
      'x6_unboxed' << match.UnboxInt64('x6'),
      'y6_unboxed' << match.UnboxInt64('y6'),
      'v6' << match.BinaryInt64Op('x6_unboxed', 'y6_unboxed'),
      'v6_boxed' << match.BoxInt64('v6'),
      match.MoveArgument('v6_boxed'),
      match.StaticCall(),
      'v7' << match.BinaryInt64Op('a', 'b'),
      'v7_boxed' << match.BoxInt64('v7'),
      match.MoveArgument('v7_boxed'),
      match.StaticCall(),
      match.Return(),
    ]),
  ]);
}

void main(List<String> args) {
  // Make sure all parameters are non-constant.
  // Also make sure A/B is polymorphic to prevent
  // devirtualization of instance calls.
  testDouble(args.length > 0 ? A1() : A2(), d(1), d(2), (d(3), d(4)));
  testInt(args.length > 0 ? B1() : B2(), i(1), i(2), (i(3), i(4)));
}
