// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper functionality for invoking Git.
 */
library git;

import 'io.dart';
import 'utils.dart';

/// Tests whether or not the git command-line app is available for use.
Future<bool> get isInstalled {
  if (_isGitInstalledCache != null) {
    // TODO(rnystrom): The sleep is to pump the message queue. Can use
    // Future.immediate() when #3356 is fixed.
    return sleep(0).transform((_) => _isGitInstalledCache);
  }

  return _gitCommand.transform((git) => git != null);
}

/// Run a git process with [args] from [workingDir]. Returns the stdout as a
/// list of strings if it succeeded. Completes to an exception if it failed.
Future<List<String>> run(List<String> args, [String workingDir]) {
  return _gitCommand.chain((git) {
    return runProcess(git, args, workingDir: workingDir);
  }).transform((result) {
    if (!result.success) throw new Exception(
        'Git error. Command: git ${Strings.join(args, " ")}\n'
        '${Strings.join(result.stderr, "\n")}');

    return result.stdout;
  });
}

bool _isGitInstalledCache;

/// The cached Git command.
String _gitCommandCache;

/// Returns the name of the git command-line app, or null if Git could not be
/// found on the user's PATH.
Future<String> get _gitCommand {
  // TODO(nweiz): Just use Future.immediate once issue 3356 is fixed.
  if (_gitCommandCache != null) {
    return sleep(0).transform((_) => _gitCommandCache);
  }

  return _tryGitCommand("git").chain((success) {
    if (success) return new Future.immediate("git");

    // Git is sometimes installed on Windows as `git.cmd`
    return _tryGitCommand("git.cmd").transform((success) {
      if (success) return "git.cmd";
      return null;
    });
  }).transform((command) {
    _gitCommandCache = command;
    return command;
  });
}

/// Checks whether [command] is the Git command for this computer.
Future<bool> _tryGitCommand(String command) {
  var completer = new Completer<bool>();

  // If "git --version" prints something familiar, git is working.
  var future = runProcess(command, ["--version"]);

  future.then((results) {
    var regex = new RegExp("^git version");
    completer.complete(results.stdout.length == 1 &&
                       regex.hasMatch(results.stdout[0]));
  });

  future.handleException((err) {
    // If the process failed, they probably don't have it.
    completer.complete(false);
    return true;
  });

  return completer.future;
}