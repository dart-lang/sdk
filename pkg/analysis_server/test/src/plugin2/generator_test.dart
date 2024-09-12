// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin2/generator.dart';
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
    var pluginPackageGenerator = PluginPackageGenerator({
      'no_bools': '^1.0.0',
      'no_ints': '^1.2.0',
    });
    expect(
      pluginPackageGenerator.generateEntrypoint(),
      contains('''
import 'package:no_bools/main.dart' as no_bools;
import 'package:no_ints/main.dart' as no_ints;
'''),
    );
  }

  void test_entrypointListsPluginInstances() {
    var pluginPackageGenerator = PluginPackageGenerator({
      'no_bools': '^1.0.0',
      'no_ints': '^1.2.0',
    });
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

  void test_pubspecContainsGitDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator({
      'no_bools': {'git': 'https://example.com/example.git'},
    });
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
dependencies:
  no_bools:
    git: https://example.com/example.git
'''),
    );
  }

  void test_pubspecContainsPathDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator({
      'no_bools': {'path': '../no_bools_plugin'},
      'no_ints': {'path': 'tools/no_ints_plugin'},
    });
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
dependencies:
  no_bools:
    path: ../no_bools_plugin
  no_ints:
    path: tools/no_ints_plugin
'''),
    );
  }

  void test_pubspecContainsVersionedDependencies() {
    var pluginPackageGenerator = PluginPackageGenerator({
      'no_bools': '^1.0.0',
      'no_ints': '^1.2.0',
    });
    expect(
      pluginPackageGenerator.generatePubspec(),
      contains('''
dependencies:
  no_bools: ^1.0.0
  no_ints: ^1.2.0
'''),
    );
  }
}
