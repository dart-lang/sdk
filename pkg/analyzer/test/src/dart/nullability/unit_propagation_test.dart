// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnitPropagationTest);
  });
}

/// TODO(paulberry): write more tests
@reflectiveTest
class UnitPropagationTest {
  var solver = Solver();

  ConstraintVariable newVar(String name) => _NamedConstraintVariable(name);

  test_record_copies_conditions() {
    var a = newVar('a');
    var b = newVar('b');
    var conditions = [a];
    solver.record(conditions, b);
    conditions.removeLast();
    expect(a.value, false);
    expect(b.value, false);
    solver.record([], a);
    expect(a.value, true);
    expect(b.value, true);
  }

  test_record_propagates_true_variables_immediately() {
    var a = newVar('a');
    expect(a.value, false);
    solver.record([], a);
    expect(a.value, true);
    var b = newVar('b');
    expect(b.value, false);
    solver.record([a], b);
    expect(b.value, true);
  }
}

class _NamedConstraintVariable extends ConstraintVariable {
  final String _name;

  _NamedConstraintVariable(this._name);

  @override
  String toString() => _name;
}
