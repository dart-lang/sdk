// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/deferred_closure_heuristic.dart';
import 'package:test/test.dart';

main() {
  test('single', () {
    // If there is just a single closure and no type variables, it is selected.
    var f = Closure('f');
    expect(
        _TestClosureDeps(typeVars: [], closures: [f])
            .planClosureReconciliationStages(),
        [
          {f}
        ]);
  });

  test('simple dependency', () {
    // If f depends on g, then g is selected first, and then f.
    var f = Closure('f', argTypes: ['T']);
    var g = Closure('g', retTypes: ['T']);
    expect(
        _TestClosureDeps(typeVars: ['T'], closures: [f, g])
            .planClosureReconciliationStages(),
        [
          {g},
          {f}
        ]);
  });

  test('long chain', () {
    // If f depends on g and g depends on h, then we do three separate stages:
    // h, then g, then f.
    var f = Closure('f', argTypes: ['T']);
    var g = Closure('g', argTypes: ['U'], retTypes: ['T']);
    var h = Closure('h', retTypes: ['U']);
    expect(
        _TestClosureDeps(typeVars: ['T', 'U'], closures: [f, g, h])
            .planClosureReconciliationStages(),
        [
          {h},
          {g},
          {f}
        ]);
  });

  test('unrelated closure', () {
    // Closures that are independent of all the others are inferred during the
    // first stage.
    var f = Closure('f', argTypes: ['T']);
    var g = Closure('g', retTypes: ['T']);
    var h = Closure('h');
    expect(
        _TestClosureDeps(typeVars: ['T', 'U'], closures: [f, g, h])
            .planClosureReconciliationStages(),
        [
          {g, h},
          {f}
        ]);
  });

  test('independent chains', () {
    // If f depends on g, and h depends on i, then g and i are selected first,
    // and then f and h.
    var f = Closure('f', argTypes: ['T']);
    var g = Closure('g', retTypes: ['T']);
    var h = Closure('h', argTypes: ['U']);
    var i = Closure('i', retTypes: ['U']);
    expect(
        _TestClosureDeps(typeVars: ['T', 'U'], closures: [f, g, h, i])
            .planClosureReconciliationStages(),
        [
          {g, i},
          {f, h}
        ]);
  });

  test('diamond', () {
    // Test a diamond dependency shape: f depends on g and h; g and h both
    // depend on i.
    var f = Closure('f', argTypes: ['T', 'U']);
    var g = Closure('g', argTypes: ['V'], retTypes: ['T']);
    var h = Closure('h', argTypes: ['V'], retTypes: ['U']);
    var i = Closure('i', retTypes: ['V']);
    expect(
        _TestClosureDeps(typeVars: ['T', 'U', 'V'], closures: [f, g, h, i])
            .planClosureReconciliationStages(),
        [
          {i},
          {g, h},
          {f}
        ]);
  });

  test('cycle', () {
    // A dependency cycle is inferred all at once.
    var f = Closure('f', argTypes: ['T']);
    var g = Closure('g', argTypes: ['U']);
    var h = Closure('h', argTypes: ['U'], retTypes: ['T']);
    var i = Closure('i', argTypes: ['T'], retTypes: ['U']);
    expect(
        _TestClosureDeps(typeVars: ['T', 'U'], closures: [f, g, h, i])
            .planClosureReconciliationStages(),
        [
          {h, i},
          {f, g}
        ]);
  });
}

class Closure {
  final String name;
  final List<String> argTypes;
  final List<String> retTypes;

  Closure(this.name, {this.argTypes = const [], this.retTypes = const []});

  @override
  String toString() => name;
}

class _TestClosureDeps extends ClosureDependencies<String, Closure> {
  final List<String> typeVars;
  final List<Closure> closures;

  _TestClosureDeps({required this.typeVars, required this.closures})
      : super(closures, typeVars);

  @override
  Set<String> typeVarsFreeInClosureArguments(Closure closure) =>
      closure.argTypes.toSet();

  @override
  Set<String> typeVarsFreeInClosureReturns(Closure closure) =>
      closure.retTypes.toSet();
}
