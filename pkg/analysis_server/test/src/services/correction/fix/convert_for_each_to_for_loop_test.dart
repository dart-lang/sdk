// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertForEachToForLoopBulkTest);
    defineReflectiveTests(ConvertForEachToForLoopTest);
  });
}

@reflectiveTest
class ConvertForEachToForLoopBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_function_literals_in_foreach_calls;

  Future<void> test_blockBody_blockBody() async {
    await resolveTestCode(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  a.forEach((ea) {
    b.forEach((eb) {
      result.add('$ea $eb');
    });
  });
}
''');
    await assertHasFix(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  for (var ea in a) {
    for (var eb in b) {
      result.add('$ea $eb');
    }
  }
}
''');
  }

  Future<void> test_blockBody_expressionBody() async {
    await resolveTestCode(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  a.forEach((ea) {
    b.forEach((eb) => result.add('$ea $eb'));
  });
}
''');
    await assertHasFix(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  for (var ea in a) {
    for (var eb in b) {
      result.add('$ea $eb');
    }
  }
}
''');
  }

  Future<void> test_expressionBody_blockBody() async {
    await resolveTestCode(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  a.forEach((ea) => b.forEach((eb) {
      result.add('$ea $eb');
    }));
}
''');
    await assertHasFix(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  for (var ea in a) {
    b.forEach((eb) {
      result.add('$ea $eb');
    });
  }
}
''');
  }

  Future<void> test_expressionBody_expressionBody() async {
    await resolveTestCode(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  a.forEach((ea) => b.forEach((eb) => result.add('$ea $eb')));
}
''');
    await assertHasFix(r'''
void f(List<String> a, List<String> b) {
  var result = <String>[];
  for (var ea in a) {
    b.forEach((eb) => result.add('$ea $eb'));
  }
}
''');
  }
}

@reflectiveTest
class ConvertForEachToForLoopTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_FOR_EACH_TO_FOR_LOOP;

  @override
  String get lintCode => LintNames.avoid_function_literals_in_foreach_calls;

  Future<void> test_blockBody() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) {
    e.length / 2;
  });
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (var e in list) {
    e.length / 2;
  }
}
''');
  }

  Future<void> test_blockBody_async() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) async {
    e.length / 2;
  });
}
''');
    await assertNoFix();
  }

  Future<void> test_blockBody_asyncStar() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) async* {
    e.length / 2;
  });
}
''');
    await assertNoFix();
  }

  Future<void> test_blockBody_preferFinal() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.prefer_final_in_for_each,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) {
    e.substring(3, 7);
  });
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (final e in list) {
    e.substring(3, 7);
  }
}
''');
  }

  Future<void> test_blockBody_preferFinal_specifyTypes() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.prefer_final_in_for_each,
        LintNames.always_specify_types,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) {
    e.substring(3, 7);
  });
}
''');
    await assertHasFix(
      '''
void f(List<String> list) {
  for (final String e in list) {
    e.substring(3, 7);
  }
}
''',
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_blockBody_specifyTypes() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.always_specify_types,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) {
    e.substring(3, 7);
  });
}
''');
    await assertHasFix(
      '''
void f(List<String> list) {
  for (String e in list) {
    e.substring(3, 7);
  }
}
''',
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_blockBody_specifyTypes_prefixed() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.always_specify_types,
      ],
    );
    await resolveTestCode('''
import 'dart:core' as core;

void f(core.List<core.Set<core.String>> list) {
  list.forEach((e) {
    e.map((s) => s.substring(3, 7));
  });
}
''');
    await assertHasFix(
      '''
import 'dart:core' as core;

void f(core.List<core.Set<core.String>> list) {
  for (core.Set<core.String> e in list) {
    e.map((s) => s.substring(3, 7));
  }
}
''',
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_blockBody_syncStar() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) sync* {
    e.length / 2;
  });
}
''');
    await assertNoFix();
  }

  Future<void> test_expressionBody() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) => e.substring(3, 7));
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (var e in list) {
    e.substring(3, 7);
  }
}
''');
  }

  Future<void> test_expressionBody_async() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) async => e.substring(3, 7));
}
''');
    await assertNoFix();
  }

  Future<void> test_expressionBody_asyncStar() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) async* => e.substring(3, 7));
}
''');
    await assertNoFix(
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_expressionBody_preferFinal() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.prefer_final_in_for_each,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) => e.substring(3, 7));
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (final e in list) {
    e.substring(3, 7);
  }
}
''');
  }

  Future<void> test_expressionBody_preferFinal_specifyTypes() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.prefer_final_in_for_each,
        LintNames.always_specify_types,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) => e.substring(3, 7));
}
''');
    await assertHasFix(
      '''
void f(List<String> list) {
  for (final String e in list) {
    e.substring(3, 7);
  }
}
''',
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_expressionBody_specifyTypes() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.avoid_function_literals_in_foreach_calls,
        LintNames.always_specify_types,
      ],
    );
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) => e.substring(3, 7));
}
''');
    await assertHasFix(
      '''
void f(List<String> list) {
  for (String e in list) {
    e.substring(3, 7);
  }
}
''',
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_expressionBody_syncStar() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) sync* => e.substring(3, 7));
}
''');
    await assertNoFix(
      errorFilter:
          (error) =>
              error.errorCode.name ==
              LintNames.avoid_function_literals_in_foreach_calls,
    );
  }

  Future<void> test_functionExpression() async {
    await resolveTestCode('''
void f(List<List<int?>> lists) {
  lists.forEach((list) {
    list.map((x) {
      if (x == null) return 0;
      return x.abs();
    });
  });
}
''');
    await assertHasFix('''
void f(List<List<int?>> lists) {
  for (var list in lists) {
    list.map((x) {
      if (x == null) return 0;
      return x.abs();
    });
  }
}
''');
  }

  Future<void> test_mapLiteral() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.forEach((x) => {1: 2});
}
''');
    await assertNoFix();
  }

  Future<void> test_mapLiteral_typeArguments() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.forEach((x) => <int, int>{x: 2});
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var x in list) {
    <int, int>{x: 2};
  }
}
''');
  }

  Future<void> test_return() async {
    await resolveTestCode('''
void f(List<String> list) {
  list.forEach((e) {
    if (e == 'whatever') {
      return;
    }
  });
}
''');
    await assertHasFix('''
void f(List<String> list) {
  for (var e in list) {
    if (e == 'whatever') {
      continue;
    }
  }
}
''');
  }

  Future<void> test_setLiteral() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.forEach((x) => {print('')});
}
''');
    await assertNoFix(
      errorFilter: (error) => error.errorCode.type == ErrorType.LINT,
    );
  }

  Future<void> test_setLiteral_multiple() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.forEach((x) => {print(''), print('')});
}
''');
    await assertNoFix(
      errorFilter: (error) => error.errorCode.type == ErrorType.LINT,
    );
  }

  Future<void> test_setLiteral_statement() async {
    await resolveTestCode('''
void f(List<int> list, bool b) {
  list.forEach((x) => {if (b) print('')});
}
''');
    await assertNoFix(
      errorFilter: (error) => error.errorCode.type == ErrorType.LINT,
    );
  }

  Future<void> test_setLiteral_typeArguments() async {
    await resolveTestCode('''
void f(List<int> list) {
  list.forEach((x) => <int>{x});
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var x in list) {
    <int>{x};
  }
}
''', errorFilter: (error) => error.errorCode.type == ErrorType.LINT);
  }
}
