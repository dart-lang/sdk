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
import 'package:front_end/src/fasta/kernel/utils.dart'
    show writeProgramToFile, serializeProgram;
import "package:front_end/src/api_prototype/memory_file_system.dart"
    show MemoryFileSystem;
import 'package:kernel/kernel.dart'
    show Class, EmptyStatement, Library, Procedure, Program;

import 'package:front_end/src/fasta/fasta_codes.dart' show LocatedMessage;

import 'package:front_end/src/fasta/severity.dart' show Severity;

Directory outDir;

main() async {
  await runPassingTest(testDart2jsCompile);
  await runPassingTest(testDisappearingLibrary);
  await runPassingTest(testDeferredLibrary);
  await runPassingTest(testStrongModeMixins);
  await runFailingTest(
      testStrongModeMixins2,
      "testStrongModeMixins2_a.dart: Error: "
      "The parameter 'value' of the method 'A::child' has type");
}

void runFailingTest(dynamic test, String expectContains) async {
  try {
    await runPassingTest(test);
    throw "Expected this to fail.";
  } catch (e) {
    if (e.toString().contains(expectContains)) {
      print("got expected error as this test is currently failing");
    } else {
      rethrow;
    }
  }
}

void runPassingTest(dynamic test) async {
  outDir =
      Directory.systemTemp.createTempSync("incremental_load_from_dill_test");
  try {
    await test();
    print("----");
  } finally {
    outDir.deleteSync(recursive: true);
  }
}

/// Compile in strong mode. Use mixins.
void testStrongModeMixins2() async {
  final Uri a = outDir.uri.resolve("testStrongModeMixins2_a.dart");
  final Uri b = outDir.uri.resolve("testStrongModeMixins2_b.dart");

  Uri output = outDir.uri.resolve("testStrongModeMixins2_full.dill");
  Uri bootstrappedOutput =
      outDir.uri.resolve("testStrongModeMixins2_full_from_bootstrap.dill");

  new File.fromUri(a).writeAsStringSync("""
    import 'testStrongModeMixins2_b.dart';
    class A extends Object with B<C>, D<Object> {}
    """);
  new File.fromUri(b).writeAsStringSync("""
    abstract class B<ChildType extends Object> extends Object {
      ChildType get child => null;
      set child(ChildType value) {}
    }

    class C extends Object {}

    abstract class D<T extends Object> extends Object with B<T> {}
    """);

  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(a, output, options: getOptions(true));
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  bool bootstrapResult = await bootstrapCompile(
      a, bootstrappedOutput, output, [a],
      performSizeTests: false, options: getOptions(true));
  print("Bootstrapped compile(s) from ${output.pathSegments.last} "
      "took ${stopwatch.elapsedMilliseconds} ms");
  Expect.isTrue(bootstrapResult);

  // Compare the two files.
  List<int> normalDillData = new File.fromUri(output).readAsBytesSync();
  List<int> bootstrappedDillData =
      new File.fromUri(bootstrappedOutput).readAsBytesSync();
  checkBootstrappedIsEqual(normalDillData, bootstrappedDillData);
}

/// Compile in strong mode. Invalidate a file so type inferrer starts
/// on something compiled from source and (potentially) goes into
/// something loaded from dill.
void testStrongModeMixins() async {
  final Uri a = outDir.uri.resolve("testStrongModeMixins_a.dart");
  final Uri b = outDir.uri.resolve("testStrongModeMixins_b.dart");

  Uri output = outDir.uri.resolve("testStrongModeMixins_full.dill");
  Uri bootstrappedOutput =
      outDir.uri.resolve("testStrongModeMixins_full_from_bootstrap.dill");

  new File.fromUri(a).writeAsStringSync("""
    import 'testStrongModeMixins_b.dart';
    class A extends Object with B<Object>, C {}
    """);
  new File.fromUri(b).writeAsStringSync("""
    abstract class C<T extends Object> extends Object with B<T> {}
    abstract class B<ChildType extends Object> extends Object {}
    """);

  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(a, output, options: getOptions(true));
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  bool bootstrapResult = await bootstrapCompile(
      a, bootstrappedOutput, output, [a],
      performSizeTests: false, options: getOptions(true));
  print("Bootstrapped compile(s) from ${output.pathSegments.last} "
      "took ${stopwatch.elapsedMilliseconds} ms");
  Expect.isTrue(bootstrapResult);

  // Compare the two files.
  List<int> normalDillData = new File.fromUri(output).readAsBytesSync();
  List<int> bootstrappedDillData =
      new File.fromUri(bootstrappedOutput).readAsBytesSync();
  checkBootstrappedIsEqual(normalDillData, bootstrappedDillData);
}

/// Test loading from a dill file with a deferred library.
/// This is done by bootstrapping with no changes.
void testDeferredLibrary() async {
  final Uri input = outDir.uri.resolve("testDeferredLibrary_main.dart");
  final Uri b = outDir.uri.resolve("testDeferredLibrary_b.dart");
  Uri output = outDir.uri.resolve("testDeferredLibrary_full.dill");
  Uri bootstrappedOutput =
      outDir.uri.resolve("testDeferredLibrary_full_from_bootstrap.dill");
  new File.fromUri(input).writeAsStringSync("""
      import 'testDeferredLibrary_b.dart' deferred as b;

      void main() {
        print(b.foo());
      }
      """);
  new File.fromUri(b).writeAsStringSync("""
      String foo() => "hello from foo in b";
      """);

  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(input, output);
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  stopwatch.reset();
  bool bootstrapResult = await bootstrapCompile(
      input, bootstrappedOutput, output, [],
      performSizeTests: false);
  print("Bootstrapped compile(s) from ${output.pathSegments.last} "
      "took ${stopwatch.elapsedMilliseconds} ms");
  Expect.isTrue(bootstrapResult);

  // Compare the two files.
  List<int> normalDillData = new File.fromUri(output).readAsBytesSync();
  List<int> bootstrappedDillData =
      new File.fromUri(bootstrappedOutput).readAsBytesSync();
  checkBootstrappedIsEqual(normalDillData, bootstrappedDillData);
}

void testDart2jsCompile() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  final Uri invalidateUri = Uri.parse("package:compiler/src/filenames.dart");
  Uri normalDill = outDir.uri.resolve("dart2js.full.dill");
  Uri bootstrappedDill = outDir.uri.resolve("dart2js.bootstrap.dill");
  Uri nonexisting = outDir.uri.resolve("dart2js.nonexisting.dill");
  Uri nonLoadable = outDir.uri.resolve("dart2js.nonloadable.dill");

  // Compile dart2js without bootstrapping.
  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(dart2jsUrl, normalDill);
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  // Create a file that cannot be (fully) loaded as a dill file.
  List<int> corruptData = new File.fromUri(normalDill).readAsBytesSync();
  for (int i = 10 * (corruptData.length ~/ 16);
      i < 15 * (corruptData.length ~/ 16);
      ++i) {
    corruptData[i] = 42;
  }
  new File.fromUri(nonLoadable).writeAsBytesSync(corruptData);

  // Compile dart2js, bootstrapping from the just-compiled dill,
  // a nonexisting file and a dill file that isn't valid.
  for (List<Object> bootstrapData in [
    [normalDill, true],
    [nonexisting, false],
    //  [nonLoadable, false] // disabled for now
  ]) {
    Uri bootstrapWith = bootstrapData[0];
    bool bootstrapExpect = bootstrapData[1];
    stopwatch.reset();
    bool bootstrapResult = await bootstrapCompile(
        dart2jsUrl, bootstrappedDill, bootstrapWith, [invalidateUri]);
    Expect.equals(bootstrapExpect, bootstrapResult);
    print("Bootstrapped compile(s) from ${bootstrapWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    List<int> normalDillData = new File.fromUri(normalDill).readAsBytesSync();
    List<int> bootstrappedDillData =
        new File.fromUri(bootstrappedDill).readAsBytesSync();
    checkBootstrappedIsEqual(normalDillData, bootstrappedDillData);
  }
}

void checkBootstrappedIsEqual(
    List<int> normalDillData, List<int> bootstrappedDillData) {
  Expect.equals(normalDillData.length, bootstrappedDillData.length);
  for (int i = 0; i < normalDillData.length; ++i) {
    if (normalDillData[i] != bootstrappedDillData[i]) {
      Expect.fail("Normally compiled and bootstrapped compile differs.");
    }
  }
}

/// Compile an application with n libraries, then
/// compile "the same" application, but with m < n libraries,
/// where (at least one) of the missing libraries are "in the middle"
/// of the library list ---  bootstrapping from the dill with n libarries.
void testDisappearingLibrary() async {
  final Uri base = Uri.parse("org-dartlang-test:///");
  final Uri sdkSummary = base.resolve("vm_platform.dill");
  final Uri main = base.resolve("main.dart");
  final Uri b = base.resolve("b.dart");
  final Uri bootstrap = base.resolve("bootstrapFrom.dill");
  final List<int> sdkSummaryData = await new File.fromUri(
          computePlatformBinariesLocation().resolve("vm_platform.dill"))
      .readAsBytes();

  List<int> libCount2;
  {
    MemoryFileSystem fs = new MemoryFileSystem(base);
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);

    fs.entityForUri(main).writeAsStringSync("""
      library mainLibrary;
      import "b.dart" as b;

      main() {
        b.foo();
      }
      """);

    fs.entityForUri(b).writeAsStringSync("""
      library bLibrary;

      foo() {
        print("hello from b.dart foo!");
      }
      """);

    CompilerOptions options = getOptions(false);
    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    IncrementalCompiler compiler =
        new IncrementalKernelGenerator(options, main);
    Stopwatch stopwatch = new Stopwatch()..start();
    var program = await compiler.computeDelta();
    throwOnEmptyMixinBodies(program);
    print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");
    libCount2 = serializeProgram(program);
    if (program.libraries.length != 2) {
      throw "Expected 2 libraries, got ${program.libraries.length}";
    }
    if (program.libraries[0].fileUri != main) {
      throw "Expected the first library to have uri $main but was "
          "${program.libraries[0].fileUri}";
    }
  }

  {
    MemoryFileSystem fs = new MemoryFileSystem(base);
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryData);
    fs.entityForUri(bootstrap).writeAsBytesSync(libCount2);
    fs.entityForUri(b).writeAsStringSync("""
      library bLibrary;

      main() {
        print("hello from b!");
      }
      """);
    CompilerOptions options = getOptions(false);
    options.fileSystem = fs;
    options.sdkRoot = null;
    options.sdkSummary = sdkSummary;
    IncrementalCompiler compiler =
        new IncrementalKernelGenerator(options, b, bootstrap);
    compiler.invalidate(main);
    compiler.invalidate(b);
    Stopwatch stopwatch = new Stopwatch()..start();
    var program = await compiler.computeDelta();
    throwOnEmptyMixinBodies(program);
    print("Bootstrapped compile took ${stopwatch.elapsedMilliseconds} ms");
    if (program.libraries.length != 1) {
      throw "Expected 1 library, got ${program.libraries.length}";
    }
  }
}

CompilerOptions getOptions(bool strong) {
  final Uri sdkRoot = computePlatformBinariesLocation();
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..onProblem = (LocatedMessage message, Severity severity, String formatted,
        int line, int column) {
      if (severity == Severity.error || severity == Severity.warning) {
        Expect.fail("Unexpected error: $formatted");
      }
    }
    ..strongMode = strong;
  if (strong) {
    options.sdkSummary =
        computePlatformBinariesLocation().resolve("vm_platform_strong.dill");
  } else {
    options.sdkSummary =
        computePlatformBinariesLocation().resolve("vm_platform.dill");
  }
  return options;
}

Future<bool> normalCompile(Uri input, Uri output,
    {CompilerOptions options}) async {
  options ??= getOptions(false);
  IncrementalCompiler compiler = new IncrementalKernelGenerator(options, input);
  var program = await compiler.computeDelta();
  throwOnEmptyMixinBodies(program);
  await writeProgramToFile(program, output);
  return compiler.initializedFromDill;
}

void throwOnEmptyMixinBodies(Program program) {
  int empty = countEmptyMixinBodies(program);
  if (empty != 0) {
    throw "Expected 0 empty bodies in mixins, but found $empty";
  }
}

int countEmptyMixinBodies(Program program) {
  int empty = 0;
  for (Library lib in program.libraries) {
    for (Class c in lib.classes) {
      if (c.isSyntheticMixinImplementation) {
        // Assume mixin
        for (Procedure p in c.procedures) {
          if (p.function.body is EmptyStatement) {
            empty++;
          }
        }
      }
    }
  }
  return empty;
}

Future<bool> bootstrapCompile(
    Uri input, Uri output, Uri bootstrapWith, List<Uri> invalidateUris,
    {bool performSizeTests: true, CompilerOptions options}) async {
  options ??= getOptions(false);
  IncrementalCompiler compiler =
      new IncrementalKernelGenerator(options, input, bootstrapWith);
  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }
  var bootstrappedProgram = await compiler.computeDelta();
  throwOnEmptyMixinBodies(bootstrappedProgram);
  bool result = compiler.initializedFromDill;
  await writeProgramToFile(bootstrappedProgram, output);
  for (Uri invalidateUri in invalidateUris) {
    compiler.invalidate(invalidateUri);
  }

  var partialProgram = await compiler.computeDelta();
  throwOnEmptyMixinBodies(partialProgram);
  var emptyProgram = await compiler.computeDelta();
  throwOnEmptyMixinBodies(emptyProgram);

  var fullLibUris =
      bootstrappedProgram.libraries.map((lib) => lib.importUri).toList();
  var partialLibUris =
      partialProgram.libraries.map((lib) => lib.importUri).toList();
  var emptyLibUris =
      emptyProgram.libraries.map((lib) => lib.importUri).toList();

  if (performSizeTests) {
    Expect.isTrue(fullLibUris.length > partialLibUris.length);
    Expect.isTrue(partialLibUris.isNotEmpty);
    Expect.isTrue(emptyLibUris.isEmpty);
  }

  return result;
}
