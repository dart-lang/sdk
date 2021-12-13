// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/equivalence.dart';
import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;
import 'package:kernel/target/targets.dart';
import 'incremental_suite.dart' as helper;
import 'package:front_end/src/fasta/util/outline_extractor.dart';
import 'package:package_config/package_config.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) throw "Wants 1 argument.";
  Uri input = Uri.base.resolve(args.single);
  Uri packageUri = input.resolve(".packages");
  Stopwatch stopwatch = new Stopwatch()..start();
  PackageConfig packageFile = await loadPackageConfigUri(packageUri);
  print("Read packages file in ${stopwatch.elapsedMilliseconds} ms");
  List<Package> packages = packageFile.packages.toList();
  int packageNum = 0;
  for (Package package in packages) {
    packageNum++;
    print("\n\nProcessing package #$packageNum (${package.name}) "
        "of ${packages.length}");
    Directory dir = new Directory.fromUri(package.packageUriRoot);
    List<Uri> uris = [];
    for (FileSystemEntity entry in dir.listSync(recursive: true)) {
      if (entry is File && entry.path.endsWith(".dart")) {
        // Hack.
        String content = entry.readAsStringSync();
        if (content.contains("part of")) continue;
        String asString = "${entry.uri}";
        String packageName = package.name;
        Uri packageUri = package.packageUriRoot;
        String prefix = "${packageUri}";
        if (asString.startsWith(prefix)) {
          Uri reversed = Uri.parse(
              "package:$packageName/${asString.substring(prefix.length)}");
          uris.add(reversed);
        } else {
          throw "Unexpected!";
        }
      }
    }
    print("(found ${uris.length} files)");
    if (uris.isEmpty) continue;
    await processUri(uris, null, packageUri);
  }
  print(" => That's ${packages.length} packages!");

  if (1 + 1 == 2) return;

  Component fullComponent = await processUri([input], null, packageUri);
  List<Uri> uris = fullComponent.libraries.map((l) => l.importUri).toList();
  int i = 0;
  for (Uri uri in uris) {
    i++;
    print("\n\nProcessing $uri (${i} of ${uris.length})");
    try {
      await processUri([uri], fullComponent, packageUri);
    } catch (e, st) {
      print("\n\n-------------\n\n");
      print("Crashed on uri $uri");
      print("Exception: '$e'");
      print(st);
      print("\n\n-------------\n\n");
    }
  }
}

Future<Component> processUri(final List<Uri> inputs, Component? fullComponent,
    final Uri packageUri) async {
  TargetFlags targetFlags =
      new TargetFlags(enableNullSafety: true, trackWidgetCreation: false);
  Target? target = new Dart2jsTarget("dart2js", targetFlags);
  Uri sdkSummary = Uri.base.resolve("out/ReleaseX64/dart2js_outline.dill");
  Stopwatch stopwatch = new Stopwatch()..start();
  Stopwatch extractCompile = new Stopwatch()..start();
  Map<Uri, String> processedFiles = await extractOutline(inputs,
      packages: packageUri, target: target, platform: sdkSummary);
  extractCompile.stop();
  print("Got ${processedFiles.keys.length} files "
      "in ${stopwatch.elapsedMilliseconds} ms");

  Set<Uri> inputsSet = inputs.toSet();

  Stopwatch plainCompile = new Stopwatch()..start();
  List<Library> libs1;
  {
    stopwatch.reset();
    CompilerOptions options = helper.getOptions();
    options.target = target;
    options.sdkSummary = sdkSummary;
    options.packagesFileUri = packageUri;
    helper.TestIncrementalCompiler compiler =
        new helper.TestIncrementalCompiler(options, inputs.first,
            /* initializeFrom = */ null, /* outlineOnly = */ true);
    fullComponent = fullComponent ??
        (await compiler.computeDelta(entryPoints: inputs)).component;
    print("Compiled full in ${stopwatch.elapsedMilliseconds} ms "
        "to ${fullComponent.libraries.length} libraries");
    plainCompile.stop();

    libs1 = fullComponent.libraries
        .where((element) => inputsSet.contains(element.importUri))
        .toList();
  }
  List<Library> libs2;
  {
    stopwatch.reset();
    extractCompile.start();
    CompilerOptions options = helper.getOptions();
    options.target = target;
    options.sdkSummary = sdkSummary;
    options.packagesFileUri = packageUri;
    MemoryFileSystem mfs = new MemoryFileSystem(Uri.base);
    mfs.entityForUri(packageUri).writeAsBytesSync(
        await options.fileSystem.entityForUri(packageUri).readAsBytes());
    if (options.sdkSummary != null) {
      mfs.entityForUri(options.sdkSummary!).writeAsBytesSync(await options
          .fileSystem
          .entityForUri(options.sdkSummary!)
          .readAsBytes());
    }
    if (options.librariesSpecificationUri != null) {
      mfs.entityForUri(options.librariesSpecificationUri!).writeAsBytesSync(
          await options.fileSystem
              .entityForUri(options.librariesSpecificationUri!)
              .readAsBytes());
    }
    for (MapEntry<Uri, String> entry in processedFiles.entries) {
      mfs.entityForUri(entry.key).writeAsStringSync(entry.value);
    }
    options.fileSystem = mfs;
    helper.TestIncrementalCompiler compiler =
        new helper.TestIncrementalCompiler(options, inputs.first,
            /* initializeFrom = */ null, /* outlineOnly = */ true);
    IncrementalCompilerResult c =
        await compiler.computeDelta(entryPoints: inputs);
    print("Compiled outlined in ${stopwatch.elapsedMilliseconds} ms "
        "to ${c.component.libraries.length} libraries");
    extractCompile.stop();

    libs2 = c.component.libraries
        .where((element) => inputsSet.contains(element.importUri))
        .toList();
  }

  int libSorter(Library a, Library b) {
    return a.importUri.toString().compareTo(b.importUri.toString());
  }

  libs1.sort(libSorter);
  libs2.sort(libSorter);
  if (libs1.length != libs2.length) {
    print("Bad:");
    print(
        "Not the same amount of libraries: ${libs1.length} vs ${libs2.length}");
    throw "bad result for $inputs";
  }
  List<EquivalenceResult> badResults = [];
  for (int i = 0; i < libs1.length; i++) {
    EquivalenceResult result =
        checkEquivalence(libs1[i], libs2[i], strategy: const Strategy());
    if (!result.isEquivalent) {
      badResults.add(result);
    }
  }

  if (badResults.isEmpty) {
    print("OK");
  } else {
    print("Bad:");
    for (EquivalenceResult badResult in badResults) {
      print(badResult);
      print("---");
    }
    // globalDebuggingNames = new NameSystem();
    // print(lib1.leakingDebugToString());
    // print("\n---\nvs\n----\n");
    // globalDebuggingNames = new NameSystem();
    // print(lib2.leakingDebugToString());
    throw "bad result for $inputs";
  }

  if (plainCompile.elapsedMilliseconds > extractCompile.elapsedMilliseconds) {
    print("=> Plain compile slower! "
        "(${plainCompile.elapsedMilliseconds} vs "
        "${extractCompile.elapsedMilliseconds})");
  } else {
    print("=> Plain compile faster! "
        "(${plainCompile.elapsedMilliseconds} vs "
        "${extractCompile.elapsedMilliseconds})");
  }

  return fullComponent;
}

class Strategy extends EquivalenceStrategy {
  const Strategy();

  @override
  bool checkTreeNode_fileOffset(
      EquivalenceVisitor visitor, TreeNode node, TreeNode other) {
    return true;
  }

  @override
  bool checkAssertStatement_conditionStartOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return true;
  }

  @override
  bool checkAssertStatement_conditionEndOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return true;
  }

  @override
  bool checkClass_startFileOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return true;
  }

  @override
  bool checkClass_fileEndOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return true;
  }

  @override
  bool checkProcedure_startFileOffset(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return true;
  }

  @override
  bool checkConstructor_startFileOffset(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return true;
  }

  @override
  bool checkMember_fileEndOffset(
      EquivalenceVisitor visitor, Member node, Member other) {
    return true;
  }

  @override
  bool checkFunctionNode_fileEndOffset(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return true;
  }

  @override
  bool checkBlock_fileEndOffset(
      EquivalenceVisitor visitor, Block node, Block other) {
    return true;
  }

  @override
  bool checkLibrary_additionalExports(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkSets(
        node.additionalExports.toSet(),
        other.additionalExports.toSet(),
        visitor.matchReferences,
        visitor.checkReferences,
        'additionalExports');
  }

  @override
  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    // Check procedures as a set instead of a list to allow for reordering.
    List<Procedure> a = node.procedures.toList();
    int sorter(Procedure x, Procedure y) {
      int result = x.name.text.compareTo(y.name.text);
      if (result != 0) return result;
      result = x.kind.index - y.kind.index;
      if (result != 0) return result;
      // other stuff?
      return 0;
    }

    a.sort(sorter);
    List<Procedure> b = other.procedures.toList();
    b.sort(sorter);
    // return visitor.checkSets(a.toSet(), b.toSet(),
    //     visitor.matchNamedNodes, visitor.checkNodes, 'procedures');

    return visitor.checkLists(a, b, visitor.checkNodes, 'procedures');
  }
}
