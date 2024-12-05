// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Add tests for field formal parameters.
    // TODO(srawlins): Add tests for super formal parameters.
    // TODO(srawlins): Add tests for local function parameters.
    // TODO(srawlins): Add tests for function literal parameters.
    // TODO(srawlins): Add tests for method parameters.
    // TODO(srawlins): Add tests for parameters with default values.
    defineReflectiveTests(AlwaysPutRequiredNamedParametersFirstTest);
  });
}

@reflectiveTest
class AlwaysPutRequiredNamedParametersFirstTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.always_put_required_named_parameters_first;

  test_constructor_requiredAfterOptional() async {
    await assertDiagnostics(r'''
class C {
  C.f({
    int? a,
    required int? b,
  });
}
''', [
      lint(48, 1),
    ]);
  }

  test_constructor_requiredAfterRequired() async {
    await assertNoDiagnostics(r'''
class C {
  C.f({
    required int? a,
    required int? b,
  });
}
''');
  }

  test_constructor_requiredAnnotationAfterOptional() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  C.f({
    int? a,
    @required int? b,
  });
}
''', [
      lint(82, 1),
    ]);
  }

  test_constructor_requiredAnnotationAfterRequiredAnnotation() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  C.f({
    @required int? a,
    @required int? b,
  });
}
''');
  }

  test_topLevelFunction_requiredAfterOptional() async {
    await assertDiagnostics(r'''
void f({
  int? a,
  required int? b,
}) {}
''', [
      lint(35, 1),
    ]);
  }

  test_topLevelFunction_requiredAfterRequired() async {
    await assertNoDiagnostics(r'''
void f({
  required int? a,
  required int? b,
}) {}
''');
  }

  test_topLevelFunction_requiredAnnotationAfterOptional() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
void f({
  int? a,
  @required int? b,
}) {}
''', [
      lint(69, 1),
    ]);
  }

  test_topLevelFunction_requiredAnnotationAfterRequiredAnnotation() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f({
  @required int? a,
  @required int? b,
}) {}
''');
  }
}
