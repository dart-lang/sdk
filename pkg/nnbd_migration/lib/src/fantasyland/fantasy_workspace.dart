// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';

/// Represent a single [FantasyWorkspace].
abstract class FantasyWorkspace {
  Directory get workspaceRoot;

  /// Fully initialized subpackages.
  ///
  /// This is fully populated once all [addPackageToWorkspace] futures are
  /// complete.
  Map<String, FantasySubPackage> subPackages = {};

  /// Asynchronously add one package to the workspace.
  ///
  /// Completes when the given package and all its dependencies (implementation
  /// dependent) are added to the workspace.
  Future<void> addPackageToWorkspace(String packageName);

  /// Asynchronously add one repository to the workspace.
  ///
  /// Completes when the repository is synced and cloned.
  /// Completes immediately if the [repoName] is already added.
  Future<FantasyRepo> addRepoToWorkspace(String repoName);
}

/// Build a "fantasyland"style repository structure suitable for applying
/// a migration to.
Future<FantasyWorkspace> buildFantasyLand(String topLevelPackage,
    List<String> extraPackages, Directory fantasyLandDir) {
  return FantasyWorkspaceTopLevelDevDepsImpl.buildFor(
      topLevelPackage, extraPackages, fantasyLandDir);
}
