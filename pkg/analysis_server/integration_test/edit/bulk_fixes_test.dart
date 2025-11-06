// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesTest);
  });
}

@reflectiveTest
class BulkFixesTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_bulk_fix_override() async {
    writeFile(sourcePath(file_paths.analysisOptionsYaml), '''
linter:
  rules:
    - annotate_overrides
''');
    writeFile(sourcePath('test.dart'), '''
class A {
  void f() {}
}
class B extends A {
  void f() { }
}
''');
    await standardAnalysisSetup();
    await analysisFinished;

    var result = await sendEditBulkFixes([sourceDirectory.path]);
    expect(result.edits, hasLength(1));
  }

  Future<void> test_bulk_fix_override_first() async {
    writeFile(sourcePath(file_paths.analysisOptionsYaml), '''
linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
''');
    writeFile(sourcePath('test.dart'), '''
abstract class A {
  void foo();
}

class B extends A {
  foo() {}
}
''');
    await standardAnalysisSetup();
    await analysisFinished;

    var result = await sendEditBulkFixes([sourceDirectory.path]);
    var edits = result.edits;
    expect(edits, hasLength(1));
    expect(edits.single.edits, hasLength(2));
  }

  Future<void> test_bulk_fix_with_parts() async {
    writeFile(sourcePath(file_paths.analysisOptionsYaml), '''
linter:
  rules:
    - empty_statements
    - prefer_const_constructors
''');
    writeFile(sourcePath('part.dart'), '''
part of 'test.dart';

class C {
  const C();
}

C b() {
  // dart fix should only add a single const
  return C();
}
''');
    writeFile(sourcePath('test.dart'), '''
part 'part.dart';

void a() {
  // need to trigger a lint in main.dart for the bug to happen
  ;
  b();
}
''');
    await standardAnalysisSetup();
    await analysisFinished;

    var result = await sendEditBulkFixes([sourceDirectory.path]);
    var edits = result.edits;
    expect(edits, hasLength(2));
    expect(edits.first.edits, hasLength(1));
    expect(edits.last.edits, hasLength(1));
  }
}
