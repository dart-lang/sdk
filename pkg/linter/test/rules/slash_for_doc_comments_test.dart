// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SlashForDocCommentsTest);
  });
}

@reflectiveTest
class SlashForDocCommentsTest extends LintRuleTest {
  @override
  String get lintRule => 'slash_for_doc_comments';

  test_class() async {
    await assertDiagnostics(r'''
/** C */
class C {}
''', [
      lint(0, 8),
    ]);
  }

  test_constructor() async {
    await assertDiagnostics(r'''
class C {
  /** C */
  C();
}
''', [
      lint(12, 8),
    ]);
  }

  test_enum() async {
    await assertDiagnostics(r'''
/** E */
enum E {
  A,
  B
}
''', [
      lint(0, 8),
    ]);
  }

  test_enumConstant() async {
    await assertDiagnostics(r'''
enum E {
  /** A */
  A,
  B
}
''', [
      lint(11, 8),
    ]);
  }

  test_extension() async {
    await assertDiagnostics(r'''
/** A */
extension on int {}
''', [
      lint(0, 8),
    ]);
  }

  test_field() async {
    await assertDiagnostics(r'''
class C {
  /** x */
  var x;
}
''', [
      lint(12, 8),
    ]);
  }

  test_library() async {
    await assertDiagnostics(r'''
/** l */
library l;
''', [
      lint(0, 8),
    ]);
  }

  test_localFunction() async {
    await assertDiagnostics(r'''
void f() {
  /** g */
  // ignore: unused_element
  void g() {}
}
''', [
      lint(13, 8),
    ]);
  }

  test_method() async {
    await assertDiagnostics(r'''
class C {
  /** f */
  void f() {}
}
''', [
      lint(12, 8),
    ]);
  }

  test_mixin() async {
    await assertDiagnostics(r'''
/** M */
mixin M {}
''', [
      lint(0, 8),
    ]);
  }

  test_mixinApplication() async {
    await assertDiagnostics(r'''
/** C */
class C = Object with M;

mixin M {}
''', [
      lint(0, 8),
    ]);
  }

  test_noComment() async {
    await assertNoDiagnostics(r'''
mixin M {}
''');
  }

  test_oneAsterisk_class() async {
    await assertNoDiagnostics(r'''
/* C */
class C {}
''');
  }

  test_oneAsterisk_mixin() async {
    await assertNoDiagnostics(r'''
/* M */
mixin M {}
''');
  }

  test_threeSlashes_class() async {
    await assertNoDiagnostics(r'''
/// OK
class C {}
''');
  }

  test_topLevelFunction() async {
    await assertDiagnostics(r'''
/** f */
void f() {}
''', [
      lint(0, 8),
    ]);
  }

  test_topLevelVariable() async {
    await assertDiagnostics(r'''
/** x */
var x = 1;
''', [
      lint(0, 8),
    ]);
  }

  test_typedef_genericFunctionType() async {
    await assertDiagnostics(r'''
/** T */
typedef T = bool Function();
''', [
      lint(0, 8),
    ]);
  }

  test_typedef_legacy() async {
    await assertDiagnostics(r'''
/** F */
typedef bool F();
''', [
      lint(0, 8),
    ]);
  }

  test_typedef_nonFunction() async {
    await assertDiagnostics(r'''
/** T */
typedef T = Object;
''', [
      lint(0, 8),
    ]);
  }
}
