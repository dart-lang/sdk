// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginLocatorTest);
  });
}

@reflectiveTest
class PluginLocatorTest with ResourceProviderMixin {
  String packageRoot;
  String pubspecPath;
  String defaultDirPath;
  PluginLocator locator;

  void setUp() {
    packageRoot = newFolder('/package').path;
    locator = PluginLocator(resourceProvider);
  }

  @failingTest
  void test_findPlugin_inPubspec_defaultDir() {
    // Support for specifying plugin locations in the pubspec is temporarily
    // disabled.
    var dirPath = _createPubspecWithKey();
    _createDefaultDir();
    expect(locator.findPlugin(packageRoot), dirPath);
  }

  @failingTest
  void test_findPlugin_inPubspec_noDefaultDir() {
    // Support for specifying plugin locations in the pubspec is temporarily
    // disabled.
    var dirPath = _createPubspecWithKey();
    expect(locator.findPlugin(packageRoot), dirPath);
  }

  void test_findPlugin_noPubspec_defaultDir() {
    _createDefaultDir();
    expect(locator.findPlugin(packageRoot), defaultDirPath);
  }

  void test_findPlugin_noPubspec_noDefaultDir() {
    expect(locator.findPlugin(packageRoot), isNull);
  }

  void test_findPlugin_notInPubspec_defaultDir() {
    _createPubspecWithoutKey();
    _createDefaultDir();
    expect(locator.findPlugin(packageRoot), defaultDirPath);
  }

  void test_findPlugin_notInPubspec_noDefaultDir() {
    _createPubspecWithoutKey();
    expect(locator.findPlugin(packageRoot), isNull);
  }

  void _createDefaultDir() {
    defaultDirPath = newFolder(
            '/package/${PluginLocator.toolsFolderName}/${PluginLocator.defaultPluginFolderName}')
        .path;
  }

  void _createPubspec(String content) {
    pubspecPath =
        newFile('/package/${PluginLocator.pubspecFileName}', content: content)
            .path;
  }

  String _createPubspecWithKey() {
    var nonDefaultPath = newFolder('/package/pluginDir').path;
    _createPubspec('''
name: test_project
${PluginLocator.analyzerPluginKey}: $nonDefaultPath
''');
    return nonDefaultPath;
  }

  void _createPubspecWithoutKey() {
    _createPubspec('''
name: test_project
''');
  }
}
