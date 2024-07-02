// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../tool/_fasta/entry_points.dart' show compilePlatformEntryPoint;
import 'coverage_helper.dart';

Future<void> main(List<String> arguments) async {
  Uri? coverageUri;
  for (String argument in arguments) {
    if (argument.startsWith("--coverage=")) {
      coverageUri = Uri.base
          .resolveUri(Uri.file(argument.substring("--coverage=".length)));
    } else {
      throw "Unsupported argument: $argument";
    }
  }
  if (coverageUri == null) {
    throw "Need --coverage=<dir>/ argument";
  }

  Directory tmp =
      Directory.systemTemp.createTempSync("compile_platform_coverage");
  String outlinePath = tmp.uri.resolve("vm_outline_strong.dill").toFilePath();
  String platformPath = tmp.uri.resolve("vm_platform_strong.dill").toFilePath();

  await compilePlatformEntryPoint([
    "dart:core",
    "-Ddart.vm.product=false",
    "-Ddart.isVM=true",
    "--nnbd-strong",
    "--single-root-scheme=org-dartlang-sdk",
    "--single-root-base=.",
    "org-dartlang-sdk:///sdk/lib/libraries.json",
    outlinePath,
    platformPath,
    outlinePath,
  ]);

  tmp.deleteSync(recursive: true);

  const String displayName = "compile platform";
  File f = new File.fromUri(coverageUri.resolve("$displayName.coverage"));
  // Force compiling seems to add something like 1 second to the collection
  // time, but we get rid of uncompiled functions so it seems to be worth it.
  (await collectCoverage(displayName: displayName, forceCompile: true))
      ?.writeToFile(f);
}
