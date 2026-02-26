// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToInitializingFormalBulkTest);
    defineReflectiveTests(ConvertToInitializingFormalTest);
  });
}

@reflectiveTest
class ConvertToInitializingFormalBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_initializing_formals;

  Future<void> test_inBody_contiguous() async {
    await resolveTestCode(r'''
class C {
  int? a;
  int? b;
  int? c;
  int? d;
  C(int? a, int? b, int? c, int? d) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.d = d;
  }
}
''');
    // Doesn't fix b because both a and b try to remove the whitespace between
    // the first two statements.
    await assertHasFix(r'''
class C {
  int? a;
  int? b;
  int? c;
  int? d;
  C(this.a, int? b, this.c, this.d) {
    this.b = b;
  }
}
''');
  }

  Future<void> test_inBody_noncontiguous() async {
    await resolveTestCode(r'''
class C {
  int? a;
  int? b;
  int? c;
  C(int? a, int? b, int? c) {
    this.a = a;
    print(1);
    this.b = b;
    print(2);
    this.c = c;
  }
}
''');
    await assertHasFix(r'''
class C {
  int? a;
  int? b;
  int? c;
  C(this.a, this.b, this.c) {
    print(1);
    print(2);
  }
}
''');
  }

  Future<void> test_inInitializer_contiguous() async {
    await resolveTestCode(r'''
class C {
  int? a;
  int? b;
  int? c;
  int? d;
  C(int? a, int? b, int? c, int? d) : a = a, b = b, c = c, d = d;
}
''');
    // Doesn't fix b because both a and b try to remove the same comma.
    await assertHasFix(r'''
class C {
  int? a;
  int? b;
  int? c;
  int? d;
  C(this.a, int? b, this.c, this.d) : b = b;
}
''');
  }

  Future<void> test_inInitializer_noncontiguous() async {
    await resolveTestCode(r'''
class C {
  int? a;
  int x;
  int? b;
  int y;
  int? c;
  C(int? a, int? b, int? c) : a = a, x = 1, b = b, y = 2, c = c;
}
''');
    await assertHasFix(r'''
class C {
  int? a;
  int x;
  int? b;
  int y;
  int? c;
  C(this.a, this.b, this.c) : x = 1, y = 2;
}
''');
  }
}

@reflectiveTest
class ConvertToInitializingFormalTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToInitializingFormal;

  @override
  String get lintCode => LintNames.prefer_initializing_formals;

  Future<void> test_assignment_differentType() async {
    await resolveTestCode('''
class C {
  Object a = '';

  C(String a) {
    this.a = a;
  }
}
''');
    await assertHasFix('''
class C {
  Object a = '';

  C(String this.a);
}
''');
  }

  Future<void> test_assignment_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int a) {
    this.a = a;
  }
}
''');
    await assertHasFix('''
class C {
  int a = 0;
  C(this.a);
}
''');
  }

  Future<void> test_assignment_named() async {
    await resolveTestCode('''
class C {
  int? a;
  C({int? a = 1}) {
    this.a = a;
  }
}
''');
    await assertHasFix('''
class C {
  int? a;
  C({this.a = 1});
}
''');
  }

  Future<void> test_assignment_named_private() async {
    await resolveTestCode('''
class C {
  int? _a;
  C({int? a = 1}) {
    this._a = a;
  }
}
''');
    await assertHasFix('''
class C {
  int? _a;
  C({this._a = 1});
}
''', filter: (d) => d.diagnosticCode != diag.unusedField);
  }

  Future<void> test_assignment_named_private_unsupported() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  int? _a;
  C({int? a = 1}) {
    this._a = a;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_assignment_named_private_withCommentReference() async {
    await resolveTestCode('''
class C {
  int? _a;
  /// [a]
  C({int? a = 1}) {
    this._a = a;
  }
}
''');
    await assertHasFix('''
class C {
  int? _a;
  /// [_a]
  C({this._a = 1});
}
''', filter: (d) => d.diagnosticCode != diag.unusedField);
  }

  Future<void> test_assignment_named_private_withType() async {
    await resolveTestCode('''
class C {
  num? _a;
  C({int? a = 1}) {
    this._a = a;
  }
}
''');
    await assertHasFix('''
class C {
  num? _a;
  C({int? this._a = 1});
}
''', filter: (d) => d.diagnosticCode != diag.unusedField);
  }

  Future<void> test_assignment_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a = 0;
  C(int a) {
    this.a = a;
    print(1);
  }
}
''');
    await assertHasFix('''
class C {
  int a = 0;
  C(this.a) {
    print(1);
  }
}
''');
  }

  Future<void> test_assignment_otherInitializer() async {
    await resolveTestCode('''
class C {
  int? x;
  int? y;

  C({int? x}) : y = 1 {
    this.x = x;
  }
}
''');
    await assertHasFix('''
class C {
  int? x;
  int? y;

  C({this.x}) : y = 1;
}
''');
  }

  Future<void> test_assignment_positional_differentType() async {
    await resolveTestCode('''
class C {
  Object? a;
  C([String? a]) {
    this.a = a;
  }
}
''');
    await assertHasFix('''
class C {
  Object? a;
  C([String? this.a]);
}
''');
  }

  Future<void> test_initializer_differentType() async {
    await resolveTestCode('''
class C {
  final Object name;
  C.forName(String name) : name = name;
}
''');
    await assertHasFix('''
class C {
  final Object name;
  C.forName(String this.name);
}
''');
  }

  Future<void> test_initializer_emptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  C(int a) : this.a = a;
}
''');
    await assertHasFix('''
class C {
  int a;
  C(this.a);
}
''');
  }

  Future<void> test_initializer_named_differentType() async {
    await resolveTestCode('''
class C {
  Object? a;
  C({String? a}) : a = a;
}
''');
    await assertHasFix('''
class C {
  Object? a;
  C({String? this.a});
}
''');
  }

  Future<void> test_initializer_named_private() async {
    await resolveTestCode('''
class C {
  Object? _a;
  C({Object? a}) : _a = a;
}
''');
    await assertHasFix('''
class C {
  Object? _a;
  C({this._a});
}
''', filter: (d) => d.diagnosticCode != diag.unusedField);
  }

  Future<void> test_initializer_named_private_unsupported() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  Object? _a;
  C({Object? a}) : _a = a;
}
''');
    await assertNoFix();
  }

  Future<void> test_initializer_named_private_withType() async {
    await resolveTestCode('''
class C {
  Object? _a;
  C({int? a}) : _a = a;
}
''');
    await assertHasFix('''
class C {
  Object? _a;
  C({int? this._a});
}
''', filter: (d) => d.diagnosticCode != diag.unusedField);
  }

  Future<void> test_initializer_notEmptyAfterRemoval() async {
    await resolveTestCode('''
class C {
  int a;
  int b;
  C(int a) : this.a = a, this.b = 2;
}
''');
    await assertHasFix('''
class C {
  int a;
  int b;
  C(this.a) : this.b = 2;
}
''');
  }

  Future<void> test_initializer_parameterRequired() async {
    await resolveTestCode('''
class C {
  final int foo;
  C({required int foo}) : foo = foo;
}
''');
    await assertHasFix('''
class C {
  final int foo;
  C({required this.foo});
}
''');
  }

  Future<void> test_initializer_positional() async {
    await resolveTestCode('''
class C {
  int? a;
  C([int? a = 1]): a = a;
}
''');
    await assertHasFix('''
class C {
  int? a;
  C([this.a = 1]);
}
''');
  }
}
