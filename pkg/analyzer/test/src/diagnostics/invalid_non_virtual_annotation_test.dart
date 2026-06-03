// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNonVirtualAnnotationTest);
  });
}

@reflectiveTest
class InvalidNonVirtualAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
  int m = 7;
}
''');
  }

  test_instanceField_originPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

abstract class C(@nonVirtual final int m);
''');
  }

  test_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
  void m() {}
}
''');
  }

  test_instanceMethod_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

abstract class C {
  @nonVirtual
// ^^^^^^^^^^
// [diag.invalidNonVirtualAnnotation] The annotation '@nonVirtual' can only be applied to a concrete instance member.
  void m();
}
''');
  }

  test_instanceMethod_onExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

extension type E(int i) {
  @nonVirtual
// ^^^^^^^^^^
// [diag.invalidNonVirtualAnnotation] The annotation '@nonVirtual' can only be applied to a concrete instance member.
  void m() { }
}
''');
  }

  test_parameter_onPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

abstract class C(@nonVirtual int m);
//                ^^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'nonVirtual' can only be used on overridable members.
''');
  }
}
