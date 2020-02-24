// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo_impl.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_sub_package.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';
import 'package:nnbd_migration/src/utilities/multi_future_tracker.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';

class FantasyWorkspaceError extends Error {
  final String message;
  FantasyWorkspaceError(this.message);

  @override
  String toString() => message;
}

// TODO(jcollins-g): consider refactor that makes resourceProvider required.
class FantasyWorkspaceDependencies {
  final Future<FantasyRepo> Function(FantasyRepoSettings, String, bool,
      {FantasyRepoDependencies fantasyRepoDependencies}) buildGitRepoFrom;
  final ResourceProvider resourceProvider;
  final SubprocessLauncher launcher;

  FantasyWorkspaceDependencies(
      {ResourceProvider resourceProvider,
      SubprocessLauncher launcher,
      Future<FantasyRepo> Function(FantasyRepoSettings, String, bool,
              {FantasyRepoDependencies fantasyRepoDependencies})
          buildGitRepoFrom,
      List<String> dartfixExec})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE,
        launcher = launcher ?? SubprocessLauncher('fantasy-workspace'),
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

  File _packageConfigJson;
  File get packageConfigJson => _packageConfigJson ??=
      _external.resourceProvider.getFile(_external.resourceProvider.pathContext
          .join(workspaceRootPath, '.dart_tool', 'package_config.json'));

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
  Future<void> addPackageNameToWorkspace(String packageName, bool allowUpdate);

  Future<FantasySubPackage> addPackageToWorkspace(
      FantasySubPackageSettings packageSettings, bool allowUpdate) async {
    FantasyRepo containingRepo =
        await addRepoToWorkspace(packageSettings.repoSettings, allowUpdate);
    FantasySubPackage fantasySubPackage =
        FantasySubPackage(packageSettings, containingRepo);
    // TODO(jcollins-g): throw if double add
    subPackages[packageSettings] = fantasySubPackage;
    fantasySubPackage.cleanUp();
    return fantasySubPackage;
  }

  @override
  Future<void> forceMigratePackages(
      Iterable<FantasySubPackage> subPackages,
      Iterable<FantasySubPackage> subPackagesLibOnly,
      String sdkPath,
      List<String> dartfixExec) async {
    String dartfix_bin = dartfixExec.first;
    List<String> args = dartfixExec.sublist(1);
    args.addAll(
        ['upgrade', 'sdk', '--no-preview', '--force', '--sdk=$sdkPath']);
    for (FantasySubPackage subPackage in subPackages) {
      args.add(subPackage.packageRoot.path);
    }
    for (FantasySubPackage subPackage in subPackagesLibOnly) {
      args.add(subPackage.packageRoot.getChildAssumingFolder('lib').path);
    }
    return _external.launcher.runStreamed(dartfix_bin, args);
  }

  static const _repoSubDir = '_repo';

  /// Add one repository to the workspace.
  ///
  /// If allowUpdate is true, the repository will be pulled before being
  /// synced.
  ///
  /// The returned [Future] completes when the repository is synced and cloned.
  Future<FantasyRepo> addRepoToWorkspace(
      FantasyRepoSettings repoSettings, bool allowUpdate) {
    if (_repos.containsKey(repoSettings.name)) return _repos[repoSettings.name];
    Folder repoRoot = _external.resourceProvider.getFolder(_external
        .resourceProvider.pathContext
        .canonicalize(_external.resourceProvider.pathContext
            .join(workspaceRootPath, _repoSubDir, repoSettings.name)));
    _repos[repoSettings.name] = _external.buildGitRepoFrom(
        repoSettings, repoRoot.path, allowUpdate,
        fantasyRepoDependencies:
            FantasyRepoDependencies.fromWorkspaceDependencies(_external));
    return _repos[repoSettings.name];
  }

  @override
  Future<void> rewritePackageConfigWith(FantasySubPackage subPackage) async {
    return _packageConfigLock.runFutureFromClosure(
        () async => _rewritePackageConfigWith(subPackage));
  }

  // Only one [_rewritePackageConfigWith] should be running at a time
  // per workspace.
  Future<void> _rewritePackageConfigWith(FantasySubPackage subPackage) async {
    if (packagesFile.exists) {
      // A rogue .packages file can signal to tools the absence of a
      // [FantasySubPackage.languageVersion].  This paradoxically will mean
      // to our tools that all language features, including NNBD, are enabled,
      // which is not necessarily what we want.  It is safer to delete this to
      // prevent it from being used accidentally.
      packagesFile.delete();
    }
    Map<String, Object> packageConfigMap = {
      "configVersion": 2,
      "packages": <Map<String, String>>[],
    };
    if (packageConfigJson.exists) {
      packageConfigMap = jsonDecode(packageConfigJson.readAsStringSync())
          as Map<String, Object>;
    }

    packageConfigMap['generated'] = DateTime.now().toIso8601String();
    packageConfigMap['generator'] = 'fantasyland';
    // TODO(jcollins-g): analyzer seems to depend on this and ignore some versions
    packageConfigMap['generatorVersion'] = "2.8.0-dev.9999.0";

    var packages = packageConfigMap['packages'] as List;
    var rewriteMe =
        packages.firstWhere((p) => p['name'] == subPackage.name, orElse: () {
      Map<String, String> newMap = {};
      packages.add(newMap);
      return newMap;
    });

    rewriteMe['name'] = subPackage.name;
    String subPackageRootUriString =
        subPackage.packageRoot.toUri().normalizePath().toString();
    if (subPackageRootUriString.endsWith('/')) {
      subPackageRootUriString = subPackageRootUriString.substring(
          0, subPackageRootUriString.length - 1);
    }
    rewriteMe['rootUri'] = subPackageRootUriString;
    // TODO(jcollins-g): is this ever anything different?
    rewriteMe['packageUri'] = 'lib/';
    if (subPackage.languageVersion != null) {
      rewriteMe['languageVersion'] = subPackage.languageVersion;
    } else {
      rewriteMe.remove('languageVersion');
    }

    packageConfigJson.parent.create();
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    packageConfigJson.writeAsStringSync(encoder.convert(packageConfigMap));
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

  static Future<FantasyWorkspace> buildFor(
      String topLevelPackage,
      List<String> extraPackageNames,
      String workspaceRootPath,
      bool allowUpdate,
      {FantasyWorkspaceDependencies workspaceDependencies}) async {
    var workspace = FantasyWorkspaceTopLevelDevDepsImpl._(
        topLevelPackage, workspaceRootPath,
        workspaceDependencies: workspaceDependencies);
    await Future.wait([
      for (var n in [topLevelPackage, ...extraPackageNames])
        workspace.addPackageNameToWorkspace(n, allowUpdate)
    ]);
    return workspace;
  }

  Future<FantasySubPackage> addPackageNameToWorkspace(
      String packageName, bool allowUpdate) async {
    FantasySubPackageSettings packageSettings =
        FantasySubPackageSettings.fromName(packageName);
    return await addPackageToWorkspace(packageSettings, allowUpdate);
  }

  @override
  Future<FantasySubPackage> addPackageToWorkspace(
      FantasySubPackageSettings packageSettings, bool allowUpdate,
      {Set<FantasySubPackageSettings> seenPackages}) async {
    seenPackages ??= {};
    if (seenPackages.contains(packageSettings)) return null;
    seenPackages.add(packageSettings);
    return await _addPackageToWorkspace(
        packageSettings, allowUpdate, seenPackages);
  }

  Future<FantasySubPackage> _addPackageToWorkspace(
      FantasySubPackageSettings packageSettings,
      bool allowUpdate,
      Set<FantasySubPackageSettings> seenPackages) async {
    FantasySubPackage fantasySubPackage =
        await super.addPackageToWorkspace(packageSettings, allowUpdate);
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
        addPackageToWorkspace(subPackageSettings, allowUpdate,
            seenPackages: seenPackages)
    ]);
    return fantasySubPackage;
  }
}
