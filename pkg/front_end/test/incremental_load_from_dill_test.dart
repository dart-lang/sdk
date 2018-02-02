// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/memory_file_system.dart'
    show MemoryFileSystem;
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;
import 'package:front_end/src/fasta/kernel/utils.dart' show serializeProgram;
import 'package:front_end/src/testing/hybrid_file_system.dart'
    show HybridFileSystem;

final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
final Uri invalidateUri = Uri.parse("package:compiler/src/filenames.dart");
Uri normalDill;
Uri bootstrappedDill;
Uri root = Uri.parse('org-dartlang-test:///');
MemoryFileSystem fs = new MemoryFileSystem(root);

main() async {
  fs.entityForUri(root).createDirectory();
  normalDill = root.resolve("dart2js.full.dill");
  bootstrappedDill = root.resolve("dart2js.bootstrap.dill");
  Uri nonexisting = root.resolve("dart2js.nonexisting.dill");
  Uri nonLoadable = root.resolve("dart2js.nonloadable.dill");

  // Compile dart2js without bootstrapping.
  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile();
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  // Create a file that cannot be (fully) loaded as a dill file.
  List<int> corruptData = await fs.entityForUri(normalDill).readAsBytes();
  for (int i = 10 * (corruptData.length ~/ 16);
      i < 15 * (corruptData.length ~/ 16);
      ++i) {
    corruptData[i] = 42;
  }
  fs.entityForUri(nonLoadable).writeAsBytesSync(corruptData);

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
    List<int> normalDillData = await fs.entityForUri(normalDill).readAsBytes();
    List<int> bootstrappedDillData =
        await fs.entityForUri(bootstrappedDill).readAsBytes();
    Expect.equals(normalDillData.length, bootstrappedDillData.length);
    for (int i = 0; i < normalDillData.length; ++i) {
      if (normalDillData[i] != bootstrappedDillData[i]) {
        Expect.fail("Normally compiled and bootstrapped compile differs.");
      }
    }
    Expect.equals(bootstrapExpect, bootstrapResult);
  }
}

CompilerOptions getOptions() {
  final Uri sdkRoot = computePlatformBinariesLocation();
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..strongMode = false
    ..fileSystem = new HybridFileSystem(fs);
  return options;
}

Future<bool> normalCompile() async {
  CompilerOptions options = getOptions();
  IncrementalCompiler compiler =
      new IncrementalKernelGenerator(options, dart2jsUrl);
  var program = await compiler.computeDelta();
  List<int> data = serializeProgram(program);
  fs.entityForUri(normalDill).writeAsBytesSync(data);
  return compiler.bootstrapSuccess;
}

Future<bool> bootstrapCompile(Uri bootstrapWith) async {
  CompilerOptions options = getOptions();
  IncrementalCompiler compiler =
      new IncrementalKernelGenerator(options, dart2jsUrl, bootstrapWith);
  compiler.invalidate(invalidateUri);
  var bootstrappedProgram = await compiler.computeDelta();
  bool result = compiler.bootstrapSuccess;
  List<int> data = serializeProgram(bootstrappedProgram);
  fs.entityForUri(bootstrappedDill).writeAsBytesSync(data);
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
