// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library build_dart;

import "dart:io";
import "package:args/args.dart";

bool cleanBuild;
bool fullBuild;
bool useMachineInterface;

List<String> changedFiles;
List<String> removedFiles;

/**
 * If the file is named 'build.dart' and is placed in the root directory of a
 * project or in a directory containing a pubspec.yaml file, then the Editor
 * will automatically invoke that file whenever a file in that project changes.
 * See the source code of [processArgs] for information about the legal command
 * line options.
 */
void main(List<String> arguments) {
  processArgs(arguments);

  if (cleanBuild) {
    handleCleanCommand();
  } else if (fullBuild) {
    handleFullBuild();
  } else {
    handleChangedFiles(changedFiles);
    handleRemovedFiles(removedFiles);
  }

  // Return a non-zero code to indicate a build failure.
  //exit(1);
}

/**
 * Handle --changed, --removed, --clean, --full, and --help command-line args.
 */
void processArgs(List<String> arguments) {
  var parser = new ArgParser();
  parser.addOption("changed",
      help: "the file has changed since the last build", allowMultiple: true);
  parser.addOption("removed",
      help: "the file was removed since the last build", allowMultiple: true);
  parser.addFlag("clean", negatable: false, help: "remove any build artifacts");
  parser.addFlag("full", negatable: false, help: "perform a full build");
  parser.addFlag("machine",
      negatable: false, help: "produce warnings in a machine parseable format");
  parser.addFlag("help", negatable: false, help: "display this help and exit");

  var args = parser.parse(arguments);

  if (args["help"]) {
    print(parser.getUsage());
    exit(0);
  }

  changedFiles = args["changed"];
  removedFiles = args["removed"];

  useMachineInterface = args["machine"];

  cleanBuild = args["clean"];
  fullBuild = args["full"];
}

/**
 * Delete all generated files.
 */
void handleCleanCommand() {
  Directory current = Directory.current;
  current.list(recursive: true).listen((FileSystemEntity entity) {
    if (entity is File) _maybeClean(entity);
  });
}

/**
 * Recursively scan the current directory looking for .foo files to process.
 */
void handleFullBuild() {
  var files = <String>[];

  Directory.current.list(recursive: true).listen((entity) {
    if (entity is File) {
      files.add((entity as File).resolveSymbolicLinksSync());
    }
  }, onDone: () => handleChangedFiles(files));
}

/**
 * Process the given list of changed files.
 */
void handleChangedFiles(List<String> files) {
  files.forEach(_processFile);
}

/**
 * Process the given list of removed files.
 */
void handleRemovedFiles(List<String> files) {}

/**
 * Convert a .foo file to a .foobar file.
 */
void _processFile(String arg) {
  if (arg.endsWith(".foo")) {
    print("processing: ${arg}");

    File file = new File(arg);

    String contents = file.readAsStringSync();

    File outFile = new File("${arg}bar");

    IOSink out = outFile.openWrite();
    out.writeln("// processed from ${file.path}:");
    if (contents != null) {
      out.write(contents);
    }
    out.close();

    _findErrors(arg);

    print("wrote: ${outFile.path}");
  }
}

void _findErrors(String arg) {
  File file = new File(arg);

  List lines = file.readAsLinesSync();

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains("woot") && !lines[i].startsWith("//")) {
      if (useMachineInterface) {
        // Ideally, we should emit the charStart and charEnd params as well.
        print('[{"method":"error","params":{"file":"$arg","line":${i+1},'
            '"message":"woot not supported"}}]');
      }
    }
  }
}

/**
 * If this file is a generated file (based on the extension), delete it.
 */
void _maybeClean(File file) {
  if (file.path.endsWith(".foobar")) {
    file.delete();
  }
}
