#!tools/sdks/dart-sdk/bin/dart
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helps rolling dependency to the newest version available
/// (or a target version).
///
/// Usage: ./tools/manage_deps.dart bump <dependency> [--branch <branch>] [--target <ref>]
///
/// This will:
/// 0. Check that git is clean
/// 1. Create branch `<branch> ?? bump_<dependency>`
/// 2. Update `DEPS` for `<dependency>`
/// 3. Create a commit with `git log` of imported commits in the message.
/// 4. Prompt to create a CL

// @dart = 2.13
library bump;

import 'dart:io';
import 'package:args/command_runner.dart';

import 'package:path/path.dart' as p;

class BumpCommand extends Command<int> {
  @override
  String get description => '''
Bump a dependency in DEPS and create a CL

This will:
0. Check that git is clean
1. Create branch `<branch> ?? bump_<dependency>`
2. Update `DEPS` for `<dependency>`
3. Create a commit with `git log` of imported commits in the message.
4. Prompt to create a CL
''';

  String get invocation =>
      './tools/manage_deps.dart bump <path/to/dependency> <options>';

  BumpCommand() {
    argParser.addOption(
      'branch',
      help: 'The name of the branch where the update is created.',
      valueHelp: 'branch-name',
    );
    argParser.addOption(
      'target',
      help: 'The git ref to update to.',
      valueHelp: 'ref',
    );
  }

  @override
  String get name => 'bump';

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    if (argResults.rest.length != 1) {
      usageException('No dependency directory given');
    }
    final status = runProcessForLines(['git', 'status', '--porcelain'],
        explanation: 'Checking if your git checkout is clean');
    if (status.isNotEmpty) {
      print('Note your git checkout is dirty!');
    }

    final pkgDir = argResults.rest.first;
    if (!Directory(pkgDir).existsSync()) {
      usageException('No directory $pkgDir');
    }
    final toUpdate = p.split(pkgDir).last;
    final branchName = argResults['branch'] ?? 'bump_$toUpdate';

    final exists = runProcessForExitCode(
        ['git', 'rev-parse', '--verify', branchName],
        explanation: 'Checking if branch-name exists');
    if (exists == 0) {
      print('Branch $branchName already exist - delete it?');
      if (!prompt()) {
        print('Ok - exiting');
        exit(-1);
      }
      runProcessAssumingSuccess(
        ['git', 'branch', '-D', branchName],
        explanation: 'Deleting existing branch',
      );
    }
    runProcessAssumingSuccess(
      ['git', 'checkout', '-b', branchName],
      explanation: 'Creating branch',
    );

    final currentRev = runProcessForLines(
      ['gclient', 'getdep', '-r', p.join('sdk', pkgDir)],
      explanation: 'Finding current revision',
    ).first;

    final originUrl = runProcessForLines(
      ['git', 'config', '--get', 'remote.origin.url'],
      workingDirectory: pkgDir,
      explanation: 'Finding origin url',
    ).first;

    runProcessAssumingSuccess(
      ['git', 'fetch', 'origin'],
      workingDirectory: pkgDir,
      explanation: 'Retrieving updates to $toUpdate',
    );

    final gitRevParseResult = runProcessForLines([
      'git',
      'rev-parse',
      if (argResults.wasParsed('target'))
        argResults['target']
      else
        'origin/HEAD',
    ], workingDirectory: pkgDir, explanation: 'Finding sha-id');

    final target = gitRevParseResult.first;
    if (currentRev == target) {
      print('Already at $target - nothing to do');
      return -1;
    }
    runProcessAssumingSuccess(
      ['gclient', 'setdep', '-r', '${p.join('sdk', pkgDir)}@$target'],
      explanation: 'Updating $toUpdate',
    );
    runProcessAssumingSuccess(
      ['gclient', 'sync', '-D'],
      explanation: 'Syncing your deps',
    );
    runProcessAssumingSuccess(
      [
        Platform.resolvedExecutable,
        'tools/generate_package_config.dart',
      ],
      explanation: 'Updating package config',
    );
    final gitLogResult = runProcessForLines([
      'git',
      'log',
      '--format=%C(auto) $originUrl/+/%h %s ',
      '$currentRev..$target',
    ], workingDirectory: pkgDir, explanation: 'Listing new commits');
    final commitMessage = '''
Bump $toUpdate to $target

Changes:
```
> git log --format="%C(auto) %h %s" ${currentRev.substring(0, 7)}..${target.substring(0, 7)}
${gitLogResult.join('\n')}
```
Diff: $originUrl/+/$currentRev~..$target/
''';
    runProcessAssumingSuccess(['git', 'commit', '-am', commitMessage],
        explanation: 'Committing');
    print('Consider updating CHANGELOG.md');
    print('Do you want to create a CL?');
    if (prompt()) {
      await runProcessInteractively(
        ['git', 'cl', 'upload', '-m', commitMessage],
        explanation: 'Creating CL',
      );
    }
    return 0;
  }
}

Future<void> main(List<String> args) async {
  final runner = CommandRunner<int>(
      'manage_deps.dart', 'helps managing the DEPS file',
      usageLineLength: 80)
    ..addCommand(BumpCommand());
  try {
    exit(await runner.run(args) ?? -1);
  } on UsageException catch (e) {
    print(e.message);
    print(e.usage);
  }
}

bool prompt() {
  stdout.write('(y/N):');
  final answer = stdin.readLineSync() ?? '';
  return answer.trim().toLowerCase() == 'y';
}

void printRunningLine(
    List<String> cmd, String? explanation, String? workingDirectory) {
  stdout.write(
      "${explanation ?? 'Running'}: `${cmd.join(' ')}` ${workingDirectory == null ? '' : 'in $workingDirectory'}");
}

void printSuccessTrailer(ProcessResult result, String? onFailure) {
  if (result.exitCode == 0) {
    stdout.writeln(' ✓');
  } else {
    stdout.writeln(' X');
    stderr.write(result.stdout);
    stderr.write(result.stderr);
    if (onFailure != null) {
      print(onFailure);
    }
    throw Exception();
  }
}

void runProcessAssumingSuccess(List<String> cmd,
    {String? explanation,
    String? workingDirectory,
    Map<String, String> environment = const {},
    String? onFailure}) {
  printRunningLine(cmd, explanation, workingDirectory);
  final result = Process.runSync(
    cmd[0],
    cmd.skip(1).toList(),
    workingDirectory: workingDirectory,
    environment: environment,
  );
  printSuccessTrailer(result, onFailure);
}

List<String> runProcessForLines(List<String> cmd,
    {String? explanation, String? workingDirectory, String? onFailure}) {
  printRunningLine(cmd, explanation, workingDirectory);
  final result = Process.runSync(
    cmd[0],
    cmd.skip(1).toList(),
    workingDirectory: workingDirectory,
  );
  printSuccessTrailer(result, onFailure);
  final output = (result.stdout as String);
  return output == '' ? <String>[] : output.split('\n');
}

Future<void> runProcessInteractively(List<String> cmd,
    {String? explanation, String? workingDirectory}) async {
  printRunningLine(cmd, explanation, workingDirectory);
  stdout.writeln('');
  final process = await Process.start(cmd[0], cmd.skip(1).toList(),
      workingDirectory: workingDirectory, mode: ProcessStartMode.inheritStdio);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception();
  }
}

int runProcessForExitCode(List<String> cmd,
    {String? explanation, String? workingDirectory}) {
  printRunningLine(cmd, explanation, workingDirectory);
  final result = Process.runSync(
    cmd[0],
    cmd.skip(1).toList(),
    workingDirectory: workingDirectory,
  );
  stdout.writeln(' => ${result.exitCode}');
  return result.exitCode;
}
