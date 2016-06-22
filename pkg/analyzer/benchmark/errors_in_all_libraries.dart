#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Resolves this library and everything it transitively imports and generates
/// errors in all of those libraries. Does this in an infinite loop, starting
/// from scratch each time, to show how VM warm-up affects things and to make
/// it easier to connect to this with observatory.
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  JavaSystemIO.setProperty(
      "com.google.dart.sdk",
      p.normalize(
          p.join(p.dirname(p.fromUri(Platform.script)), "../../../sdk")));

  // Assumes you have run "pub get" in the analyzer directory itself and uses
  // that "packages" directory as its package root.
  var packageRoot =
      p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), "packages"));

  var best = new Duration(days: 1);
  while (true) {
    var start = new DateTime.now();
    AnalysisEngine.instance.clearCaches();

    var context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory([
      new DartUriResolver(DirectoryBasedDartSdk.defaultSdk),
      new ResourceUriResolver(PhysicalResourceProvider.INSTANCE),
      new PackageUriResolver([new JavaFile(packageRoot)])
    ]);

    AnalysisOptionsImpl options = context.analysisOptions;
    options.strongMode = true;
    options.strongModeHints = true;

    var mainSource =
        new FileBasedSource(new JavaFile(p.fromUri(Platform.script)));
    context.applyChanges(new ChangeSet()..addedSource(mainSource));

    var initialLibrary =
        context.resolveCompilationUnit2(mainSource, mainSource);

    // Walk all of the transitively referenced libraries and compute errors.
    var errorCount = 0;
    var allLibraries = _reachableLibraries(initialLibrary.element.library);
    for (var lib in allLibraries) {
      for (var unit in lib.units) {
        var source = unit.source;

        // Skip core libraries.
        if (source.uri.scheme == 'dart') continue;

        var librarySource = context.getLibrariesContaining(source).single;
        context.resolveCompilationUnit2(source, librarySource);
        errorCount += context.computeErrors(source).length;
      }
    }

    var elapsed = new DateTime.now().difference(start);
    print("$elapsed : $errorCount errors ${elapsed < best ? "(best)" : ""}");
    if (elapsed < best) best = elapsed;
  }
}

/// Returns all libraries transitively imported or exported from [start].
List<LibraryElement> _reachableLibraries(LibraryElement start) {
  var results = <LibraryElement>[];
  var seen = new Set();
  void find(LibraryElement lib) {
    if (seen.contains(lib)) return;
    seen.add(lib);
    results.add(lib);
    lib.importedLibraries.forEach(find);
    lib.exportedLibraries.forEach(find);
  }
  find(start);
  return results;
}
