// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:matcher/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDependencyTest);
  });
}

@reflectiveTest
class AddDependencyTest extends PubspecFixTest {
  @override
  FixKind get kind => PubspecFixKind.addDependency;

  Future<void> test_addMissingDependency() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
''', {'matcher', 'path'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
''');
  }

  Future<void> test_addMissingDependency_when_noDeps() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
''', {'matcher'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  matcher: any
''');
  }

  Future<void> test_addMissingDevDependency() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  checks: any
''', {'path'}, {'matcher', 'checks'});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  checks: any
  matcher: any
''');
  }

  Future<void> test_addMissingDevDependency_when_no_deps() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
''', {}, {'matcher'});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dev_dependencies:
  matcher: any
''');
  }

  Future<void> test_addMissingDevDependency_when_no_dev_deps() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
''', {'path'}, {'matcher'});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
''');
  }

  Future<void> test_addRemoveDevDependency() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
''', {'path', 'matcher'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
''');
  }

  Future<void> test_addRemoveMissingDependency() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
  test: any
''', {'path', 'matcher'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
dev_dependencies:
  test: any
''');
  }

  Future<void> test_addRemoveMissingDependency_in_the_end() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  test: any
  matcher: any
''', {'path', 'matcher'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
dev_dependencies:
  test: any
''');
  }

  Future<void> test_addRemoveMissingDependency_multiple() async {
    _runValidator('''
name: tests
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
  checks: any
  test: any
  lints: any
''', {'path', 'matcher', 'test', 'lints'}, {});
    await assertHasFix('''
name: tests
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
  test: any
  lints: any
dev_dependencies:
  checks: any
''');
  }

  Future<void> test_addRemoveMissingDependency_not_in_the_end() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dev_dependencies:
  matcher: any
dependencies:
  path: any
''', {'path', 'matcher'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
''');
  }

  Future<void> test_addRemoveMissingDependency_two() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
  test: any
  checks: any
''', {'path', 'matcher', 'checks'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
  checks: any
dev_dependencies:
  test: any
''');
  }

  Future<void> test_addRemoveMissingDependency_two_at_end() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  test: any
  matcher: any
  checks: any
''', {'path', 'matcher', 'checks'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
  checks: any
dev_dependencies:
  test: any
''');
  }

  Future<void> test_addRemoveMissingDependency_two_at_start() async {
    _runValidator('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
dev_dependencies:
  matcher: any
  checks: any
  test: any
''', {'path', 'matcher', 'checks'}, {});
    await assertHasFix('''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  path: any
  matcher: any
  checks: any
dev_dependencies:
  test: any
''');
  }

  void _runValidator(
      String content, Set<String> usedDeps, Set<String> usedDevDeps) {
    this.content = content;
    node = loadYamlNode(this.content);
    var file = newFile('/home/test/pubspec.yaml', content);
    var source = FileSource(file);

    var errors = MissingDependencyValidator(node, source, resourceProvider)
        .validate(usedDeps, usedDevDeps);
    expect(errors.length, 1);
    error = errors[0];
  }
}
