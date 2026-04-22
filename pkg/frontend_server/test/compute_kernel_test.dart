// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/compiler_state.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:frontend_server/compute_kernel.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';

Future<void> main() async {
  await runHelper(
    ddc_summary_sources_change_standalone_standalone_require_both,
  );
  await runHelper(
    ddc_summary_sources_change_standalone_require_one_require_both,
  );

  if (_countFailures != 0) {
    // Set the exit code so the bots go red.
    throw "Got $_countFailures failures.";
  }
}

int _countFailures = 0;

/// Compile one standalone package, then compile another standalone package,
/// then compile a third requiring both.
/// At one point we had a bug where the target wasn't updated properly and the
/// output of the second compile was empty. In that case the third compile would
/// be missing sources.
Future<void> ddc_summary_sources_change_standalone_standalone_require_both(
  Directory dir,
) async {
  Uri outDirUri = dir.uri.resolve("out");
  new Directory.fromUri(outDirUri)..createSync();
  Uri packagesFileUri = dir.uri.resolve("packages.json");
  _writePackageFilePkg1To3(packagesFileUri);

  Uri ddcOutlineUri = computePlatformBinariesLocation(
    forceBuildDir: true,
  ).resolve("ddc_outline.dill");

  final Map<Uri, List<int>> inputDigests = {
    ddcOutlineUri: [0],
  };

  // Compile package:pkg1/file.dart - a standalone package.
  Uri pkg1File = dir.uri.resolve("live/pkg1/lib/file.dart");
  new File.fromUri(pkg1File)
    ..createSync(recursive: true)
    ..writeAsStringSync("int pkg1() { return 42; }");

  InitializedCompilerState? previousState;
  Uri pkg1Output = outDirUri.resolve("1.dill");
  ComputeKernelResult result = await _compileSummaryAndCheck(
    pkg1Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg1/file.dart",
    previousState,
  );
  previousState = result.previousState;
  new File.fromUri(pkg1File).deleteSync();

  // Compile package:pkg2/file.dart - a standalone package.
  Uri pkg2File = dir.uri.resolve("live/pkg2/lib/file.dart");
  new File.fromUri(pkg2File)
    ..createSync(recursive: true)
    ..writeAsStringSync("int pkg2() { return 43; }");

  Uri pkg2Output = outDirUri.resolve("2.dill");
  result = await _compileSummaryAndCheck(
    pkg2Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg2/file.dart",
    previousState,
  );
  previousState = result.previousState;
  new File.fromUri(pkg2File).deleteSync();

  // Compile package:pkg3/file.dart - require both previous.
  Uri pkg3File = dir.uri.resolve("live/pkg3/lib/file.dart");
  new File.fromUri(pkg3File)
    ..createSync(recursive: true)
    ..writeAsStringSync("""
import "package:pkg1/file.dart";
import "package:pkg2/file.dart";
int pkg3() { pkg1() + pkg2() + 3; }
""");

  Uri pkg3Output = outDirUri.resolve("3.dill");
  inputDigests[pkg1Output] = [1];
  inputDigests[pkg2Output] = [2];
  result = await _compileSummaryAndCheck(
    pkg3Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg3/file.dart",
    previousState,
    inputSummaries: [pkg1Output.toFilePath(), pkg2Output.toFilePath()],
  );
  previousState = result.previousState;
}

/// Compile one standalone package, then compile another that requires the
/// first. Then compile a third that requires both the two previous.
/// At one point we had a bug where the target wasn't updated properly and the
/// second output had the same output as the first output, and trying to compile
/// the third threw because it had two summaries as input with the same library
/// inside.
Future<void> ddc_summary_sources_change_standalone_require_one_require_both(
  Directory dir,
) async {
  Uri outDirUri = dir.uri.resolve("out");
  new Directory.fromUri(outDirUri)..createSync();
  Uri packagesFileUri = dir.uri.resolve("packages.json");
  _writePackageFilePkg1To3(packagesFileUri);

  Uri ddcOutlineUri = computePlatformBinariesLocation(
    forceBuildDir: true,
  ).resolve("ddc_outline.dill");

  final Map<Uri, List<int>> inputDigests = {
    ddcOutlineUri: [0],
  };

  // Compile package:pkg1/file.dart - a standalone package.
  Uri pkg1File = dir.uri.resolve("live/pkg1/lib/file.dart");
  new File.fromUri(pkg1File)
    ..createSync(recursive: true)
    ..writeAsStringSync("int pkg1() { return 42; }");

  InitializedCompilerState? previousState;
  Uri pkg1Output = outDirUri.resolve("1.dill");
  ComputeKernelResult result = await _compileSummaryAndCheck(
    pkg1Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg1/file.dart",
    previousState,
  );
  previousState = result.previousState;
  new File.fromUri(pkg1File).deleteSync();

  // Compile package:pkg2/file.dart - needs pkg1.
  Uri pkg2File = dir.uri.resolve("live/pkg2/lib/file.dart");
  new File.fromUri(pkg2File)
    ..createSync(recursive: true)
    ..writeAsStringSync("""
import "package:pkg1/file.dart";
int pkg2() { return pkg1() + 1; }
""");
  inputDigests[pkg1Output] = [1];

  Uri pkg2Output = outDirUri.resolve("2.dill");
  result = await _compileSummaryAndCheck(
    pkg2Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg2/file.dart",
    previousState,
    inputSummaries: [pkg1Output.toFilePath()],
  );
  previousState = result.previousState;
  new File.fromUri(pkg2File).deleteSync();

  // Compile package:pkg3/file.dart - needs pkg1 and pkg2.
  Uri pkg3File = dir.uri.resolve("live/pkg3/lib/file.dart");
  new File.fromUri(pkg3File)
    ..createSync(recursive: true)
    ..writeAsStringSync("""
import "package:pkg1/file.dart";
import "package:pkg2/file.dart";
int pkg3() { return pkg1() + pkg2() + 2; }
""");
  inputDigests[pkg2Output] = [2];

  Uri pkg3Output = outDirUri.resolve("3.dill");
  result = await _compileSummaryAndCheck(
    pkg3Output,
    packagesFileUri,
    ddcOutlineUri,
    inputDigests,
    "package:pkg3/file.dart",
    previousState,
    inputSummaries: [pkg1Output.toFilePath(), pkg2Output.toFilePath()],
  );
}

Future<void> runHelper(Future<void> Function(Directory) runThis) async {
  Directory tmpDir = Directory.systemTemp.createTempSync('compute_kernel_test');
  try {
    await runThis(tmpDir);
  } catch (e, st) {
    stderr.writeln("Failure running $runThis:\n\n$e\n\n");
    stderr.writeln(st);
    stderr.writeln("\n-----\n");
    _countFailures++;
    exitCode = 1;
  } finally {
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (e) {
      // Wait a little and retry.
      sleep(const Duration(milliseconds: 42));
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (e) {
        print('Warning: Got exception when deleting temp dir: $e');
      }
    }
  }
}

Future<ComputeKernelResult> _compileSummaryAndCheck(
  Uri outDill,
  Uri packagesFileUri,
  Uri ddcOutlineUri,
  Map<Uri, List<int>> inputDigests,
  String source,
  InitializedCompilerState? previousState, {
  List<String>? inputSummaries,
}) async {
  ComputeKernelResult result = await computeKernel(
    [
      "--output=${outDill.toFilePath()}",
      "--packages-file=${packagesFileUri.toFilePath()}",
      "--dart-sdk-summary=${ddcOutlineUri.toFilePath()}",
      "--exclude-non-sources",
      "--summary-only",
      "--reuse-compiler-result",
      "--use-incremental-compiler",
      "--sound-null-safety",
      "--source=$source",
      if (inputSummaries != null)
        for (String summary in inputSummaries) "--input-summary=$summary",
    ],
    isWorker: true,
    outputBuffer: null,
    inputDigests: inputDigests,
    previousState: previousState,
  );
  if (!result.succeeded) throw "Failed to compile.";
  File outFile = new File.fromUri(outDill);

  Component component = new Component();
  new BinaryBuilder(outFile.readAsBytesSync()).readComponent(component);
  List<String> outputLibs = component.libraries
      .map((lib) => lib.importUri.toString())
      .toList();

  if (outputLibs.length != 1 || outputLibs.single != source) {
    throw "Failure: Output contained ${outputLibs.length} libraries, "
        "expected exactly 1 with uri $source: "
        "${outputLibs}";
  }

  return result;
}

void _writePackageFilePkg1To3(Uri packagesFileUri) {
  new File.fromUri(packagesFileUri)..writeAsStringSync("""
{
  "configVersion": 2,
  "packages": [
    {
      "name": "pkg1",
      "rootUri": "live/pkg1",
      "packageUri": "lib/",
      "languageVersion": "3.10"
    },
    {
      "name": "pkg2",
      "rootUri": "live/pkg2",
      "packageUri": "lib/",
      "languageVersion": "3.10"
    },
    {
      "name": "pkg3",
      "rootUri": "live/pkg3",
      "packageUri": "lib/",
      "languageVersion": "3.10"
    }
  ]
}
""");
}
