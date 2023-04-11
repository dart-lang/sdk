// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/core.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// A long [Timeout] is provided for tests that start a process on
/// `bin/dartdev.dart` as the command is not compiled ahead of time, and each
/// invocation requires the VM to compile the entire dependency graph.
const Timeout longTimeout = Timeout(Duration(minutes: 5));

/// This version of dart is the last guaranteed pre-null safety language
/// version:
const String dartVersionFilePrefix2_9 = '''
// ignore: illegal_language_version_override
// @dart = 2.9
''';

void initGlobalState() {
  log = Logger.standard();
}

/// Creates a test-project in a temp-dir that will [dispose] itself at the end
/// of the test.
TestProject project(
    {String? mainSrc,
    String? analysisOptions,
    bool logAnalytics = false,
    String name = TestProject._defaultProjectName,
    VersionConstraint? sdkConstraint,
    Map<String, dynamic>? pubspecExtras}) {
  var testProject = TestProject(
      mainSrc: mainSrc,
      name: name,
      analysisOptions: analysisOptions,
      logAnalytics: logAnalytics,
      sdkConstraint: sdkConstraint,
      pubspecExtras: pubspecExtras);
  addTearDown(() => testProject.dispose());
  return testProject;
}

class TestProject {
  static const String _defaultProjectName = 'dartdev_temp';

  late Directory root;

  Directory get dir => Directory(dirPath);

  String get dirPath => path.join(root.path, 'myapp');

  String get pubCachePath => path.join(root.path, 'pub_cache');

  String get pubCacheBinPath => path.join(pubCachePath, 'bin');

  String get mainPath => path.join(dirPath, relativeFilePath);

  final String name;

  String get relativeFilePath => 'lib/main.dart';

  final bool logAnalytics;

  Process? _process;

  TestProject({
    String? mainSrc,
    String? analysisOptions,
    this.name = _defaultProjectName,
    this.logAnalytics = false,
    VersionConstraint? sdkConstraint,
    Map<String, dynamic>? pubspecExtras,
  }) {
    initGlobalState();
    root = Directory.systemTemp.createTempSync('dartdev');
    file(
      'pubspec.yaml',
      JsonEncoder.withIndent('  ').convert(
        {
          'name': name,
          'environment': {'sdk': sdkConstraint?.toString() ?? '^2.19.0'},
          ...?pubspecExtras,
        },
      ),
    );
    if (analysisOptions != null) {
      file('analysis_options.yaml', analysisOptions);
    }
    if (mainSrc != null) {
      file(relativeFilePath, mainSrc);
    }
  }

  void file(String name, String contents) {
    var file = File(path.join(dir.path, name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  void deleteFile(String name) {
    var file = File(path.join(dir.path, name));
    assert(file.existsSync());
    file.deleteSync();
  }

  Future<void> dispose() async {
    _process?.kill();
    await _process?.exitCode;
    _process = null;
    await deleteDirectory(root);
  }

  Future<ProcessResult> runAnalyze(
    List<String> arguments, {
    String? workingDir,
  }) async {
    return run(['analyze', '--suppress-analytics', ...arguments]);
  }

  Future<ProcessResult> runFix(
    List<String> arguments, {
    String? workingDir,
  }) async {
    return run(['fix', '--suppress-analytics', ...arguments]);
  }

  Future<ProcessResult> run(
    List<String> arguments, {
    String? workingDir,
  }) async {
    final process = await start(arguments, workingDir: workingDir);
    final stdoutContents = process.stdout.transform(utf8.decoder).join();
    final stderrContents = process.stderr.transform(utf8.decoder).join();
    final code = await process.exitCode;
    return ProcessResult(
      process.pid,
      code,
      await stdoutContents,
      await stderrContents,
    );
  }

  Future<Process> start(
    List<String> arguments, {
    String? workingDir,
  }) {
    return Process.start(
        Platform.resolvedExecutable,
        [
          ...arguments,
        ],
        workingDirectory: workingDir ?? dir.path,
        environment: {
          if (logAnalytics) '_DARTDEV_LOG_ANALYTICS': 'true',
          'PUB_CACHE': pubCachePath,
        })
      ..then((p) => _process = p);
  }

  String? _sdkRootPath;

  /// Return the root of the SDK.
  String get sdkRootPath {
    if (_sdkRootPath == null) {
      // Assumes the script importing this one is somewhere under the SDK.
      String current = path.canonicalize(Platform.script.toFilePath());
      do {
        String tryDir = path.dirname(current);
        if (File(path.join(tryDir, 'pkg', 'dartdev', 'bin', 'dartdev.dart'))
            .existsSync()) {
          _sdkRootPath = tryDir;
          return _sdkRootPath!;
        }
        current = tryDir;
      } while (path.dirname(current) != current);
      throw StateError('can not find SDK repository root');
    }
    return _sdkRootPath!;
  }

  String get absolutePathToDartdevFile =>
      path.join(sdkRootPath, 'pkg', 'dartdev', 'bin', 'dartdev.dart');

  Directory? findDirectory(String name) {
    var directory = Directory(path.join(dir.path, name));
    return directory.existsSync() ? directory : null;
  }

  File? findFile(String name) {
    var file = File(path.join(dir.path, name));
    return file.existsSync() ? file : null;
  }
}

Future<void> deleteDirectory(Directory dir) async {
  int deleteAttempts = 5;
  while (deleteAttempts >= 0) {
    deleteAttempts--;
    try {
      if (!dir.existsSync()) {
        return;
      }
      dir.deleteSync(recursive: true);
    } catch (e) {
      if (deleteAttempts <= 0) {
        rethrow;
      }
      await Future.delayed(Duration(milliseconds: 500));
      log.stdout('Got $e while deleting $dir. Trying again...');
    }
  }
}

/// Checks that this is the `dart` executable in the bin folder rather than the
/// `dart` in the root of the build folder.
///
/// Many of this package tests rely on having the SDK folder layout.
void ensureRunFromSdkBinDart() {
  final uri = Uri(path: Platform.resolvedExecutable);
  final pathReversed = uri.pathSegments.reversed.toList();
  if (!pathReversed[0].startsWith('dart')) {
    throw StateError('Main executable is not Dart: ${uri.toFilePath()}.');
  }
  if (pathReversed.length < 2 || pathReversed[1] != 'bin') {
    throw StateError(
        '''Main executable is not from an SDK build: ${uri.toFilePath()}.
The `pkg/dartdev` tests must be run with the `dart` executable in the `bin` folder.
''');
  }
}
