// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToStaticMemberOfExtendedTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnqualifiedReferenceToStaticMemberOfExtendedTypeTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics('''
class MyClass {
  static int get zero => 0;
}
extension MyExtension on MyClass {
  void m() {
    zero;
//  ^^^^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
  }
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics('''
class MyClass {
  static void sm() {}
}
extension MyExtension on MyClass {
  void m() {
    sm();
//  ^^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
  }
}
''');
  }

  test_methodTearoff() async {
    await resolveTestCodeWithDiagnostics('''
class MyClass {
  static void sm<T>() {}
}
extension MyExtension on MyClass {
  void m() {
    sm<int>;
//  ^^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
  }
}
''');
  }

  test_readWrite() async {
    await resolveTestCodeWithDiagnostics('''
class MyClass {
  static int get x => 0;
  static set x(int _) {}
}

extension MyExtension on MyClass {
  void f() {
    x = 0;
//  ^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
    x += 1;
//  ^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
    ++x;
//    ^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
    x++;
//  ^
// [diag.unqualifiedReferenceToStaticMemberOfExtendedType] Static members from the extended type or one of its superclasses must be qualified by the name of the defining type.
  }
}
''');
  }
}
