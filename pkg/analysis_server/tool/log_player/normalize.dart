// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, exit;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:package_config/package_config.dart';

import '../performance/project_generator/project_generator.dart'
    show ContextRoot, getContextRoots;
import 'log.dart';

Future<void> main(List<String> args) async {
  var parsed = argParser.parse(args);
  if (parsed.flag('help')) {
    print(argParser.usage);
    return;
  }

  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var inputFile = resourceProvider.getFile(
    Uri.base.resolve(parsed.option('input')!).toFilePath(),
  );
  if (!inputFile.exists) {
    print('Input file ${inputFile.path} does not exist');
    exit(1);
  }
  var outputFile = resourceProvider.getFile(
    Uri.base.resolve(parsed.option('output')!).toFilePath(),
  );
  var rootDirPath = parsed.option('root-dir');
  if (rootDirPath == null) {
    print('Root directory not specified');
    exit(1);
  }
  var rootDir = resourceProvider.getFolder(rootDirPath);
  if (!rootDir.exists) {
    print('Root directory $rootDirPath does not exist');
    exit(1);
  }

  List<ContextRoot> contextRoots;

  var packageConfigPath = parsed.option('package-config');
  if (packageConfigPath != null) {
    var packageConfigFile = resourceProvider.getFile(packageConfigPath);
    if (!packageConfigFile.exists) {
      print('Package config file $packageConfigPath does not exist');
      exit(1);
    }
    var packageConfig = PackageConfig.parseBytes(
      packageConfigFile.readAsBytesSync(),
      packageConfigFile.toUri(),
    );

    contextRoots = [ContextRoot(Directory(rootDirPath), packageConfig)];
  } else {
    contextRoots = await getContextRoots(rootDirPath);
  }

  print('normalizing log at ${inputFile.path}');
  var normalized = normalizeLog(inputFile, contextRoots);
  outputFile.writeAsStringSync(normalized);
  print('wrote normalized log to ${outputFile.path}');

  var absFileMatches = normalized.allMatches('"file:///');
  if (absFileMatches.isNotEmpty) {
    print('found ${absFileMatches.length} absolute file paths remaining:');
  }
  for (var match in absFileMatches.take(5)) {
    print('- ${match.group(0)}');
  }
}

final argParser = ArgParser()
  ..addOption(
    'input',
    abbr: 'i',
    help: 'The path to the input log to be normalized',
    mandatory: true,
  )
  ..addOption(
    'output',
    abbr: 'o',
    help: 'The path output the normalized log to',
    mandatory: true,
  )
  ..addOption(
    'root-dir',
    abbr: 'r',
    help: 'The path to the root directory for normalizing package paths',
    mandatory: true,
  )
  ..addOption(
    'package-config',
    abbr: 'p',
    help:
        'The path to the package config file, if specified, will be used '
        'instead of inferring it from the workspace directories.',
  )
  ..addFlag('help', abbr: 'h', help: 'Prints the usage text');

/// Reads an [input] log file, and attempts to normalize it so that it can work
/// across multiple environments.
///
/// Specifically, this:
///   - Replaces all workspace folder paths with {{workspaceFolder-[i]}}
///     placeholders.
///   - Replaces the Dart SDK root with {{dartSdkRoot}}.
///   - Replaces all package roots with {{package-root:[package-name]}}
///
/// Returns the new file contents after normalization.
//
// TODO(somebody): Support legacy protocol.
//
// TODO(somebody): Don't take a package config, instead infer them from the
// workspace directories.
String normalizeLog(File input, List<ContextRoot> contextRoots) {
  var content = input.readAsStringSync();

  // First, replace the workspace folder paths.
  var original = Log.fromString(content, {});
  var initializeMessage = original.entries.firstWhere(
    (log) => log.isMessage && log.message.isInitializeRequest,
  );
  var workspaceFolders =
      ((initializeMessage.message.map['params']
                  as Map<String, Object?>)['workspaceFolders']
              as List)
          .cast<Map<String, Object?>>();
  for (var i = 0; i < workspaceFolders.length; i++) {
    var folder = workspaceFolders[i];
    var uri = Uri.parse(folder['uri'] as String);
    content = content.replaceAll(uri.path, '{{workspaceFolder-$i}}');
  }

  // Next, replace the dart sdk path
  content = content.replaceAll(sdkPath, '{{dartSdkRoot}}');

  // TODO(somebody): Replace the flutter SDK path with {{flutterSdkRoot}}.

  // Finally, replace the package roots
  for (var i = 0; i < contextRoots.length; i++) {
    var contextRoot = contextRoots[i];

    for (var package in contextRoot.packageConfig.packages) {
      content = content.replaceAll(
        package.root.toString(),
        '{{context-$i:package-root:${package.name}}}',
      );
    }
  }
  return content;
}
