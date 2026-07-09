// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustCallSuperTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MustCallSuperTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_containsSuperCall() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a(); // OK
  }
}
''');
  }

  test_fromExtendingClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_abstractInSubclass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
abstract class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a();
}
''');
  }

  test_fromExtendingClass_abstractInSuperclass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
abstract class A {
  @mustCallSuper
  void a();
}
class B extends A {
  @override
  void a() {}
}
''');
  }

  test_fromExtendingClass_genericClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A<T> {
  @mustCallSuper
  void a() {}
}
class B extends A<int> {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_genericMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a<T>() {}
}
class B extends A {
  @override
  void a<T>() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_getter() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  int get a => 1;
}
class B extends A {
  @override
  int get a => 2;
//        ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_getter_containsSuperCall() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  int get a => 1;
}
class B extends A {
  @override
  int get a {
    super.a;
    return 2;
  }
}
''');
  }

  test_fromExtendingClass_getter_invokesSuper_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int get foo => 0;

  set foo(int _) {}
}

class B extends A {
  int get foo {
//        ^^^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
    super.foo = 0;
    return 0;
  }
}
''');
  }

  test_fromExtendingClass_operator() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  operator ==(Object o) => o is A;
}
class B extends A {
  @override
  operator ==(Object o) => o is B;
//         ^^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_operator_containsSuperCall() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  operator ==(Object o) => o is A;
}
class B extends A {
  @override
  operator ==(Object o) => o is B && super == o;
}
''');
  }

  test_fromExtendingClass_setter() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  set a(int value) {}
}
class B extends A {
  @override
  set a(int value) {}
//    ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_fromExtendingClass_setter_containsSuperCall() async {
    await resolveTestCodeWithDiagnostics('''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  set a(int value) {}
}
class B extends A {
  @override
  set a(int value) {
    super.a = value;
  }
}
''');
  }

  test_fromExtendingClass_setter_invokesSuper_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  int get foo => 0;

  @mustCallSuper
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {
//    ^^^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
    super.foo;
  }
}
''');
  }

  test_fromInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C implements A {
  @override
  void a() {}
}
''');
  }

  test_fromMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
mixin Mixin {
  @mustCallSuper
  void a() {}
}
class C with Mixin {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'Mixin', but doesn't invoke the overridden method.
}
''');
  }

  test_fromMixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
mixin Mixin {
  @mustCallSuper
  void set a(int value) {}
}
class C with Mixin {
  @override
  void set a(int value) {}
//         ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'Mixin', but doesn't invoke the overridden method.
}
''');
  }

  test_fromMixin_throughExtendingClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
mixin M {
  @mustCallSuper
  void a() {}
}
class C with M {}
class D extends C {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'M', but doesn't invoke the overridden method.
}
''');
  }

  test_indirectlyInherited() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class C extends A {
  @override
  void a() {
    super.a();
  }
}
class D extends C {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_indirectlyInheritedFromMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
mixin Mixin {
  @mustCallSuper
  void b() {}
}
class C extends Object with Mixin {}
class D extends C {
  @override
  void b() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'Mixin', but doesn't invoke the overridden method.
}
''');
  }

  test_indirectlyInheritedFromMixinConstraint() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
mixin C on A {
  @override
  void a() {}
//     ^
// [diag.mustCallSuper] This method overrides a method annotated as '@mustCallSuper' in 'A', but doesn't invoke the overridden method.
}
''');
  }

  test_overriddenWithFuture() async {
    // https://github.com/flutter/flutter/issues/11646
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    final value = super.bar();
    return value.then((Null _) {
      return null;
    });
  }
}
''');
  }

  test_overriddenWithFuture2() async {
    // https://github.com/flutter/flutter/issues/11646
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  Future<Null> bar() => new Future<Null>.value();
}
class C extends A {
  @override
  Future<Null> bar() {
    return super.bar().then((Null _) {
      return null;
    });
  }
}
''');
  }
}
