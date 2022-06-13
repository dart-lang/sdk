// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;

/// Generate or update corpus data.
/// Input is a list of directories, or a file containing such a list.
/// Output is produced in a `~/completion_metrics/third_party/apps` directory.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('A file name or list of directories is required.');
    exit(1);
  }

  final repos = <String>[];
  if (args.length == 1 && !Directory(args[0]).existsSync()) {
    final contents = File(args[0]).readAsStringSync();
    repos.addAll(LineSplitter().convert(contents));
  } else {
    repos.addAll(args);
  }

  if (!Directory(_appDir).existsSync()) {
    print('Creating: $_appDir');
    Directory(_appDir).createSync(recursive: true);
  }

  print('Cloning repositories...');
  if (!updateExistingClones) {
    print('(Skipping git updates.)');
  }
  for (var repo in repos) {
    final clone = await _clone(_trimName(repo));
    if (clone.exitCode != 0) {
      print('Error cloning $repo: ${clone.msg}');
    } else {
      final cloneDir = Directory(clone.directory);
      await _runPubGet(cloneDir);
      if (recurseForDependencies) {
        for (var dir in cloneDir.listSync(recursive: true)) {
          await _runPubGet(dir);
        }
      }
    }
  }
}

/// Whether to force a pub get if a package config is found.
final forcePubUpdate = false;

/// Whether to recurse into projects when installing dependencies.
final recurseForDependencies = true;

/// Whether to update existing clones.
final updateExistingClones = false;

final _appDir =
    path.join(_homeDir, 'completion_metrics', 'third_party', 'apps');

final _homeDir = Platform.isWindows
    ? Platform.environment['LOCALAPPDATA']!
    : Platform.environment['HOME']!;

final _package_config = path.join('.dart_tool', 'package_config.json');

Future<CloneResult> _clone(String repo) async {
  final name =
      _trimName(repo.split('https://github.com/').last.replaceAll('/', '_'));
  final cloneDir = path.join(_appDir, name);
  ProcessResult result;
  if (Directory(cloneDir).existsSync()) {
    if (!updateExistingClones) {
      return CloneResult(0, cloneDir);
    }
    print('Repository "$name" exists -- pulling to update');
    result = await Process.run('git', ['pull'], workingDirectory: cloneDir);
  } else {
    print('Cloning $repo to $cloneDir');
    result = await Process.run(
        'git', ['clone', '--recurse-submodules', '$repo.git', cloneDir]);
  }
  return CloneResult(result.exitCode, cloneDir, msg: result.stderr as String);
}

bool _hasPubspec(FileSystemEntity f) =>
    f is Directory &&
    File(path.join(f.path, file_paths.pubspecYaml)).existsSync();

Future<ProcessResult> _runPub(String dir) async =>
    await Process.run('flutter', ['pub', 'get'], workingDirectory: dir);

Future<void> _runPubGet(FileSystemEntity dir) async {
  if (_hasPubspec(dir)) {
    final packageFile = path.join(dir.path, _package_config);
    if (!File(packageFile).existsSync() || forcePubUpdate) {
      final relativeDirPath = path.relative(dir.path, from: _appDir);
      print('Getting pub dependencies for "$relativeDirPath"...');
      final pubRun = await _runPub(dir.path);
      if (pubRun.exitCode != 0) {
        print('Error: ${pubRun.stderr}');
      }
    }
  }
}

String _trimName(String name) {
  while (name.endsWith('/')) {
    name = name.substring(0, name.length - 1);
  }
  return name;
}

class CloneResult {
  final String directory;
  final int exitCode;
  final String msg;
  CloneResult(this.exitCode, this.directory, {this.msg = ''});
}
