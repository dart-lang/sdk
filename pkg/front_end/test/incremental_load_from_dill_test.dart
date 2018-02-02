// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show Directory, File;

import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/fasta/kernel/utils.dart' show writeProgramToFile;

final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
final Uri invalidateUri = Uri.parse("package:compiler/src/filenames.dart");
Directory outDir;
Uri normalDill;
Uri bootstrappedDill;

main() async {
  outDir =
      Directory.systemTemp.createTempSync("incremental_load_from_dill_test");
  normalDill = outDir.uri.resolve("dart2js.full.dill");
  bootstrappedDill = outDir.uri.resolve("dart2js.bootstrap.dill");
  Uri nonexisting = outDir.uri.resolve("dart2js.nonexisting.dill");
  Uri nonLoadable = outDir.uri.resolve("dart2js.nonloadable.dill");
  try {
    // Compile dart2js without bootstrapping.
    Stopwatch stopwatch = new Stopwatch()..start();
    await normalCompile();
    print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

    // Create a file that cannot be (fully) loaded as a dill file.
    List<int> corruptData = new File.fromUri(normalDill).readAsBytesSync();
    for (int i = 10 * (corruptData.length ~/ 16);
        i < 15 * (corruptData.length ~/ 16);
        ++i) {
      corruptData[i] = 42;
    }
    new File.fromUri(nonLoadable).writeAsBytesSync(corruptData);

    // Compile dart2js, bootstrapping from the just-compiled dill.
    for (List<Object> bootstrapData in [
      [normalDill, true],
      [nonexisting, false],
      [nonLoadable, false]
    ]) {
      Uri bootstrapWith = bootstrapData[0];
      bool bootstrapExpect = bootstrapData[1];
      stopwatch.reset();
      bool bootstrapResult = await bootstrapCompile(bootstrapWith);
      print("Bootstrapped compile(s) from ${bootstrapWith.pathSegments.last} "
          "took ${stopwatch.elapsedMilliseconds} ms");

      // Compare the two files.
      List<int> normalDillData = new File.fromUri(normalDill).readAsBytesSync();
      List<int> bootstrappedDillData =
          new File.fromUri(bootstrappedDill).readAsBytesSync();
      Expect.equals(normalDillData.length, bootstrappedDillData.length);
      for (int i = 0; i < normalDillData.length; ++i) {
        if (normalDillData[i] != bootstrappedDillData[i]) {
          Expect.fail("Normally compiled and bootstrapped compile differs.");
        }
      }
      Expect.equals(bootstrapExpect, bootstrapResult);
    }
  } finally {
    outDir.deleteSync(recursive: true);
  }
}

CompilerOptions getOptions() {
  final Uri sdkRoot = computePlatformBinariesLocation();
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..strongMode = false;
  return options;
}

Future<bool> normalCompile() async {
  CompilerOptions options = getOptions();
  IncrementalCompiler compiler =
      new IncrementalKernelGenerator(options, dart2jsUrl);
  var y = await compiler.computeDelta();
  await writeProgramToFile(y, normalDill);
  return compiler.bootstrapSuccess;
}

Future<bool> bootstrapCompile(Uri bootstrapWith) async {
  CompilerOptions options = getOptions();
  IncrementalCompiler compiler =
      new IncrementalKernelGenerator(options, dart2jsUrl, bootstrapWith);
  compiler.invalidate(invalidateUri);
  var bootstrappedProgram = await compiler.computeDelta();
  bool result = compiler.bootstrapSuccess;
  await writeProgramToFile(bootstrappedProgram, bootstrappedDill);
  compiler.invalidate(invalidateUri);

  var partialProgram = await compiler.computeDelta();
  var emptyProgram = await compiler.computeDelta();

  var fullLibUris =
      bootstrappedProgram.libraries.map((lib) => lib.importUri).toList();
  var partialLibUris =
      partialProgram.libraries.map((lib) => lib.importUri).toList();
  var emptyLibUris =
      emptyProgram.libraries.map((lib) => lib.importUri).toList();

  Expect.isTrue(fullLibUris.length > partialLibUris.length);
  Expect.isTrue(partialLibUris.isNotEmpty);
  Expect.isTrue(emptyLibUris.isEmpty);

  return result;
}
