// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Kernel);
  });
}

/// Tests marked with this annotation fail because they test features that
/// were implemented in Analyzer, but are intentionally not included into
/// the Dart 2.0 plan, or disabled for Dart 2.0 altogether.
const notForDart2 = const Object();

/// Tests marked with this annotation fail because of an Analyzer problem.
class AnalyzerProblem {
  const AnalyzerProblem(String issueUri);
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class NonErrorResolverTest_Kernel extends NonErrorResolverTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  @AnalyzerProblem('https://github.com/dart-lang/sdk/issues/33636')
  test_ambiguousImport_showCombinator() async {
    return super.test_ambiguousImport_showCombinator();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33795')
  test_annotated_partOfDeclaration() async {
    return super.test_annotated_partOfDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeConstructor() async {
    return super.test_commentReference_beforeConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeEnum() async {
    return super.test_commentReference_beforeEnum();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunction_blockBody() async {
    return super.test_commentReference_beforeFunction_blockBody();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunction_expressionBody() async {
    return super.test_commentReference_beforeFunction_expressionBody();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunctionTypeAlias() async {
    return super.test_commentReference_beforeFunctionTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeGenericTypeAlias() async {
    return super.test_commentReference_beforeGenericTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeGetter() async {
    return super.test_commentReference_beforeGetter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeMethod() async {
    return super.test_commentReference_beforeMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_class() async {
    return super.test_commentReference_class();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_setter() async {
    return super.test_commentReference_setter();
  }

  @override
  test_conflictingStaticSetterAndInstanceMember_thisClass_method() async {
    return super
        .test_conflictingStaticSetterAndInstanceMember_thisClass_method();
  }

  @override
  test_constConstructorWithMixinWithField_withoutSuperMixins() async {
    return super.test_constConstructorWithMixinWithField_withoutSuperMixins();
  }

  @override
  @failingTest
  test_constConstructorWithMixinWithField_withSuperMixins() async {
    return super.test_constConstructorWithMixinWithField_withSuperMixins();
  }

  @override
  @failingTest
  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    return super.test_finalNotInitialized_hasNativeClause_hasConstructor();
  }

  @override
  @failingTest
  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    return super.test_finalNotInitialized_hasNativeClause_noConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33799')
  test_functionTypeAlias_scope_signature() async {
    return super.test_functionTypeAlias_scope_signature();
  }

  @override // passes with kernel
  test_infer_mixin() => super.test_infer_mixin();

  @override // Passes with kernel
  test_infer_mixin_multiplyConstrained() =>
      super.test_infer_mixin_multiplyConstrained();

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30609')
  test_metadata_enumConstantDeclaration() {
    // Failed to resolve 2 nodes
    return super.test_metadata_enumConstantDeclaration();
  }

  @override
  @failingTest
  test_nativeConstConstructor() {
    return super.test_nativeConstConstructor();
  }

  @override
  test_null_callMethod() async {
    return super.test_null_callMethod();
  }

  @override
  test_null_callOperator() async {
    return super.test_null_callOperator();
  }

  @override
  @failingTest
  test_optionalNew_rewrite() {
    return super.test_optionalNew_rewrite();
  }

  @override
  @failingTest
  test_undefinedIdentifier_synthetic_whenMethodName() async {
    return super.test_undefinedIdentifier_synthetic_whenMethodName();
  }
}
