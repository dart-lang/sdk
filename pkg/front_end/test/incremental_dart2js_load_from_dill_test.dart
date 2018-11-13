// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:io' show Directory, File;

import 'package:expect/expect.dart' show Expect;

import 'incremental_load_from_dill_test.dart'
    show normalCompile, initializedCompile, checkIsEqual;

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
  final Uri invalidateUri = Uri.parse("package:compiler/src/filenames.dart");
  Uri normalDill = outDir.uri.resolve("dart2js.full.dill");
  Uri fullDillFromInitialized =
      outDir.uri.resolve("dart2js.full_from_initialized.dill");
  Uri nonexisting = outDir.uri.resolve("dart2js.nonexisting.dill");

  // Compile dart2js without initializing from dill.
  Stopwatch stopwatch = new Stopwatch()..start();
  await normalCompile(dart2jsUrl, normalDill);
  print("Normal compile took ${stopwatch.elapsedMilliseconds} ms");

  // Compile dart2js, initializing from the just-compiled dill,
  // a nonexisting file and a dill file that isn't valid.
  for (List<Object> initializationData in [
    [normalDill, true],
    [nonexisting, false],
  ]) {
    Uri initializeWith = initializationData[0];
    bool initializeExpect = initializationData[1];
    stopwatch.reset();
    bool initializeResult = await initializedCompile(
        dart2jsUrl, fullDillFromInitialized, initializeWith, [invalidateUri]);
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
        dart2jsUrl, fullDillFromInitialized, initializeWith, []);
    Expect.equals(initializeExpect, initializeResult);
    print("Initialized compile(s) from ${initializeWith.pathSegments.last} "
        "took ${stopwatch.elapsedMilliseconds} ms");

    // Compare the two files.
    initializedDillData =
        new File.fromUri(fullDillFromInitialized).readAsBytesSync();
    checkIsEqual(normalDillData, initializedDillData);
  }
}
