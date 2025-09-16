// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterStyleTodosTest);
  });
}

@reflectiveTest
class FlutterStyleTodosTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.flutter_style_todos;

  // TODO(srawlins): line "// TODO(somebody): something,
  // github.com/flutter/flutter" currently isn't recognized as a
  // bad pattern, should the URI part be validated or should this
  // be an acceptable case
  test_badPatterns() async {
    await assertDiagnostics(
      r'''
// TODO something
// Todo something
// todo something
// TODO(somebody) something
// TODO: something
// Todo(somebody): something
// todo(somebody): something
// ToDo(somebody): something
// TODO(somebody): something, github.com/flutter/flutter
// ToDo(somebody): something, https://github.com/flutter/flutter
''',
      [
        lint(0, 17),
        lint(18, 17),
        lint(36, 17),
        lint(54, 27),
        lint(82, 18),
        lint(101, 28),
        lint(130, 28),
        lint(159, 28),
        lint(245, 64),
      ],
    );
  }

  test_badUsername_comma() async {
    await assertDiagnostics(r'// TODO(user1,user2): bla', [lint(0, 25)]);
  }

  test_badUsername_extraSymbols() async {
    await assertDiagnostics(r'// TODO(#12357): bla', [lint(0, 20)]);
  }

  test_charactersBeforeTODO() async {
    await assertNoDiagnostics(r'''
// comment TODO(user): bla
/// final todo = Todo(name: 'test todo', description: 'todo description');
/// Something interesting. TODO(someone): this is an ugly test case.
''');
  }

  test_docComment() async {
    await assertDiagnostics(r'/// TODO(user): bla', [lint(0, 19)]);
  }

  test_extraColon() async {
    await assertDiagnostics(r'// TODO:(user): bla', [lint(0, 19)]);
  }

  test_goodPatterns() async {
    await assertNoDiagnostics(r'''
// TODO(somebody): something
// TODO(somebody): something, https://github.com/flutter/flutter
''');
  }

  test_goodPatterns_noLeadingSpace() async {
    await assertNoDiagnostics(r'''
//TODO(somebody): something
//TODO(somebody): something, https://github.com/flutter/flutter
''');
  }

  test_justTodo() async {
    await assertDiagnostics(r'// TODO', [lint(0, 7)]);
  }

  test_justTodo_noLeadingSpace() async {
    await assertDiagnostics(r'//TODO', [lint(0, 6)]);
  }

  test_missingColon() async {
    await assertDiagnostics(r'// TODO(user) bla', [lint(0, 17)]);
  }

  test_missingMessage() async {
    await assertDiagnostics(
      r'''
//TODO(somebody):
// TODO(somebody):
''',
      [lint(0, 17), lint(18, 18)],
    );
  }

  test_missingParens() async {
    await assertDiagnostics(r'// TODO: bla', [lint(0, 12)]);
  }

  test_properFormat_dottedUsername() async {
    await assertNoDiagnostics(r'// TODO(user.name): bla');
  }

  test_properFormat_hyphenatedUsername() async {
    await assertNoDiagnostics(r'// TODO(user-name): bla');
  }

  test_properFormat_simpleUsername() async {
    await assertNoDiagnostics(r'// TODO(username): bla');
  }

  test_slashStar() async {
    await assertNoDiagnostics(r'/* TODO bla */');
  }

  test_slashStarStar() async {
    await assertNoDiagnostics(r'/** TODO bla **/');
  }

  test_spaceBeforeColon() async {
    await assertDiagnostics(r'// TODO(user) : bla', [lint(0, 19)]);
  }
}
