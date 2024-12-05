// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceContainerWithColoredBoxTest);
    defineReflectiveTests(ReplaceContainerWithColoredBoxMultiTest);
  });
}

@reflectiveTest
class ReplaceContainerWithColoredBoxMultiTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_colored_box;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(lints: [LintNames.use_colored_box]);
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
    color: Colors.red,
    child: Container(
      color: Colors.red,
      child: Row(),
    ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return ColoredBox(
    color: Colors.red,
    child: ColoredBox(
      color: Colors.red,
      child: Row(),
    ),
  );
}
''');
  }
}

@reflectiveTest
class ReplaceContainerWithColoredBoxTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_CONTAINER_WITH_COLORED_BOX;

  @override
  String get lintCode => LintNames.use_colored_box;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(lints: [LintNames.use_colored_box]);
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return Container(
    color: Colors.red,
    child: Row(),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

Widget buildRow() {
  return ColoredBox(
    color: Colors.red,
    child: Row(),
  );
}
''');
  }
}
