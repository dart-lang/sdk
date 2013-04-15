// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functionality for invoking Git.
library git;

import 'dart:async';
import 'io.dart';
import 'log.dart' as log;
import 'utils.dart';

/// Tests whether or not the git command-line app is available for use.
Future<bool> get isInstalled {
  if (_isGitInstalledCache != null) {
    return new Future.value(_isGitInstalledCache);
  }

  return _gitCommand.then((git) => git != null);
}

/// Run a git process with [args] from [workingDir]. Returns the stdout as a
/// list of strings if it succeeded. Completes to an exception if it failed.
Future<List<String>> run(List<String> args,
    {String workingDir, Map<String, String> environment}) {
  return _gitCommand.then((git) {
    return runProcess(git, args, workingDir: workingDir,
        environment: environment);
  }).then((result) {
    if (!result.success) throw new Exception(
        'Git error. Command: git ${args.join(" ")}\n'
        '${result.stderr.join("\n")}');

    return result.stdout;
  });
}

bool _isGitInstalledCache;

/// The cached Git command.
String _gitCommandCache;

/// Returns the name of the git command-line app, or null if Git could not be
/// found on the user's PATH.
Future<String> get _gitCommand {
  if (_gitCommandCache != null) {
    return new Future.value(_gitCommandCache);
  }

  return _tryGitCommand("git").then((success) {
    if (success) return "git";

    // Git is sometimes installed on Windows as `git.cmd`
    return _tryGitCommand("git.cmd").then((success) {
      if (success) return "git.cmd";
      return null;
    });
  }).then((command) {
    log.fine('Determined git command $command.');
    _gitCommandCache = command;
    return command;
  });
}

/// Checks whether [command] is the Git command for this computer.
Future<bool> _tryGitCommand(String command) {
  // If "git --version" prints something familiar, git is working.
  return runProcess(command, ["--version"]).then((results) {
    var regexp = new RegExp("^git version");
    return results.stdout.length == 1 && regexp.hasMatch(results.stdout[0]);
  }).catchError((err) {
    // If the process failed, they probably don't have it.
    return false;
  });
}
