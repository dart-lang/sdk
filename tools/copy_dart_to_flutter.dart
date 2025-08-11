// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script builds a local Dart SDK and copies the contents to the cache of
// a local Flutter SDK. This script is helpful for testing local SDK changes,
// such as Dart Analysis Server changes for example, against a Flutter project.
//
// Note: this script will not be sufficient if the local Dart SDK changes also
// need to be included in the build of the Flutter enginge. There are no
// guarantees you will be able to run a Flutter app with these changes applied.
// This script is mainly useful for testing static features, like static
// analysis.
//
// For ease of use, consider setting the LOCAL_DART_SDK and LOCAL_FLUTTER_SDK
// environment variables. Otherwise, you will need to specify these paths via
// the -d and -f options when running this script. You can add the following to
// your .bash_profile or .zshrc file to set the environment variables:
//
// export LOCAL_DART_SDK='/Users/me/path/to/dart-sdk/sdk'
// export LOCAL_FLUTTER_SDK='/Users/me/path/to/flutter'

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const _architecture = 'arch';
const _buildSdk = 'build-sdk';
const _help = 'help';
const _localDart = 'local-dart';
const _localFlutter = 'local-flutter';
const _reset = 'reset';
const _verbose = 'verbose';

final _parser = ArgParser()
  ..addOption(
    _architecture,
    abbr: 'a',
    help: 'Specify your machine\'s architecture.',
    allowed: ['ARM64', 'X64'],
    defaultsTo: 'ARM64',
  )
  ..addFlag(
    _buildSdk,
    negatable: true,
    defaultsTo: true,
    help: 'Whether to build the Dart SDK as part of running this script. '
        'Negate with --no-$_buildSdk if you have already built the Dart '
        'SDK locally and want to skip this step.',
  )
  ..addOption(
    _localDart,
    abbr: 'd',
    help: 'Path to your local Dart SDK directory. If unspecified, this value '
        'will default to the value of the LOCAL_DART_SDK environment '
        'variable.',
    valueHelp: '/Users/me/path/to/dart-sdk/sdk',
  )
  ..addOption(
    _localFlutter,
    abbr: 'f',
    help: 'Path to your local Flutter SDK directory. If unspecified, this '
        'value will default to the value of the LOCAL_FLUTTER_SDK '
        'environment variable.',
    valueHelp: '/Users/me/path/to/flutter',
  )
  ..addFlag(
    _verbose,
    negatable: false,
    abbr: 'v',
    help: 'Run the script with verbose output, which will forward the stdout '
        'and stderr of all sub-processes.',
  )
  ..addFlag(
    _help,
    negatable: false,
    abbr: 'h',
    help: 'Show the program usage.',
  )
  ..addSeparator('Additional commands')
  ..addFlag(
    _reset,
    negatable: false,
    help: 'Reset your local Flutter SDK cache to undo the effects of running '
        'this script.',
  );

void main(List<String> args) async {
  if (Platform.isWindows) {
    throw Exception('This script is not currently supported for Windows.');
  }

  final options = _parser.parse(args);
  if (options.flag(_help)) {
    print(_parser.usage);
    exit(0);
  }

  _verboseOutput = options.flag(_verbose);

  final reset = options.flag(_reset);
  if (reset) {
    await _resetLocalFlutterSdk(options);
    exit(0);
  }

  var localDartSdk =
      options.option(_localDart) ?? Platform.environment['LOCAL_DART_SDK'];
  var localFlutterSdk = options.option(_localFlutter) ??
      Platform.environment['LOCAL_FLUTTER_SDK'];
  if (localDartSdk == null || localFlutterSdk == null) {
    stderr.writeln(
      'Error: either the --$_localDart and --$_localFlutter arguments must be '
      'passed or the LOCAL_DART_SDK and LOCAL_FLUTTER_SDK environment '
      'variables must be set.',
    );
    exit(1);
  }
  localDartSdk = _maybeRemoveTrailingSlash(localDartSdk);
  localFlutterSdk = _maybeRemoveTrailingSlash(localFlutterSdk);

  if (options.flag(_buildSdk)) {
    stdout.writeln('Building the Dart SDK...');
    await _runCommand(
        './tools/build.py',
        [
          '-mrelease',
          'create_sdk',
        ],
        workingDirectory: localDartSdk);
  }

  await _deleteDartSdkInFlutterCache(localFlutterSdk);

  // Copy the built Dart SDK to the Flutter SDK cache.
  String outDirectory;
  if (Platform.isMacOS) {
    outDirectory = 'xcodebuild';
  } else if (Platform.isLinux) {
    outDirectory = 'out';
  } else {
    outDirectory = 'unsupported';
  }
  final builtDartSdkPath = path.join(
    localDartSdk,
    outDirectory,
    'Release${options.option(_architecture)}',
    'dart-sdk',
  );
  final flutterCacheDartSdkPath = _flutterCachePrefix(
    'dart-sdk',
    localFlutterSdk: localFlutterSdk,
  );
  stdout.writeln(
    'Copying the built Dart SDK at $builtDartSdkPath to the Flutter SDK cache '
    'at $flutterCacheDartSdkPath...',
  );
  await _runCommand('cp', ['-R', builtDartSdkPath, flutterCacheDartSdkPath]);

  // Delete and regenerate the Flutter tools snapshot file so that Flutter tools
  // will rebuild the snapshot with your local Dart SDK changes.
  final flutterToolsSnapshotPath = _flutterCachePrefix(
    'flutter_tools.snapshot',
    localFlutterSdk: localFlutterSdk,
  );
  await _runCommand('rm', [flutterToolsSnapshotPath]);
  stdout.writeln('Regenerating the $flutterToolsSnapshotPath file...');
  await _runCommand(path.join(localFlutterSdk, 'bin', 'flutter'), [
    '--version',
  ]);

  stdout.writeln(
    'Finished copying local Dart SDK build to the local Flutter SDK.\n\nTo '
    'reset your local Flutter SDK state, run: '
    'dart tools/copy_dart_to_flutter.dart --reset.',
  );
}

Future<void> _resetLocalFlutterSdk(ArgResults options) async {
  var localFlutterSdk = options.option(_localFlutter) ??
      Platform.environment['LOCAL_FLUTTER_SDK'];
  if (localFlutterSdk == null) {
    stderr.writeln(
      'Error: either the --$_localFlutter argument must be passed or the '
      'LOCAL_FLUTTER_SDK environment variable must be set.',
    );
    exit(1);
  }

  await _deleteDartSdkInFlutterCache(localFlutterSdk);
  final flutterToolsSnapshotPath = _flutterCachePrefix(
    'flutter_tools.snapshot',
    localFlutterSdk: localFlutterSdk,
  );
  final flutterToolsStampPath = _flutterCachePrefix(
    'flutter_tools.stamp',
    localFlutterSdk: localFlutterSdk,
  );
  final engineStampPath = _flutterCachePrefix(
    'engine-dart-sdk.stamp',
    localFlutterSdk: localFlutterSdk,
  );
  await _runCommand('rm', [
    flutterToolsSnapshotPath,
    flutterToolsStampPath,
    engineStampPath,
  ]);
  // Regenerate the local Flutter cache with the original values.
  await _runCommand(path.join(localFlutterSdk, 'bin', 'flutter'), [
    '--version',
  ]);

  stdout.writeln('Finished restting your local Flutter SDK cache.');
}

Future<void> _deleteDartSdkInFlutterCache(String localFlutterSdk) async {
  final flutterCacheDartSdkPath = _flutterCachePrefix(
    'dart-sdk',
    localFlutterSdk: localFlutterSdk,
  );
  stdout.writeln(
    'Deleting the Dart SDK in the Flutter SDK cache at '
    '$flutterCacheDartSdkPath...',
  );
  await _runCommand('rm', ['-rf', flutterCacheDartSdkPath]);
}

String _flutterCachePrefix(String value, {required String localFlutterSdk}) =>
    path.join(localFlutterSdk, 'bin', 'cache', value);

String _maybeRemoveTrailingSlash(String path) {
  if (path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  } else {
    return path;
  }
}

/// Top level variable to track whether the --verbose flag was specified.
///
/// Tracked as a top level variable so that it does not have to be passed as a
/// parameter everywhere.
var _verboseOutput = false;

/// Runs a command in a sub-process and optionally forwards stdout and stderr to
/// the main process running this script.
///
/// If a sub-process exits with a non-zero exit code, the main process will
/// exit.
Future<void> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln(
    '${workingDirectory != null ? '$workingDirectory ' : ''}'
    '> $executable ${arguments.join(' ')}',
  );
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (_verboseOutput) {
    process.stdout.transform(utf8.decoder).listen(stdout.write);
    process.stderr.transform(utf8.decoder).listen(stderr.write);
  }
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}
