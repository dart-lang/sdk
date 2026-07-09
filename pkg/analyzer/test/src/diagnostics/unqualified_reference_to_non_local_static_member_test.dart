// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToNonLocalStaticMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnqualifiedReferenceToNonLocalStaticMemberTest
    extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
//         ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }

  test_getter_invoke() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void Function() get a => () {};
}

class B extends A {
  void b() {
    a();
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }

  test_getter_invokeTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 1;
}

class B extends A {
  static bar() {
    foo.abs();
//  ^^^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }

  test_methodTearoff() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void a<T>() {}
}
class B extends A {
  void b() {
    a<int>;
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }

  test_methodTearoff_noTypeArguments() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  static void a() {}
}
class B extends A {
  void b() {
    a;
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }

  test_readWrite() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}
class B extends A {
  void f() {
    x = 0;
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
    x += 1;
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
    ++x;
//    ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
    x++;
//  ^
// [diag.unqualifiedReferenceToNonLocalStaticMember] Static members from supertypes must be qualified by the name of the defining type.
  }
}
''');
  }
}
