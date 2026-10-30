// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/workspace_trust.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceTrustTest);
  });
}

@reflectiveTest
class WorkspaceTrustTest with ResourceProviderMixin {
  late WorkspaceTrust workspaceTrust;

  void setUp() {
    workspaceTrust = WorkspaceTrust(resourceProvider);
  }

  void test_contentTrust_excludesDartToolAndGitFolders() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');

    var hash1 = workspaceTrust.computeFolderHash(pluginFolder);
    expect(hash1, isNotNull);

    newFile('/plugins/p1/.dart_tool/package_config.json', '{}');
    newFile('/plugins/p1/.git/HEAD', 'ref: refs/heads/main');

    var hash2 = workspaceTrust.computeFolderHash(pluginFolder);
    expect(hash2, equals(hash1));
  }

  void test_contentTrust_invalidatedWhenFileChanges() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');

    expect(
      workspaceTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );

    workspaceTrust.setContentTrust('p1', pluginFolder);
    expect(
      workspaceTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.trusted,
    );

    // Modify the plugin's code contents.
    newFile('/plugins/p1/lib/main.dart', 'int x = 2;');
    expect(
      workspaceTrust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );
  }

  void test_contentTrust_multipleHashesSupportedForSamePlugin() {
    var v1Folder = newFolder('/cache/p1-1.0.0');
    newFile('/cache/p1-1.0.0/lib/main.dart', 'int v = 1;');
    var v2Folder = newFolder('/cache/p1-2.0.0');
    newFile('/cache/p1-2.0.0/lib/main.dart', 'int v = 2;');

    workspaceTrust.setContentTrust('p1', v1Folder);
    workspaceTrust.setContentTrust('p1', v2Folder);

    expect(
      workspaceTrust.getTrust('p1', pluginFolder: v1Folder),
      TrustSetting.trusted,
    );
    expect(
      workspaceTrust.getTrust('p1', pluginFolder: v2Folder),
      TrustSetting.trusted,
    );
  }

  void test_corruptedStorageFile_returnsUnset() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');
    var storageFile = newFile('/state/workspace_trust.json', 'not valid json');
    var trust = WorkspaceTrust(resourceProvider, storageFile);

    expect(
      trust.getTrust('p1', pluginFolder: pluginFolder),
      TrustSetting.unset,
    );
  }
}
