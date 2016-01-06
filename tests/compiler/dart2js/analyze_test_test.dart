// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.analyze_test.test;

import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind;
import 'package:compiler/src/filenames.dart' show
    nativeToUriPath;

import 'analyze_helper.dart';
import 'memory_compiler.dart';

/**
 * Map of white-listed warnings and errors.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String, List/*<String|MessageKind>*/> WHITE_LIST = const {
  // Several tests import mirrors; any of these might trigger the warning.
  ".dart": const [
      MessageKind.IMPORT_EXPERIMENTAL_MIRRORS,
  ],
  "/test/src/util/": const [
      "Library 'package:async/async.dart' doesn't export a "
      "'ForkableStream' declaration.",
  ],
  "mirrors_test.dart": const [
      MessageKind.INVALID_SYMBOL,
      MessageKind.PRIVATE_IDENTIFIER,
  ],
};

const List<String> SKIP_LIST = const <String>[
  // Helper files:
  "dart2js_batch2_run.dart",
  "http_launch_data/",
  "mirrors_helper.dart",
  "path%20with%20spaces/",
  "one_line_dart_program.dart",
  "sourcemaps/invokes_test_file.dart",
  // No longer maintained:
  "backend_dart/",
  // Broken tests:
  "http_test.dart",
];

main(List<String> arguments) {
  bool verbose = arguments.contains('-v');

  List<String> options = <String>[
    Flags.analyzeOnly,
    Flags.analyzeMain,
    '--categories=Client,Server'];
  if (verbose) {
    options.add(Flags.verbose);
  }
  asyncTest(() async {
    List<Uri> uriList = <Uri>[];
    Directory dir =
        new Directory.fromUri(Uri.base.resolve('tests/compiler/dart2js/'));
    for (FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        Uri file = Uri.base.resolve(nativeToUriPath(entity.path));
        if (!SKIP_LIST.any((skip) => file.path.contains(skip))) {
          uriList.add(file);
        }
      }
    }
    await analyze(uriList, WHITE_LIST, mode: AnalysisMode.URI);
  });
}
