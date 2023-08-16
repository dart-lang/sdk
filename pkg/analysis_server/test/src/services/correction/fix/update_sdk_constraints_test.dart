// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateSdkConstraintsTest);
  });
}

@reflectiveTest
class UpdateSdkConstraintsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.UPDATE_SDK_CONSTRAINTS;

  /// Asserts that a library with [content] can be updated from the [from]
  /// constraints to the [to] constraints.
  Future<void> assertUpdate(
      {required String content,
      String from = '^2.0.0',
      required String to}) async {
    updateTestPubspecFile('''
environment:
  sdk: $from
''');
    await resolveTestCode(content);
    await assertHasFix('''
environment:
  sdk: $to
''', target: testPubspecPath);
  }

  /// Asserts that a library with `>>>` can be updated from the [from]
  /// constraints to the [to] constraints.
  Future<void> assertUpdateWithGtGtGt(
      {required String from, required String to}) async {
    await assertUpdate(content: r'''
class C {
  C operator >>>(C other) => this;
}
''', from: from, to: to);
  }

  Future<void> test_any() async {
    await assertUpdateWithGtGtGt(from: 'any', to: '^2.14.0');
  }

  Future<void> test_caret() async {
    await assertUpdateWithGtGtGt(from: '^2.12.0', to: '^2.14.0');
  }

  Future<void> test_compound() async {
    await assertUpdateWithGtGtGt(
        from: "'>=2.12.0 <3.0.0'", to: "'>=2.14.0 <3.0.0'");
  }

  Future<void> test_gt() async {
    await assertUpdateWithGtGtGt(from: "'>2.12.0'", to: "'>=2.14.0'");
  }

  Future<void> test_gte() async {
    await assertUpdateWithGtGtGt(from: "'>=2.12.0'", to: "'>=2.14.0'");
  }

  Future<void> test_gtGtGtOperator() async {
    writeTestPackageConfig(languageVersion: latestLanguageVersion);
    createAnalysisOptionsFile(experiments: [EnableString.triple_shift]);
    await assertUpdate(content: '''
class C {
  C operator >>>(C other) => this;
}
''', to: '^2.14.0');
  }
}
