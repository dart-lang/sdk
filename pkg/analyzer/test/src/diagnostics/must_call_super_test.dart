// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustCallSuperTest);
  });
}

@reflectiveTest
class MustCallSuperTest extends DriverResolutionTest with PackageMixin {
  @override
  setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_containsSuperCall() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a()
  {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 115, 1),
    ]);
  }

  test_fromExtendingClass_abstractInSubclass() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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

  test_fromInterface() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Mixin {
  @mustCallSuper
  void a() {}
}
class C with Mixin {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 120, 1),
    ]);
  }

  test_indirectlyInherited() async {
    await assertErrorsInCode(r'''
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
}
''', [
      error(HintCode.MUST_CALL_SUPER, 181, 1),
    ]);
  }

  test_indirectlyInheritedFromMixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class Mixin {
  @mustCallSuper
  void b() {}
}
class C extends Object with Mixin {}
class D extends C {
  @override
  void b() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 156, 1),
    ]);
  }

  test_indirectlyInheritedFromMixinConstraint() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  void a() {}
}
mixin C on A {
  @override
  void a() {}
}
''', [
      error(HintCode.MUST_CALL_SUPER, 110, 1),
    ]);
  }

  test_overriddenWithFuture() async {
    // https://github.com/flutter/flutter/issues/11646
    await assertNoErrorsInCode(r'''
import 'dart:async';
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
    await assertNoErrorsInCode(r'''
import 'dart:async';
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
