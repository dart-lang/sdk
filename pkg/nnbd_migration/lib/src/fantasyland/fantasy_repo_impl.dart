// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show ProcessException;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_workspace_impl.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';

const _httpGithub = 'https://github.com';

class FantasyRepoDependencies {
  final ResourceProvider resourceProvider;
  final SubprocessLauncher launcher;

  FantasyRepoDependencies(
      {ResourceProvider resourceProvider,
      String name,
      SubprocessLauncher launcher})
      : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE,
        launcher = launcher ??
            SubprocessLauncher(
                'FantasyRepo.${name == null ? "buildFrom" : "buildFrom-$name"}');

  factory FantasyRepoDependencies.fromWorkspaceDependencies(
      FantasyWorkspaceDependencies workspaceDependencies) {
    return FantasyRepoDependencies(
        resourceProvider: workspaceDependencies.resourceProvider,
        launcher: workspaceDependencies.launcher);
  }
}

/// Represent a single git clone that may be referred to by one or more
/// [FantasySubPackage]s.
class FantasyRepoGitImpl extends FantasyRepo {
  final String name;
  final FantasyRepoSettings repoSettings;
  final String _repoRootPath;
  Folder get repoRoot => _external.resourceProvider.getFolder(_repoRootPath);
  final FantasyRepoDependencies _external;

  FantasyRepoGitImpl(this.repoSettings, this._repoRootPath,
      {FantasyRepoDependencies fantasyRepoDependencies})
      : name = repoSettings.name,
        _external = fantasyRepoDependencies ??
            FantasyRepoDependencies(name: repoSettings.name);

  bool _isInitialized = false;

  /// Call exactly once per [FantasyRepoGitImpl].
  ///
  /// May throw [FantasyRepoException] in the event of problems and does
  /// not clean up filesystem state.
  Future<void> init([bool allowUpdate = true]) async {
    assert(_isInitialized == false);
    if (repoRoot.exists && allowUpdate) {
      await _update(_external.launcher);
      // TODO(jcollins-g): handle "update" of pinned revision edge case
    } else if (!repoRoot.exists) {
      await _clone(_external.launcher);
    }
    _isInitialized = true;
    return;
  }

  /// Configure a git repository locally and initialize it.
  ///
  /// Throws [FantasyRepoCloneException] in the event we can not finish
  /// initializing.
  Future<void> _clone(SubprocessLauncher launcher) async {
    assert(_isInitialized == false);
    repoRoot.parent.create();
    await launcher.runStreamed('git', ['init', repoRoot.path]);
    await launcher.runStreamed(
        'git',
        [
          'remote',
          'add',
          'origin',
          '-t',
          repoSettings.branch,
          repoSettings.clone
        ],
        workingDirectory: repoRoot.path);

    String cloneHttp =
        repoSettings.clone.replaceFirst('$githubHost:', '$_httpGithub/');
    await launcher.runStreamed('git',
        ['remote', 'add', 'originHTTP', '-t', repoSettings.branch, cloneHttp],
        workingDirectory: repoRoot.path);

    // Do not get the working directory wrong on this command or it could
    // alter a user's repository config based on the CWD, which is bad.  Other
    // commands in [FantasyRepo] will not fail silently with permanent,
    // confusing results, but this one can.
    await launcher.runStreamed('git', ['config', 'core.sparsecheckout', 'true'],
        workingDirectory: repoRoot.path);

    File sparseCheckout = _external.resourceProvider.getFile(_external
        .resourceProvider.pathContext
        .join(repoRoot.path, '.git', 'info', 'sparse-checkout'));
    sparseCheckout.writeAsStringSync([
      '**\n',
      '!**/.packages\n',
      '!**/pubspec.lock\n',
      '!**/.dart_tool/package_config.json\n'
    ].join());
    List<String> args = ['pull'];
    if (repoSettings.revision == 'master') {
      args.add('--depth=1');
    }
    args.addAll(['--rebase', 'originHTTP', repoSettings.revision]);
    await launcher.runStreamed('git', args,
        workingDirectory: repoRoot.path, retries: 5);
  }

  Future<void> _update(SubprocessLauncher launcher) async {
    assert(_isInitialized == false);
    try {
      await launcher.runStreamed(
          'git', ['pull', '--rebase', 'originHTTP', repoSettings.revision],
          workingDirectory: repoRoot.path, retries: 5);
    } catch (e) {
      if (e is ProcessException) {
        throw FantasyRepoUpdateException(
            'Unable to update clone for: $repoSettings');
      }
      rethrow;
    }
  }
}
