// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MatchingSuperParametersTest);
  });
}

@reflectiveTest
class MatchingSuperParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.matching_super_parameters;

  test_primaryToPrimary_explicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;

  this : super.named();
}

class C.named(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_primaryToPrimary_explicitInvocation_matchingWithOffset_withNamedExplicit() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;

  this : super.named(z: 1);
}

class C.named(this.x, this.y, {required this.z}) {
  final int x;
  final int y;
  final int z;
}
''');
  }

  test_primaryToPrimary_explicitInvocation_matchingWithOffset_withNamedSuper() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y, {required super.z}) extends C {
  final String w;

  this : super.named();
}

class C.named(this.x, this.y, {required this.z}) {
  final int x;
  final int y;
  final int z;
}
''');
  }

  test_primaryToPrimary_explicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/) extends C {
  final String w;

  this : super.named();
}

class C.named(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_primaryToPrimary_implicitInvocation_matchingWithGap() async {
    await assertNoDiagnostics(r'''
class D(super.x, this.w, super.y) extends C {
  final String w;
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_primaryToPrimary_implicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_primaryToPrimary_implicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/) extends C {
  final String w;
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_primaryToPrimary_implicitInvocation_nonMatching_omittedOptional() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, [!super.y!]) extends C {
  final String w;
}

class C(this.x, [this.y]) {
  final int x;
  final int? y;
}
''');
  }

  test_primaryToPrimary_implicitInvocation_nonMatching_tooMany() async {
    await assertDiagnostics(
      r'''
class D(this.w, super.y, super.x) extends C {
  final String w;
}

class C(this.x) {
  final int x;
}
''',
      [
        // No lint.
        error(diag.superFormalParameterWithoutAssociatedPositional, 31, 1),
      ],
    );
  }

  test_primaryToSecondary_explicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;

  this : super.named();
}

class C {
  final int x;
  final int y;

  C.named(this.x, this.y);
}
''');
  }

  test_primaryToSecondary_explicitInvocation_matchingWithOffset_withNamedExplicit() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;

  this : super.named(z: 1);
}

class C {
  final int x;
  final int y;
  final int z;

  C.named(this.x, this.y, {required this.z});
}
''');
  }

  test_primaryToSecondary_explicitInvocation_matchingWithOffset_withNamedSuper() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y, {required super.z}) extends C {
  final String w;

  this : super.named();
}

class C {
  final int x;
  final int y;
  final int z;

  C.named(this.x, this.y, {required this.z});
}
''');
  }

  test_primaryToSecondary_explicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/) extends C {
  final String w;

  this : super.named();
}

class C {
  final int x;
  final int y;

  C.named(this.x, this.y);
}
''');
  }

  test_primaryToSecondary_implicitInvocation_matchingWithGap() async {
    await assertNoDiagnostics(r'''
class D(super.x, this.w, super.y) extends C {
  final String w;
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''');
  }

  test_primaryToSecondary_implicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D(this.w, super.x, super.y) extends C {
  final String w;
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''');
  }

  test_primaryToSecondary_implicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/) extends C {
  final String w;
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''');
  }

  test_primaryToSecondary_implicitInvocation_nonMatching_omittedOptional() async {
    await assertDiagnosticsFromMarkdown(r'''
class D(this.w, [!super.y!]) extends C {
  final String w;
}

class C {
  final int x;
  final int? y;

  C(this.x, [this.y]);
}
''');
  }

  test_primaryToSecondary_implicitInvocation_nonMatching_tooMany() async {
    await assertDiagnostics(
      r'''
class D(this.w, super.y, super.x) extends C {
  final String w;
}

class C {
  final int x;

  C(this.x);
}
''',
      [
        // No lint.
        error(diag.superFormalParameterWithoutAssociatedPositional, 31, 1),
      ],
    );
  }

  test_secondaryToPrimary_explicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(this.w, super.x, super.y) : super.named();
}

class C.named(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_secondaryToPrimary_explicitInvocation_matchingWithOffset_withNamedExplicit() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(this.w, super.x, super.y) : super.named(z: 1);
}

class C.named(this.x, this.y, {required this.z}) {
  final int x;
  final int y;
  final int z;
}
''');
  }

  test_secondaryToPrimary_explicitInvocation_matchingWithOffset_withNamedSuper() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(this.w, super.x, super.y, {required super.z}) : super.named();
}

class C.named(this.x, this.y, {required this.z}) {
  final int x;
  final int y;
  final int z;
}
''');
  }

  test_secondaryToPrimary_explicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D extends C {
  final String w;

  D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/) : super.named();
}

class C.named(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_secondaryToPrimary_implicitInvocation_matchingWithGap() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(super.x, this.w, super.y);
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_secondaryToPrimary_implicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(this.w, super.x, super.y);
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_secondaryToPrimary_implicitInvocation_nonMatching() async {
    await assertDiagnosticsFromMarkdown(r'''
class D extends C {
  final String w;

  D(this.w, /*[0*/super.y/*0]*/, /*[1*/super.x/*1]*/);
}

class C(this.x, this.y) {
  final int x;
  final int y;
}
''');
  }

  test_secondaryToPrimary_implicitInvocation_nonMatching_omittedOptional() async {
    await assertDiagnosticsFromMarkdown(r'''
class D extends C {
  final String w;

  D(this.w, [!super.y!]);
}

class C(this.x, [this.y]) {
  final int x;
  final int? y;
}
''');
  }

  test_secondaryToPrimary_implicitInvocation_nonMatching_tooMany() async {
    await assertDiagnostics(
      r'''
class D extends C {
  final String w;

  D(this.w, super.y, super.x);
}

class C(this.x) {
  final int x;
}
''',
      [
        // No lint.
        error(diag.superFormalParameterWithoutAssociatedPositional, 66, 1),
      ],
    );
  }

  test_secondaryToSecondary_explicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.x,
    super.y,
  ) : super.named();
}

class C {
  final int x;
  final int y;

  C.named(this.x, this.y);
}
''');
  }

  test_secondaryToSecondary_explicitInvocation_matchingWithOffset_withNamedExplicit() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.x,
    super.y,
  ) : super.named(z: 1);
}

class C {
  final int x;
  final int y;
  final int z;

  C.named(this.x, this.y, {required this.z});
}
''');
  }

  test_secondaryToSecondary_explicitInvocation_matchingWithOffset_withNamedSuper() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.x,
    super.y, {
    required super.z,
  }) : super.named();
}

class C {
  final int x;
  final int y;
  final int z;

  C.named(this.x, this.y, {required this.z});
}
''');
  }

  test_secondaryToSecondary_explicitInvocation_nonMatching() async {
    await assertDiagnostics(
      r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.y,
    super.x,
  ) : super.named();
}

class C {
  final int x;
  final int y;

  C.named(this.x, this.y);
}
''',
      [lint(60, 7), lint(73, 7)],
    );
  }

  test_secondaryToSecondary_implicitInvocation_matchingWithGap() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(
    super.x,
    this.w,
    super.y,
  );
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''');
  }

  test_secondaryToSecondary_implicitInvocation_matchingWithOffset() async {
    await assertNoDiagnostics(r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.x,
    super.y,
  );
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''');
  }

  test_secondaryToSecondary_implicitInvocation_nonMatching() async {
    await assertDiagnostics(
      r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.y,
    super.x,
  );
}

class C {
  final int x;
  final int y;

  C(this.x, this.y);
}
''',
      [lint(60, 7), lint(73, 7)],
    );
  }

  test_secondaryToSecondary_implicitInvocation_nonMatching_omittedOptional() async {
    await assertDiagnostics(
      r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.y,
  );
}

class C {
  final int x;
  final int? y;

  C(this.x, [this.y]);
}
''',
      [lint(60, 7)],
    );
  }

  test_secondaryToSecondary_implicitInvocation_nonMatching_tooMany() async {
    await assertDiagnostics(
      r'''
class D extends C {
  final String w;

  D(
    this.w,
    super.y,
    super.x,
  );
}

class C {
  final int x;

  C(this.x);
}
''',
      [
        // No lint.
        error(diag.superFormalParameterWithoutAssociatedPositional, 79, 1),
      ],
    );
  }
}
