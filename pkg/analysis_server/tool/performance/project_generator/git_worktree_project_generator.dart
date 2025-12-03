// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that creates a new git working tree for an already
/// cloned local repo, checked out at a specific [ref] (commit sha, tag, or branch name).
class GitWorktreeProjectGenerator implements ProjectGenerator {
  /// The Directory containing the local git repo.
  final Directory originalRepo;

  /// The ref (commit sha, tag, or branch) to check out into a new working tree.
  final String ref;

  GitWorktreeProjectGenerator(this.originalRepo, this.ref);

  @override
  String get description =>
      'Creating git worktree for "${originalRepo.path}" at ref "$ref"';

  @override
  Future<Iterable<Directory>> setUp() async {
    var projectDir = await Directory.systemTemp.createTemp('as_git_worktree');
    await runGitCommand([
      'worktree',
      'add',
      '-d',
      projectDir.path,
    ], originalRepo);
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
  }
}
