// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:developer";
import 'dart:io' show Platform;

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';

import 'package:kernel/kernel.dart'
    show Component, Library, LibraryPart, Reference;

import 'incremental_load_from_dill_suite.dart' as helper;

import "incremental_utils.dart" as util;

main(List<String> args) async {
  bool fast = false;
  bool useExperimentalInvalidation = false;
  bool addDebugBreaks = false;
  int limit = -1;
  for (String arg in args) {
    if (arg == "--fast") {
      fast = true;
    } else if (arg == "--experimental") {
      useExperimentalInvalidation = true;
    } else if (arg == "--addDebugBreaks") {
      addDebugBreaks = true;
    } else if (arg.startsWith("--limit=")) {
      limit = int.parse(arg.substring("--limit=".length));
    } else {
      throw "Unsupported argument: $arg";
    }
  }

  Dart2jsTester dart2jsTester = new Dart2jsTester(
      useExperimentalInvalidation, fast, addDebugBreaks, limit);
  await dart2jsTester.test();
}

class Dart2jsTester {
  final bool useExperimentalInvalidation;
  final bool fast;
  final bool addDebugBreaks;
  final int limit;

  Stopwatch stopwatch = new Stopwatch();
  List<int> firstCompileData;
  Map<Uri, List<int>> libToData;
  List<Uri> uris;

  List<Uri> diffs = <Uri>[];
  Set<Uri> componentUris = new Set<Uri>();

  Dart2jsTester(this.useExperimentalInvalidation, this.fast,
      this.addDebugBreaks, this.limit);

  void test() async {
    helper.TestIncrementalCompiler compiler = await setup();
    if (addDebugBreaks) {
      debugger();
    }

    diffs = <Uri>[];
    componentUris = new Set<Uri>();

    Stopwatch localStopwatch = new Stopwatch()..start();
    int recompiles = 0;
    for (int i = 0; i < uris.length; i++) {
      if (limit >= 0 && limit < i) break;
      recompiles++;
      Uri uri = uris[i];
      await step(uri, i, compiler, localStopwatch);
    }

    print("A total of ${diffs.length} diffs:");
    for (Uri uri in diffs) {
      print(" - $uri");
    }

    print("Done after ${recompiles} recompiles in "
        "${stopwatch.elapsedMilliseconds} ms");
  }

  Future step(Uri uri, int i, helper.TestIncrementalCompiler compiler,
      Stopwatch localStopwatch) async {
    print("Invalidating $uri ($i)");
    compiler.invalidate(uri);
    localStopwatch.reset();
    Component c2 = await compiler.computeDelta(fullComponent: true);
    print("Recompiled in ${localStopwatch.elapsedMilliseconds} ms");
    print("invalidatedImportUrisForTesting: "
        "${compiler.invalidatedImportUrisForTesting}");
    print("rebuildBodiesCount: ${compiler.rebuildBodiesCount}");
    localStopwatch.reset();
    Set<Uri> thisUris = new Set<Uri>.from(c2.libraries.map((l) => l.importUri));
    if (componentUris.isNotEmpty) {
      Set<Uri> diffUris = {};
      diffUris.addAll(thisUris.difference(componentUris));
      diffUris.addAll(componentUris.difference(thisUris));
      if (diffUris.isNotEmpty) {
        print("Diffs for this compile: $diffUris");
      }
    }
    componentUris.clear();
    componentUris.addAll(thisUris);

    if (fast) {
      print("Got ${c2.libraries.length} libraries");
      c2.libraries.sort((l1, l2) {
        return "${l1.fileUri}".compareTo("${l2.fileUri}");
      });

      c2.problemsAsJson?.sort();

      c2.computeCanonicalNames();

      int foundCount = 0;
      for (Library library in c2.libraries) {
        Set<Uri> uris = new Set<Uri>();
        uris.add(library.importUri);
        for (LibraryPart part in library.parts) {
          Uri uri = library.importUri.resolve(part.partUri);
          uris.add(uri);
        }
        if (!uris.contains(uri)) continue;
        foundCount++;
        library.additionalExports.sort((Reference r1, Reference r2) {
          return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
        });
        library.problemsAsJson?.sort();

        List<int> libSerialized =
            serializeComponent(c2, filter: (l) => l == library);
        if (!isEqual(libToData[library.importUri], libSerialized)) {
          print("=====");
          print("=====");
          print("=====");
          print("Notice diff on $uri ($i)!");
          libToData[library.importUri] = libSerialized;
          diffs.add(uri);
          print("=====");
          print("=====");
          print("=====");
        }
      }
      if (foundCount != 1) {
        throw "Expected to find $uri, but it $foundCount times.";
      }
      print("Serialized library in ${localStopwatch.elapsedMilliseconds} ms");
    } else {
      List<int> thisCompileData = util.postProcess(c2);
      print("Serialized in ${localStopwatch.elapsedMilliseconds} ms");
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
    }
    if (addDebugBreaks) {
      debugger();
    }
    print("-----");
  }

  Future<helper.TestIncrementalCompiler> setup() async {
    stopwatch.reset();
    stopwatch.start();
    Uri input = Platform.script.resolve("../../compiler/bin/dart2js.dart");
    CompilerOptions options = helper.getOptions();
    options.explicitExperimentalFlags[ExperimentalFlag
        .alternativeInvalidationStrategy] = useExperimentalInvalidation;
    helper.TestIncrementalCompiler compiler =
        new helper.TestIncrementalCompiler(options, input);
    Component c = await compiler.computeDelta();
    print("Compiled dart2js to Component with ${c.libraries.length} libraries "
        "in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();
    if (fast) {
      libToData = {};
      c.libraries.sort((l1, l2) {
        return "${l1.fileUri}".compareTo("${l2.fileUri}");
      });

      c.problemsAsJson?.sort();

      c.computeCanonicalNames();

      for (Library library in c.libraries) {
        library.additionalExports.sort((Reference r1, Reference r2) {
          return "${r1.canonicalName}".compareTo("${r2.canonicalName}");
        });
        library.problemsAsJson?.sort();

        List<int> libSerialized =
            serializeComponent(c, filter: (l) => l == library);
        libToData[library.importUri] = libSerialized;
      }
    } else {
      firstCompileData = util.postProcess(c);
    }
    print("Serialized in ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.reset();

    uris = c.uriToSource.values
        .map((s) => s != null ? s.importUri : null)
        .where((u) => u != null && u.scheme != "dart")
        .toSet()
        .toList();

    c = null;

    return compiler;
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
}
