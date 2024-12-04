// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../utils/test_instrumentation_service.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HasFixesTest);
    defineReflectiveTests(ChangeMapTest);
    defineReflectiveTests(NoFixTest);
    defineReflectiveTests(PubspecFixTest);
  });
}

@reflectiveTest
class ChangeMapTest extends BulkFixProcessorTest {
  Future<void> test_changeMap() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.annotate_overrides, LintNames.unnecessary_new],
    );

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
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.unnecessary_new],
    );

    await resolveTestCode('''
class A { }

var a = new A();
''');

    var analysisContext = contextFor(testFile);
    var changeWorkspace = await workspace;
    var token = CancelableToken();
    var processor = BulkFixProcessor(
      TestInstrumentationService(),
      changeWorkspace,
      cancellationToken: token,
    );

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
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.annotate_overrides, LintNames.unnecessary_new],
    );

    await resolveTestCode('''
class A { }

var a = new A();
''');

    expect(await computeHasFixes(), isTrue);
  }

  Future<void> test_hasFixes_in_part() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.unnecessary_new],
    );

    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

class A { }

var a = new A();
''');

    await resolveTestCode('''
part 'a.dart';
''');

    expect(await computeHasFixes(), isTrue);
  }

  Future<void> test_hasFixes_in_part_and_library() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.unnecessary_new],
    );

    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

class A { }

var a = new A();
''');

    newFile('$testPackageLibPath/b.dart', '''
part of 'test.dart';

class B { }

var b = new B();
''');

    await resolveTestCode('''
part 'a.dart';
part 'b.dart';

class C{}
var c = new C();
''');

    expect(await computeHasFixes(), isTrue);
    expect(processor.changeMap.libraryMap.length, 3);
  }

  Future<void> test_hasFixes_stoppedAfterFirst() async {
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [LintNames.annotate_overrides, LintNames.unnecessary_new],
    );

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
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [
        'avoid_catching_errors', // NOTE: not in lintProducerMap
      ],
    );

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
    createAnalysisOptionsFile(
      experiments: experiments,
      lints: [
        'avoid_catching_errors', // NOTE: not in lintProducerMap
      ],
    );

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

@reflectiveTest
class PubspecFixTest extends BulkFixProcessorTest {
  Future<void> test_delete_change() async {
    var content = '''
name: test
dependencies:
  a: any
dev_dependencies:
  b: any
  c: any
  d: any
''';
    var expected = '''
name: test
dependencies:
  a: any
  c: any
dev_dependencies:
  b: any
  d: any
''';
    updateTestPubspecFile(content);

    newFile('$testPackageLibPath/lib.dart', '''
import 'package:c/c.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');
    var testFile = newFile('$testPackageTestPath/test.dart', '''
import 'package:b/b.dart';
import 'package:c/c.dart';
import 'package:d/d.dart';
import 'package:test/lib.dart';
void f() {
  print(C());
}
''');
    await getResolvedUnit(testFile);
    await assertFixPubspec(content, expected);
  }

  Future<void> test_fix() async {
    var content = '''
name: test
''';
    var expected = '''
name: test
dependencies:
  a: any
''';
    updateTestPubspecFile(content);

    await resolveTestCode('''
import 'package:a/a.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');
    await assertFixPubspec(content, expected);
  }

  Future<void> test_multiple_changes() async {
    var content = '''
name: test
dependencies:
  a: any
''';
    var expected = '''
name: test
dependencies:
  a: any
  b: any
  c: any
''';
    updateTestPubspecFile(content);

    await resolveTestCode('''
import 'package:b/b.dart';
import 'package:c/c.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');

    await assertFixPubspec(content, expected);
  }

  Future<void> test_multiple_pubspec_change() async {
    var content = '''
name: test
dependencies:
  a: any
dev_dependencies:
  b: any
  d: any
  c: any
''';
    var expected = '''
name: test
dependencies:
  a: any
  c: any
  test2: any
dev_dependencies:
  b: any
  d: any
''';
    updateTestPubspecFile(content);

    newFile('$testPackageLibPath/lib.dart', '''
import 'package:c/c.dart';
import 'package:test2/lib.dart';
import 'package:flutter_gen/gen.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');
    var testFile = newFile('$testPackageTestPath/test.dart', '''
import 'package:b/b.dart';
import 'package:c/c.dart';
import 'package:d/d.dart';
import 'package:test/lib.dart';
void f() {
  print(C());
}
''');

    newFile('$workspaceRootPath/test2/lib.dart', '''
import 'package:d/d.dart';
import 'package:flutter_gen/gen.dart';

class A{}
''');
    var test2PubspecContent = '''
name: test2
deps:
  d: any
''';
    var test2Pubspec = newFile(
      '$workspaceRootPath/test2/pubspec.yaml',
      test2PubspecContent,
    );
    await getResolvedUnit(testFile);
    await assertFixPubspec(content, expected);
    await assertFixPubspec(
      test2PubspecContent,
      test2PubspecContent,
      file: test2Pubspec,
    );
  }

  Future<void> test_no_exception() async {
    var content = '''
name: test
dependencies:
  a: any
  any
''';
    var expected = '''
name: test
dependencies:
  a: any
  any
''';

    updateTestPubspecFile(content);
    await resolveTestCode('''
import 'package:a/a.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');

    await assertFixPubspec(content, expected);
  }

  Future<void> test_no_fix() async {
    var content = '''
name: test
dependencies:
  a: any
''';
    var expected = '''
name: test
dependencies:
  a: any
''';

    updateTestPubspecFile(content);
    await resolveTestCode('''
import 'package:a/a.dart';

void bad() {
  try {
  } on Error catch (e) {
    print(e);
  }
}
''');

    await assertFixPubspec(content, expected);
  }
}
