// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.git;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/descriptor.dart';

import '../../lib/src/git.dart' as git;

/// Describes a Git repository and its contents.
class GitRepoDescriptor extends DirectoryDescriptor {
  GitRepoDescriptor(String name, List<Descriptor> contents)
      : super(name, contents);

  /// Creates the Git repository and commits the contents.
  Future create([String parent]) => schedule(() {
    return super.create(parent).then((_) {
      return _runGitCommands(
          parent,
          [['init'], ['add', '.'], ['commit', '-m', 'initial commit']]);
    });
  }, 'creating Git repo:\n${describe()}');

  /// Writes this descriptor to the filesystem, than commits any changes from
  /// the previous structure to the Git repo.
  ///
  /// [parent] defaults to [defaultRoot].
  Future commit([String parent]) => schedule(() {
    return super.create(parent).then((_) {
      return _runGitCommands(
          parent,
          [['add', '.'], ['commit', '-m', 'update']]);
    });
  }, 'committing Git repo:\n${describe()}');

  /// Return a Future that completes to the commit in the git repository
  /// referred to by [ref] at the current point in the scheduled test run.
  ///
  /// [parent] defaults to [defaultRoot].
  Future<String> revParse(String ref, [String parent]) => schedule(() {
    return _runGit(['rev-parse', ref], parent).then((output) => output[0]);
  }, 'parsing revision $ref for Git repo:\n${describe()}');

  /// Schedule a Git command to run in this repository.
  ///
  /// [parent] defaults to [defaultRoot].
  Future runGit(List<String> args, [String parent]) => schedule(() {
    return _runGit(args, parent);
  }, "running 'git ${args.join(' ')}' in Git repo:\n${describe()}");

  Future _runGitCommands(String parent, List<List<String>> commands) =>
      Future.forEach(commands, (command) => _runGit(command, parent));

  Future<List<String>> _runGit(List<String> args, String parent) {
    // Explicitly specify the committer information. Git needs this to commit
    // and we don't want to rely on the buildbots having this already set up.
    var environment = {
      'GIT_AUTHOR_NAME': 'Pub Test',
      'GIT_AUTHOR_EMAIL': 'pub@dartlang.org',
      'GIT_COMMITTER_NAME': 'Pub Test',
      'GIT_COMMITTER_EMAIL': 'pub@dartlang.org'
    };

    if (parent == null) parent = defaultRoot;
    return git.run(
        args,
        workingDir: path.join(parent, name),
        environment: environment);
  }
}

