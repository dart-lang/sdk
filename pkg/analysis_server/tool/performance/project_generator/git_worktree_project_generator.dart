// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

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

  /// The root temp dir to clean up, if it isn't the same as the project dir.
  Directory? tmpDir;

  GitWorktreeProjectGenerator(
    this.originalRepo,
    this.ref, {
    this.isSdkRepo = false,
  });

  @override
  String get description =>
      'Creating git worktree for "${originalRepo.path}" at ref "$ref"';

  @override
  Future<Iterable<Directory>> setUp() async {
    var projectDir = await Directory.systemTemp.createTemp('as_git_worktree');
    if (isSdkRepo) {
      if (tmpDir != null) {
        throw StateError(
          'Project already set up, must wait for tearDown to complete to call '
          'setUp again',
        );
      }
      tmpDir = projectDir;
      projectDir = Directory(p.join(projectDir.path, 'sdk'));
    }
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
    return [projectDir];
  }

  @override
  Future<void> tearDown(Iterable<Directory> workspaceDirs) async {
    if (workspaceDirs.length != 1) {
      throw StateError('Expected exactly one workspace directory');
    }
    await runGitCommand([
      'worktree',
      'remove',
      '-f',
      workspaceDirs.single.path,
    ], originalRepo);
    await tmpDir?.delete(recursive: true);
    tmpDir = null;
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
