// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SlashForDocCommentsTest);
  });
}

@reflectiveTest
class SlashForDocCommentsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.slash_for_doc_comments;

  test_class() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** C */!]
class C {}
''');
  }

  test_constructor() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!/** C */!]
  C();
}
''');
  }

  test_enum() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** E */!]
enum E {
  A,
  B
}
''');
  }

  test_enumConstant() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  [!/** A */!]
  A,
  B
}
''');
  }

  test_extension() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** A */!]
extension on int {}
''');
  }

  test_field() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!/** x */!]
  var x;
}
''');
  }

  test_library() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** l */!]
library l;
''');
  }

  test_localFunction() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  [!/** g */!]
  // ignore: unused_element
  void g() {}
}
''');
  }

  test_method() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  [!/** f */!]
  void f() {}
}
''');
  }

  test_mixin() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** M */!]
mixin M {}
''');
  }

  test_mixinApplication() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** C */!]
class C = Object with M;

mixin M {}
''');
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

  test_primaryConstructorBody() async {
    await assertDiagnosticsFromMarkup(r'''
class C() {
  [!/** C */!]
  this;
}
''');
  }

  test_threeSlashes_class() async {
    await assertNoDiagnostics(r'''
/// OK
class C {}
''');
  }

  test_topLevelFunction() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** f */!]
void f() {}
''');
  }

  test_topLevelVariable() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** x */!]
var x = 1;
''');
  }

  test_typedef_genericFunctionType() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** T */!]
typedef T = bool Function();
''');
  }

  test_typedef_legacy() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** F */!]
typedef bool F();
''');
  }

  test_typedef_nonFunction() async {
    await assertDiagnosticsFromMarkup(r'''
[!/** T */!]
typedef T = Object;
''');
  }
}
