// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

const _packageOption = 'package';
const _versionOption = 'version';
const _resetFlag = 'reset';
const _skipStableCheckFlag = 'skipStableCheck';

final _packageDir = File.fromUri(Platform.script).parent.parent.path;

/// Note: Must be run from the /tool directory.
///
/// To prepare DWDS for release:
///  `dart run release.dart -p dwds`
///
/// To reset DWDS after a release:
///  `dart run release.dart --reset -p dwds -v [[wip version]]`

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      _packageOption,
      abbr: 'p',
      allowed: ['dwds'],
      defaultsTo: 'dwds',
    )
    ..addOption(_versionOption, abbr: 'v')
    ..addFlag(_resetFlag, abbr: 'r')
    ..addFlag(_skipStableCheckFlag, abbr: 's');

  final argResults = parser.parse(arguments);
  final package = argResults[_packageOption] as String?;
  if (package == null) {
    _logWarning('Please specify package with -p dwds or --package=dwds');
    return;
  }

  final isReset = argResults[_resetFlag] as bool?;
  final newVersion = argResults[_versionOption] as String?;
  final skipStableCheck = argResults[_skipStableCheckFlag] as bool?;

  int exitCode;
  if (isReset == true) {
    exitCode = await runReset(newVersion: newVersion);
  } else {
    exitCode = await runRelease(
      newVersion: newVersion,
      skipStableCheck: skipStableCheck,
    );
  }
  if (exitCode != 0) {
    _logWarning('Run terminated unexpectedly with exit code: $exitCode');
  }
}

Future<int> runReset({String? newVersion}) {
  // Check that a new wip version has been provided.
  final currentVersion = _readVersionFile();
  if (newVersion == null || !newVersion.contains('wip')) {
    _logInfo('''
      Please provide the next wip version for dwds, e.g. -v 3.0.1-wip
      Current version is $currentVersion.
    ''');
    return Future.value(1);
  }

  // Reset the dependency overrides for the package:
  _updateOverrides(includeOverrides: true);

  // Update the version strings in CHANGELOG and pubspec.yaml.
  _updateVersionStrings(
    currentVersion: currentVersion,
    nextVersion: newVersion,
    isReset: true,
  );

  // Build the package.
  final exitCode = _buildPackage();
  return exitCode;
}

Future<int> runRelease({String? newVersion, bool? skipStableCheck}) async {
  // Check that we are on a stable version of Dart.
  if (skipStableCheck != true) {
    final checkVersionProcess = await Process.run('dart', ['--version']);
    final versionInfo = checkVersionProcess.stdout as String;
    if (!versionInfo.contains('stable')) {
      _logWarning('''
        Expected to be on stable version of Dart, instead on:
        $versionInfo
        To skip this check, re-run with --skipStableCheck
        ''');
      return checkVersionProcess.exitCode;
    }
  }

  // Remove any dependency overrides for the package:
  _logInfo('Removing dependency overrides for dwds.');
  _updateOverrides(includeOverrides: false);

  // Run dart pub upgrade.
  _logInfo('Upgrading pub packages for dwds');
  final pubUpgradeProcess = await Process.run('dart', [
    'pub',
    'upgrade',
  ], workingDirectory: _packageDir);
  final upgradeErrors = pubUpgradeProcess.stderr as String;
  if (upgradeErrors.isNotEmpty) {
    _logWarning(upgradeErrors);
    return pubUpgradeProcess.exitCode;
  }

  // Update the version strings in CHANGELOG and pubspec.yaml.
  final currentVersion = _readVersionFile();
  final nextVersion = newVersion ?? _removeWip(currentVersion);
  _updateVersionStrings(
    currentVersion: currentVersion,
    nextVersion: nextVersion,
  );

  // Build the package.
  final exitCode = _buildPackage();
  return exitCode;
}

Future<int> _buildPackage() async {
  _logInfo('Building dwds');
  final buildProcess = await Process.run('dart', [
    'run',
    'tool/build.dart',
  ], workingDirectory: _packageDir);

  final buildErrors = buildProcess.stderr as String;
  if (buildErrors.isNotEmpty) {
    _logWarning(buildErrors);
  }
  return buildProcess.exitCode;
}

void _updateOverrides({required bool includeOverrides}) {
  final overridesFilePath = '$_packageDir/pubspec_overrides.yaml';
  final noOverridesFilePath = '$_packageDir/ignore_pubspec_overrides.yaml';
  if (includeOverrides) {
    _renameFile(currentName: noOverridesFilePath, newName: overridesFilePath);
  } else {
    _renameFile(currentName: overridesFilePath, newName: noOverridesFilePath);
  }
}

void _renameFile({required String currentName, required String newName}) {
  final currentFile = File(currentName);
  if (!currentFile.existsSync()) {
    _logInfo('Skip renaming $currentName to $newName, file does not exist.');
    return;
  }
  currentFile.rename(newName);
}

void _updateVersionStrings({
  required String nextVersion,
  required String currentVersion,
  bool isReset = false,
}) {
  _logInfo('Updating dwds from $currentVersion to $nextVersion');
  final pubspec = File('$_packageDir/pubspec.yaml');
  final changelog = File('$_packageDir/CHANGELOG.md');
  if (isReset) {
    _addNewLine(changelog, newLine: '## $nextVersion');
    _replaceInFile(pubspec, query: currentVersion, replaceWith: nextVersion);
  } else {
    for (final file in [pubspec, changelog]) {
      _replaceInFile(file, query: currentVersion, replaceWith: nextVersion);
    }
  }
}

void _addNewLine(File file, {required String newLine, int insertAt = 0}) {
  final currentLines = file.readAsLinesSync();
  final linesBefore = currentLines.sublist(0, insertAt);
  final linesAfter = currentLines.sublist(insertAt);
  final newLines = [...linesBefore, newLine, '', ...linesAfter];
  final content = newLines.joinWithNewLine();
  return file.writeAsStringSync(content);
}

bool _replaceInFile(
  File file, {
  required String query,
  required String replaceWith,
}) {
  final newLines = <String>[];
  var replaced = false;
  for (final line in file.readAsLinesSync()) {
    if (line.contains(query)) {
      newLines.add(line.replaceAll(query, replaceWith));
      replaced = true;
    } else {
      newLines.add(line);
    }
  }
  final content = newLines.joinWithNewLine();
  file.writeAsStringSync(content);
  return replaced;
}

String _readVersionFile() {
  final versionFile = File('$_packageDir/lib/src/version.dart');
  final lines = versionFile.readAsLinesSync();
  for (final line in lines) {
    if (line.startsWith('const packageVersion =')) {
      final version = line
          .split('=')
          .last
          .split('')
          .where((char) => char != ';' && char != "'" && char != '"')
          .join('');
      return version.trim();
    }
  }
  throw Exception('Could not read version in dwds/lib/src/version.dart');
}

String _removeWip(String wipVersion) {
  if (!wipVersion.contains('wip')) {
    throw Exception('$wipVersion is not a wip version.');
  }
  return wipVersion.split('-wip').first;
}

void _logInfo(String message) {
  stdout.writeln(message);
}

void _logWarning(String warning) {
  stderr.writeln(warning);
}

extension JoinExtension on List<String> {
  String joinWithNewLine() {
    return '${join('\n')}\n';
  }
}
