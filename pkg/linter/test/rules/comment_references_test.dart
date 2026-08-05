// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentReferencesTest);
  });
}

@reflectiveTest
class CommentReferencesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.comment_references;

  test_false() async {
    await assertDiagnosticsFromMarkup(r'''
/// [[!false!]]
class C {}
''');
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
    await assertDiagnosticsFromMarkup(r'''
/// [[!null!]]
class C {}
''');
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

  test_parameter_constructor_privateNamed_invalid() async {
    // See https://github.com/dart-lang/sdk/issues/62768#issuecomment-3963248264
    // for context on why a lint is expected here.
    await assertDiagnosticsFromMarkup(r'''
class A {
  final int _x;

  /// [[!x!]]
  A({required this._x});
}
''');
  }

  test_parameter_constructor_privateNamed_valid() async {
    await assertNoDiagnostics(r'''
class A {
  final int _x;

  /// [_x]
  A({required this._x});
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

  test_prefixedIdentifier_constructorTearoff() async {
    await assertNoDiagnostics(r'''
/// Text [Future.delayed].
class C {}
''');
  }

  test_prefixedIdentifier_importPrefix() async {
    await assertNoDiagnostics(r'''
import 'dart:async' as async;
/// Text [async.FutureOr].
class C {}
''');
  }

  test_prefixedIdentifier_instanceMember() async {
    await assertNoDiagnostics(r'''
/// Text [int.isEven].
class C {}
''');
  }

  test_prefixedIdentifier_instanceMember_onTypedef() async {
    await assertNoDiagnostics(r'''
typedef int2 = int;

/// Text [int2.isEven].
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

  test_propertyAccess_onTypedef() async {
    await assertNoDiagnostics(r'''
import '' as self;
class A {
  int get x => 7;
}
typedef B = A;

/// Text [self.B.x].
class C {}
''');
  }

  test_this() async {
    await assertDiagnosticsFromMarkup(r'''
/// [[!this!]]
class C {}
''');
  }

  test_true() async {
    await assertDiagnosticsFromMarkup(r'''
/// [[!true!]]
class C {}
''');
  }

  test_typeAlias() async {
    await assertNoDiagnostics(r'''
/// Text [Td].
class C {}

typedef Td = C;
''');
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
    await assertDiagnosticsFromMarkup(r'''
/// Text [[!y!]].
class C {}
''');
  }

  test_unknownElement_dottedName() async {
    await assertDiagnosticsFromMarkup(r'''
/// Parameter [[!y.z!]].
class C {}
''');
  }

  test_unknownElement_followedByColon() async {
    await assertDiagnosticsFromMarkup(r'''
/// Parameter [[!y!]]: z.
void f(int x) {}
''');
  }

  test_unknownElement_twiceDottedName() async {
    await assertDiagnosticsFromMarkup(r'''
/// Parameter [[!x.y.z!]].
class C {}
''');
  }
}
