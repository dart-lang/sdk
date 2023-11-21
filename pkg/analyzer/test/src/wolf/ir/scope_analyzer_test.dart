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
  final labelToScope = <String, int>{};
  late final TestIRContainer ir;
  late final Scopes scopeAnalysisResult;

  LiteralRef get dummyLiteral => LiteralRef(0);

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

  void test_scopeCount() {
    _analyze((ir) => ir
      ..ordinaryFunction(parameterCount: 1)
      ..label('block')
      ..block(0, 0)
      ..end()
      ..end());
    check(scopeAnalysisResult.scopeCount).equals(2);
  }

  void _analyze(void Function(TestIRWriter) writeIR) {
    var writer = TestIRWriter();
    writeIR(writer);
    ir = TestIRContainer(writer);
    validate(ir);
    scopeAnalysisResult = analyzeScopes(ir,
        eventListener:
            _ScopeAnalyzerEventListener(ir: ir, labelToScope: labelToScope));
  }
}

final class _ScopeAnalyzerEventListener extends ScopeAnalyzerEventListener {
  final TestIRContainer ir;
  final Map<String, int> labelToScope;

  _ScopeAnalyzerEventListener({required this.ir, required this.labelToScope});

  @override
  void onPushScope({required int address, required int scope}) {
    // Record the scope name.
    if (ir.addressToLabel(address) case var name?) {
      labelToScope[name] = scope;
    }
  }
}
