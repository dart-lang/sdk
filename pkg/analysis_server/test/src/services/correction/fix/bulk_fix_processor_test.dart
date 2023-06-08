// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../utils/test_instrumentation_service.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HasFixesTest);
    defineReflectiveTests(ChangeMapTest);
    defineReflectiveTests(NoFixTest);
  });
}

@reflectiveTest
class ChangeMapTest extends BulkFixProcessorTest {
  Future<void> test_changeMap() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      LintNames.annotate_overrides,
      LintNames.unnecessary_new,
    ]);

    await resolveTestCode('''
class A { }

var a = new A();
var aa = new A();
''');

    var processor = await computeFixes();
    var changeMap = processor.changeMap;
    var errors = changeMap.libraryMap[testFile.path]!;
    expect(errors, hasLength(1));
    expect(errors[LintNames.unnecessary_new], 2);
  }

  Future<void> test_changeMap_cancelled() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      LintNames.unnecessary_new,
    ]);

    await resolveTestCode('''
class A { }

var a = new A();
''');

    var analysisContext = contextFor(testFile.path);
    var changeWorkspace = await workspace;
    var token = CancelableToken();
    var processor = BulkFixProcessor(
        TestInstrumentationService(), changeWorkspace,
        cancellationToken: token);

    // Begin computing fixes, then immediately cancel.
    var fixErrorsFuture = processor.fixErrors([analysisContext]);
    token.cancel();

    // Wait for code to return and expect that we didn't compute any changes
    // (because we exited early).
    await fixErrorsFuture;
    expect(processor.changeMap.libraryMap, isEmpty);
  }
}

@reflectiveTest
class HasFixesTest extends BulkFixProcessorTest {
  Future<void> test_hasFixes() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      LintNames.annotate_overrides,
      LintNames.unnecessary_new,
    ]);

    await resolveTestCode('''
class A { }

var a = new A();
''');

    expect(await computeHasFixes(), isTrue);
  }

  Future<void> test_hasFixes_stoppedAfterFirst() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      LintNames.annotate_overrides,
      LintNames.unnecessary_new,
    ]);

    await resolveTestCode('''
class A { String a => ''; }
class B extends A { String a => ''; }

var a = new A();
''');

    expect(await computeHasFixes(), isTrue);
    // We should only have computed one, despite the above code having two
    // fixable issues.
    expect(processor.changeMap.libraryMap[testFile.path], hasLength(1));
  }

  Future<void> test_noFixes() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      'avoid_catching_errors', // NOTE: not in lintProducerMap
    ]);

    await resolveTestCode('''
void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');

    expect(await computeHasFixes(), isFalse);
  }
}

@reflectiveTest
class NoFixTest extends BulkFixProcessorTest {
  /// See: https://github.com/dart-lang/sdk/issues/45177
  Future<void> test_noFix() async {
    createAnalysisOptionsFile(experiments: experiments, lints: [
      'avoid_catching_errors', // NOTE: not in lintProducerMap
    ]);

    await resolveTestCode('''
void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');

    var processor = await computeFixes();
    expect(processor.fixDetails, isEmpty);
  }
}
