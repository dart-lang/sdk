// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_warning_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class StaticWarningCodeTest_Kernel extends StaticWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_argumentTypeNotAssignable_annotation_namedConstructor() async {
    return super.test_argumentTypeNotAssignable_annotation_namedConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_inConstructor_1() async {
    return super.test_finalNotInitialized_inConstructor_1();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_inConstructor_2() async {
    return super.test_finalNotInitialized_inConstructor_2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_inConstructor_3() async {
    return super.test_finalNotInitialized_inConstructor_3();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_importOfNonLibrary() async {
    return super.test_importOfNonLibrary();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverride_nonDefaultOverridesDefault() async {
    return super.test_invalidOverride_nonDefaultOverridesDefault();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverride_nonDefaultOverridesDefault_named() async {
    return super.test_invalidOverride_nonDefaultOverridesDefault_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_newWithUndefinedConstructorDefault() async {
    return super.test_newWithUndefinedConstructorDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_redirectToMissingConstructor_unnamed() async {
    return super.test_redirectToMissingConstructor_unnamed();
  }
}
