// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that object loads are not hoisted if type doesn't guarantee safety.
// Regression test for https://github.com/dart-lang/sdk/issues/63413.
import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

class Wrapper {
  static int cnt = 0;
  // Note: we want a known _OneByteString value to avoid polymorphic inlining
  // of codeUnitAt.
  final String value = (cnt++ & 1) == 1 ? "0123456789" : "9876543210";
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int promotion1(dynamic x, bool f) {
  var result = 0;
  for (int i = 0; i < 10; i++) {
    if (f) {
      x as Wrapper;
    } else {
      x as Wrapper;
    }
    result += x.value.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int promotion2(dynamic x, bool f) {
  var result = 0;
  for (int i = 0; i < 10; i++) {
    if (f) {
      x as Wrapper;
    } else {
      x as Wrapper;
    }
    result += x.value.codeUnitAt(i);
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int promotion3(Wrapper? x) {
  var result = 0;
  bool isNotNull = x != null;
  for (int i = 0; i < 10; i++) {
    if (isNotNull) {
      result += x.value.codeUnitAt(i);
    }
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int promotion4(Wrapper? x, {required bool isNotNull}) {
  var result = 0;
  for (int i = 0; i < 10; i++) {
    if (isNotNull) {
      result += x!.value.codeUnitAt(i);
    }
  }
  return result;
}

sealed class Base {
  void foo();
}

final class Child1 extends Base {
  void foo() {}
}

final class Child2(final String payload) extends Base {
  void foo() {
    print(payload.length);
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int promotion5(Base b) {
  var result = 0;
  for (int i = 0; i < 10; i++) {
    if (b is Child1) {
      return 0;
    } else {
      // Note: TFA currently does not promote |b| to Child2 in this branch.
      // so this test will not fail on main.
      b.foo();
    }
  }
  return result;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int pointerLoad(int address) {
  final ptr = Pointer<Int32>.fromAddress(address);
  var result = 0;
  for (int i = 0; i < 10; i++) {
    if (address > 10) {
      result += ptr.value;
    }
  }
  return result;
}

@pragma('vm:never-inline')
dynamic getSmi() => 123;

void main() {
  try {
    promotion1(Wrapper(), false);
  } catch (_) {}

  try {
    promotion1(getSmi(), true);
    promotion1(getSmi(), false);
  } catch (_) {}

  try {
    promotion2(Wrapper(), false);
  } catch (_) {}

  try {
    promotion2(getSmi(), true);
  } catch (_) {}

  promotion3(null);
  promotion3(Wrapper());
  promotion4(null, isNotNull: false);
  promotion4(Wrapper(), isNotNull: true);

  promotion5(Child1());
  promotion5(Child2(Wrapper().value));

  pointerLoad(0);
  pointerLoad(1);
}

void expectNoLicm(FlowGraph graph, {bool allowHoistOfLoadClassId = false}) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      match.tight([
        match.seq(
          match.noneOf({
            'LoadField',
            if (!allowHoistOfLoadClassId) 'LoadClassId',
            'LoadIndexed',
          }),
        ),
        match.Goto('loop-header'),
      ]),
    ]),
    'loop-header' << match.block('Join', isLoopHeader: true, []),
  ]);
}

void matchIL$promotion1(FlowGraph graph) {
  expectNoLicm(graph);
}

void matchIL$promotion2(FlowGraph graph) {
  expectNoLicm(graph);
}

void matchIL$promotion3(FlowGraph graph) {
  expectNoLicm(graph);
}

void matchIL$promotion4(FlowGraph graph) {
  expectNoLicm(graph);
}

void matchIL$promotion5(FlowGraph graph) {
  expectNoLicm(graph, allowHoistOfLoadClassId: true);
}

void matchIL$pointerLoad(FlowGraph graph) {
  expectNoLicm(graph);
}
