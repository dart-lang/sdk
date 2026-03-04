// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that creates a new git working tree for an already
/// cloned local repo, checked out at a specific [ref] (commit sha, tag, or
/// branch name).
class GitWorktreeProjectGenerator implements ProjectGenerator {
  /// The Directory containing the local git repo.
  final Directory originalRepo;

  /// The ref (commit sha, tag, or branch) to check out into a new working tree.
  final String ref;

  /// Whether or not this is an SDK repo. If it is, we use gclient and set things
  /// up a bit differently.
  final bool isSdkRepo;

  /// Relative paths to the sub-directories of the repo that should be open in
  /// this workspace.
  final Iterable<String>? openSubdirs;

  GitWorktreeProjectGenerator(
    this.originalRepo,
    this.ref, {
    this.isSdkRepo = false,
    this.openSubdirs,
  });

  @override
  String get description =>
      'Creating git worktree for "${originalRepo.path}" at ref "$ref"';

  @override
  Future<Workspace> setUp() async {
    var tmpDir = await Directory.systemTemp.createTemp('as_git_worktree');
    var projectDir = isSdkRepo ? Directory(p.join(tmpDir.path, 'sdk')) : tmpDir;
    await runGitCommand([
      'worktree',
      'add',
      '-d',
      projectDir.path,
      ref,
    ], originalRepo);
    if (isSdkRepo) {
      await _setUpSdk(projectDir);
    }
    return Workspace(
      contextRoots: await getContextRoots(projectDir.path, isSdk: isSdkRepo),
      workspaceDirectories: [
        if (openSubdirs case var openSubdirs?) ...[
          for (var subdir in openSubdirs)
            Directory(p.join(projectDir.path, subdir)),
        ] else
          projectDir,
      ],
      rootDirectories: [tmpDir],
    );
  }

  @override
  Future<void> tearDown(Workspace workspace) async {
    var rootDir = workspace.rootDirectories.single;
    await runGitCommand([
      'worktree',
      'remove',
      '-f',
      isSdkRepo ? p.join(rootDir.path, 'sdk') : rootDir.path,
    ], originalRepo);
    if (rootDir.existsSync()) {
      await rootDir.delete(recursive: true);
    }
  }

  Future<void> _setUpSdk(Directory projectDir) async {
    print('Running gclient sync in ${projectDir.path}');
    var newGclientDir = p.dirname(projectDir.path);
    var oldGclientDir = p.dirname(p.normalize(originalRepo.path));
    for (var file in ['.gclient', '.gclient_entries']) {
      await File(p.join(oldGclientDir, file)).copy(p.join(newGclientDir, file));
    }

    var gclientSyncResult = await Process.run('gclient', [
      'sync',
    ], workingDirectory: projectDir.path);
    if (gclientSyncResult.exitCode != 0) {
      throw StateError(
        'Failed to run `gclient sync`:\n'
        'StdOut:\n${gclientSyncResult.stdout}\n'
        'StdErr:\n${gclientSyncResult.stderr}',
      );
    }
  }
}
