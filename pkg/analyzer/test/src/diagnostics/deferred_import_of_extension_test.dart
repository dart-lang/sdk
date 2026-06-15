// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeferredImportOfExtensionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeferredImportOfExtensionTest extends PubPackageResolutionTest {
  Future<void> test_deferredImport_withExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart' deferred as foo;
//     ^^^^^^^^^^
// [diag.deferredImportOfExtension] Deferred library imports must hide all extension declarations.

void f() {
  foo.C();
}
''');
  }

  Future<void> test_deferredImport_withHiddenExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart' deferred as foo hide E;

void f() {
  foo.C();
}
''');
  }

  Future<void> test_deferredImport_withoutExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart' deferred as foo;

void f() {
  foo.C();
}
''');
  }

  Future<void> test_deferredImport_withShownNonExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart' deferred as foo show C;

void f() {
  foo.C();
}
''');
  }
}
