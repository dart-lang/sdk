// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';

export 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';

/// Represent a single [FantasyWorkspace].
abstract class FantasyWorkspace {
  String get workspaceRootPath;

  /// Fully initialized subpackages.
  Map<FantasySubPackageSettings, FantasySubPackage> subPackages;

  /// Add a package to the workspace, given [packageSettings].
  ///
  /// Completes when the repository and subPackage is added.
  /// If allowUpdate is true, the repository may be updated to the latest
  /// version.
  Future<FantasySubPackage> addPackageToWorkspace(
      FantasySubPackageSettings packageSettings, bool allowUpdate);

  /// Run the dart analyzer over these packages.
  ///
  /// Assumes they have been migrated.
  Future<void> analyzePackages(
      Iterable<FantasySubPackage> subPackages,
      Iterable<FantasySubPackage> subPackagesLibOnly,
      List<String> dartanalyzerExec);

  /// Force-migrate these packages.
  ///
  /// All [subPackages] must be part of this workspace.  Returned future
  /// completes when all [subPackages] have been migrated.  Completes with
  /// `true` if packages needed to be migrated, `false` if skipped.
  Future<bool> forceMigratePackages(Iterable<FantasySubPackage> subPackages,
      Iterable<FantasySubPackage> subPackagesLibOnly, List<String> dartdevExec);

  /// Rewrite the package_config.json and/or .packages for this package.
  Future<void> rewritePackageConfigWith(FantasySubPackage subPackage);
}

/// Build a "fantasyland"-style repository structure suitable for applying
/// a migration to.
Future<FantasyWorkspace> buildFantasyLand(String topLevelPackage,
    List<String> extraPackages, String fantasyLandDir, bool allowUpdate) {
  return FantasyWorkspaceTopLevelDevDepsImpl.buildFor(
      topLevelPackage, extraPackages, fantasyLandDir, allowUpdate);
}
