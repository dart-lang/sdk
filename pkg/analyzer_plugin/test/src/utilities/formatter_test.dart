// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/src/utilities/formatter.dart';
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../support/abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatterTest);
  });
}

@reflectiveTest
class FormatterTest extends AbstractSingleUnitTest {
  Future<void> test_experiments() async {
    await resolveTestCode('');
    var formatter = createFormatter(result);
    expect(formatter.experimentFlags, experimentsForTests);
  }

  Future<void> test_languageVersion_default() async {
    await resolveTestCode('');
    var formatter = createFormatter(result);
    expect(formatter.languageVersion, defaultFormatterVersion);
  }

  Future<void> test_languageVersion_override() async {
    await resolveTestCode('// @dart=2.12');
    var formatter = createFormatter(result);
    expect(formatter.languageVersion, Version(2, 12, 0));
  }

  Future<void> test_pageWidth() async {
    newFile(convertPath('$testPackageRootPath/analysis_options.yaml'), '''
formatter:
  page_width: 123
''');
    await resolveTestCode('');
    var formatter = createFormatter(result);
    expect(formatter.pageWidth, 123);
  }

  Future<void> test_trailingCommas() async {
    newFile(convertPath('$testPackageRootPath/analysis_options.yaml'), '''
formatter:
  trailing_commas: preserve
''');
    await resolveTestCode('');
    var formatter = createFormatter(result);
    expect(formatter.trailingCommas, TrailingCommas.preserve);
  }
}
