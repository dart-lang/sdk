// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidVisibilityAnnotationTest);
  });
}

@reflectiveTest
class InvalidVisibilityAnnotationTest extends DriverResolutionTest
    with PackageMixin {
  @override
  void setUp() {
    super.setUp();
    addMetaPackage();
  }

  test_fields_multipleMixed() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a, b;
}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_fields_multiplePrivate() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a, _b;
}
''', [
      HintCode.INVALID_VISIBILITY_ANNOTATION,
      HintCode.INVALID_VISIBILITY_ANNOTATION
    ]);
  }

  test_fields_multiplePublic() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int a, b;
}
''');
  }

  test_privateClass() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting class _C {}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateConstructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting C._() {}
}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateEnum() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting enum _E {a, b, c}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateField() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a;
}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateMethod() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting void _m() {}
}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateMixin() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting mixin _M {}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateTopLevelFunction() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting void _f() {}
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateTopLevelVariable() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1;
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_privateTypedef() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting typedef _T = Function();
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_topLevelVariable_multipleMixed() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1, b = 2;
''', [HintCode.INVALID_VISIBILITY_ANNOTATION]);
  }

  test_topLevelVariable_multiplePrivate() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1, _b = 2;
''', [
      HintCode.INVALID_VISIBILITY_ANNOTATION,
      HintCode.INVALID_VISIBILITY_ANNOTATION
    ]);
  }

  test_topLevelVariable_multiplePublic() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting final a = 1, b = 2;
''');
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@visibleForTesting void f() {}
@visibleForTesting enum E {a, b, c}
@visibleForTesting typedef T = Function();
@visibleForTesting class C1 {}
@visibleForTesting mixin M {}
class C2 {
  @visibleForTesting C2.named() {}
}
class C3 {
  @visibleForTesting void m() {}
}
''');
  }
}
