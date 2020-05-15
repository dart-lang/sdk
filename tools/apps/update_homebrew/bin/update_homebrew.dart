// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:update_homebrew/update_homebrew.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('dry-run', abbr: 'n')
    ..addOption('revision', abbr: 'r')
    ..addOption('channel', abbr: 'c', allowed: supportedChannels)
    ..addOption('key', abbr: 'k');
  final options = parser.parse(args);
  final dryRun = options['dry-run'] as bool;
  final revision = options['revision'] as String;
  final channel = options['channel'] as String;
  if ([revision, channel].contains(null)) {
    print(
        "Usage: update_homebrew.dart -r version -c channel [-k ssh_key] [-n]\n"
        "  ssh_key should allow pushes to $githubRepo on github");
    exitCode = 1;
    return;
  }

  Map<String, String> gitEnvironment;

  final key = options['key'] as String;
  if (key != null) {
    final sshWrapper = Platform.script.resolve('ssh_with_key').toFilePath();
    gitEnvironment = {'GIT_SSH': sshWrapper, 'SSH_KEY_PATH': key};
  }

  await Chain.capture(() async {
    var tempDir = await Directory.systemTemp.createTemp('update_homebrew');

    try {
      var repository = tempDir.path;

      await runGit(['clone', 'git@github.com:$githubRepo.git', '.'], repository,
          gitEnvironment);
      await writeHomebrewInfo(channel, revision, repository);
      await runGit([
        'commit',
        '-a',
        '-m',
        'Updated $channel branch to revision $revision'
      ], repository, gitEnvironment);
      if (dryRun) {
        await runGit(['diff', 'origin/master'], repository, gitEnvironment);
      } else {
        await runGit(['push'], repository, gitEnvironment);
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  }, onError: (error, chain) {
    print(error);
    print(chain.terse);
    exitCode = 1;
  });
}
