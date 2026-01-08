// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that creates a new git working tree for an already
/// cloned local repo, checked out at a specific [ref] (commit sha, tag, or branch name).
class GitWorktreeProjectGenerator implements ProjectGenerator {
  /// The Directory containing the local git repo.
  final Directory originalRepo;

  /// The ref (commit sha, tag, or branch) to check out into a new working tree.
  final String ref;

  /// Whether or not this is an SDK repo. If it is, we use gclient and set things
  /// up a bit differently.
  final bool isSdkRepo;

  GitWorktreeProjectGenerator(
    this.originalRepo,
    this.ref, {
    this.isSdkRepo = false,
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
    ], originalRepo);
    if (isSdkRepo) {
      await _setUpSdk(projectDir);
    } else {
      await runPubGet(projectDir);
    }
    return Workspace(
      [ContextRoot(projectDir, (await findPackageConfig(projectDir))!)],
      [tmpDir],
    );
  }

  @override
  Future<void> tearDown(Workspace workspace) async {
    for (var contextRoot in workspace.contextRoots) {
      await runGitCommand([
        'worktree',
        'remove',
        '-f',
        contextRoot.dir.path,
      ], originalRepo);
    }
    for (var rootDir in workspace.rootDirectories) {
      if (rootDir.existsSync()) {
        await workspace.rootDirectories.single.delete(recursive: true);
      }
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
