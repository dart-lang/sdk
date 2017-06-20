// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_locator.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginLocatorTest);
  });
}

@reflectiveTest
class PluginLocatorTest {
  MemoryResourceProvider resourceProvider;
  String packageRoot;
  String pubspecPath;
  String defaultDirPath;
  PluginLocator locator;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    packageRoot = resourceProvider.convertPath('/package');
    resourceProvider.newFolder(packageRoot);
    locator = new PluginLocator(resourceProvider);
  }

  void test_findPlugin_inPubspec_defaultDir() {
    String dirPath = _createPubspecWithKey();
    _createDefaultDir();
    expect(locator.findPlugin(packageRoot), dirPath);
  }

  void test_findPlugin_inPubspec_noDefaultDir() {
    String dirPath = _createPubspecWithKey();
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
    defaultDirPath = resourceProvider.pathContext.join(packageRoot,
        PluginLocator.toolsFolderName, PluginLocator.defaultPluginFolderName);
    resourceProvider.newFolder(defaultDirPath);
  }

  void _createPubspec(String content) {
    pubspecPath = resourceProvider.pathContext
        .join(packageRoot, PluginLocator.pubspecFileName);
    resourceProvider.newFile(pubspecPath, content);
  }

  String _createPubspecWithKey() {
    String nonDefaultPath =
        resourceProvider.pathContext.join(packageRoot, 'pluginDir');
    _createPubspec('''
name: test_project
${PluginLocator.analyzerPluginKey}: $nonDefaultPath
''');
    resourceProvider.newFolder(nonDefaultPath);
    return nonDefaultPath;
  }

  void _createPubspecWithoutKey() {
    _createPubspec('''
name: test_project
''');
  }
}
