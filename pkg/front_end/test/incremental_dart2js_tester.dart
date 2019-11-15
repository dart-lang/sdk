// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'package:kernel/kernel.dart' show Component;

import 'incremental_load_from_dill_suite.dart' as helper;

import "incremental_utils.dart" as util;

main() async {
  Stopwatch stopwatch = new Stopwatch()..start();
  Uri input = Platform.script.resolve("../../compiler/bin/dart2js.dart");
  CompilerOptions options = helper.getOptions(targetName: "None");
  helper.TestIncrementalCompiler compiler =
      new helper.TestIncrementalCompiler(options, input);
  Component c = await compiler.computeDelta();
  print("Compiled dart2js to Component with ${c.libraries.length} libraries "
      "in ${stopwatch.elapsedMilliseconds} ms.");
  stopwatch.reset();
  List<int> firstCompileData = util.postProcess(c);
  print("Serialized in ${stopwatch.elapsedMilliseconds} ms");
  stopwatch.reset();

  List<Uri> uris = c.uriToSource.values
      .map((s) => s != null ? s.importUri : null)
      .where((u) => u != null && u.scheme != "dart")
      .toSet()
      .toList();

  c = null;

  List<Uri> diffs = new List<Uri>();

  for (int i = 0; i < uris.length; i++) {
    Uri uri = uris[i];
    print("Invalidating $uri ($i)");
    compiler.invalidate(uri);
    Component c2 = await compiler.computeDelta(fullComponent: true);
    print("invalidatedImportUrisForTesting: "
        "${compiler.invalidatedImportUrisForTesting}");
    List<int> thisCompileData = util.postProcess(c2);
    if (!isEqual(firstCompileData, thisCompileData)) {
      print("=====");
      print("=====");
      print("=====");
      print("Notice diff on $uri ($i)!");
      firstCompileData = thisCompileData;
      diffs.add(uri);
      print("=====");
      print("=====");
      print("=====");
    }
    print("-----");
  }

  print("A total of ${diffs.length} diffs:");
  for (Uri uri in diffs) {
    print(" - $uri");
  }

  print("Done after ${uris.length} recompiles in "
      "${stopwatch.elapsedMilliseconds} ms");
}

bool isEqual(List<int> a, List<int> b) {
  int length = a.length;
  if (b.length != length) {
    return false;
  }
  for (int i = 0; i < length; ++i) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
