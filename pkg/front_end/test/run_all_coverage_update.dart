// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory;

import '../tool/coverage_merger.dart' show mergeFromDirUri;
import 'run_all_coverage.dart' show runAllCoverageTests;

Future<void> main() async {
  Directory coverageTmpDir = await runAllCoverageTests(silent: true);

  await mergeFromDirUri(
    Uri.base.resolve(".dart_tool/package_config.json"),
    coverageTmpDir.uri,
    silent: true,
    extraCoverageIgnores: ["coverage-ignore(suite):"],
    extraCoverageBlockIgnores: ["coverage-ignore-block(suite):"],
    addAndRemoveCommentsInFiles: true,
  );
}
