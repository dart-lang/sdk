// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest_Driver);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest_Driver extends CompileTimeErrorCodeTestBase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_awaitInWrongContext_sync() {
    return super.test_awaitInWrongContext_sync();
  }

  @override
  @failingTest
  test_constEvalThrowsException() {
    return super.test_constEvalThrowsException();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_typedef() {
    return super.test_genericFunctionTypeArgument_typedef();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_async() {
    return super.test_invalidIdentifierInAsync_async();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_await() {
    return super.test_invalidIdentifierInAsync_await();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_yield() {
    return super.test_invalidIdentifierInAsync_yield();
  }

  @override
  @failingTest
  test_mixinOfNonClass() {
    return super.test_mixinOfNonClass();
  }

  @override
  @failingTest
  test_objectCannotExtendAnotherClass() {
    return super.test_objectCannotExtendAnotherClass();
  }

  @override
  @failingTest
  test_superInitializerInObject() {
    return super.test_superInitializerInObject();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_async() {
    return super.test_yieldEachInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_sync() {
    return super.test_yieldEachInNonGenerator_sync();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_async() {
    return super.test_yieldInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_sync() {
    return super.test_yieldInNonGenerator_sync();
  }
}
