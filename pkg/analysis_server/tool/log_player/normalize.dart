// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exit;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart';
import 'package:package_config/package_config.dart';

import 'log.dart';

void main(List<String> args) {
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
  var packageConfigFile = resourceProvider.getFile(
    Uri.base.resolve(parsed.option('package-config')!).toFilePath(),
  );
  if (!packageConfigFile.exists) {
    print('Package config file ${packageConfigFile.path} does not exist');
    exit(1);
  }
  var packageConfig = PackageConfig.parseBytes(
    packageConfigFile.readAsBytesSync(),
    packageConfigFile.toUri(),
  );

  print('normalizing log at ${inputFile.path}');
  var normalized = normalizeLog(inputFile, packageConfig);
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
    'package-config',
    abbr: 'p',
    help: 'The path to the package config file for normalizing package paths',
    mandatory: true,
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
String normalizeLog(File input, PackageConfig packageCofig) {
  var content = input.readAsStringSync();

  // First, replace the workspace folder paths.
  var original = Log.fromString(content, {});
  var initializeMessage = original.entries.firstWhere(
    (log) => log.isMessage && log.message.isInitialize,
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

  // Finally, replace the package roots
  for (var package in packageCofig.packages) {
    content = content.replaceAll(
      package.root.toString(),
      '{{package-root:${package.name}}}',
    );
  }
  return content;
}
