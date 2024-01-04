// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:analyzer/src/wolf/ir/scope_analyzer.dart';
import 'package:analyzer/src/wolf/ir/validator.dart';
import 'package:checks/checks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScopeAnalyzerTest);
  });
}

@reflectiveTest
class ScopeAnalyzerTest {
  final _addressToOnAnalyzeCallbacks =
      <int, List<void Function(ScopeAnalyzerEventListener)>>{};
  final labelToScope = <String, int>{};
  final labelToStateVar = <String, StateVar>{};
  late final TestIRContainer ir;
  late final Scopes scopeAnalysisResult;

  /// If `true`, an extra state variable will be created for each scope, to test
  /// that local variable indices and state variable indices are properly
  /// distinguished.
  bool createExtraStateVarPerScope = true;

  LiteralRef get dummyLiteral => LiteralRef(0);

  /// The state variables affected by instructions in [scope].
  ///
  /// This is a simple wrapper around [Scopes.effectAt], [Scopes.effectCount],
  /// and [Scopes.effectIndex] to simplify testing. Non-test code will use those
  /// lower-level methods directly.
  List<StateVar> affectedStateVariables(int scope) {
    var index = scopeAnalysisResult.effectIndex(scope);
    var count = scopeAnalysisResult.effectCount(scope);
    return [
      for (var i = 0; i < count; i++) scopeAnalysisResult.effectAt(index + i)
    ];
  }

  void test_affectedStateVariables_coalescesRedundantWrites() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 4)
      ..label('alloc')
      ..alloc(2)
      ..label('block')
      ..block(3, 0)
      ..writeLocal(0)
      ..writeLocal(1)
      ..writeLocal(0)
      ..end()
      ..release(2)
      ..end());
    check(affectedStateVariables(labelToScope['block']!)).unorderedEquals(
        [labelToStateVar['alloc0']!, labelToStateVar['alloc1']!]);
  }

  void test_affectedStateVariables_coalescesRedundantWrites_inInnerBlock() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 5)
      ..label('alloc')
      ..alloc(3)
      ..label('outer block')
      ..block(4, 0)
      ..writeLocal(0)
      ..writeLocal(1)
      ..label('inner block')
      ..block(2, 0)
      ..writeLocal(0)
      ..writeLocal(2)
      ..end()
      ..end()
      ..release(3)
      ..end());
    check(affectedStateVariables(labelToScope['inner block']!)).unorderedEquals(
        [labelToStateVar['alloc0']!, labelToStateVar['alloc2']!]);
    check(affectedStateVariables(labelToScope['outer block']!))
        .unorderedEquals([
      labelToStateVar['alloc0']!,
      labelToStateVar['alloc1']!,
      labelToStateVar['alloc2']!
    ]);
  }

  void test_affectedStateVariables_ignoresUnusedVariables() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('alloc')
      ..alloc(2)
      ..label('block')
      ..block(0, 0)
      ..end()
      ..release(2)
      ..end());
    check(affectedStateVariables(labelToScope['block']!)).isEmpty();
  }

  void test_affectedStateVariables_ignoresVariablesReleasedInsideScope() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..label('block')
      ..block(2, 0)
      ..label('alloc')
      ..alloc(2)
      ..writeLocal(0)
      ..writeLocal(1)
      ..release(2)
      ..end()
      ..end());
    check(affectedStateVariables(labelToScope['block']!)).isEmpty();
  }

  void test_affectedStateVariables_tracksLocalVariableWrites() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..label('alloc')
      ..alloc(2)
      ..label('block')
      ..block(2, 0)
      ..writeLocal(0)
      ..writeLocal(1)
      ..end()
      ..release(2)
      ..end());
    check(affectedStateVariables(labelToScope['block']!)).unorderedEquals(
        [labelToStateVar['alloc0']!, labelToStateVar['alloc1']!]);
  }

  void
      test_affectedStateVariables_tracksLocalVariableWrites_whenLaterWrittenInEnclosingBlock() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..label('x')
      ..alloc(1)
      ..label('outer block')
      ..block(2, 0)
      ..label('inner block')
      ..block(1, 0)
      ..writeLocal(0)
      ..end()
      ..writeLocal(0)
      ..end()
      ..release(1)
      ..end());
    check(affectedStateVariables(labelToScope['inner block']!))
        .unorderedEquals([labelToStateVar['x']!]);
    check(affectedStateVariables(labelToScope['outer block']!))
        .unorderedEquals([labelToStateVar['x']!]);
  }

  void
      test_affectedStateVariables_tracksLocalVariableWrites_whenPreviouslyWrittenInEnclosingBlock() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 3)
      ..label('x')
      ..alloc(1)
      ..label('outer block')
      ..block(2, 0)
      ..writeLocal(0)
      ..label('inner block')
      ..block(1, 0)
      ..writeLocal(0)
      ..end()
      ..end()
      ..release(1)
      ..end());
    check(affectedStateVariables(labelToScope['inner block']!))
        .unorderedEquals([labelToStateVar['x']!]);
    check(affectedStateVariables(labelToScope['outer block']!))
        .unorderedEquals([labelToStateVar['x']!]);
  }

  void
      test_affectedStateVariables_tracksReallocatedLocalsAsSeparateStateVars() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..block(0, 0)
      ..label('x')
      ..alloc(1)
      ..release(1)
      ..end()
      ..block(0, 0)
      ..label('y')
      ..alloc(1)
      ..release(1)
      ..end()
      ..end());
    check(labelToStateVar['x']!).not((s) => s.equals(labelToStateVar['y']!));
  }

  void test_allocIndexToStateVar() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('x')
      ..alloc(2)
      ..label('y')
      ..alloc(3)
      ..release(3)
      ..label('z')
      ..alloc(2)
      ..release(4)
      ..end());
    check(scopeAnalysisResult.allocIndexToStateVar(0))
        .equals(labelToStateVar['x0']!);
    check(scopeAnalysisResult.allocIndexToStateVar(1))
        .equals(labelToStateVar['x1']!);
    check(scopeAnalysisResult.allocIndexToStateVar(2))
        .equals(labelToStateVar['y0']!);
    check(scopeAnalysisResult.allocIndexToStateVar(3))
        .equals(labelToStateVar['y1']!);
    check(scopeAnalysisResult.allocIndexToStateVar(4))
        .equals(labelToStateVar['y2']!);
    check(scopeAnalysisResult.allocIndexToStateVar(5))
        .equals(labelToStateVar['z0']!);
    check(scopeAnalysisResult.allocIndexToStateVar(6))
        .equals(labelToStateVar['z1']!);
  }

  void test_ancestorContainingAddress() {
    _analyze((ir) => ir
      ..label('function')
      ..ordinaryFunction(parameterCount: 1)
      ..label('block1')
      ..block(0, 0)
      ..label('block2')
      ..block(0, 0)
      ..label('block2end')
      ..end()
      ..label('block3')
      ..block(0, 0)
      ..end()
      ..label('block1end')
      ..end()
      ..label('block4')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.ancestorContainingAddress(
            scope: labelToScope['block2']!,
            address: ir.labelToAddress('block2end')!))
        .equals(labelToScope['block2']!);
    check(scopeAnalysisResult.ancestorContainingAddress(
            scope: labelToScope['block2']!,
            address: ir.labelToAddress('block2end')! + 1))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.ancestorContainingAddress(
            scope: labelToScope['block2']!,
            address: ir.labelToAddress('block1end')!))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.ancestorContainingAddress(
            scope: labelToScope['block2']!,
            address: ir.labelToAddress('block1end')! + 1))
        .equals(labelToScope['function']!);
  }

  void test_beginAddress() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('block')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.beginAddress(labelToScope['block']!)).equals(1);
  }

  void test_endAddress() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('block')
      ..block(0, 0)
      ..label('end')
      ..end()
      ..end());
    check(scopeAnalysisResult.endAddress(labelToScope['block']!))
        .equals(ir.labelToAddress('end')!);
  }

  void test_lastDescendant() {
    _analyze((ir) => ir
      ..label('function')
      ..ordinaryFunction(parameterCount: 1)
      ..label('block1')
      ..block(0, 0)
      ..end()
      ..label('block2')
      ..block(0, 0)
      ..label('block3')
      ..block(0, 0)
      ..end()
      ..end()
      ..end());
    check(scopeAnalysisResult.beginAddress(
            scopeAnalysisResult.lastDescendant(labelToScope['function']!)))
        .equals(ir.labelToAddress('block3')!);
    check(scopeAnalysisResult.beginAddress(
            scopeAnalysisResult.lastDescendant(labelToScope['block1']!)))
        .equals(ir.labelToAddress('block1')!);
    check(scopeAnalysisResult.beginAddress(
            scopeAnalysisResult.lastDescendant(labelToScope['block2']!)))
        .equals(ir.labelToAddress('block3')!);
    check(scopeAnalysisResult.beginAddress(
            scopeAnalysisResult.lastDescendant(labelToScope['block3']!)))
        .equals(ir.labelToAddress('block3')!);
  }

  void test_mostRecentScope_manyScopes() {
    _analyze((ir) => ir
      ..label('function')
      ..ordinaryFunction(parameterCount: 1)
      ..label('block1')
      ..block(0, 0)
      ..label('block2')
      ..block(0, 0)
      ..end()
      ..label('block3')
      ..block(0, 0)
      ..end()
      ..end()
      ..label('block4')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('function')!))
        .equals(labelToScope['function']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block1')! - 1))
        .equals(labelToScope['function']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block1')!))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block2')! - 1))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block2')!))
        .equals(labelToScope['block2']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block3')! - 1))
        .equals(labelToScope['block2']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block3')!))
        .equals(labelToScope['block3']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block4')! - 1))
        .equals(labelToScope['block3']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('block4')!))
        .equals(labelToScope['block4']!);
  }

  void test_mostRecentScope_oneScope() {
    _analyze((ir) => ir
      ..label('function')
      ..ordinaryFunction(parameterCount: 1)
      ..label('end')
      ..end());
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('function')!))
        .equals(labelToScope['function']!);
    check(scopeAnalysisResult.mostRecentScope(ir.labelToAddress('end')!))
        .equals(labelToScope['function']!);
  }

  void test_onAlloc_distinguishesAllocations() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('x')
      ..alloc(1)
      ..label('y')
      ..alloc(1)
      ..release(2)
      ..end());
    check(labelToStateVar['x']!).not((s) => s.equals(labelToStateVar['y']!));
  }

  void test_parent() {
    _analyze((ir) => ir
      ..label('function')
      ..ordinaryFunction(parameterCount: 1)
      ..label('block1')
      ..block(0, 0)
      ..label('block2')
      ..block(0, 0)
      ..end()
      ..label('block3')
      ..block(0, 0)
      ..end()
      ..end()
      ..label('block4')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.parent(labelToScope['function']!)).equals(-1);
    check(scopeAnalysisResult.parent(labelToScope['block1']!))
        .equals(labelToScope['function']!);
    check(scopeAnalysisResult.parent(labelToScope['block2']!))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.parent(labelToScope['block3']!))
        .equals(labelToScope['block1']!);
    check(scopeAnalysisResult.parent(labelToScope['block4']!))
        .equals(labelToScope['function']!);
  }

  void test_scopeCount() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('block')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.scopeCount).equals(2);
  }

  void test_stateVarAffected() {
    late StateVar stateVar;
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 4)
      ..onAnalyze((eventListener) => stateVar = eventListener.createStateVar())
      ..drop()
      ..label('block1')
      ..block(1, 0)
      ..drop()
      ..end()
      ..label('block2')
      ..block(1, 0)
      ..onAnalyze((eventListener) => eventListener.stateVarAffected(stateVar))
      ..drop()
      ..end()
      ..end());
    check(affectedStateVariables(labelToScope['block1']!))
        .not((s) => s.contains(stateVar));
    check(affectedStateVariables(labelToScope['block2']!)).contains(stateVar);
  }

  void test_stateVarCount() {
    createExtraStateVarPerScope = false;
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..alloc(2)
      ..alloc(3)
      ..release(3)
      ..alloc(2)
      ..release(4)
      ..end());
    check(scopeAnalysisResult.stateVarCount).equals(7);
  }

  void _analyze(void Function(_ScopeAnalyzerTestIRWriter) writeIR) {
    var writer = _ScopeAnalyzerTestIRWriter(_addressToOnAnalyzeCallbacks);
    writeIR(writer);
    ir = TestIRContainer(writer);
    validate(ir);
    var eventListener = _ScopeAnalyzerEventListener(this);
    scopeAnalysisResult = analyzeScopes(ir, eventListener: eventListener);
    check(
            because: 'make sure all callbacks got invoked',
            _addressToOnAnalyzeCallbacks)
        .isEmpty();
  }
}

final class _ScopeAnalyzerEventListener extends ScopeAnalyzerEventListener {
  final ScopeAnalyzerTest test;

  _ScopeAnalyzerEventListener(this.test);

  @override
  void onAlloc({required int index, required StateVar stateVar}) {
    if (test.ir.allocIndexToName(index) case var name?) {
      test.labelToStateVar[name] = stateVar;
    }
  }

  @override
  void onFinished() => _onAddress(test.ir.endAddress);

  @override
  void onInstruction(int address) => _onAddress(address);

  @override
  void onPushScope({required int address, required int scope}) {
    // Record the scope name.
    if (test.ir.addressToLabel(address) case var name?) {
      test.labelToScope[name] = scope;
    }
    if (test.createExtraStateVarPerScope) {
      createStateVar();
    }
  }

  void _onAddress(int address) {
    if (test._addressToOnAnalyzeCallbacks.remove(address) case var callbacks?) {
      for (var callback in callbacks) {
        callback(this);
      }
    }
  }
}

/// IR writer that can record callbacks to be executed during scope analysis.
///
/// These callbacks will have access to the [ScopeAnalyzerEventListener] so they
/// can query and modify scope analysis state.
class _ScopeAnalyzerTestIRWriter extends TestIRWriter {
  final Map<int, List<void Function(ScopeAnalyzerEventListener)>>
      _addressToOnAnalyzeCallbacks;

  _ScopeAnalyzerTestIRWriter(this._addressToOnAnalyzeCallbacks);

  void onAnalyze(void Function(ScopeAnalyzerEventListener) callback) {
    _addressToOnAnalyzeCallbacks
        .putIfAbsent(nextInstructionAddress, () => [])
        .add(callback);
  }
}
