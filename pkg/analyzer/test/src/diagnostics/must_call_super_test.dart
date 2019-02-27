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
  setUp() {
    super.setUp();
    addMetaPackage();
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
''', [HintCode.MUST_CALL_SUPER]);
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
''', [HintCode.MUST_CALL_SUPER]);
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
