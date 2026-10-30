// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_trust.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginTrustTest);
  });
}

@reflectiveTest
class PluginTrustTest with ResourceProviderMixin {
  late PluginTrust pluginTrust;

  void setUp() {
    pluginTrust = PluginTrust(resourceProvider);
  }

  void test_contentTrust_excludesDartToolAndGitFolders() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');

    var hash1 = pluginTrust.computeFolderHash(pluginFolder);
    expect(hash1, isNotNull);

    newFile('/plugins/p1/.dart_tool/package_config.json', '{}');
    newFile('/plugins/p1/.git/HEAD', 'ref: refs/heads/main');

    var hash2 = pluginTrust.computeFolderHash(pluginFolder);
    expect(hash2, equals(hash1));
  }

  void test_contentTrust_invalidatedWhenFileChanges() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');

    expect(
      pluginTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );

    pluginTrust.setContentTrust('p1', pluginFolder);
    expect(
      pluginTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.trusted,
    );

    // Modify the plugin's code contents.
    newFile('/plugins/p1/lib/main.dart', 'int x = 2;');
    expect(
      pluginTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );
  }

  void test_contentTrust_multipleHashesSupportedForSamePlugin() {
    var v1Folder = newFolder('/cache/p1-1.0.0');
    newFile('/cache/p1-1.0.0/lib/main.dart', 'int v = 1;');
    var v2Folder = newFolder('/cache/p1-2.0.0');
    newFile('/cache/p1-2.0.0/lib/main.dart', 'int v = 2;');

    pluginTrust.setContentTrust('p1', v1Folder);
    pluginTrust.setContentTrust('p1', v2Folder);

    expect(
      pluginTrust.getTrust('p1', pluginFolder: v1Folder),
      TrustSetting.trusted,
    );
    expect(
      pluginTrust.getTrust('p1', pluginFolder: v2Folder),
      TrustSetting.trusted,
    );
  }

  void test_corruptedStorageFile_returnsUnset() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');
    var storageFile = newFile('/state/plugin_trust.json', 'not valid json');
    var trust = PluginTrust(resourceProvider, storageFile);

    expect(
      trust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );
  }
}
