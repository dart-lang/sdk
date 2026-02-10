// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../utilities/git.dart';
import 'project_generator.dart';

/// A [ProjectGenerator] that clones a git [repo] and checks out a specific
/// [ref] (commit sha, tag, or branch name).
class GitCloneProjectGenerator implements ProjectGenerator {
  /// The URI of the git repo to clone.
  final String repo;

  /// The ref (commit sha, tag, or branch) to check out.
  final String ref;

  /// Relative paths to the sub-directories of the repo to open in the
  /// workspace.
  final Iterable<String>? openSubdirs;

  GitCloneProjectGenerator(this.repo, this.ref, {this.openSubdirs});

  @override
  String get description => 'Cloning git repo "$repo" at ref "$ref"';

  @override
  Future<Workspace> setUp() async {
    var outputDir = await Directory.systemTemp.createTemp('as_git_clone');
    await runGitCommand(['clone', repo, '.'], outputDir);
    await runGitCommand(['fetch', 'origin', ref], outputDir);
    await runGitCommand(['checkout', ref], outputDir);
    var workspaceDirectories = <Directory>[];
    var contextRoots = <ContextRoot>[];
    if (openSubdirs != null) {
      for (var subdir in openSubdirs!) {
        var dir = Directory(p.join(outputDir.path, subdir));
        workspaceDirectories.add(dir);
        contextRoots.addAll(await getContextRoots(dir.path));
      }
    } else {
      workspaceDirectories.add(outputDir);
      contextRoots.addAll(await getContextRoots(outputDir.path));
    }
    return Workspace(
      contextRoots: contextRoots,
      workspaceDirectories: workspaceDirectories,
    );
  }

  @override
  Future<void> tearDown(Workspace workspace) async {
    await Future.wait(
      workspace.rootDirectories.map((dir) => dir.delete(recursive: true)),
    );
  }
}
