// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';

export 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';

/// Represent a single [FantasyWorkspace].
abstract class FantasyWorkspace {
  Directory get workspaceRoot;

  /// Fully initialized subpackages.
  Map<String, FantasySubPackage> subPackages;
}

/// Build a "fantasyland"-style repository structure suitable for applying
/// a migration to.
Future<FantasyWorkspace> buildFantasyLand(String topLevelPackage,
    List<String> extraPackages, Directory fantasyLandDir) {
  return FantasyWorkspaceTopLevelDevDepsImpl.buildFor(
      topLevelPackage, extraPackages, fantasyLandDir);
}
