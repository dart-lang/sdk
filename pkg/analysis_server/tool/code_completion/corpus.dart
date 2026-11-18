// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:path/path.dart' as path;

/// Generate or update corpus data.
/// Input is a list of directories/URLs, or a file containing `<url>[@<rev>]`
/// lines.
/// Output is produced in `~/completion_metrics/third_party/<list_name>` (or
/// `apps` when arguments are passed directly).
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('A file name or list of directories is required.');
    exit(1);
  }

  var repos = <String>[];
  var subdir = 'apps';
  if (args.length == 1 && File(args[0]).existsSync()) {
    subdir = path.basenameWithoutExtension(args[0]);
    repos.addAll(File(args[0]).linesWithoutCommentsOrBlanks);
  } else {
    repos.addAll(args);
  }

  _appDir = path.join(_homeDir, 'completion_metrics', 'third_party', subdir);
  if (!Directory(_appDir).existsSync()) {
    print('Creating: $_appDir');
    Directory(_appDir).createSync(recursive: true);
  }

  print('Cloning repositories...');
  if (!updateExistingClones) {
    print('(Skipping git updates.)');
  }
  for (var repo in repos) {
    var clone = await _clone(_trimName(repo));
    if (clone.exitCode != 0) {
      print('Error cloning $repo: ${clone.msg}');
    } else {
      var cloneDir = Directory(clone.directory);
      await _runPubGet(cloneDir);
      if (recurseForDependencies) {
        for (var dir in cloneDir.listSync(
          recursive: true,
          followLinks: false,
        )) {
          await _runPubGet(dir);
        }
      }

      // TODO(dantup): For DevTools to analyze cleanly, we need to run
      //  `dt generate-code`. Currently this must be done manually, but we
      //  should handle it here if we plan to keep DevTools in the corpus.
    }
  }
}

/// Whether to force a pub get if a package config is found.
final forcePubUpdate = false;

/// Whether to recurse into projects when installing dependencies.
final recurseForDependencies = true;

/// Whether to update existing clones.
final updateExistingClones = false;

late final String _appDir;

final _homeDir = Platform.isWindows
    ? Platform.environment['LOCALAPPDATA']!
    : Platform.environment['HOME']!;

final _packageConfig = path.join('.dart_tool', 'package_config.json');

/// A pattern used to detect if a package is part of a workspace and therefore
/// doesn't need `pub get` running in it directly.
final _workspaceResolutionPattern = RegExp(
  r'^\s*resolution\s*:\s*workspace\b',
  multiLine: true,
);

Future<CloneResult> _clone(String repo) async {
  var [repoUrl, ...rest] = repo.split('@');
  repoUrl = _trimName(repoUrl);
  var revision = rest.firstOrNull;
  var name = _trimName(
    repoUrl.split('https://github.com/').last.replaceAll('/', '_'),
  );
  var cloneDir = path.join(_appDir, name);
  ProcessResult result;
  if (Directory(cloneDir).existsSync()) {
    if (!updateExistingClones) {
      return CloneResult(0, cloneDir);
    }
    print('Repository "$name" exists -- updating');
    result = await _runGit([revision != null ? 'fetch' : 'pull'], cloneDir);
  } else {
    print('Cloning $repo to $cloneDir');
    // Omit `--recurse-submodules` as some Flutter apps include `flutter/flutter`
    // as a git submodule.
    result = await _runGit([
      'clone',
      '--filter=blob:none',
      '-c',
      'core.longpaths=true', // Allow long paths on Windows
      if (revision != null) '--no-checkout',
      '$repoUrl.git',
      cloneDir,
    ]);
  }
  if (result.exitCode == 0 && revision != null) {
    result = await _runGit(['checkout', revision], cloneDir);
  }
  return CloneResult(result.exitCode, cloneDir, msg: result.stderr as String);
}

bool _hasPubspec(FileSystemEntity f) =>
    f is Directory &&
    // Exclude pubspecs in hidden folders inside the repo.
    !path
        .split(path.relative(f.path, from: _appDir))
        .any((part) => part.startsWith('.')) &&
    File(path.join(f.path, file_paths.pubspecYaml)).existsSync();

Future<ProcessResult> _runGit(List<String> args, [String? workingDirectory]) =>
    Process.run('git', args, workingDirectory: workingDirectory);

Future<ProcessResult> _runPub(String dir) async {
  var binName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  return await Process.run(binName, ['pub', 'get'], workingDirectory: dir);
}

Future<void> _runPubGet(FileSystemEntity dir) async {
  if (_hasPubspec(dir)) {
    // If this package is part of a workspace, we don't need to run `pub get`
    // here as it'll be done in the workspace.
    var pubspec = File(path.join(dir.path, file_paths.pubspecYaml));
    if (_workspaceResolutionPattern.hasMatch(pubspec.readAsStringSync())) {
      return;
    }
    var packageFile = path.join(dir.path, _packageConfig);
    if (!File(packageFile).existsSync() || forcePubUpdate) {
      var relativeDirPath = path.relative(dir.path, from: _appDir);
      print('Getting pub dependencies for "$relativeDirPath"...');
      var pubRun = await _runPub(dir.path);
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
  new(this.exitCode, this.directory, {this.msg = ''});
}

extension on File {
  /// A helper to return only non-blank lines from a file that don't start with
  /// a `#` comment marker.
  Iterable<String> get linesWithoutCommentsOrBlanks {
    var contents = readAsStringSync();
    return LineSplitter()
        .convert(contents)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'));
  }
}
