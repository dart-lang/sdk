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
  String get lintRule => LintNames.comment_references;

  test_constructorTearoff() async {
    await assertNoDiagnostics(r'''
/// Text [Future.delayed].
class C {}
''');
  }

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

  test_markdown_inlineLink_onePeriod() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256.Sha256](http://tools.ietf.org/html/rfc6234) hash function.
class C {}
''');
  }

  test_markdown_inlineLink_textSpansLines() async {
    await assertNoDiagnostics(r'''
/// A [link spanning
/// multiple lines](http://tools.ietf.org/html/rfc6234)
class C {}
''');
  }

  test_markdown_inlineLink_twoPeriods() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256.Sha256.Sha256](http://tools.ietf.org/html/rfc6234) hash function.
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

  test_markdown_referenceLink_onePeriod() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256.Sha256][rfc] hash function.
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

  test_markdown_referenceLink_shortcut_onePeriod() async {
    await assertNoDiagnostics(r'''
/// A link to [rfc.rfc][] hash function.
///
/// [rfc.rfc]: http://tools.ietf.org/html/rfc6234
class C {}
''');
  }

  test_markdown_referenceLink_shortcut_twoPeriods() async {
    await assertNoDiagnostics(r'''
/// A link to [rfc.rfc.rfc][] hash function.
///
/// [rfc.rfc.rfc]: http://tools.ietf.org/html/rfc6234
class C {}
''');
  }

  test_markdown_referenceLink_twoPeriods() async {
    await assertNoDiagnostics(r'''
/// A link to [Sha256.Sha256.Sha256][rfc] hash function.
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

  test_parameter_constructor_field() async {
    await assertNoDiagnostics(r'''
class A {
  final int x;

  /// [x]
  A(this.x);
}
''');
  }

  test_parameter_constructor_super() async {
    await assertNoDiagnostics(r'''
class A {
  A(int x);
}

class B extends A {
  /// [x]
  B(super.x);
}
''');
  }

  test_prefixedIdentifier_importPrefix() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as async;
/// Text [async.FutureOr].
class C {}
''');
  }

  test_prefixedIdentifier_staticMethod() async {
    await assertNoDiagnostics(r'''
/// Text [Future.wait].
class C {}
''');
  }

  test_prefixedIdentifier_staticProperty() async {
    await assertNoDiagnostics(r'''
/// Text [double.nan].
class C {}
''');
  }

  test_propertyAccess() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as async;
/// Text [async.Future.value].
class C {}
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

  test_typeName() async {
    await assertNoDiagnostics(r'''
/// Text [Future].
class C {}
''');
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
/// Text [y].
class C {}
''', [
      lint(10, 1),
    ]);
  }

  test_unknownElement_dottedName() async {
    await assertDiagnostics(r'''
/// Parameter [y.z].
class C {}
''', [
      lint(15, 3),
    ]);
  }

  test_unknownElement_followedByColon() async {
    await assertDiagnostics(r'''
/// Parameter [y]: z.
void f(int x) {}
''', [
      lint(15, 1),
    ]);
  }

  test_unknownElement_twiceDottedName() async {
    await assertDiagnostics(r'''
/// Parameter [x.y.z].
class C {}
''', [
      lint(15, 5),
    ]);
  }
}
