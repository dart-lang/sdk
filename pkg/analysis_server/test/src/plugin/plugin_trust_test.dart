// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/plugin/plugin_trust.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
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
    var source = PathPluginSource(path: pluginFolder.path);

    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.unset,
    );

    pluginTrust.setContentTrust('p1', source, pluginFolder);
    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.trusted,
    );

    // Modify the plugin's code contents.
    newFile('/plugins/p1/lib/main.dart', 'int x = 2;');
    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.unset,
    );
  }

  void test_contentTrust_multipleHashesSupportedForSamePlugin() {
    var v1Folder = newFolder('/cache/p1-1.0.0');
    newFile('/cache/p1-1.0.0/lib/main.dart', 'int v = 1;');
    var v2Folder = newFolder('/cache/p1-2.0.0');
    newFile('/cache/p1-2.0.0/lib/main.dart', 'int v = 2;');

    var source1 = VersionedPluginSource(constraint: '^1.0.0');
    var source2 = VersionedPluginSource(constraint: '^2.0.0');

    pluginTrust.setContentTrust('p1', source1, v1Folder);
    pluginTrust.setContentTrust('p1', source2, v2Folder);

    expect(
      pluginTrust.getTrust('p1', source1, pluginFolder: v1Folder),
      TrustSetting.trusted,
    );
    expect(
      pluginTrust.getTrust('p1', source2, pluginFolder: v2Folder),
      TrustSetting.trusted,
    );
  }

  void test_contentTrust_overridesPreviousNeverTrustAndViceVersa() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');
    var source = VersionedPluginSource(constraint: '^1.0.0');

    pluginTrust.setSourceTrust('p1', source, trusted: false);
    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.untrusted,
    );

    // Trusting contents clears the explicit untrusted source entry.
    pluginTrust.setContentTrust('p1', source, pluginFolder);
    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.trusted,
    );

    // Explicitly untrusting the source clears trusted content hashes.
    pluginTrust.setSourceTrust('p1', source, trusted: false);
    expect(pluginTrust.hasTrustedHashes('p1'), isFalse);
    expect(
      pluginTrust.getTrust('p1', source, pluginFolder: pluginFolder),
      TrustSetting.untrusted,
    );
  }

  void test_corruptedStorageFile_returnsUnset() {
    var pluginFolder = newFolder('/plugins/p1');
    newFile('/plugins/p1/lib/main.dart', 'int x = 1;');
    var storageFile = newFile('/state/plugin_trust.json', 'not valid json');
    var trust = PluginTrust(resourceProvider, storageFile);

    expect(
      trust.getTrust(
        'p1',
        VersionedPluginSource(constraint: '^1.0.0'),
        pluginFolder: pluginFolder,
      ),
      TrustSetting.unset,
    );
  }

  void test_gitSource_ignoresRefAndTagPattern_includesPath() {
    var gitV1 = GitPluginSource(
      url: 'https://github.com/example/p2.git',
      ref: 'v1.0.0',
      tagPattern: 'v*',
    );
    var gitV2 = GitPluginSource(
      url: 'https://github.com/example/p2.git',
      ref: 'abcdef123456',
    );
    var gitWithSubpath = GitPluginSource(
      url: 'https://github.com/example/p2.git',
      path: 'pkgs/p2',
    );

    pluginTrust.setSourceTrust('p2', gitV1, trusted: true);
    expect(pluginTrust.getTrust('p2', gitV1), TrustSetting.trusted);
    expect(pluginTrust.getTrust('p2', gitV2), TrustSetting.trusted);
    expect(pluginTrust.getTrust('p2', gitWithSubpath), TrustSetting.unset);
  }

  void test_pathSource_resolvesSymbolicLinks() {
    var realFolder = newFolder('/real/p3');
    var linkPath = convertPath('/linked_p3');
    newLink(linkPath, realFolder.path);

    pluginTrust.setSourceTrust(
      'p3',
      PathPluginSource(path: linkPath),
      trusted: true,
    );
    expect(
      pluginTrust.getTrust('p3', PathPluginSource(path: realFolder.path)),
      TrustSetting.trusted,
    );
    expect(
      pluginTrust.getTrust('p3', PathPluginSource(path: linkPath)),
      TrustSetting.trusted,
    );
  }

  void test_versionedSource_ignoresVersionConstraint_respectsHostedUrl() {
    var v1 = VersionedPluginSource(constraint: '^1.0.0');
    var v2 = VersionedPluginSource(constraint: '^2.0.0');
    var customHost = VersionedPluginSource(
      constraint: '^1.0.0',
      hostedUrl: 'https://pub.example.com/',
    );
    var customHostNoSlash = VersionedPluginSource(
      constraint: '^2.0.0',
      hostedUrl: 'https://pub.example.com',
    );
    var otherHost = VersionedPluginSource(
      constraint: '^1.0.0',
      hostedUrl: 'https://evil.example.com',
    );

    pluginTrust.setSourceTrust('p1', v1, trusted: true);
    expect(pluginTrust.getTrust('p1', v1), TrustSetting.trusted);
    expect(pluginTrust.getTrust('p1', v2), TrustSetting.trusted);
    expect(pluginTrust.getTrust('p1', customHost), TrustSetting.unset);
    expect(pluginTrust.getTrust('other_plugin', v1), TrustSetting.unset);

    pluginTrust.setSourceTrust('p1', customHost, trusted: true);
    expect(pluginTrust.getTrust('p1', customHostNoSlash), TrustSetting.trusted);
    expect(pluginTrust.getTrust('p1', otherHost), TrustSetting.unset);
  }
}
