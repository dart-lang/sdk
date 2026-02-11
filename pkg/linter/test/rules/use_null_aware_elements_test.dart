// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseNullAwareElementsTest);
  });
}

@reflectiveTest
class UseNullAwareElementsTest extends LintRuleTest {
  @override
  String get lintRule => 'use_null_aware_elements';

  test_nonPromotable_nullCheck_list() async {
    await assertDiagnostics(
      r'''
int count = 0;
int? get x => count++;
List<int> f() {
  return [
    if (x != null) x,
    if (null != x) x,
  ];
}
''',
      [
        // No lints, since `x` is not promotable.
        error(diag.listElementTypeNotAssignableNullability, 84, 1),
        error(diag.listElementTypeNotAssignableNullability, 106, 1),
      ],
    );
  }

  test_nullCheck_list() async {
    await assertDiagnostics(
      r'''
List<int> f(int? x) {
  return [
    if (x != null) x,
    if (null != x) x,
  ];
}
''',
      [lint(37, 2), lint(59, 2)],
    );
  }

  test_nullCheck_mapKey() async {
    await assertDiagnostics(
      r'''
Map<int, String> f(int? x, int? y) {
  return {
    if (x != null) x: "",
    if (null != y) y: "",
  };
}
''',
      [lint(52, 2), lint(78, 2)],
    );
  }

  test_nullCheck_mapKeyAndValue() async {
    await assertDiagnostics(
      r'''
Map<int, int> f(int? x) {
  return {
    if (x != null) x: x,
  };
}
''',
      [lint(41, 2)],
    );
  }

  test_nullCheck_mapValue() async {
    await assertDiagnostics(
      r'''
Map<String, int> f(int? x, int? y) {
  return {
    if (x != null) "key1": x,
    if (null != y) "key2": y,
  };
}
''',
      [lint(52, 2), lint(82, 2)],
    );
  }

  test_nullCheck_set() async {
    await assertDiagnostics(
      r'''
Set<int> f(int? x, int? y) {
  return {
    if (x != null) x,
    if (null != y) y,
  };
}
''',
      [lint(44, 2), lint(66, 2)],
    );
  }

  test_nullCheckPattern_list() async {
    await assertDiagnostics(
      r'''
List<int> f(int? x) {
  return [
    if (x case var y?) y,
  ];
}
''',
      [lint(37, 2)],
    );
  }

  test_nullCheckPattern_mapKey() async {
    await assertDiagnostics(
      r'''
Map<int, String> f(int? x) {
  return {
    if (x case var y?) y: "value",
  };
}
''',
      [lint(44, 2)],
    );
  }

  test_nullCheckPattern_mapValue() async {
    await assertDiagnostics(
      r'''
Map<String, int> f(int? x) {
  return {
    if (x case var y?) "key": y,
  };
}
''',
      [lint(44, 2)],
    );
  }

  test_nullCheckPattern_set() async {
    await assertDiagnostics(
      r'''
Set<int> f(int? x) {
  return {
    if (x case var y?) y,
  };
}
''',
      [lint(36, 2)],
    );
  }

  test_nullCheckPattern_whenClause_list() async {
    await assertNoDiagnostics(r'''
List<int> f(int? x) {
  return [
    if (x case var y? when y.isEven) y,
  ];
}
''');
  }
}
