// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverResolutionTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class AnalysisDriverResolutionTest_Kernel extends AnalysisDriverResolutionTest {
  @override
  bool get useCFE => true;

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_annotation_prefixed_classConstructor() {
    // TODO(paulberry): broken because prefixes are not working properly
    return super.test_annotation_prefixed_classConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_annotation_prefixed_classConstructorNamed() {
    // TODO(paulberry): broken because prefixes are not working properly
    return super.test_annotation_prefixed_classConstructorNamed();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_annotation_prefixed_classField() {
    // TODO(paulberry): broken because prefixes are not working properly
    return super.test_annotation_prefixed_classField();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_annotation_prefixed_topLevelVariable() {
    // TODO(paulberry): broken because prefixes are not working properly
    return super.test_annotation_prefixed_topLevelVariable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31605')
  test_constructor_redirected_generic() async {
    await super.test_constructor_redirected_generic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionExpressionInvocation() {
    // TODO(paulberry): broken because of in-progress FunctionTypeImpl rework
    return super.test_functionExpressionInvocation();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_instanceCreation_prefixed() {
    // TODO(paulberry): broken because prefixes are not working properly
    return super.test_instanceCreation_prefixed();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_isExpression_not() {
    // TODO(paulberry): I suspect that the special case for is! has bit rotted
    return super.test_isExpression_not();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_local_function_generic() {
    // TODO(paulberry): I suspect this is broken due to the function type's
    // generic parameters not being properly associated with the generic
    // parameters from the kernel representation.
    return super.test_local_function_generic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_type_functionTypeAlias() {
    // TODO(paulberry): broken because of in-progress FunctionTypeImpl rework
    return super.test_type_functionTypeAlias();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
