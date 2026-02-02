// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin2/generator.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GeneratorTest);
  });
}

@reflectiveTest
class GeneratorTest {
  void test_entrypointImportsPluginEntrypoints() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: VersionedPluginSource(constraint: '^1.2.0'),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generateEntrypoint(),
      contains('''
import 'package:no_bools/main.dart' as no_bools;
import 'package:no_ints/main.dart' as no_ints;
'''),
    );
  }

  void test_entrypointListsPluginInstances() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: VersionedPluginSource(constraint: '^1.2.0'),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generateEntrypoint(),
      contains('''
    plugins: [
      no_bools.plugin,
      no_ints.plugin,
    ],
'''),
    );
  }

  void test_pubspecContainsDependencyOverrides() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
      ],
      dependencyOverrides: {
        'dep_one': VersionedPluginSource(constraint: '2.0.0'),
        'dep_two': PathPluginSource(path: '/aaa/bbb/ccc'),
      },
    );
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
dependency_overrides:
  dep_one: 2.0.0
  dep_two:
    path: /aaa/bbb/ccc
'''),
    );
  }

  void test_pubspecContainsGitDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: GitPluginSource(url: 'https://example.com/example.git'),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
  no_bools:
    git:
      url: https://example.com/example.git
'''),
    );
  }

  void test_pubspecContainsPathDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: PathPluginSource(path: '../no_bools_plugin'),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: PathPluginSource(path: 'tools/no_ints_plugin'),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
  no_bools:
    path: ../no_bools_plugin
  no_ints:
    path: tools/no_ints_plugin
'''),
    );
  }

  void test_pubspecContainsSdkConstraint() {
    var pluginPackageGenerator = PluginPackageGenerator(configurations: []);
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
environment:
  sdk: ^3.6.0
'''),
    );
  }

  void test_pubspecContainsVersionedDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: VersionedPluginSource(constraint: '^1.2.0'),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
  no_bools: ^1.0.0
  no_ints: ^1.2.0
'''),
    );
  }

  void test_pubspecContainsVersionedHostedDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator(
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(
            constraint: '^1.0.0',
            hostedUrl: 'https://example.com/packages/',
          ),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: VersionedPluginSource(
            constraint: '^1.2.0',
            hostedUrl: 'https://example.com/packages/',
          ),
        ),
      ],
    );
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
  no_bools:
    version: ^1.0.0
    hosted: https://example.com/packages/
  no_ints:
    version: ^1.2.0
    hosted: https://example.com/packages/
'''),
    );
  }

  void test_useMapConstructor() {
    var pluginPackageGenerator = PluginPackageGenerator(
      useMapConstructor: true,
      configurations: [
        PluginConfiguration(
          name: 'no_bools',
          source: VersionedPluginSource(constraint: '^1.0.0'),
        ),
        PluginConfiguration(
          name: 'no_ints',
          source: VersionedPluginSource(constraint: '^1.2.0'),
        ),
      ],
    );
    var entrypoint = pluginPackageGenerator.generateEntrypoint();
    expect(entrypoint, contains("'no_bools': no_bools.plugin,"));
    expect(entrypoint, contains("'no_ints': no_ints.plugin,"));
    var pubspec = pluginPackageGenerator.generatePubspec();
    expect(pubspec, contains('analysis_server_plugin: ^0.3.8'));
  }
}
