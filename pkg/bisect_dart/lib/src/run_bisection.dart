// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cli_config/cli_config.dart';
import 'package:logging/logging.dart';

import 'bisection_config.dart';
import 'run_process.dart';

Future<void> runMain(List<String> args) async {
  if (args.contains('--help')) {
    print(BisectionConfig.helpMessage());
    return;
  }
  final config = BisectionConfig.fromConfig(await Config.fromArgs(args: args));
  await runBisection(config);
}

Future<void> runBisection(BisectionConfig config) async {
  final name = config.name;
  final startHash = config.start;
  final endHash = config.end;
  final testCommands = config.testCommands;
  final failurePattern = config.failurePattern;
  final sdkCheckout = config.sdkPath;

  final logsDir =
      Directory.current.uri.resolve('.dart_tool/bisect_dart/$name/logs/');
  await Directory.fromUri(logsDir).create(recursive: true);
  final logFileUri = logsDir.resolve('full.txt');
  final logFile = File.fromUri(logFileUri);
  if (await logFile.exists()) {
    await logFile.delete();
  }
  final logger = _mainLogger('', logFileUri);
  logger.info('Writing detailed log to ${logFileUri.toFilePath()}.');
  logger.config('Bisection configuration: $config.');

  await _ensureSdkRepo(sdkCheckout, logger);

  logger.info('Ensuring failure reproduces on $startHash.');
  final shouldFail = await _checkCommit(
      startHash, testCommands, failurePattern, sdkCheckout, logger);
  if (!shouldFail) {
    throw Exception('$startHash failed to reproduce the error.');
  }

  final hashBeforeRange = await _commitHashBefore(endHash, sdkCheckout, logger);
  logger.info('Ensuring failure does not reproduce on $hashBeforeRange.');
  final shouldSucceed = await _checkCommit(
      hashBeforeRange, testCommands, failurePattern, sdkCheckout, logger);
  if (shouldSucceed) {
    throw Exception('$startHash failed to reproduced the error.');
  }

  final commitHashes =
      await _commitHashesInRange(startHash, endHash, sdkCheckout, logger);
  final regressionCommit = await _bisect(
      commitHashes, testCommands, failurePattern, sdkCheckout, logger);
  logger.info('Bisected to $regressionCommit.');
}

Future<String> _bisect(
  List<String> commitHashes,
  List<String> testCommands,
  Pattern failurePattern,
  Uri sdkCheckout,
  Logger logger,
) async {
  if (commitHashes.length == 1) {
    return commitHashes.single;
  }
  final numCommits = commitHashes.length;
  final pivotIndex = numCommits ~/ 2;
  final pivot = commitHashes[pivotIndex];
  logger.info(
    'Bisecting ${commitHashes.first}...${commitHashes.last} '
    '($numCommits commits). Trying $pivot.',
  );
  final commitResult = await _checkCommit(
    pivot,
    testCommands,
    failurePattern,
    sdkCheckout,
    logger,
  );
  List<String> remainingCommits;
  if (commitResult) {
    // Reproduces on pivot, so it must be in the older half of commits.
    remainingCommits = commitHashes.skip(pivotIndex).toList();
  } else {
    remainingCommits = commitHashes.take(pivotIndex).toList();
  }
  return await _bisect(
      remainingCommits, testCommands, failurePattern, sdkCheckout, logger);
}

/// Returns true if the commit has the [failurePattern].
Future<bool> _checkCommit(String hash, List<String> testCommands,
    Pattern failurePattern, Uri sdkCheckout, Logger logger) async {
  logger.config('Testing $hash.');
  await _gitCheckout(hash, sdkCheckout, logger);
  await _gclientSync(sdkCheckout, logger);
  final testOutput = await _runTest(testCommands, sdkCheckout, logger);
  final matches = failurePattern.allMatches(testOutput).toList();
  final foundFailure = matches.isNotEmpty;
  if (foundFailure) {
    logger.info('Commit $hash, reproduces failure.');
  } else {
    logger.info('Commit $hash, does not reproduce failure.');
  }
  return foundFailure;
}

Future<void> _ensureSdkRepo(Uri sdkCheckout, Logger logger) async {
  logger.info('Ensuring SDK repo in ${sdkCheckout.toFilePath()}.');
  final workDir = Directory.fromUri(sdkCheckout).parent;
  if (!await workDir.exists()) {
    await workDir.create(recursive: true);
    await runProcess(
      executable: Uri.file('fetch'),
      arguments: ['dart'],
      logger: logger,
      workingDirectory: workDir.uri,
    );
  } else {
    await runProcess(
      executable: Uri.file('git'),
      arguments: ['stash', '--include-untracked'],
      logger: logger,
      workingDirectory: sdkCheckout,
    );
    await runProcess(
      executable: Uri.file('git'),
      arguments: ['fetch'],
      logger: logger,
      workingDirectory: sdkCheckout,
    );
  }
}

Future<void> _gitCheckout(String hash, Uri sdkCheckout, Logger logger) {
  return runProcess(
    executable: Uri.file('git'),
    arguments: ['checkout', hash],
    logger: logger,
    workingDirectory: sdkCheckout,
  );
}

Future<void> _gclientSync(Uri sdkCheckout, Logger logger) {
  return runProcess(
    executable: Uri.file('gclient'),
    arguments: ['sync', '-D'],
    logger: logger,
    workingDirectory: sdkCheckout,
  );
}

Future<String> _runTest(
    List<String> testCommands, Uri sdkCheckout, Logger logger) async {
  var output = '';
  for (final command in testCommands) {
    final commandSplit = command.split(' ');
    final result = await runProcess(
      executable: Uri.file(commandSplit.first),
      arguments: commandSplit.sublist(1),
      logger: logger,
      workingDirectory: sdkCheckout,
      captureOutput: true,
    );
    output += result.stdout;
    output += result.stderr;
  }
  return output;
}

/// Ordered from now to old.
Future<List<String>> _commitHashesInRange(String commitHashStart,
    String commitHashEnd, Uri sdkCheckout, Logger logger) async {
  final result = await runProcess(
    executable: Uri.file('git'),
    arguments: [
      'log',
      '--pretty=format:"%h"',
      '$commitHashEnd...$commitHashStart',
    ],
    captureOutput: true,
    logger: logger,
    workingDirectory: sdkCheckout,
  );
  return result.stdout.trim().replaceAll('"', '').split('\n');
}

Future<String> _commitHashBefore(
    String commitHash, Uri sdkCheckout, Logger logger) async {
  final result = await runProcess(
    executable: Uri.file('git'),
    arguments: [
      'log',
      '--pretty=format:"%h"',
      '$commitHash~1...$commitHash~2',
    ],
    captureOutput: true,
    logger: logger,
    workingDirectory: sdkCheckout,
  );
  return result.stdout.trim().replaceAll('"', '');
}

Logger _mainLogger(String name, Uri filePath) {
  final file = File.fromUri(filePath);
  return Logger('')
    ..level = Level.ALL
    ..onRecord.listen((record) {
      if (record.level >= Level.INFO) {
        print(record.message);
      }
      file.writeAsStringSync(
        '${record.message}\n',
        mode: FileMode.append,
      );
    });
}
