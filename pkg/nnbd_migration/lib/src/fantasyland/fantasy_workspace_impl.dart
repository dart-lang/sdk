// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo_impl.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';
import 'package:nnbd_migration/src/utilities/multi_future_tracker.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:package_config/packages_file.dart' as packages_file;

class FantasyWorkspaceError extends Error {
  final String message;
  FantasyWorkspaceError(this.message);

  @override
  String toString() => message;
}

// TODO(jcollins-g): consider refactor that makes resourceProvider required.
class FantasyWorkspaceDependencies {
  final Future<FantasyRepo> Function(FantasyRepoSettings, String,
      {FantasyRepoDependencies fantasyRepoDependencies}) buildGitRepoFrom;
  final ResourceProvider resourceProvider;
  final SubprocessLauncher launcher;

  FantasyWorkspaceDependencies(
      {ResourceProvider resourceProvider,
      SubprocessLauncher launcher,
      Future<FantasyRepo> Function(FantasyRepoSettings, String,
              {FantasyRepoDependencies fantasyRepoDependencies})
          buildGitRepoFrom})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE,
        launcher = launcher, // Pass through to FantasyRepoDependencies.
        buildGitRepoFrom = buildGitRepoFrom ?? FantasyRepo.buildGitRepoFrom;
}

abstract class FantasyWorkspaceBase extends FantasyWorkspace {
  final String workspaceRootPath;

  final FantasyWorkspaceDependencies _external;

  FantasyWorkspaceBase._(this.workspaceRootPath,
      {FantasyWorkspaceDependencies workspaceDependencies})
      : _external = workspaceDependencies ?? FantasyWorkspaceDependencies() {
    if (!_external.resourceProvider.pathContext.isAbsolute(workspaceRootPath)) {
      throw FantasyWorkspaceError('workspaceRootPath must be absolute');
    }
  }

  MultiFutureTracker _packageConfigLock = MultiFutureTracker(1);

  /// Repositories on which [addRepoToWorkspace] has been called.
  Map<String, Future<FantasyRepo>> _repos = {};

  /// Fully initialized subpackages.
  ///
  /// This is complete once all [addPackageNameToWorkspace] futures are complete.
  /// futures are complete.  Packages may appear here early.
  Map<FantasySubPackageSettings, FantasySubPackage> subPackages = {};

  File _packagesFile;
  File get packagesFile => _packagesFile ??= _external.resourceProvider.getFile(
      _external.resourceProvider.pathContext
          .join(workspaceRootPath, '.packages'));

  // TODO(jcollins-g): use package_config when pub package is updated, or
  // implement writing for the analyzer version ourselves.
  File get packageConfigJson => throw UnimplementedError();

  /// The returned future should complete only when this package's repository
  /// is:
  ///
  ///  cloned
  ///  up to date
  ///  added to the global .packages
  ///  symlinked into the workspace
  ///  has a [FantasySubPackage] assigned to its key in [subPackages].
  ///
  /// Returns a list of [FantasySubPackageSettings] that needed to be added as
  /// dependencies.
  ///
  /// Which dependencies are automatically added is implementation dependent.
  Future<void> addPackageNameToWorkspace(String packageName);

  Future<FantasySubPackage> addPackageToWorkspace(
      FantasySubPackageSettings packageSettings) async {
    FantasyRepo containingRepo =
        await addRepoToWorkspace(packageSettings.repoSettings);
    FantasySubPackage fantasySubPackage =
        FantasySubPackage(packageSettings, containingRepo);
    // TODO(jcollins-g): throw if double add
    subPackages[packageSettings] = fantasySubPackage;
    return fantasySubPackage;
  }

  static const _repoSubDir = '_repo';

  /// Add one repository to the workspace.
  ///
  /// The returned [Future] completes when the repository is synced and cloned.
  Future<FantasyRepo> addRepoToWorkspace(FantasyRepoSettings repoSettings) {
    if (_repos.containsKey(repoSettings.name)) return _repos[repoSettings.name];
    Folder repoRoot = _external.resourceProvider.getFolder(_external
        .resourceProvider.pathContext
        .canonicalize(_external.resourceProvider.pathContext
            .join(workspaceRootPath, _repoSubDir, repoSettings.name)));
    _repos[repoSettings.name] = _external.buildGitRepoFrom(
        repoSettings, repoRoot.path,
        fantasyRepoDependencies:
            FantasyRepoDependencies.fromWorkspaceDependencies(_external));
    return _repos[repoSettings.name];
  }

  Future<void> rewritePackageConfigWith(FantasySubPackage subPackage) async {
    return _packageConfigLock.runFutureFromClosure(
        () async => _rewritePackageConfigWith(subPackage));
  }

  // Only one [_rewritePackageConfigWith] should be running at a time
  // per workspace.
  Future<void> _rewritePackageConfigWith(FantasySubPackage subPackage) async {
    Map<String, Uri> uriMap = {};
    if (packagesFile.exists) {
      var uri = packagesFile.toUri();
      var content = packagesFile.readAsBytesSync();
      uriMap = packages_file.parse(content, uri);
    }
    uriMap[subPackage.name] =
        subPackage.packageRoot.getChildAssumingFolder('lib').toUri();
    StringBuffer buffer = StringBuffer();
    packages_file.write(buffer, uriMap);
    // TODO(jcollins-g): Consider accumulating rewrites rather than doing
    // this once per package.
    // TODO(jcollins-g): support package_config.json.
    return packagesFile.writeAsStringSync(buffer.toString());
  }
}

/// Represents a [FantasyWorkspaceBase] that only fetches dev_dependencies
/// for the top level package.
class FantasyWorkspaceTopLevelDevDepsImpl extends FantasyWorkspaceBase {
  final String topLevelPackage;

  FantasyWorkspaceTopLevelDevDepsImpl._(
      this.topLevelPackage, String workspaceRootPath,
      {FantasyWorkspaceDependencies workspaceDependencies})
      : super._(workspaceRootPath,
            workspaceDependencies: workspaceDependencies);

  static Future<FantasyWorkspace> buildFor(String topLevelPackage,
      List<String> extraPackageNames, String workspaceRootPath,
      {FantasyWorkspaceDependencies workspaceDependencies}) async {
    var workspace = FantasyWorkspaceTopLevelDevDepsImpl._(
        topLevelPackage, workspaceRootPath,
        workspaceDependencies: workspaceDependencies);
    await Future.wait([
      for (var n in [topLevelPackage, ...extraPackageNames])
        workspace.addPackageNameToWorkspace(n)
    ]);
    return workspace;
  }

  Future<FantasySubPackage> addPackageNameToWorkspace(
      String packageName) async {
    FantasySubPackageSettings packageSettings =
        FantasySubPackageSettings.fromName(packageName);
    return await addPackageToWorkspace(packageSettings);
  }

  @override
  Future<FantasySubPackage> addPackageToWorkspace(
      FantasySubPackageSettings packageSettings,
      {Set<FantasySubPackageSettings> seenPackages}) async {
    seenPackages ??= {};
    if (seenPackages.contains(packageSettings)) return null;
    seenPackages.add(packageSettings);
    await _addPackageToWorkspace(packageSettings, seenPackages);
  }

  Future<FantasySubPackage> _addPackageToWorkspace(
      FantasySubPackageSettings packageSettings,
      Set<FantasySubPackageSettings> seenPackages) async {
    FantasySubPackage fantasySubPackage =
        await super.addPackageToWorkspace(packageSettings);
    String packageName = packageSettings.name;

    await rewritePackageConfigWith(fantasySubPackage);
    List<FantasySubPackageSettings> dependencies = [];

    if (packageName == topLevelPackage) {
      dependencies = await fantasySubPackage.getPackageAllDependencies();
    } else {
      dependencies = await fantasySubPackage.getPackageDependencies();
    }

    await Future.wait([
      for (var subPackageSettings in dependencies)
        addPackageToWorkspace(subPackageSettings, seenPackages: seenPackages)
    ]);
    return fantasySubPackage;
  }
}
