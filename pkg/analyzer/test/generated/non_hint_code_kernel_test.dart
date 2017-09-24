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

@reflectiveTest
class NonHintCodeTest_Kernel extends NonHintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_deprecatedMemberUse_inDeprecatedLibrary() async {
    return super.test_deprecatedMemberUse_inDeprecatedLibrary();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingField_inInterface() async {
    return super.test_overrideOnNonOverridingField_inInterface();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingField_inSuperclass() async {
    return super.test_overrideOnNonOverridingField_inSuperclass();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingGetter_inInterface() async {
    return super.test_overrideOnNonOverridingGetter_inInterface();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingGetter_inSuperclass() async {
    return super.test_overrideOnNonOverridingGetter_inSuperclass();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingMethod_inInterface() async {
    return super.test_overrideOnNonOverridingMethod_inInterface();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingMethod_inSuperclass() async {
    return super.test_overrideOnNonOverridingMethod_inSuperclass();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingMethod_inSuperclass_abstract() async {
    return super.test_overrideOnNonOverridingMethod_inSuperclass_abstract();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingSetter_inInterface() async {
    return super.test_overrideOnNonOverridingSetter_inInterface();
  }

  @override
  @failingTest
  test_overrideOnNonOverridingSetter_inSuperclass() async {
    return super.test_overrideOnNonOverridingSetter_inSuperclass();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed() async {
    return super.test_proxy_annotation_prefixed();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed2() async {
    return super.test_proxy_annotation_prefixed2();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed3() async {
    return super.test_proxy_annotation_prefixed3();
  }

  @override
  @failingTest
  test_unusedImport_annotationOnDirective() async {
    return super.test_unusedImport_annotationOnDirective();
  }

  @override
  @failingTest
  test_unusedImport_metadata() async {
    return super.test_unusedImport_metadata();
  }
}
