// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoExpressionBodyTest);
    defineReflectiveTests(ConvertIntoExpressionBodyBulkTest);
  });
}

@reflectiveTest
class ConvertIntoExpressionBodyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_expression_function_bodies;

  Future<void> test_immediatelyInvoked_nested() async {
    // The edits for the inner closure overlap with the edits for the outer
    // one, so only the outer closure is converted in a single pass. The result
    // still means the same thing: the body of the outer closure invokes the
    // inner closure.
    await resolveTestCode('''
final x = () {
  return () {
    return 1;
  }();
}();
''');
    await assertHasFix('''
final x = (() => () {
    return 1;
  }())();
''');
  }

  Future<void> test_singleFile() async {
    // See the discussion in https://dart-review.googlesource.com/c/sdk/+/217521
    // for the nested closure case (var f = () ...).
    // Note this is another place where multiple passes will improve results.
    await resolveTestCode('''
class A {
  mmm() async {
    return 42;
  }
  int nnn() {
    return mmm() + 1;
  }
}

var f = () {
  return () {
    return 3;
  };
};
''');
    await assertHasFix('''
class A {
  mmm() async => 42;
  int nnn() => mmm() + 1;
}

var f = () => () {
    return 3;
  };
''');
  }
}

@reflectiveTest
class ConvertIntoExpressionBodyTest extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.convertIntoExpressionBody;

  @override
  String get lintCode => LintNames.prefer_expression_function_bodies;

  /// More coverage in the `convert_into_expression_body_test.dart` assist test.
  Future<void> test_async() async {
    await resolveTestCode('''
class A {
  mmm() async {
    return 42;
  }
}
''');
    await assertHasFix('''
class A {
  mmm() async => 42;
}
''');
  }

  Future<void> test_closure_cascadeSection_followedByCascade() async {
    await resolveTestCode('''
class C {
  bool Function(String)? filter;
  bool verbose = false;
}

void f(C c) {
  c
    ..filter = (s) {
      return s.isNotEmpty;
    }
    ..verbose = true;
}
''');
    await assertHasFix('''
class C {
  bool Function(String)? filter;
  bool verbose = false;
}

void f(C c) {
  c
    ..filter = ((s) => s.isNotEmpty)
    ..verbose = true;
}
''');
  }

  Future<void> test_closure_followedByPropertyAccess() async {
    await resolveTestCode('''
final x = () {
  return 1;
}.hashCode;
''');
    await assertHasFix('''
final x = (() => 1).hashCode;
''');
  }

  Future<void> test_closure_immediatelyInvoked() async {
    await resolveTestCode('''
int compute() => 42;

final int x = () {
  return compute();
}();
''');
    await assertHasFix('''
int compute() => 42;

final int x = (() => compute())();
''');
  }
}
