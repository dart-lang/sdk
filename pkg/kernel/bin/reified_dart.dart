#!/usr/bin/env dart
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:path/path.dart' as path;

args.ArgParser parser = new args.ArgParser(allowTrailingOptions: true)
  ..addOption("sdk",
      abbr: "s",
      help: "Path to the Dart SDK. By default it will be searched at the path\n"
          "'../../../out/ReleaseX64/patched_sdk' relative to the directory\n"
          "of 'reified_dart'.",
      defaultsTo: null)
  ..addOption("dartk",
      abbr: "k",
      help: "Path to 'dartk' executable. By default it will be searched for\n"
          "in the same directory as 'reified_dart'.",
      defaultsTo: null)
  ..addOption("dill-output",
      abbr: "d",
      help: "Path to intermediate reified .dill file. If not specified,\n"
          "the intermediate file is created in a temporary location\n"
          "and is removed after program execution.",
      defaultsTo: null);

String getUsage() => """
Usage: reified_dart [options] FILE

Reifies generic types in FILE and runs the transformed program.

Examples:
    reified_dart foo.dart
    reified_dart --sdk=/path/to/sdk foo.dart
    reified_dart --sdk=/path/to/sdk --dartk=/path/to/dartk foo.dart

Options:
${parser.usage}
""";

void fail(String message) {
  stderr.writeln(message);
  exit(1);
}

args.ArgResults options;

void checkIsDirectory(String path, {String option, String description}) {
  description = (description == null ? "" : "$description\n");
  switch (new File(path).statSync().type) {
    case FileSystemEntityType.DIRECTORY:
    case FileSystemEntityType.LINK:
      return;
    case FileSystemEntityType.NOT_FOUND:
      throw fail('$description$option not found: $path');
    default:
      fail('$description$option is not a directory: $path');
  }
}

void checkIsFile(String path, {String option, String description}) {
  description = (description == null ? "" : "$description\n");
  var stat = new File(path).statSync();
  switch (stat.type) {
    case FileSystemEntityType.DIRECTORY:
      throw fail('$description$option is a directory: $path');

    case FileSystemEntityType.NOT_FOUND:
      throw fail('$description$option not found: $path');
  }
}

String getDefaultSdk() {
  String currentFile = Platform.script.toFilePath();

  // Respect different path separators.
  String relativePath = "../../../out/ReleaseX64/patched_sdk";
  List<String> components = relativePath.split("/");
  relativePath = "";
  for (String component in components) {
    relativePath = path.join(relativePath, component);
  }

  String currentDir = path.dirname(currentFile);
  String sdkPath = path.normalize(path.join(currentDir, relativePath));

  checkIsDirectory(sdkPath,
      option: "Path to Dart SDK",
      description: "The --sdk option wasn't specified, "
          "so default location was checked.");

  return sdkPath;
}

String getDefaultDartk() {
  String currentFile = Platform.script.toFilePath();
  String dartkPath = path.join(path.dirname(currentFile), "dartk.dart");

  checkIsFile(dartkPath,
      option: "Path to 'dartk'",
      description: "The --dartk option wasn't specified, "
          "so default location was checked.");

  return dartkPath;
}

main(List<String> arguments) async {
  if (arguments.length == 0) {
    fail(getUsage());
  }

  try {
    options = parser.parse(arguments);
  } on FormatException catch (e) {
    fail(e.message);
  }

  if (options.rest.length != 1) {
    fail("Exactly one FILE should be given.");
  }

  String inputFilename = options.rest.single;
  checkIsFile(inputFilename, option: "Input file");

  String sdkPath = options["sdk"] ?? getDefaultSdk();
  checkIsDirectory(sdkPath, option: "Path to Dart SDK");

  String dartkPath = options["dartk"] ?? getDefaultDartk();
  checkIsFile(dartkPath, option: "Path to 'dartk'");

  String dillOutput = options["dill-output"];
  File tempFile = null;
  if (dillOutput == null) {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    dillOutput = uri.toFilePath();
    tempFile = new File.fromUri(uri);
  }

  ProcessResult result = await Process.run(dartkPath, [
    "--strong",
    "--sdk=$sdkPath",
    "--target=vmreify",
    "--link",
    "--out=$dillOutput",
    inputFilename,
  ]);
  if (result.exitCode != 0) {
    tempFile?.parent?.delete(recursive: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    stderr.writeln("ERROR: execution of 'dartk' failed with exit code "
        "${result.exitCode}");
    exit(result.exitCode);
  }

  result = await Process.run("/usr/bin/env", [
    "dart",
    dillOutput,
    inputFilename,
  ]);

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  tempFile?.parent?.delete(recursive: true);
  if (result.exitCode != 0) {
    stderr.writeln("ERROR: execution of 'dart' failed with exit code "
        "${result.exitCode}");
    exit(result.exitCode);
  }
}
