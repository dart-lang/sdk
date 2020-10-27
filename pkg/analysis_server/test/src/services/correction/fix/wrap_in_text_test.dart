// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrapInTextTest);
  });
}

@reflectiveTest
class WrapInTextTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.WRAP_IN_TEXT;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_literal() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
Widget f() => Center(child: 'aaa');
''');
    await assertHasFix('''
import 'package:flutter/material.dart';
Widget f() => Center(child: Text('aaa'));
''');
  }

  Future<void> test_notString() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
Widget center(int i) => Center(child: i);
''');
    await assertNoFix();
  }

  Future<void> test_parameterType_notClass() async {
    await resolveTestCode('''
typedef F = void Function();

void foo({F a}) {}

void bar() {
  foo(a: '');
}
''');
    await assertNoFix();
  }

  Future<void> test_parameterType_notWidget() async {
    await resolveTestCode('''
void f(int i) {
  f('a');
}
''');
    await assertNoFix();
  }

  Future<void> test_variable() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
Widget center(String s) => Center(child: s);
''');
    await assertHasFix('''
import 'package:flutter/material.dart';
Widget center(String s) => Center(child: Text(s));
''');
  }
}
