// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertForEachToForLoop);
  });
}

@reflectiveTest
class ConvertForEachToForLoop extends BulkFixProcessorTest {
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
