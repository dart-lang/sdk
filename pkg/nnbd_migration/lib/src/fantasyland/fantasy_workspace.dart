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
}

/// Build a "fantasyland"-style repository structure suitable for applying
/// a migration to.
Future<FantasyWorkspace> buildFantasyLand(String topLevelPackage,
    List<String> extraPackages, String fantasyLandDir, bool allowUpdate) {
  return FantasyWorkspaceTopLevelDevDepsImpl.buildFor(
      topLevelPackage, extraPackages, fantasyLandDir, allowUpdate);
}
