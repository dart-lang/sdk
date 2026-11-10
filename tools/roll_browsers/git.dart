// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'process.dart';

/// The upstream ref that rolls are computed against and uploaded on top of.
const _upstreamRef = 'origin/main';

/// Git operations on an SDK checkout.
final class GitCheckout {
  final String root;

  GitCheckout(this.root);

  /// Updates [_upstreamRef] from the remote.
  Future<void> fetchUpstream() => _git(['fetch', '--quiet', 'origin', 'main']);

  /// Returns the contents of `DEPS` at [_upstreamRef].
  Future<String> readUpstreamDeps() => _git(['show', '$_upstreamRef:DEPS']);

  /// Returns how long ago the DEPS variable [name] was last changed on
  /// [_upstreamRef].
  Future<Duration> depsVarAge(String name) async {
    final pattern = '"$name":';
    final date = await _git([
      'log',
      '-1',
      '--format=%cI',
      '-G',
      pattern,
      _upstreamRef,
      '--',
      'DEPS',
    ]);
    if (date.trim().isEmpty) {
      throw StateError('No commit on $_upstreamRef changes $pattern in DEPS.');
    }
    return DateTime.now().difference(DateTime.parse(date.trim()));
  }

  /// Commits [depsContents] to `DEPS` with [commitMessage] on a temporary
  /// branch off [_upstreamRef], and runs [action] in a temporary worktree
  /// with that branch checked out.
  ///
  /// The worktree is created under the system temp directory and removed
  /// along with the branch afterwards, so this checkout's working tree and
  /// current branch are never touched.
  Future<T> withTemporaryDepsCommit<T>({
    required String depsContents,
    required String commitMessage,
    required Future<T> Function(GitCheckout worktree) action,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync('roll_browsers.');
    final worktree = GitCheckout(p.join(tempDir.path, 'sdk'));
    final branch = 'roll-browsers-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await _git([
        'worktree',
        'add',
        '--quiet',
        '--track',
        '-b',
        branch,
        worktree.root,
        _upstreamRef,
      ]);
      File(p.join(worktree.root, 'DEPS')).writeAsStringSync(depsContents);
      await worktree._git([
        'commit',
        '--quiet',
        '--all',
        '--message',
        commitMessage,
      ]);
      return await action(worktree);
    } finally {
      await _removeWorktree(worktree.root, branch);
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    }
  }

  /// Removes the worktree at [path] and deletes [branch], ignoring failures
  /// so cleanup never hides the original error.
  Future<void> _removeWorktree(String path, String branch) async {
    for (final arguments in [
      ['worktree', 'remove', '--force', path],
      ['worktree', 'prune'],
      ['branch', '--quiet', '-D', branch],
    ]) {
      await runProcess('git', arguments, workingDirectory: root);
    }
  }

  /// Runs `git cl` with [arguments] and returns its stdout.
  Future<String> cl(List<String> arguments) =>
      runChecked('git', ['cl', ...arguments], workingDirectory: root);

  Future<String> _git(List<String> arguments) =>
      runChecked('git', arguments, workingDirectory: root);
}
