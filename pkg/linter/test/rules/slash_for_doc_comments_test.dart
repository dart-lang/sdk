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
    await assertDiagnosticsFromMarkdown(r'''
[!/** C */!]
class C {}
''');
  }

  test_constructor() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!/** C */!]
  C();
}
''');
  }

  test_enum() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** E */!]
enum E {
  A,
  B
}
''');
  }

  test_enumConstant() async {
    await assertDiagnosticsFromMarkdown(r'''
enum E {
  [!/** A */!]
  A,
  B
}
''');
  }

  test_extension() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** A */!]
extension on int {}
''');
  }

  test_field() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!/** x */!]
  var x;
}
''');
  }

  test_library() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** l */!]
library l;
''');
  }

  test_localFunction() async {
    await assertDiagnosticsFromMarkdown(r'''
void f() {
  [!/** g */!]
  // ignore: unused_element
  void g() {}
}
''');
  }

  test_method() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!/** f */!]
  void f() {}
}
''');
  }

  test_mixin() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** M */!]
mixin M {}
''');
  }

  test_mixinApplication() async {
    await assertDiagnosticsFromMarkdown(r'''
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
    await assertDiagnosticsFromMarkdown(r'''
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
    await assertDiagnosticsFromMarkdown(r'''
[!/** f */!]
void f() {}
''');
  }

  test_topLevelVariable() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** x */!]
var x = 1;
''');
  }

  test_typedef_genericFunctionType() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** T */!]
typedef T = bool Function();
''');
  }

  test_typedef_legacy() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** F */!]
typedef bool F();
''');
  }

  test_typedef_nonFunction() async {
    await assertDiagnosticsFromMarkdown(r'''
[!/** T */!]
typedef T = Object;
''');
  }
}
