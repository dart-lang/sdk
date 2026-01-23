// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BindToFieldTest);
  });
}

@reflectiveTest
class BindToFieldTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.bindAllToFields;

  Future<void> test_class_constructor_same_named_field() async {
    await resolveTestCode('''
class A {
  int? i;

  A(int ^i);
}
''');
    await assertHasAssist('''
class A {
  int? i;

  A(this.i);
}
''');
  }

  Future<void> test_class_constructor_same_named_field_wrong_type() async {
    await resolveTestCode('''
class A {
  String? i;

  A(int ^i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_class_constructor_same_named_method() async {
    await resolveTestCode('''
class A {
  void i(){}

  A(int ^i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_enum_constructor() async {
    await resolveTestCode('''
enum A {
  e(3);

  const A(int ^i);
}
''');
    await assertHasAssist('''
enum A {
  e(3);

  final int i;

  const A(this.i);
}
''');
  }

  Future<void> test_enum_constructor_same_name() async {
    await resolveTestCode('''
enum A {
  i(3);

  const A(int ^i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_factory_constructor_does_not_apply() async {
    await resolveTestCode('''
class A {
  A();
  factory A.named(int ^p) => A();
}
''');
    await assertNoAssist();
  }

  Future<void> test_final_constructor_parameter() async {
    await resolveTestCode('''
// @dart = 3.10
class A {
  A(final ^i);
}
''');
    await assertHasAssist('''
// @dart = 3.10
class A {
  final i;

  A(this.i);
}
''');
  }

  Future<void> test_imported_type() async {
    await resolveTestCode('''
import 'dart:core' as core;
class A {
  A(core.int ^p);
}
''');
    await assertHasAssist('''
import 'dart:core' as core;
class A {
  core.int p;

  A(this.p);
}
''');
  }

  Future<void> test_multiple_constructors() async {
    await resolveTestCode('''
class A {
  A(int ^i);
  A.named() {}
}
''');
    await assertHasAssist('''
class A {
  int i;

  A(this.i);
  A.named() {}
}
''');
  }

  Future<void> test_named_parameter() async {
    await resolveTestCode('''
class A {
  A({int? ^i});
}
''');
    await assertHasAssist('''
class A {
  int? i;

  A({this.i});
}
''');
  }

  Future<void> test_optional_positional_parameter() async {
    await resolveTestCode('''
class A {
  A([int? ^i]);
}
''');
    await assertHasAssist('''
class A {
  int? i;

  A([this.i]);
}
''');
  }

  Future<void> test_private_named_parameter() async {
    // This code is erroneous, but we still want to allow the assist since it
    // will fix the error.
    await resolveTestCode(
      '''
class A {
  A({int? ^_i});
}
''',
      ignore: [diag.privateNamedNonFieldParameter],
    );
    await assertHasAssist('''
class A {
  int? _i;

  A({this._i});
}
''');
  }

  Future<void> test_private_positional_parameter() async {
    await resolveTestCode('''
class A {
  A(int ^_i);
}
''');
    await assertHasAssist('''
class A {
  int _i;

  A(this._i);
}
''');
  }

  Future<void> test_redirecting_constructor_does_not_apply() async {
    await resolveTestCode('''
class A {
  A();
  A.named(int ^p) : this();
}
''');
    await assertNoAssist();
  }

  Future<void> test_required_named_parameter() async {
    await resolveTestCode('''
class A {
  A({required int ^i});
}
''');
    await assertHasAssist('''
class A {
  int i;

  A({required this.i});
}
''');
  }

  Future<void> test_required_named_untyped_parameter() async {
    await resolveTestCode('''
class A {
  A({required ^i});
}
''');
    await assertHasAssist('''
class A {
  var i;

  A({required this.i});
}
''');
  }

  Future<void> test_static_method_parameter_does_not_apply() async {
    await resolveTestCode('''
class A {
  static void myMethod(int ^i) {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_this() async {
    await resolveTestCode('''
class A {
  int i;

  A(this.^i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_type_parameter() async {
    await resolveTestCode('''
class A<T> {
  A(T ^p);
}
''');
    await assertHasAssist('''
class A<T> {
  T p;

  A(this.p);
}
''');
  }

  Future<void> test_typed_constructor_parameter() async {
    await resolveTestCode('''
class A {
  A(int ^i);
}
''');
    await assertHasAssist('''
class A {
  int i;

  A(this.i);
}
''');
  }

  Future<void> test_typed_function_parameter() async {
    await resolveTestCode('''
class A {
  A(void Function(int i) ^i);
}
''');
    await assertHasAssist('''
class A {
  void Function(int i) i;

  A(this.i);
}
''');
  }

  Future<void> test_typed_super() async {
    await resolveTestCode('''
class A extends B {
  A(super.^i);
}

class B {
  B(int i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_typed_super_default() async {
    await resolveTestCode('''
class A extends B {
  A([super.^i = 42]);
}

class B {
  B(int i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_untyped_constructor_parameter() async {
    await resolveTestCode('''
class A {
  A(^i);
}
''');
    await assertHasAssist('''
class A {
  var i;

  A(this.i);
}
''');
  }

  Future<void> test_untyped_default_function_parameter() async {
    await resolveTestCode('''
class A {
  A([void ^f(int i) = foo]);
}

void foo(int k) => null;
''');
    await assertHasAssist('''
class A {
  void Function(int i) f;

  A([this.f = foo]);
}

void foo(int k) => null;
''');
  }

  Future<void> test_untyped_function_parameter() async {
    await resolveTestCode('''
class A {
  A(void ^f(int i));
}
''');
    await assertHasAssist('''
class A {
  void Function(int i) f;

  A(this.f);
}
''');
  }

  Future<void> test_untyped_required_function_parameter() async {
    await resolveTestCode('''
class A {
  A({required void ^f(int i)});
}

void foo(int k) => null;
''');
    await assertHasAssist('''
class A {
  void Function(int i) f;

  A({this.f});
}

void foo(int k) => null;
''');
  }

  Future<void> test_var_constructor_parameter() async {
    await resolveTestCode('''
// @dart = 3.10
class A {
  A(var ^i);
}
''');
    await assertHasAssist('''
// @dart = 3.10
class A {
  var i;

  A(this.i);
}
''');
  }

  Future<void> test_with_initializer_list() async {
    await resolveTestCode('''
class A {
  A(int? ^i) : assert(i != null);
}
''');
    await assertHasAssist('''
class A {
  int? i;

  A(this.i) : assert(i != null);
}
''');
  }

  Future<void> test_with_ordering_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);

    await resolveTestCode('''
class A {
  A(int ^i);
}
''');
    await assertHasAssist('''
class A {
  A(this.i);

  int i;
}
''');
  }

  Future<void> test_with_ordering_lint_existing_fields() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);

    await resolveTestCode('''
class A {
  A(int ^i);

  int k = 0;
}
''');
    await assertHasAssist('''
class A {
  A(this.i);

  int k = 0;

  int i;
}
''');
  }
}
