// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_hint_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class NonHintCodeTest_Kernel extends NonHintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get previewDart2 => true;

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_deadCode_deadBlock_if_debugConst_propertyAccessor() async {
    await super.test_deadCode_deadBlock_if_debugConst_propertyAccessor();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_deadCode_statementAfterIfWithoutElse() async {
    await super.test_deadCode_statementAfterIfWithoutElse();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    await super.test_deprecatedMemberUse_inDeprecatedLibrary();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_divisionOptimization() async {
//    NoSuchMethodError: The getter 'element' was called on null.
//    Receiver: null
//    Tried calling: element
//    #0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)
//    #1      ResolutionApplier.visitMethodInvocation (package:analyzer/src/fasta/resolution_applier.dart:385:48)
//    #2      MethodInvocationImpl.accept (package:analyzer/src/dart/ast/ast.dart:7595:49)
//    #3      ResolutionApplier.visitBinaryExpression (package:analyzer/src/fasta/resolution_applier.dart:115:23)
    await super.test_divisionOptimization();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_divisionOptimization_supressIfDivisionNotDefinedInCore() async {
    await super.test_divisionOptimization_supressIfDivisionNotDefinedInCore();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_divisionOptimization_supressIfDivisionOverridden() async {
    await super.test_divisionOptimization_supressIfDivisionOverridden();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_duplicateImport_as() async {
    // Expected 0 errors of type HintCode.UNUSED_IMPORT, found 1 (38)
    await super.test_duplicateImport_as();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_importDeferredLibraryWithLoadFunction() async {
    await super.test_importDeferredLibraryWithLoadFunction();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_propagatedFieldType() async {
    await super.test_propagatedFieldType();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_proxy_annotation_prefixed() async {
    await super.test_proxy_annotation_prefixed();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_proxy_annotation_prefixed2() async {
    await super.test_proxy_annotation_prefixed2();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_proxy_annotation_prefixed3() async {
    await super.test_proxy_annotation_prefixed3();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_undefinedMethod_dynamic() async {
    await super.test_undefinedMethod_dynamic();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_undefinedMethod_inSubtype() async {
    await super.test_undefinedMethod_inSubtype();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_undefinedMethod_unionType_all() async {
    await super.test_undefinedMethod_unionType_all();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_undefinedMethod_unionType_some() async {
    await super.test_undefinedMethod_unionType_some();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unnecessaryCast_13855_parameter_A() async {
    await super.test_unnecessaryCast_13855_parameter_A();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unnecessaryCast_conditionalExpression() async {
    await super.test_unnecessaryCast_conditionalExpression();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unnecessaryCast_generics() async {
    await super.test_unnecessaryCast_generics();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_as_equalPrefixes() async {
    await super.test_unusedImport_as_equalPrefixes();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_metadata() async {
    await super.test_unusedImport_metadata();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_prefix_topLevelFunction() async {
    await super.test_unusedImport_prefix_topLevelFunction();
  }

  @failingTest
  @override
  @potentialAnalyzerProblem
  test_unusedImport_prefix_topLevelFunction2() async {
    await super.test_unusedImport_prefix_topLevelFunction2();
  }
}
