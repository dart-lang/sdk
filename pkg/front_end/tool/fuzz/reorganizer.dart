// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File, FileSystemEntity;

import '../../test/utils/io_utils.dart' show computeRepoDirUri;

import 'compile_helper.dart';
import 'stacktrace_utils.dart';

final Uri repoDir = computeRepoDirUri();

Future<void> main(List<String> args) async {
  List<Directory> directories = [];
  Directory? outputDirectory;
  for (int i = 0; i < args.length; i++) {
    String arg = args[i];
    if (arg.startsWith("--output=")) {
      outputDirectory = new Directory(
        arg.substring("--output=".length),
      ).absolute;
    } else {
      Directory d = new Directory(arg);
      if (d.existsSync()) {
        directories.add(d);
      } else {
        print("Error: $arg isn't a directory.");
      }
    }
  }
  if (outputDirectory == null) throw "No --output= given";

  Helper helper = new Helper();
  await helper.setup();
  int good = 0;
  int bad = 0;

  for (int i = 0; i < directories.length; i++) {
    Directory d = directories[i];
    for (FileSystemEntity file in d.listSync(recursive: true)) {
      if (file is! File) continue;
      String content = file.readAsStringSync();
      (Object, StackTrace)? result = await helper.compile(content);
      String filename = file.uri.pathSegments.last;
      if (result == null) {
        print("${filename}: OK");
        good++;
      } else {
        String category = categorize(result.$2);
        print("${filename}: Still crashes: $category");
        bad++;
        Directory d = new Directory.fromUri(
          outputDirectory.uri.resolve("$category/"),
        );
        d.createSync(recursive: true);
        File f = new File.fromUri(
          outputDirectory.uri.resolve("$category/$bad.input"),
        );
        f.writeAsStringSync(content);
      }
    }
  }
  print("Done. $good good, $bad bad.");
}
