// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceContainedWithSizedBoxTest);
    defineReflectiveTests(ReplaceContainedWithSizedBoxMultiTest);
  });
}

@reflectiveTest
class ReplaceContainedWithSizedBoxMultiTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.sized_box_for_whitespace;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
    width: 10,
    child: 
      Container(
        width: 10,
        child: Row(),
      ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return SizedBox(
    width: 10,
    child: 
      SizedBox(
        width: 10,
        child: Row(),
      ),
  );
}
''');
  }
}

@reflectiveTest
class ReplaceContainedWithSizedBoxTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_CONTAINER_WITH_SIZED_BOX;

  @override
  String get lintCode => LintNames.sized_box_for_whitespace;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
    width: 10,
    child: Row(),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return SizedBox(
    width: 10,
    child: Row(),
  );
}
''');
  }
}
