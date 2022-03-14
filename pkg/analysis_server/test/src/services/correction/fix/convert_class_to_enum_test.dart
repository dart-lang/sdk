// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertClassToEnumBulkTest);
    defineReflectiveTests(ConvertClassToEnumTest);
  });
}

@reflectiveTest
class ConvertClassToEnumBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_enums;

  Future<void> test_multipleClasses() async {
    await resolveTestCode('''
class _E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);

  final int value;

  const _E(this.value);
}

class E {
  static const E c0 = E._(0);
  static const E c1 = E._(1);

  final int value;

  const E._(this.value);
}

var x = [_E.c0, _E.c1];
''');
    await assertHasFix('''
enum _E {
  c0(0),
  c1(1);

  final int value;

  const _E(this.value);
}

enum E {
  c0._(0),
  c1._(1);

  final int value;

  const E._(this.value);
}

var x = [_E.c0, _E.c1];
''');
  }
}

@reflectiveTest
class ConvertClassToEnumTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_CLASS_TO_ENUM;

  @override
  String get lintCode => LintNames.use_enums;

  Future<void> test_minimal_intField_privateClass() async {
    await resolveTestCode('''
class _E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);

  final int value;

  const _E(this.value);
}

var x = [_E.c0, _E.c1];
''');
    await assertHasFix('''
enum _E {
  c0(0),
  c1(1);

  final int value;

  const _E(this.value);
}

var x = [_E.c0, _E.c1];
''');
  }

  Future<void> test_minimal_intField_publicClass() async {
    await resolveTestCode('''
class E {
  static const E c0 = E._(0);
  static const E c1 = E._(1);

  final int value;

  const E._(this.value);
}
''');
    await assertHasFix('''
enum E {
  c0._(0),
  c1._(1);

  final int value;

  const E._(this.value);
}
''');
  }

  Future<void> test_minimal_notIntField_privateClass() async {
    await resolveTestCode('''
class _E {
  static const _E c0 = _E('c0');
  static const _E c1 = _E('c1');

  final String name;

  const _E(this.name);
}

var x = [_E.c0, _E.c1];
''');
    await assertHasFix('''
enum _E {
  c0('c0'),
  c1('c1');

  final String name;

  const _E(this.name);
}

var x = [_E.c0, _E.c1];
''');
  }

  Future<void> test_minimal_notIntField_publicClass() async {
    await resolveTestCode('''
class E {
  static const E c0 = E._('c0');
  static const E c1 = E._('c1');

  final String name;

  const E._(this.name);
}
''');
    await assertHasFix('''
enum E {
  c0._('c0'),
  c1._('c1');

  final String name;

  const E._(this.name);
}
''');
  }

  Future<void> test_withReferencedFactoryConstructor() async {
    await resolveTestCode('''
class _E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);

  final int value;

  const _E(this.value);

  factory _E.withValue(int x) => c0;
}

_E e = _E.withValue(0);

var x = [_E.c0, _E.c1];
''');
    await assertHasFix('''
enum _E {
  c0(0),
  c1(1);

  final int value;

  const _E(this.value);

  factory _E.withValue(int x) => c0;
}

_E e = _E.withValue(0);

var x = [_E.c0, _E.c1];
''');
  }
}
