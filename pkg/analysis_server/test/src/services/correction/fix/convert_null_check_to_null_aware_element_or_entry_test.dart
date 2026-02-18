// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertNullCheckToNullAwareElementOrEntryBulkTest);
    defineReflectiveTests(ConvertNullCheckToNullAwareElementOrEntryTest);
  });
}

@reflectiveTest
class ConvertNullCheckToNullAwareElementOrEntryBulkTest
    extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_null_aware_elements;

  Future<void> test_nullCheck_list() async {
    await resolveTestCode('''
List<int> f(int? x) {
  return [
    if (x != null) x,
    if (null != x) x,
  ];
}
''');
    await assertHasFix('''
List<int> f(int? x) {
  return [
    ?x,
    ?x,
  ];
}
''');
  }

  Future<void> test_nullCheck_mapKey() async {
    await resolveTestCode('''
Map<int, String> f(int? x, int? y) {
  return {
    if (x != null) x: "",
    if (null != y) y: "",
  };
}
''');
    await assertHasFix('''
Map<int, String> f(int? x, int? y) {
  return {
    ?x: "",
    ?y: "",
  };
}
''');
  }

  Future<void> test_nullCheck_mapValue() async {
    await resolveTestCode('''
Map<String, int> f(int? x, int? y) {
  return {
    if (x != null) "key1": x,
    if (null != y) "key2": y,
  };
}
''');
    await assertHasFix('''
Map<String, int> f(int? x, int? y) {
  return {
    "key1": ?x,
    "key2": ?y,
  };
}
''');
  }

  Future<void> test_nullCheck_set() async {
    await resolveTestCode('''
Set<int> f(int? x, int? y) {
  return {
    if (x != null) x,
    if (null != y) y,
  };
}
''');
    await assertHasFix('''
Set<int> f(int? x, int? y) {
  return {
    ?x,
    ?y,
  };
}
''');
  }
}

@reflectiveTest
class ConvertNullCheckToNullAwareElementOrEntryTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertNullCheckToNullAwareElementOrEntry;

  @override
  String get lintCode => LintNames.use_null_aware_elements;

  Future<void> test_nullCheck_getter_list() async {
    await resolveTestCode('''
abstract class A {
  int? get x;
  List<int> f() {
    return [
      if (x != null) x!,
    ];
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get x;
  List<int> f() {
    return [
      ?x,
    ];
  }
}
''');
  }

  Future<void> test_nullCheck_getter_mapKey() async {
    await resolveTestCode('''
abstract class A {
  int? get x;
  Map<int, String> f() {
    return {
      if (x != null) x!: "",
    };
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get x;
  Map<int, String> f() {
    return {
      ?x: "",
    };
  }
}
''');
  }

  Future<void> test_nullCheck_getter_mapKeyAndValue() async {
    await resolveTestCode('''
abstract class A {
  int? get x;
  Map<int, int> f() {
    return {
      if (x != null) x!: x!,
    };
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get x;
  Map<int, int> f() {
    return {
      ?x: x!,
    };
  }
}
''');
  }

  Future<void> test_nullCheck_getter_mapValue() async {
    await resolveTestCode('''
abstract class A {
  int? get x;
  Map<String, int> f() {
    return {
      if (x != null) "key1": x!,
    };
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get x;
  Map<String, int> f() {
    return {
      "key1": ?x,
    };
  }
}
''');
  }

  Future<void> test_nullCheck_getter_set() async {
    await resolveTestCode('''
abstract class A {
  int? get x;
  Set<int> f() {
    return {
      if (x != null) x!,
    };
  }
}
''');
    await assertHasFix('''
abstract class A {
  int? get x;
  Set<int> f() {
    return {
      ?x,
    };
  }
}
''');
  }

  Future<void> test_nullCheck_promotable_list() async {
    await resolveTestCode('''
List<int> f(int? x) {
  return [
    if (x != null) x,
  ];
}
''');
    await assertHasFix('''
List<int> f(int? x) {
  return [
    ?x,
  ];
}
''');
  }

  Future<void> test_nullCheck_promotable_mapKey() async {
    await resolveTestCode('''
Map<int, String> f(int? x) {
  return {
    if (x != null) x: "",
  };
}
''');
    await assertHasFix('''
Map<int, String> f(int? x) {
  return {
    ?x: "",
  };
}
''');
  }

  Future<void> test_nullCheck_promotable_mapKeyAndValue() async {
    await resolveTestCode('''
Map<int, int> f(int? x) {
  return {
    if (x != null) x: x,
  };
}
''');
    await assertHasFix('''
Map<int, int> f(int? x) {
  return {
    ?x: x,
  };
}
''');
  }

  Future<void> test_nullCheck_promotable_mapValue() async {
    await resolveTestCode('''
Map<String, int> f(int? x) {
  return {
    if (x != null) "key1": x,
  };
}
''');
    await assertHasFix('''
Map<String, int> f(int? x) {
  return {
    "key1": ?x,
  };
}
''');
  }

  Future<void> test_nullCheck_promotable_set() async {
    await resolveTestCode('''
Set<int> f(int? x) {
  return {
    if (x != null) x,
  };
}
''');
    await assertHasFix('''
Set<int> f(int? x) {
  return {
    ?x,
  };
}
''');
  }

  Future<void> test_nullCheckPattern_list() async {
    await resolveTestCode('''
List<int> f(int? x) {
  return [
    if (x case var y?) y,
  ];
}
''');
    await assertHasFix('''
List<int> f(int? x) {
  return [
    ?x,
  ];
}
''');
  }

  Future<void> test_nullCheckPattern_mapComplexValue() async {
    await resolveTestCode('''
Map<String, int> f(int? x) {
  return {
    if (x != null ? (x.isEven == false ? 0 : 1) : null case var y?) "key": y,
  };
}
''');
    await assertHasFix('''
Map<String, int> f(int? x) {
  return {
    "key": ?x != null ? (x.isEven == false ? 0 : 1) : null,
  };
}
''');
  }

  Future<void> test_nullCheckPattern_mapKey() async {
    await resolveTestCode('''
Map<int, String> f(int? x) {
  return {
    if (x case var y?) y: "value",
  };
}
''');
    await assertHasFix('''
Map<int, String> f(int? x) {
  return {
    ?x: "value",
  };
}
''');
  }

  Future<void> test_nullCheckPattern_mapValue() async {
    await resolveTestCode('''
Map<String, int> f(int? x) {
  return {
    if (x case var y?) "key": y,
  };
}
''');
    await assertHasFix('''
Map<String, int> f(int? x) {
  return {
    "key": ?x,
  };
}
''');
  }

  Future<void> test_nullCheckPattern_set() async {
    await resolveTestCode('''
Set<int> f(int? x) {
  return {
    if (x case var y?) y,
  };
}
''');
    await assertHasFix('''
Set<int> f(int? x) {
  return {
    ?x,
  };
}
''');
  }

  Future<void> test_spread_case_getter_list() async {
    await resolveTestCode('''
List<int>? get x => null;
List<int> f() => [
  if (x case var y?) ...y,
];
''');
    await assertHasFix('''
List<int>? get x => null;
List<int> f() => [
  ...?x,
];
''');
  }

  Future<void> test_spread_case_getter_map() async {
    await resolveTestCode('''
Map<int, int>? get x => null;
Map<int, int> f() => {
  if (x case var y?) ...y,
};
''');
    await assertHasFix('''
Map<int, int>? get x => null;
Map<int, int> f() => {
  ...?x,
};
''');
  }

  Future<void> test_spread_case_list() async {
    await resolveTestCode('''
List<int> f(List<int>? x) => [
  if (x case var y?) ...y,
];
''');
    await assertHasFix('''
List<int> f(List<int>? x) => [
  ...?x,
];
''');
  }

  Future<void> test_spread_case_map() async {
    await resolveTestCode('''
Map<int, int> f(Map<int, int>? x) => {
  if (x case var y?) ...y,
};
''');
    await assertHasFix('''
Map<int, int> f(Map<int, int>? x) => {
  ...?x,
};
''');
  }

  Future<void> test_spread_getter_list() async {
    await resolveTestCode('''
List<int>? get x => null;
List<int> f() => [
  if (x != null) ...x!,
];
''');
    await assertHasFix('''
List<int>? get x => null;
List<int> f() => [
  ...?x,
];
''');
  }

  Future<void> test_spread_getter_map() async {
    await resolveTestCode('''
Map<int, int>? get x => null;
Map<int, int> f() => {
  if (x != null) ...x!,
};
''');
    await assertHasFix('''
Map<int, int>? get x => null;
Map<int, int> f() => {
  ...?x,
};
''');
  }

  Future<void> test_spread_list() async {
    await resolveTestCode('''
List<int> f(List<int>? x) => [
  if (x != null) ...x,
];
''');
    await assertHasFix('''
List<int> f(List<int>? x) => [
  ...?x,
];
''');
  }

  Future<void> test_spread_map() async {
    await resolveTestCode('''
Map<int, int> f(Map<int, int>? x) => {
  if (x != null) ...x,
};
''');
    await assertHasFix('''
Map<int, int> f(Map<int, int>? x) => {
  ...?x,
};
''');
  }

  Future<void> test_spread_set() async {
    await resolveTestCode('''
Set<int> f(List<int>? x) => {
  if (x != null) ...x,
};
''');
    await assertHasFix('''
Set<int> f(List<int>? x) => {
  ...?x,
};
''');
  }
}
