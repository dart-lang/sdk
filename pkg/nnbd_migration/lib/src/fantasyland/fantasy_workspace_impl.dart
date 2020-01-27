// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';

/// Represent a single [FantasyWorkspaceImpl].
abstract class FantasyWorkspaceImpl extends FantasyWorkspace {
  @override
  final Directory workspaceRoot;

  FantasyWorkspaceImpl._(this.workspaceRoot);

  /// Repositories on which [addRepoToWorkspace] has been called.
  Map<String, Future<FantasyRepo>> _repos = {};

  /// Sub-packages on which [addPackageToWorkspace] has been called.
  Map<String, Future<List<String>>> _packageDependencies = {};

  /// Fully initialized subpackages.
  ///
  /// This is complete once all [addPackageToWorkspace] futures are complete.
  /// futures are complete.
  Map<String, FantasySubPackage> subPackages = {};

  /// Implementation-dependent part of addPackageToWorkspace.
  ///
  /// The returned future should complete only when this package's repository
  /// is:
  ///
  ///  cloned
  ///  up to date
  ///  added to the global .packages
  ///  symlinked into the workspace
  ///  has a [FantasySubPackage] assigned to its key in [subPackages].
  ///
  /// Returns a list of packageNames that needed to be added as dependencies.
  ///
  /// Which dependencies are automatically added is implementation dependent.
  Future<List<String>> addPackageToWorkspaceInternal(String packageName);

  Future<void> addPackageToWorkspace(String packageName) async {
    if (_packageDependencies.containsKey(packageName)) return;
    _packageDependencies[packageName] =
        addPackageToWorkspaceInternal(packageName);
    return Future.wait((await _packageDependencies[packageName])
        .map((n) => addPackageToWorkspace(n)));
  }

  /// Asynchronously add one repository to the workspace.
  ///
  /// Completes when the repository is synced and cloned.
  /// Completes immediately if the [repoName] is already added.
  Future<FantasyRepo> addRepoToWorkspace(String repoName) {
    if (_repos.containsKey(repoName)) return _repos[repoName];
    _repos[repoName] = FantasyRepo.buildFrom(repoName, workspaceRoot);
    return _repos[repoName];
  }
}

/// Represents a [FantasyWorkspaceImpl] that only fetches dev_dependencies
/// for the top level package.
class FantasyWorkspaceTopLevelDevDepsImpl extends FantasyWorkspaceImpl {
  final String topLevelPackage;

  FantasyWorkspaceTopLevelDevDepsImpl._(
      this.topLevelPackage, Directory workspaceRoot)
      : super._(workspaceRoot);

  static Future<FantasyWorkspace> buildFor(String topLevelPackage,
      List<String> extraPackageNames, Directory workspaceRoot) async {
    if (!await workspaceRoot.exists())
      await workspaceRoot.create(recursive: true);

    var workspace =
        FantasyWorkspaceTopLevelDevDepsImpl._(topLevelPackage, workspaceRoot);
    await Future.wait([
      for (var n in [topLevelPackage, ...extraPackageNames])
        workspace.addPackageToWorkspace(n)
    ]);
    return workspace;
  }

  Future<List<String>> addPackageToWorkspaceInternal(String packageName) async {
    FantasySubPackageSettings packageSettings =
        FantasySubPackageSettings.fromName(packageName);
    FantasyRepo containingRepo =
        await addRepoToWorkspace(packageSettings.repoName);
    await FantasySubPackage.buildFrom(
        packageName, containingRepo, workspaceRoot);
    if (packageName == topLevelPackage) {
      throw UnimplementedError(); // TODO(jcollins-g): implement some dependency calculations.
    }
    return [];
  }
}
