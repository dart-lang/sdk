// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import "dart:io";

import 'package:front_end/src/api_unstable/vm.dart'
    show computePlatformBinariesLocation;

main() {
  final Directory tmpDir =
      Directory.systemTemp.createTempSync("obfuscationtest");
  try {
    final Uri tmpDirUri = tmpDir.uri;
    final Uri secretfilename = tmpDirUri.resolve("secretfilename.dart");
    final File secretfilenameFile = new File.fromUri(secretfilename);
    secretfilenameFile.writeAsStringSync("""
import "secretfilename2.dart";

main() {
  print("Hello, World!");
  verySecretFoo();
}
""");
    final Uri secretfilename2 = tmpDirUri.resolve("secretfilename2.dart");
    final File secretfilename2File = new File.fromUri(secretfilename2);
    secretfilename2File.writeAsStringSync("""
@pragma('vm:entry-point')
void verySecretFoo() {
  print("foo!");
  alsoVerySecretFoo();
}

void alsoVerySecretFoo() {
  print("foo too!");
}
""");

    List<MappingPair> mapping = getSnapshotMap(tmpDir, secretfilenameFile);
    bool good = verify(mapping, {
      // This contains @pragma('vm:entry-point') and the uri should not change.
      secretfilename2.toString(),
      // This contains @pragma('vm:entry-point') and the name should not change.
      "verySecretFoo",
    }, {
      // This is not special and should have been obfuscated.
      secretfilename.toString(),
      // This is not special and should have been obfuscated.
      "alsoVerySecretFoo"
    });
    if (!good) throw "Obfuscation didn't work as expected";
    print("Good");
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}

List<MappingPair> getSnapshotMap(Directory tmpDir, File compileDartFile) {
  final Uri genKernel = Platform.script.resolve('../bin/gen_kernel.dart');
  final File genKernelFile = new File.fromUri(genKernel);
  if (!genKernelFile.existsSync()) {
    throw "Didn't find gen_kernel at $genKernel";
  }

  File resolvedExecutableFile = new File(Platform.resolvedExecutable);
  Uri resolvedExecutable = resolvedExecutableFile.uri;
  String genSnapshotFilename = "gen_snapshot";
  if (Platform.isWindows) genSnapshotFilename += ".exe";

  Uri genSnapshot = resolvedExecutable.resolve(genSnapshotFilename);
  File genSnapshotFile = new File.fromUri(genSnapshot);
  if (!genSnapshotFile.existsSync()) {
    print(
        "Didn't find gen_kernel at $genSnapshot... Trying utils/$genSnapshotFilename");
    genSnapshot = resolvedExecutable.resolve("utils/$genSnapshotFilename");
    genSnapshotFile = new File.fromUri(genSnapshot);
    if (!genSnapshotFile.existsSync()) {
      throw "Didn't find gen_kernel at $genSnapshot";
    }
  }

  final Uri platformDill = computePlatformBinariesLocation()
      .resolve('vm_platform_strong_product.dill');
  final File platformDillFile = new File.fromUri(platformDill);
  if (!platformDillFile.existsSync()) {
    throw "Didn't find vm_platform_strong_product at $platformDill";
  }

  final Uri tmpDirUri = tmpDir.uri;

  final Uri kernelDill = tmpDirUri.resolve("kernel.dill");
  final File kernelDillFile = new File.fromUri(kernelDill);

  print("Running gen_kernel");
  // Extracted from pkg/dart2native/lib/dart2native.dart.
  final ProcessResult kernelRun = Process.runSync(Platform.resolvedExecutable, [
    genKernelFile.path,
    "--platform",
    platformDillFile.path,
    "--aot",
    "-Ddart.vm.product=true",
    "-o",
    kernelDillFile.path,
    "--invocation-modes=compile",
    "--verbosity=all",
    compileDartFile.path
  ]);

  if (kernelRun.exitCode != 0) {
    throw "Got exit code ${kernelRun.exitCode}\n"
        "stdout: ${kernelRun.stdout}\n"
        "stderr: ${kernelRun.stderr}";
  }

  final Uri aotElf = tmpDirUri.resolve("aot.elf");
  final File aotElfFile = new File.fromUri(aotElf);
  final Uri obfuscationMap = tmpDirUri.resolve("obfuscation.map");
  final File obfuscationMapFile = new File.fromUri(obfuscationMap);

  print("Running $genSnapshot");
  // Extracted from pkg/dart2native/lib/dart2native.dart.
  final ProcessResult snapshotRun = Process.runSync(genSnapshotFile.path, [
    "--snapshot-kind=app-aot-elf",
    "--elf=${aotElfFile.path}",
    "--dwarf-stack-traces",
    "--obfuscate",
    "--strip",
    "--save-obfuscation-map=${obfuscationMapFile.path}",
    kernelDillFile.path,
  ]);

  if (snapshotRun.exitCode != 0) {
    throw "Got exit code ${snapshotRun.exitCode}\n"
        "stdout: ${snapshotRun.stdout}\n"
        "stderr: ${snapshotRun.stderr}";
  }

  print("Reading $obfuscationMap");

  return readJsonMapping(obfuscationMapFile);
}

List<MappingPair> readJsonMapping(File file) {
  List<MappingPair> result = [];
  List<dynamic> json = jsonDecode(file.readAsStringSync());
  for (int i = 0; i < json.length; i += 2) {
    result.add(new MappingPair(json[i] as String, json[i + 1] as String));
  }
  return result;
}

class MappingPair {
  final String from;
  final String to;

  MappingPair(this.from, this.to);

  String toString() => "MappingPair[$from->$to]";
}

bool verify(List<MappingPair> mapping, Set<String> expectedIdentity,
    Set<String> expectedDifferent) {
  bool good = true;
  Set<String> missingKeys = new Set<String>.of(expectedIdentity)
    ..addAll(expectedDifferent);
  for (MappingPair entry in mapping) {
    missingKeys.remove(entry.from);
    if (expectedIdentity.contains(entry.from) && entry.from != entry.to) {
      print("Expected ${entry.from} to map to itself, "
          "but mapped to ${entry.to}");
      good = false;
    }
    if (expectedDifferent.contains(entry.from) && entry.from == entry.to) {
      print("Expected ${entry.from} to map to something different, "
          "but it didn't.");
      good = false;
    }
  }
  if (missingKeys.isNotEmpty) {
    print("Expected to have seen the following entries which wasn't found:");
    for (String missingKey in missingKeys) {
      print("- $missingKey");
    }
    good = false;
  }
  return good;
}
