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
  String get lintRule => LintNames.use_null_aware_elements;

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
    await assertDiagnosticsFromMarkup(r'''
List<int> f(int? x) {
  return [
    /*[0*/if/*0]*/ (x != null) x,
    /*[1*/if/*1]*/ (null != x) x,
  ];
}
''');
  }

  test_nullCheck_mapKey() async {
    await assertDiagnosticsFromMarkup(r'''
Map<int, String> f(int? x, int? y) {
  return {
    /*[0*/if/*0]*/ (x != null) x: "",
    /*[1*/if/*1]*/ (null != y) y: "",
  };
}
''');
  }

  test_nullCheck_mapKeyAndValue() async {
    await assertDiagnosticsFromMarkup(r'''
Map<int, int> f(int? x) {
  return {
    [!if!] (x != null) x: x,
  };
}
''');
  }

  test_nullCheck_mapValue() async {
    await assertDiagnosticsFromMarkup(r'''
Map<String, int> f(int? x, int? y) {
  return {
    /*[0*/if/*0]*/ (x != null) "key1": x,
    /*[1*/if/*1]*/ (null != y) "key2": y,
  };
}
''');
  }

  test_nullCheck_set() async {
    await assertDiagnosticsFromMarkup(r'''
Set<int> f(int? x, int? y) {
  return {
    /*[0*/if/*0]*/ (x != null) x,
    /*[1*/if/*1]*/ (null != y) y,
  };
}
''');
  }

  test_nullCheckPattern_list() async {
    await assertDiagnosticsFromMarkup(r'''
List<int> f(int? x) {
  return [
    [!if!] (x case var y?) y,
  ];
}
''');
  }

  test_nullCheckPattern_mapKey() async {
    await assertDiagnosticsFromMarkup(r'''
Map<int, String> f(int? x) {
  return {
    [!if!] (x case var y?) y: "value",
  };
}
''');
  }

  test_nullCheckPattern_mapValue() async {
    await assertDiagnosticsFromMarkup(r'''
Map<String, int> f(int? x) {
  return {
    [!if!] (x case var y?) "key": y,
  };
}
''');
  }

  test_nullCheckPattern_set() async {
    await assertDiagnosticsFromMarkup(r'''
Set<int> f(int? x) {
  return {
    [!if!] (x case var y?) y,
  };
}
''');
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

  test_spread_getter_list() async {
    await assertDiagnosticsFromMarkup('''
List<int>? get x => null;
List<int> f() => [
  /*[0*/if/*0]*/ (x != null) ...x!,
  /*[1*/if/*1]*/ (x case var y?) ...y,
];
''');
  }

  test_spread_getter_map() async {
    await assertDiagnosticsFromMarkup('''
Map<int, int>? get x => null;
Map<int, int> f() => {
  /*[0*/if/*0]*/ (x != null) ...x!,
  /*[1*/if/*1]*/ (x case var y?) ...y,
};
''');
  }

  test_spread_list() async {
    await assertDiagnosticsFromMarkup('''
List<int> f(List<int>? x) => [
  /*[0*/if/*0]*/ (x != null) ...x,
  /*[1*/if/*1]*/ (x case var y?) ...y,
];
''');
  }

  test_spread_map() async {
    await assertDiagnosticsFromMarkup('''
Map<int, int> f(Map<int, int>? x) => {
  /*[0*/if/*0]*/ (x != null) ...x,
  /*[1*/if/*1]*/ (x case var y?) ...y,
};
''');
  }

  test_spread_set() async {
    await assertDiagnosticsFromMarkup('''
Set<int> f(List<int>? x) => {
  /*[0*/if/*0]*/ (x != null) ...x,
  /*[1*/if/*1]*/ (x case var y?) ...y,
};
''');
  }
}
