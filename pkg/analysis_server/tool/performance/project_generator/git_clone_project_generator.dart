// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that clones a git [repo] and checks out a specific
/// [ref] (commit sha, tag, or branch name).
class GitCloneProjectGenerator implements ProjectGenerator {
  /// The URI of the git repo to clone.
  final String repo;

  /// The ref (commit sha, tag, or branch) to check out.
  final String ref;

  GitCloneProjectGenerator(this.repo, this.ref);

  @override
  String get description => 'Cloning git repo "$repo" at ref "$ref"';

  @override
  Future<Iterable<Directory>> setUp() async {
    var outputDir = await Directory.systemTemp.createTemp('as_git_clone');
    await runGitCommand(['clone', repo, '.'], outputDir);
    await runGitCommand(['fetch', 'origin', ref], outputDir);
    await runGitCommand(['checkout', ref], outputDir);
    await runPubGet(outputDir);
    return [outputDir];
  }

  @override
  Future<void> tearDown(Iterable<Directory> workspaceDirs) async {
    await Future.wait(workspaceDirs.map((dir) => dir.delete(recursive: true)));
  }
}
