// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MatchingSuperParametersTest);
  });
}

@reflectiveTest
class MatchingSuperParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'matching_super_parameters';

  test_explicitSuperInvocation_matchingWithOffset() async {
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

  test_explicitSuperInvocation_matchingWithOffset_withNamedExplicit() async {
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

  test_explicitSuperInvocation_matchingWithOffset_withNamedSuper() async {
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

  test_explicitSuperInvocation_nonMatching() async {
    await assertDiagnostics(r'''
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
''', [
      lint(60, 7),
      lint(73, 7),
    ]);
  }

  test_implicitSuperInvocation_matchingWithGap() async {
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

  test_implicitSuperInvocation_matchingWithOffset() async {
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

  test_implicitSuperInvocation_nonMatching() async {
    await assertDiagnostics(r'''
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
''', [
      lint(60, 7),
      lint(73, 7),
    ]);
  }

  test_implicitSuperInvocation_nonMatching_omittedOptional() async {
    await assertDiagnostics(r'''
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
''', [
      lint(60, 7),
    ]);
  }

  test_implicitSuperInvocation_nonMatching_tooMany() async {
    await assertDiagnostics(r'''
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
''', [
      // No lint.
      error(
          CompileTimeErrorCode
              .SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL,
          79,
          1),
    ]);
  }
}
