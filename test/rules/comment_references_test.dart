// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentReferencesTest);
  });
}

@reflectiveTest
class CommentReferencesTest extends LintRuleTest {
  @override
  String get lintRule => 'comment_references';

  test_false() async {
    await assertDiagnostics(r'''
/// [false]
class C {}
''', [
      lint(5, 5),
    ]);
  }

  test_field() async {
    await assertNoDiagnostics(r'''
class A {
  int x = 0;
  /// Assigns to [x].
  void m() {}
}
''');
  }

  test_importedElement() async {
    await assertNoDiagnostics(r'''
/// [String] is OK.
class C {}
''');
  }

  test_markdown_inlineLink() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256](http://tools.ietf.org/html/rfc6234) hash function.
class C {}
''');
  }

  test_markdown_inlineLink_withTitle() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256](http://tools.ietf.org/html/rfc6234 "Some") hash function.
class C {}
''');
  }

  test_markdown_referenceLink() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
class C {}
''');
  }

  test_markdown_referenceLink_shortcut() async {
    await assertNoDiagnostics(r'''
/// A link to [rfc][] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
class C {}
''');
  }

  test_null() async {
    await assertDiagnostics(r'''
/// [null]
class C {}
''', [
      lint(5, 4),
    ]);
  }

  test_parameter() async {
    await assertNoDiagnostics(r'''
class A {
  /// Reads [x].
  void m(int x) {}
}
''');
  }

  test_this() async {
    await assertDiagnostics(r'''
/// [this]
class C {}
''', [
      lint(5, 4),
    ]);
  }

  test_true() async {
    await assertDiagnostics(r'''
/// [true]
class C {}
''', [
      lint(5, 4),
    ]);
  }

  test_unclosedSquareBracket() async {
    await assertNoDiagnostics(r'''
/// [
/// ^--- Should not crash (#819).
class C {}
''');
  }

  test_unknownElement() async {
    await assertDiagnostics(r'''
/// Parameter [y].
void f(int x) {}
''', [
      lint(15, 1),
    ]);
  }
}
