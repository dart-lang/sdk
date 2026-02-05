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
    defineReflectiveTests(ConvertToInitializingFormalTest);
  });
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
