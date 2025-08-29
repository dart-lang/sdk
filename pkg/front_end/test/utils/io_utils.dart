// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, Platform, Process, ProcessResult;

import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:package_config/package_config.dart'
    show PackageConfig, Package, LanguageVersion;
import 'package:pub_semver/pub_semver.dart' show Version;

String computeRepoDir() {
  Uri uri;
  if (Platform.script.hasAbsolutePath) {
    uri = Platform.script;
  } else if (Platform.packageConfig != null) {
    String packageConfig = Platform.packageConfig!;
    final String prefix = "file://";
    if (packageConfig.startsWith(prefix)) {
      uri = Uri.parse(packageConfig);
    } else {
      uri = Uri.base.resolve(nativeToUriPath(packageConfig));
    }
  } else {
    throw "Can't obtain the path to the SDK either via "
        "Platform.script or Platform.packageConfig";
  }
  String path = new File.fromUri(uri).parent.path;
  ProcessResult result = Process.runSync(
    'git',
    ['rev-parse', '--show-toplevel'],
    runInShell: true,
    workingDirectory: path,
  );
  if (result.exitCode != 0) {
    throw "Git returned non-zero error code (${result.exitCode}):\n\n"
        "stdout: ${result.stdout}\n\n"
        "stderr: ${result.stderr}";
  }
  String dirPath = (result.stdout as String).trim();
  if (!new Directory(dirPath).existsSync()) {
    throw "The path returned by git ($dirPath) does not actually exist.";
  }
  if (dirPath.length > 1 && dirPath[1] == ':') {
    // Absolute Windows path. Normalize drive letter to match Uri.base.
    if (Uri.base.path.length < 3 ||
        Uri.base.path[0] != '/' ||
        Uri.base.path[2] != ':') {
      throw "Expected Uri.base=${Uri.base} to be an absolute file path.";
    }
    bool isLowerCase = Uri.base.path[1] == Uri.base.path[1].toLowerCase();
    if (isLowerCase) {
      dirPath = dirPath[0].toLowerCase() + dirPath.substring(1);
    } else {
      dirPath = dirPath[0].toUpperCase() + dirPath.substring(1);
    }
  }
  return dirPath;
}

Uri computeRepoDirUri() {
  String dirPath = computeRepoDir();
  return new Directory(dirPath).uri;
}

Package? getPackageFor(String name) {
  Uri packageConfigUri = computeRepoDirUri().resolve(
    ".dart_tool/package_config.json",
  );
  PackageConfig packageConfig = PackageConfig.parseBytes(
    new File.fromUri(packageConfigUri).readAsBytesSync(),
    packageConfigUri,
  );
  for (Package package in packageConfig.packages) {
    if (package.name == name) {
      return package;
    }
  }
  return null;
}

Version getPackageVersionFor(String name) {
  Package? package = getPackageFor(name);
  if (package == null) throw "Didn't find '$name' as a package.";
  LanguageVersion? languageVersion = package.languageVersion;
  if (languageVersion == null) {
    throw "'$name' does not have a language version.";
  }
  return new Version(languageVersion.major, languageVersion.minor, 0);
}
