// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be used in the LICENSE file.

import 'package:analysis_server/src/plugin/dsatur.dart';
import 'package:analyzer/src/analysis_options/analysis_options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DsaturTest);
  });
}

@reflectiveTest
class DsaturTest {
  void test_conflict_differentGitRefs() {
    var v1 = PluginSpecVertex('v1', [
      _git('a', 'https://github.com/user/repo.git', ref: 'v1.0.0'),
    ]);
    var v2 = PluginSpecVertex('v2', [
      _git('a', 'https://github.com/user/repo.git', ref: 'v2.0.0'),
    ]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_conflict_differentPaths() {
    var v1 = PluginSpecVertex('v1', [_path('a', '/path/to/a')]);
    var v2 = PluginSpecVertex('v2', [_path('a', '/path/to/b')]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_conflict_differentPubVersions() {
    var v1 = PluginSpecVertex('v1', [_versioned('a', '^1.0.0')]);
    var v2 = PluginSpecVertex('v2', [_versioned('a', '^2.0.0')]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_conflict_fiveSpecs_makeThreeGroups() {
    var v1 = PluginSpecVertex('v1', [_versioned('a', '^1.0.0')]);
    var v2 = PluginSpecVertex('v2', [
      _versioned('a', '^1.0.0'),
      _versioned('b', '^2.0.0'),
    ]);
    var v3 = PluginSpecVertex('v3', [_versioned('a', '^2.0.0')]);
    var v4 = PluginSpecVertex('v4', [_versioned('a', '^2.0.0')]);
    var v5 = PluginSpecVertex('v5', [_versioned('c', '^3.0.0')]);

    var groups = groupVerticesMinimal([v1, v2, v3, v4, v5]);
    expect(groups, hasLength(3));

    var groupForV1 = groups.firstWhere((g) => g.contains(v1));
    expect(groupForV1, contains(v2));
    expect(groupForV1, hasLength(2));

    var groupForV3 = groups.firstWhere((g) => g.contains(v3));
    expect(groupForV3, contains(v4));
    expect(groupForV3, hasLength(2));

    var groupForV5 = groups.firstWhere((g) => g.contains(v5));
    expect(groupForV5, hasLength(1));
  }

  void test_conflict_noSubset() {
    var v1 = PluginSpecVertex('v1', [_versioned('a', '^1.0.0')]);
    var v2 = PluginSpecVertex('v2', [_versioned('b', '^2.0.0')]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_conflict_pathVsVersioned() {
    var v1 = PluginSpecVertex('v1', [_path('a', '/path/to/a')]);
    var v2 = PluginSpecVertex('v2', [_versioned('a', '^1.0.0')]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_conflict_versionedDifferentHosts() {
    var v1 = PluginSpecVertex('v1', [_versioned('a', '^1.0.0')]);
    var v2 = PluginSpecVertex('v2', [
      _versioned('a', '^1.0.0', hostedUrl: 'https://custom.pub.dev'),
    ]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(2));
  }

  void test_empty() {
    var groups = groupVerticesMinimal([]);
    expect(groups, isEmpty);
  }

  void test_noConflict_subset() {
    var v1 = PluginSpecVertex('v1', [_versioned('a', '^1.0.0')]);
    var v2 = PluginSpecVertex('v2', [
      _versioned('a', '^1.0.0'),
      _versioned('b', '^2.0.0'),
    ]);

    var groups = groupVerticesMinimal([v1, v2]);
    expect(groups, hasLength(1));
    expect(groups[0], containsAll([v1, v2]));
  }

  PluginConfiguration _git(
    String name,
    String url, {
    String? ref,
    String? path,
  }) {
    return PluginConfiguration(
      name: name,
      source: GitPluginSource(url: url, ref: ref, path: path),
    );
  }

  PluginConfiguration _path(String name, String path) {
    return PluginConfiguration(
      name: name,
      source: PathPluginSource(path: path),
    );
  }

  PluginConfiguration _versioned(
    String name,
    String constraint, {
    String? hostedUrl,
  }) {
    return PluginConfiguration(
      name: name,
      source: VersionedPluginSource(
        constraint: constraint,
        hostedUrl: hostedUrl,
      ),
    );
  }
}
