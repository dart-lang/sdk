// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/kernel.dart' show Component;
import 'package:kernel/target/targets.dart';

import 'incremental_load_from_dill_suite.dart'
    show checkIsEqual, getOptions, initializedCompile, normalCompile;

Directory outDir;

main() async {
  outDir =
      Directory.systemTemp.createTempSync("incremental_load_from_dill_test");
  try {
    await testDart2jsCompile();
    print("----");
  } finally {
    outDir.deleteSync(recursive: true);
  }
}

Future<void> testDart2jsCompile() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  final Uri invalidateUri =
      Uri.parse("package:_fe_analyzer_shared/src/util/filenames.dart");
  Uri normalDill = outDir.uri.resolve("dart2js.full.dill");
  Uri fullDillFromInitialized =
      outDir.uri.resolve("dart2js.full_from_initialized.dill");
  Uri nonexisting = outDir.uri.resolve("dart2js.nonexisting.dill");

  // Compile dart2js without initializing from dill.
  // Note: Use none-target to avoid mismatches in "interface target" caused by
  // type inference occurring before or after mixin transformation.
  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(dart2jsUrl, normalDill,
      options: getOptions(target: new NoneTarget(new TargetFlags())));
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");
  {
    // Check that we don't include the source from files from the sdk.
    final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
    Uri platformUri = sdkRoot.resolve("vm_platform_strong.dill");
    Component cSdk = new Component();
    new BinaryBuilder(new File.fromUri(platformUri).readAsBytesSync(),
            disableLazyReading: false)
        .readComponent(cSdk);

    Component c = new Component();
    new BinaryBuilder(new File.fromUri(normalDill).readAsBytesSync(),
            disableLazyReading: false)
        .readComponent(c);
    for (Uri uri in c.uriToSource.keys) {
      if (cSdk.uriToSource.containsKey(uri)) {
        if ((c.uriToSource[uri].source?.length ?? 0) != 0) {
          throw "Compile contained sources for the sdk $uri";
        }
        if ((c.uriToSource[uri].lineStarts?.length ?? 0) != 0) {
          throw "Compile contained line starts for the sdk $uri";
        }
      }
    }
  }

  // Compile dart2js, initializing from the just-compiled dill,
  // a nonexisting file.
  for (List<Object> initializationData in [
    [normalDill, true],
    [nonexisting, false],
  ]) {
    Uri initializeWith = initializationData[0];
    bool initializeExpect = initializationData[1];
    stopwatch.reset();
    bool initializeResult = await initializedCompile(
        dart2jsUrl, fullDillFromInitialized, initializeWith, [invalidateUri],
        options: getOptions(target: new NoneTarget(new TargetFlags())));
    Expect.equals(initializeExpect, initializeResult);
    print("Initialized compile(s) from ${initializeWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    List<int> normalDillData = new File.fromUri(normalDill).readAsBytesSync();
    List<int> initializedDillData =
        new File.fromUri(fullDillFromInitialized).readAsBytesSync();
    checkIsEqual(normalDillData, initializedDillData);

    // Also try without invalidating anything.
    stopwatch.reset();
    initializeResult = await initializedCompile(
        dart2jsUrl, fullDillFromInitialized, initializeWith, [],
        options: getOptions(target: new NoneTarget(new TargetFlags())));
    Expect.equals(initializeExpect, initializeResult);
    print("Initialized compile(s) from ${initializeWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    initializedDillData =
        new File.fromUri(fullDillFromInitialized).readAsBytesSync();
    checkIsEqual(normalDillData, initializedDillData);
  }
}
