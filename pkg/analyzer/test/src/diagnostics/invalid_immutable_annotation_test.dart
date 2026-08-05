// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImmutableAnnotationTest);
  });
}

@reflectiveTest
class InvalidImmutableAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class A {
  const A();
}
''');
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
extension type E(int i) {}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @immutable
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'immutable' can only be used on classes, extension types, or mixins.
  void m() {}
}
''');
  }
}
