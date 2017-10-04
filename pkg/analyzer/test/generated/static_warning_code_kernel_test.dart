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
  test_argumentTypeNotAssignable_annotation_namedConstructor() async {
    return super.test_argumentTypeNotAssignable_annotation_namedConstructor();
  }

  @override
  @failingTest
  test_caseBlockNotTerminated() async {
    return super.test_caseBlockNotTerminated();
  }

  @override
  @failingTest
  test_constWithAbstractClass() async {
    return super.test_constWithAbstractClass();
  }

  @override
  @failingTest
  test_fieldInitializedInInitializerAndDeclaration_final() async {
    return super.test_fieldInitializedInInitializerAndDeclaration_final();
  }

  @override
  @failingTest
  test_finalInitializedInDeclarationAndConstructor_initializers() async {
    return super
        .test_finalInitializedInDeclarationAndConstructor_initializers();
  }

  @override
  @failingTest
  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    return super
        .test_finalInitializedInDeclarationAndConstructor_initializingFormal();
  }

  @override
  @failingTest
  test_finalNotInitialized_inConstructor_1() async {
    return super.test_finalNotInitialized_inConstructor_1();
  }

  @override
  @failingTest
  test_finalNotInitialized_inConstructor_2() async {
    return super.test_finalNotInitialized_inConstructor_2();
  }

  @override
  @failingTest
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
  test_invalidOverride_nonDefaultOverridesDefault() async {
    return super.test_invalidOverride_nonDefaultOverridesDefault();
  }

  @override
  @failingTest
  test_invalidOverride_nonDefaultOverridesDefault_named() async {
    return super.test_invalidOverride_nonDefaultOverridesDefault_named();
  }

  @override
  @failingTest
  test_newWithAbstractClass() async {
    return super.test_newWithAbstractClass();
  }

  @override
  @failingTest
  test_newWithUndefinedConstructorDefault() async {
    return super.test_newWithUndefinedConstructorDefault();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_unnamed() async {
    return super.test_redirectToMissingConstructor_unnamed();
  }
}
