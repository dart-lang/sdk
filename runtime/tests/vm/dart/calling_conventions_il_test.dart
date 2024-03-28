// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies different corner cases around calling functions in
// Dart.
import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

abstract class Base {
  final String o;
  Base(this.o);

  String f(String v);
  String fOptional([String v = 'ok!']);
  String fNamed({String v = 'ok!'});
  int fIntInt(int a, int b);
  double fIntDouble(int a, double b);
  double fDoubleDouble(double a, double b);
  int fIntOptionalInt(int a, [int b = 0]);
  double fIntOptionalDouble(int a, [double b = 0.0]);
  double fDoubleOptionalDouble(double a, [double b = 0.0]);
  int fIntNamedInt(int a, {int b = 0});
  double fIntNamedDouble(int a, {double b = 0.0});
  double fDoubleNamedDouble(double a, {double b = 0.0});
}

class ChildSimple extends Base {
  ChildSimple(super.o);

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String f(String v) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String fOptional([String v = 'ok!']) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String fNamed({String v = 'ok!'}) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntInt(int a, int b) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntDouble(int a, double b) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleDouble(double a, double b) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntOptionalInt(int a, [int b = 0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntOptionalDouble(int a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleOptionalDouble(double a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntNamedInt(int a, {int b = 0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntNamedDouble(int a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleNamedDouble(double a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }
}

class ChildConvertingParametersToOptional extends Base {
  ChildConvertingParametersToOptional(super.o);

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String f([String v = 'ok!']) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String fOptional([String v = 'ok!']) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  String fNamed({String v = 'ok!'}) {
    Expect.equals('ok', o.substring(0, 2));
    Expect.equals('ok', v.substring(0, 2));
    return o + v;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntInt(int a, [int b = 0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntDouble(int a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleDouble(double a, [double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntOptionalInt([int a = 0, int b = 0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntOptionalDouble([int a = 0, double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleOptionalDouble([double a = 0.0, double b = 0.0]) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  int fIntNamedInt(int a, {int b = 0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fIntNamedDouble(int a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }

  @override
  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  double fDoubleNamedDouble(double a, {double b = 0.0}) {
    Expect.equals('ok', o.substring(0, 2));
    return a + b;
  }
}

void testDirectCalls1(String str, int ia, int ib) {
  final da = ia.toDouble();
  final db = ib.toDouble();
  final child = ChildSimple(str);

  Expect.equals("ok+ok+", child.f(str));
  Expect.equals("ok+ok!", child.fOptional());
  Expect.equals("ok+ok+", child.fOptional(str));
  Expect.equals("ok+ok!", child.fNamed());
  Expect.equals("ok+ok+", child.fNamed(v: str));
  Expect.equals(142, child.fIntInt(ia, ib));
  Expect.equals(142, child.fIntDouble(ia, db));
  Expect.equals(142, child.fDoubleDouble(da, db));
  Expect.equals(42, child.fIntOptionalInt(ia));
  Expect.equals(142, child.fIntOptionalInt(ia, ib));
  Expect.equals(42, child.fIntOptionalDouble(ia));
  Expect.equals(142, child.fIntOptionalDouble(ia, db));
  Expect.equals(42, child.fDoubleOptionalDouble(da));
  Expect.equals(142, child.fDoubleOptionalDouble(da, db));
  Expect.equals(42, child.fIntNamedInt(ia));
  Expect.equals(142, child.fIntNamedInt(ia, b: ib));
  Expect.equals(42, child.fIntNamedDouble(ia));
  Expect.equals(142, child.fIntNamedDouble(ia, b: db));
  Expect.equals(42, child.fDoubleNamedDouble(da));
  Expect.equals(142, child.fDoubleNamedDouble(da, b: db));
}

void testDirectCalls2(String str, int ia, int ib) {
  final da = ia.toDouble();
  final db = ib.toDouble();
  final child = ChildConvertingParametersToOptional(str);

  Expect.equals("ok+ok!", child.f());
  Expect.equals("ok+ok+", child.f(str));
  Expect.equals("ok+ok!", child.fOptional());
  Expect.equals("ok+ok+", child.fOptional(str));
  Expect.equals("ok+ok!", child.fNamed());
  Expect.equals("ok+ok+", child.fNamed(v: str));
  Expect.equals(42, child.fIntInt(ia));
  Expect.equals(142, child.fIntInt(ia, ib));
  Expect.equals(42, child.fIntDouble(ia));
  Expect.equals(142, child.fIntDouble(ia, db));
  Expect.equals(42, child.fDoubleDouble(da));
  Expect.equals(142, child.fDoubleDouble(da, db));
  Expect.equals(0, child.fIntOptionalInt());
  Expect.equals(42, child.fIntOptionalInt(ia));
  Expect.equals(142, child.fIntOptionalInt(ia, ib));
  Expect.equals(0, child.fIntOptionalDouble());
  Expect.equals(42, child.fIntOptionalDouble(ia));
  Expect.equals(142, child.fIntOptionalDouble(ia, db));
  Expect.equals(0, child.fDoubleOptionalDouble());
  Expect.equals(42, child.fDoubleOptionalDouble(da));
  Expect.equals(142, child.fDoubleOptionalDouble(da, db));
  Expect.equals(42, child.fIntNamedInt(ia));
  Expect.equals(142, child.fIntNamedInt(ia, b: ib));
  Expect.equals(42, child.fIntNamedDouble(ia));
  Expect.equals(142, child.fIntNamedDouble(ia, b: db));
  Expect.equals(42, child.fDoubleNamedDouble(da));
  Expect.equals(142, child.fDoubleNamedDouble(da, b: db));
}

void testVirtualCalls(Base child, int ia, int ib) {
  final da = ia.toDouble();
  final db = ib.toDouble();

  Expect.equals("ok+ok+", child.f(child.o));
  Expect.equals("ok+ok!", child.fOptional());
  Expect.equals("ok+ok+", child.fOptional(child.o));
  Expect.equals("ok+ok!", child.fNamed());
  Expect.equals("ok+ok+", child.fNamed(v: child.o));
  Expect.equals(142, child.fIntInt(ia, ib));
  Expect.equals(142, child.fIntDouble(ia, db));
  Expect.equals(142, child.fDoubleDouble(da, db));
  Expect.equals(42, child.fIntOptionalInt(ia));
  Expect.equals(142, child.fIntOptionalInt(ia, ib));
  Expect.equals(42, child.fIntOptionalDouble(ia));
  Expect.equals(142, child.fIntOptionalDouble(ia, db));
  Expect.equals(42, child.fDoubleOptionalDouble(da));
  Expect.equals(142, child.fDoubleOptionalDouble(da, db));
  Expect.equals(42, child.fIntNamedInt(ia));
  Expect.equals(142, child.fIntNamedInt(ia, b: ib));
  Expect.equals(42, child.fIntNamedDouble(ia));
  Expect.equals(142, child.fIntNamedDouble(ia, b: db));
  Expect.equals(42, child.fDoubleNamedDouble(da));
  Expect.equals(142, child.fDoubleNamedDouble(da, b: db));
}

void runTests(
    List<String> args,
    List<void Function(String, int, int)> directCallsTests,
    List<Base Function(String)> childClassFactories) {
  final ia = args.length >= 1 ? int.parse(args[0]) : 42;
  final ib = args.length >= 2 ? int.parse(args[1]) : 100;
  final str = args.length >= 3 ? args[2] : 'ok+';
  for (var test in directCallsTests) {
    test(str, ia, ib);
  }
  for (var f in childClassFactories) {
    testVirtualCalls(f(str), ia, ib);
  }
}

final directCallsTests = [testDirectCalls1, testDirectCalls2];
final childClassFactories = [
  ChildSimple.new,
  ChildConvertingParametersToOptional.new,
];

void main(List<String> args) {
  runTests(args, directCallsTests, childClassFactories);
}

void _matchIL(FlowGraph graph,
    {required List<String?> parameters, bool argDesc = false}) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      for (var i = 0; i < parameters.length; i++)
        if (parameters[i] != null)
          match.Parameter(index: i, location: parameters[i]),
      if (argDesc)
        match.Parameter(index: parameters.length, location: 'reg(cpu)'),
    ])
  ]);
}

void matchIL$ChildSimple$f(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', 'stack(word)']);
}

void matchIL$ChildSimple$fOptional(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null], argDesc: true);
}

void matchIL$ChildSimple$fNamed(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null], argDesc: true);
}

void matchIL$ChildSimple$fIntInt(FlowGraph graph) {
  _matchIL(graph, parameters: [
    'reg(cpu)',
    is32BitConfiguration ? '(reg(cpu), reg(cpu))' : 'reg(cpu)',
    'stack(word)',
  ]);
}

void matchIL$ChildSimple$fIntDouble(FlowGraph graph) {
  _matchIL(graph, parameters: [
    'reg(cpu)',
    is32BitConfiguration ? '(reg(cpu), reg(cpu))' : 'reg(cpu)',
    'stack(word)',
  ]);
}

void matchIL$ChildSimple$fDoubleDouble(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', 'reg(fpu)', 'stack(word)']);
}

void matchIL$ChildSimple$fIntOptionalInt(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildSimple$fIntOptionalDouble(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildSimple$fDoubleOptionalDouble(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildSimple$fIntNamedInt(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildSimple$fIntNamedDouble(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildSimple$fDoubleNamedDouble(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null, null], argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$f(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null], argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fOptional(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null], argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fNamed(FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', null], argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fIntInt(FlowGraph graph) {
  _matchIL(graph,
      parameters: [
        'reg(cpu)',
        is32BitConfiguration ? '(reg(cpu), reg(cpu))' : 'reg(cpu)',
        null,
      ],
      argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fIntDouble(FlowGraph graph) {
  _matchIL(graph,
      parameters: [
        'reg(cpu)',
        is32BitConfiguration ? '(reg(cpu), reg(cpu))' : 'reg(cpu)',
        null,
      ],
      argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fDoubleDouble(
    FlowGraph graph) {
  _matchIL(graph, parameters: ['reg(cpu)', 'reg(fpu)', null], argDesc: true);
}

void matchIL$ChildConvertingParametersToOptional$fIntOptionalInt(
    FlowGraph graph) {
  matchIL$ChildSimple$fIntOptionalInt(graph);
}

void matchIL$ChildConvertingParametersToOptional$fIntOptionalDouble(
    FlowGraph graph) {
  matchIL$ChildSimple$fIntOptionalDouble(graph);
}

void matchIL$ChildConvertingParametersToOptional$fDoubleOptionalDouble(
    FlowGraph graph) {
  matchIL$ChildSimple$fDoubleOptionalDouble(graph);
}

void matchIL$ChildConvertingParametersToOptional$fIntNamedInt(FlowGraph graph) {
  matchIL$ChildSimple$fIntNamedInt(graph);
}

void matchIL$ChildConvertingParametersToOptional$fIntNamedDouble(
    FlowGraph graph) {
  matchIL$ChildSimple$fIntNamedDouble(graph);
}

void matchIL$ChildConvertingParametersToOptional$fDoubleNamedDouble(
    FlowGraph graph) {
  matchIL$ChildSimple$fDoubleNamedDouble(graph);
}
