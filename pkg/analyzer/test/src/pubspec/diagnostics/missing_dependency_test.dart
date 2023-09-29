// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
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

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content,
      {Set<String> usedDeps = const {},
      Set<String> usedDevDeps = const {},
      List<String> addDeps = const [],
      List<String> addDevDeps = const [],
      List<String> removeDevDeps = const []}) {
    var error = _runValidator(content, usedDeps, usedDevDeps).first;
    var data = error.data as MissingDependencyData;
    expect(error.errorCode, PubspecWarningCode.MISSING_DEPENDENCY);
    expect(data.addDeps, addDeps);
    expect(data.addDevDeps, addDevDeps);
    expect(data.removeDevDeps, removeDevDeps);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content,
      {Set<String> usedDeps = const {}, Set<String> usedDevDeps = const {}}) {
    List<AnalysisError> errors = _runValidator(content, usedDeps, usedDevDeps);
    expect(errors.isEmpty, true);
  }

  @mustCallSuper
  void setUp() {
    _source = getFile('/sample/pubspec.yaml').createSource();
  }

  test_missingDependency_error() {
    assertErrors('''
name: sample
dependencies:
  path: any
''', usedDeps: {'path', 'matcher'}, addDeps: ['matcher']);
  }

  test_missingDependency_move_to_dev() {
    assertErrors('''
name: sample
dependencies:
  path: any
dev_dependencies:
  test: any
''', usedDeps: {'path', 'test'}, addDeps: ['test'], removeDevDeps: ['test']);
  }

  test_missingDependency_noError() {
    assertNoErrors('''
name: sample
dependencies:
  test: any
''', usedDeps: {'test'});
  }

  test_missingDevDependency_error() {
    assertErrors('''
name: sample
dependencies:
  path: any
dev_dependencies:
  lints: any
''', usedDeps: {'path'}, usedDevDeps: {'lints', 'test'}, addDevDeps: ['test']);
  }

  test_missingDevDependency_noError() {
    assertNoErrors('''
name: sample
dependencies:
  test: any
dev_dependencies:
  lints: any
''', usedDeps: {'test'}, usedDevDeps: {'lints'});
  }

  List<AnalysisError> _runValidator(
      String content, Set<String> usedDeps, Set<String> usedDevDeps) {
    YamlNode node = loadYamlNode(content);
    if (node is! YamlMap) {
      // The file is empty.
      node = YamlMap();
    }
    var errors =
        MissingDependencyValidator(node.nodes, _source, resourceProvider)
            .validate(usedDeps, usedDevDeps);
    return errors;
  }
}
