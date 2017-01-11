// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Driver);
  });
}

@reflectiveTest
class NonErrorResolverTest_Driver extends NonErrorResolverTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_class_type_alias_documentationComment() {
    return super.test_class_type_alias_documentationComment();
  }

  @failingTest
  @override
  test_commentReference_beforeConstructor() {
    return super.test_commentReference_beforeConstructor();
  }

  @failingTest
  @override
  test_commentReference_beforeEnum() {
    return super.test_commentReference_beforeEnum();
  }

  @failingTest
  @override
  test_commentReference_beforeFunction_blockBody() {
    return super.test_commentReference_beforeFunction_blockBody();
  }

  @failingTest
  @override
  test_commentReference_beforeFunction_expressionBody() {
    return super.test_commentReference_beforeFunction_expressionBody();
  }

  @failingTest
  @override
  test_commentReference_beforeFunctionTypeAlias() {
    return super.test_commentReference_beforeFunctionTypeAlias();
  }

  @failingTest
  @override
  test_commentReference_beforeGetter() {
    return super.test_commentReference_beforeGetter();
  }

  @failingTest
  @override
  test_commentReference_beforeMethod() {
    return super.test_commentReference_beforeMethod();
  }

  @failingTest
  @override
  test_commentReference_class() {
    return super.test_commentReference_class();
  }

  @failingTest
  @override
  test_commentReference_setter() {
    return super.test_commentReference_setter();
  }

  @failingTest
  @override
  test_invalidAnnotation_constantVariable_field_importWithPrefix() {
    return super
        .test_invalidAnnotation_constantVariable_field_importWithPrefix();
  }

  @failingTest
  @override
  test_issue_24191() {
    return super.test_issue_24191();
  }

  @failingTest
  @override
  test_nativeConstConstructor() {
    return super.test_nativeConstConstructor();
  }

  @failingTest
  @override
  test_nativeFunctionBodyInNonSDKCode_function() {
    return super.test_nativeFunctionBodyInNonSDKCode_function();
  }
}
