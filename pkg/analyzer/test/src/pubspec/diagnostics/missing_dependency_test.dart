// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:matcher/expect.dart';
import 'package:meta/meta.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingDependencyTest);
  });
}

@reflectiveTest
class MissingDependencyTest with ResourceProviderMixin {
  late Source _source;

  /// Asserts that when the validator is used on the given [content], a
  /// [diag.missingDependency] warning is produced.
  ///
  /// The message text is returned so that it can be further validated if
  /// desired.
  String assertErrors(
    String content, {
    required Set<String> usedDeps,
    required Set<String> usedDevDeps,
    List<String> addDeps = const [],
    List<String> addDevDeps = const [],
    List<String> removeDevDeps = const [],
  }) {
    var error = _runValidator(content, usedDeps, usedDevDeps).first;
    var data = MissingDependencyData.byDiagnostic[error]!;
    expect(error.diagnosticCode, diag.missingDependency);
    expect(data.addDeps, addDeps);
    expect(data.addDevDeps, addDevDeps);
    expect(data.removeDevDeps, removeDevDeps);
    return error.problemMessage.messageText(includeUrl: false);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(
    String content, {
    Set<String> usedDeps = const {},
    Set<String> usedDevDeps = const {},
  }) {
    List<Diagnostic> errors = _runValidator(content, usedDeps, usedDevDeps);
    expect(errors.isEmpty, true);
  }

  @mustCallSuper
  void setUp() {
    var file = getFile('/sample/pubspec.yaml');
    _source = FileSource(file);
  }

  test_missingDependency_error() {
    var message = assertErrors(
      '''
name: sample
dependencies:
  path: any
''',
      usedDeps: {'path', 'matcher'},
      addDeps: ['matcher'],
      usedDevDeps: {},
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(message, contains("package ''matcher' in 'dependencies''"));
  }

  test_missingDependency_move_to_dev() {
    var message = assertErrors(
      '''
name: sample
dependencies:
  path: any
dev_dependencies:
  test: any
''',
      usedDeps: {'path', 'test'},
      addDeps: ['test'],
      removeDevDeps: ['test'],
      usedDevDeps: {},
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(message, contains("package ''test' in 'dependencies''"));
  }

  test_missingDependency_noError() {
    assertNoErrors(
      '''
name: sample
dependencies:
  test: any
''',
      usedDeps: {'test'},
      usedDevDeps: {},
    );
  }

  test_missingDependency_package_noError() {
    assertNoErrors(
      '''
name: sample
dependencies:
  test: any
dev_dependencies:
  lints: any
''',
      usedDeps: {'test', 'sample'},
      usedDevDeps: {'lints'},
    );
  }

  test_missingDevDependency_error() {
    var message = assertErrors(
      '''
name: sample
dependencies:
  path: any
dev_dependencies:
  lints: any
''',
      usedDeps: {'path'},
      usedDevDeps: {'lints', 'test'},
      addDevDeps: ['test'],
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(message, contains("package ' 'test' in 'dev_dependencies''"));
  }

  test_missingDevDependency_inDeps_noError() {
    assertNoErrors(
      '''
name: sample
dependencies:
  test: any
  path: any
dev_dependencies:
  lints: any
''',
      usedDeps: {'test', 'path'},
      usedDevDeps: {'lints', 'path'},
    );
  }

  test_missingDevDependency_multiple_deps() {
    var message = assertErrors(
      '''
name: sample
dependencies:
  path: any
''',
      usedDeps: {'path', 'test', 'args'},
      usedDevDeps: {},
      addDeps: ['test', 'args'],
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(message, contains("package ''test','args' in 'dependencies''"));
  }

  test_missingDevDependency_multiple_depsAndDevDeps() {
    var message = assertErrors(
      '''
name: sample
''',
      usedDeps: {'path', 'args'},
      usedDevDeps: {'test', 'lints'},
      addDeps: ['path', 'args'],
      addDevDeps: ['test', 'lints'],
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(
      message,
      contains(
        "package ''path','args' in 'dependencies', 'test','lints' in 'dev_dependencies''",
      ),
    );
  }

  test_missingDevDependency_multiple_devDeps() {
    var message = assertErrors(
      '''
name: sample
dev_dependencies:
  path: any
''',
      usedDeps: {},
      usedDevDeps: {'path', 'test', 'args'},
      addDevDeps: ['test', 'args'],
    );
    // TODO(paulberry): see https://github.com/dart-lang/sdk/issues/62431
    expect(message, contains("package ' 'test','args' in 'dev_dependencies''"));
  }

  test_missingDevDependency_noError() {
    assertNoErrors(
      '''
name: sample
dependencies:
  test: any
dev_dependencies:
  lints: any
''',
      usedDeps: {'test'},
      usedDevDeps: {'lints'},
    );
  }

  test_missingDevDependency_package_noError() {
    assertNoErrors(
      '''
name: sample
dependencies:
  test: any
dev_dependencies:
  lints: any
''',
      usedDeps: {'test'},
      usedDevDeps: {'lints', 'sample'},
    );
  }

  List<Diagnostic> _runValidator(
    String content,
    Set<String> usedDeps,
    Set<String> usedDevDeps,
  ) {
    YamlNode node = loadYamlNode(content);
    if (node is! YamlMap) {
      // The file is empty.
      node = YamlMap();
    }
    var errors = MissingDependencyValidator(
      node,
      _source,
      resourceProvider,
    ).validate(usedDeps, usedDevDeps);
    return errors;
  }
}
