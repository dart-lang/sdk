// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.analyze_test.test;

import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart' show nativeToUriPath;

import 'analyze_helper.dart';

/**
 * Map of white-listed warnings and errors.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys.
const Map<String, List /* <String|MessageKind> */ > WHITE_LIST = const {
  "pkg/kernel/lib/transformations/closure/": const [
    "Duplicated library name 'kernel.transformations.closure.converter'",
  ],
};

const List<String> SKIP_LIST = const <String>[
  // Helper files:
  "/data/",
  "/side_effects/",
  "quarantined/http_launch_data/",
  "mirrors_helper.dart",
  "path%20with%20spaces/",
  // Broken tests:
  "quarantined/http_test.dart",
  // Package directory
  "packages/",
];

List<Uri> computeInputUris({String filter}) {
  List<Uri> uriList = <Uri>[];
  Directory dir =
      new Directory.fromUri(Uri.base.resolve('tests/compiler/dart2js/'));
  for (FileSystemEntity entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      Uri file = Uri.base.resolve(nativeToUriPath(entity.path));
      if (filter != null && !'$file'.contains(filter)) {
        continue;
      }
      if (!SKIP_LIST.any((skip) => file.path.contains(skip))) {
        uriList.add(file);
      }
    }
  }
  return uriList;
}

main(List<String> arguments) {
  List<String> options = <String>[];
  List<Uri> uriList = <Uri>[];
  String filter;
  bool first = true;
  for (String argument in arguments) {
    if (argument.startsWith('-')) {
      options.add(argument == '-v' ? Flags.verbose : argument);
    } else if (first) {
      File file = new File(argument);
      if (file.existsSync()) {
        // Read test files from [file].
        for (String line in file.readAsLinesSync()) {
          line = line.trim();
          if (line.startsWith('Analyzing uri: ')) {
            int filenameOffset = line.indexOf('tests/compiler/dart2js/');
            if (filenameOffset != -1) {
              uriList.add(Uri.base
                  .resolve(nativeToUriPath(line.substring(filenameOffset))));
            }
          }
        }
      } else {
        // Use argument as filter on test files.
        filter = argument;
      }
    } else {
      throw new ArgumentError("Extra argument $argument in $arguments.");
    }
    first = false;
  }

  asyncTest(() async {
    if (uriList.isEmpty) {
      uriList = computeInputUris(filter: filter);
    }
    await analyze(uriList, WHITE_LIST,
        mode: AnalysisMode.URI, options: options);
  });
}
