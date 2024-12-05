// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../tool/coverage_merger.dart' as coverageMerger;
import 'utils/io_utils.dart';

final Uri repoDirUri = computeRepoDirUri();

Future<void> main() async {
  String dartExtension = "";
  if (Platform.isWindows) {
    dartExtension = ".exe";
  }
  Uri dart =
      repoDirUri.resolve("out/ReleaseX64/dart-sdk/bin/dart$dartExtension");
  if (!File.fromUri(dart).existsSync()) throw "Didn't find dart at $dart";
  Directory coverageTmpDir =
      Directory.systemTemp.createTempSync("cfe_coverage");
  print("Using $coverageTmpDir for coverage.");
  List<List<String>> runThese = [];
  void addSuiteSkipVm(String suitePath) {
    runThese.add([
      dart.toFilePath(),
      "--enable-asserts",
      suitePath,
      "-DskipVm=true",
      "--coverage=${coverageTmpDir.path}/",
    ]);
  }

  void addWithCoverageArgument(String script) {
    runThese.add([
      dart.toFilePath(),
      "--enable-asserts",
      script,
      "--coverage=${coverageTmpDir.path}/",
    ]);
  }

  addSuiteSkipVm("pkg/front_end/test/fasta/strong_suite.dart");
  addSuiteSkipVm("pkg/front_end/test/fasta/modular_suite.dart");
  addSuiteSkipVm("pkg/front_end/test/fasta/weak_suite.dart");

  addWithCoverageArgument("pkg/front_end/test/fasta/messages_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/fasta/outline_suite.dart");
  addWithCoverageArgument(
      "pkg/front_end/test/fasta/textual_outline_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/fasta/expression_suite.dart");
  addWithCoverageArgument(
      "pkg/front_end/test/fasta/incremental_dartino_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/dartdoctest_suite.dart");
  addWithCoverageArgument(
      "pkg/front_end/test/incremental_bulk_compiler_smoke_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/incremental_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/lint_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/outline_extractor_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/parser_all_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/parser_equivalence_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/parser_suite.dart");
  addWithCoverageArgument(
      "pkg/front_end/test/spelling_test_not_src_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/spelling_test_src_suite.dart");
  addWithCoverageArgument("pkg/front_end/test/compile_platform_coverage.dart");

  runThese.add([
    "python3",
    "tools/test.py",
    "-cfasta",
    "-mrelease",
    "-rnone",
    "language"
  ]);
  runThese.add([
    dart.toFilePath(),
    repoDirUri
        .resolve("pkg/front_end/test/run_our_tests_with_coverage.dart")
        .toFilePath()
  ]);

  Map<String, String> environment =
      new Map<String, String>.of(Platform.environment);
  environment["CFE_COVERAGE"] = "${coverageTmpDir.path}/";

  for (List<String> runThis in runThese) {
    print("Starting $runThis");
    Process p = await Process.start(
      runThis.first,
      runThis.skip(1).toList(),
      environment: environment,
    );
    p.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      print("stdout> $line");
    });
    p.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      print("stderr> $line");
    });
    print("Exit code = ${await p.exitCode}");
  }

  // Don't include the not-compiled stuff as we've (mostly) asked the VM to
  // force compile everything and that the remaining stuff is (mostly) mixins
  // and const classes etc that shouldn't (necessarily) be compiled but is
  // potentially covered in other ways.
  await coverageMerger.mergeFromDirUri(
    repoDirUri.resolve(".dart_tool/package_config.json"),
    coverageTmpDir.uri,
    silent: false,
    extraCoverageIgnores: const [],
    extraCoverageBlockIgnores: const [],
  );
}
