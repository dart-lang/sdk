// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecTargetTest);
    defineReflectiveTests(PubspecTest);
  });
}

@reflectiveTest
class PubspecTargetTest with ResourceProviderMixin {
  void test_dependencyNames_bothSections() {
    var target = _target('''
dependencies:
  collection:
  meta:
dev_dependencies:
  test:
''');
    expect(target.dependencyNames, {'collection', 'meta', 'test'});
  }

  /// A package listed in both sections is one dependency, not two.
  void test_dependencyNames_duplicateAcrossSections() {
    var target = _target('''
dependencies:
  meta:
dev_dependencies:
  meta:
''');
    expect(target.dependencyNames, {'meta'});
  }

  /// A section with no entries parses as `null` rather than an empty map.
  void test_dependencyNames_emptySection() {
    var target = _target('''
dependencies:
dev_dependencies:
  test:
''');
    expect(target.dependencyNames, {'test'});
  }

  /// YAML allows non-string keys, which can't name a package.
  void test_dependencyNames_nonStringKeys() {
    var target = _target('''
dependencies:
  collection:
  12:
  true:
''');
    expect(target.dependencyNames, {'collection'});
  }

  /// Nothing to depend on, so nothing can be held back.
  void test_dependencyNames_withoutDependencies() {
    var target = _target('''
name: my_package
''');
    expect(target.dependencyNames, isEmpty);
  }

  /// Dependencies may be a map of source descriptions rather than bare keys.
  void test_dependencyNames_withSourceDescriptions() {
    var target = _target('''
dependencies:
  collection: ^1.0.0
  local:
    path: ../local
''');
    expect(target.dependencyNames, {'collection', 'local'});
  }

  /// A section that isn't a map can't name dependencies, and must not throw.
  void test_dependencyNames_wrongSectionType() {
    var target = _target('''
dependencies:
  - collection
  - meta
''');
    expect(target.dependencyNames, isEmpty);
  }

  /// A non-string name identifies nothing, and must not throw.
  void test_name_wrongType() {
    var target = _target('name: 12\n');
    expect(target.name, isNull);
  }

  PubspecTarget _target(String content) {
    var file = newFile(convertPath('/home/package_dir/pubspec.yaml'), content);
    return PubspecTarget(file: file, pubspec: loadYamlNode(content) as YamlMap);
  }
}

@reflectiveTest
class PubspecTest with ResourceProviderMixin {
  String get testPubspecPath => convertPath('/test/pubspec.yaml');

  void test_any() {
    _assertEdit('any', '^2.13.0');
  }

  void test_caret() {
    _assertEdit('^2.12.0', '^2.13.0');
  }

  void test_compound() {
    _assertEdit("'>=2.12.0 <3.0.0'", '>=2.13.0 <3.0.0');
  }

  void test_gt() {
    _assertEdit("'>2.12.0'", '>=2.13.0');
  }

  void test_gte() {
    _assertEdit("'>=2.12.0'", '>=2.13.0');
  }

  void test_invalid() {
    _assertEdit('not a version', null);
  }

  void test_specificVersion() {
    _assertEdit('2.12.0', null);
  }

  /// Raising only the lower bound here would produce the empty range
  /// `>=2.13.0 <2.13.0`, so the ceiling that excludes 2.13.0 is dropped.
  void test_tightUpperBound() {
    _assertEdit("'>=2.12.0 <2.13.0'", '^2.13.0');
  }

  /// A ceiling well above the new minimum is neither raised nor widened.
  void test_unrelatedUpperBound() {
    _assertEdit("'>=2.12.0 <2.20.0'", '>=2.13.0 <2.20.0');
  }

  void _assertEdit(String from, String? expectedConstraint) {
    newFile(testPubspecPath, '''
environment:
  sdk: $from
''');
    var file = getFile(testPubspecPath);
    var edit = computeEdit(file, Version(2, 13, 0));
    if (expectedConstraint == null) {
      expect(edit, isNull);
    } else {
      expect(edit, isNotNull);
      expect(edit!.newConstraint, expectedConstraint);
    }
  }
}
