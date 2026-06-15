// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidVisibilityAnnotationTest);
  });
}

@reflectiveTest
class InvalidVisibilityAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_fields_multipleMixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a = 0, b = 0;
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedField] The value of the field '_a' isn't used.
}
''');
  }

  test_fields_multiplePrivate() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a = 0, _b = 0;
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
// [diag.invalidVisibilityAnnotation] The member '_b' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedField] The value of the field '_a' isn't used.
//                               ^^
// [diag.unusedField] The value of the field '_b' isn't used.
}
''');
  }

  test_fields_multiplePublic() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int a = 0, b = 0;
}
''');
  }

  test_primaryConstructor_private() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C._() {
  @visibleForTesting
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
  this;
}
''');
  }

  test_primaryConstructor_public() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C.named() {
  @visibleForTesting
  this;
}
''');
  }

  test_privateClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting class _C {}
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_C' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedElement] The declaration '_C' isn't referenced.
''');
  }

  test_privateEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting enum _E {a, b}
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_E' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
void f(_E e) => e == _E.a || e == _E.b;
''');
  }

  test_privateExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting extension type _E(int i) {}
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_E' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                                ^^
// [diag.unusedElement] The declaration '_E' isn't referenced.
''');
  }

  test_privateField() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting int _a = 1;
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedField] The value of the field '_a' isn't used.
}
''');
  }

  test_privateMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting void _m() {}
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_m' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                        ^^
// [diag.unusedElement] The declaration '_m' isn't referenced.
}
''');
  }

  test_privateMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting mixin _M {}
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_M' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedElement] The declaration '_M' isn't referenced.
''');
  }

  test_privateTopLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting void _f() {}
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_f' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                      ^^
// [diag.unusedElement] The declaration '_f' isn't referenced.
''');
  }

  test_privateTopLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1;
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedElement] The declaration '_a' isn't referenced.
''');
  }

  test_privateTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting typedef _T = Function();
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_T' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                         ^^
// [diag.unusedElement] The declaration '_T' isn't referenced.
''');
  }

  test_secondaryConstructor_private() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting
// ^^^^^^^^^^^^^^^^^
// [diag.invalidVisibilityAnnotation] The member '_' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
  C._() {}
}
''');
  }

  test_secondaryConstructor_public() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @visibleForTesting
  C.named() {}
}
''');
  }

  test_topLevelVariable_multipleMixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1, b = 2;
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedElement] The declaration '_a' isn't referenced.
''');
  }

  test_topLevelVariable_multiplePrivate() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting final _a = 1, _b = 2;
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_a' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
// [diag.invalidVisibilityAnnotation][column 2][length 17] The member '_b' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members.
//                       ^^
// [diag.unusedElement] The declaration '_a' isn't referenced.
//                               ^^
// [diag.unusedElement] The declaration '_b' isn't referenced.
''');
  }

  test_topLevelVariable_multiplePublic() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting final a = 1, b = 2;
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@visibleForTesting void f() {}
@visibleForTesting enum E {a, b, c}
@visibleForTesting typedef T = Function();
@visibleForTesting class C1 {}
@visibleForTesting extension type ET1(int i) {}
extension type ET2(int i) {
  @visibleForTesting void m() {}
}
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
