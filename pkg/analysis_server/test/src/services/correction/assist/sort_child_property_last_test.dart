// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortChildPropertyLastTest);
  });
}

@reflectiveTest
class SortChildPropertyLastTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.sortChildPropertyLast;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_already_sorted() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    c^hildren: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_already_sorted_one_prop() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    childr^en: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_no_children() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    cro^ssAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_sort_middleArgument() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    mainAxisAlignment: MainAxisAlignment.start,
    ^children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
    assertExitPosition(after: '],');
  }

  Future<void> test_sort_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_child_properties_last]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    ^children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_sort_noTrailingComma() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    ^children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ]
  );
}
''');
    assertExitPosition(after: ']');
  }

  Future<void> test_sort_trailingComma() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    ^children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
    crossAxisAlignment: CrossAxisAlignment.center,
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
void f() {
  Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text('aaa'),
      Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
    assertExitPosition(after: '],');
  }
}
