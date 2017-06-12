// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Tests that analyzing everything from the libraries that are public from the
/// embedded category does not cause elements from other libraries to be
/// processed.
library embedded_category_boundary_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:sdk_library_metadata/libraries.dart';

import 'analyze_helper.dart';

main() async {
  List<Uri> uriList = new List<Uri>();
  libraries.forEach((String name, LibraryInfo info) {
    if (info.categories.contains(Category.embedded)) {
      uriList.add(new Uri(scheme: 'dart', path: name));
    }
  });
  asyncTest(() async {
    await analyze(uriList, {},
        checkResults: checkResults, mode: AnalysisMode.MAIN);
  });
}

/// These elements are currently escaping from dart:async via
/// `core._Resource#_readAsStream`.
Set<String> whiteList = new Set.from([
  "function(StreamController#addError)",
  "getter(StreamController#stream)",
  "setter(StreamController#onListen)"
]);

bool checkResults(Compiler compiler, CollectingDiagnosticHandler handler) {
  return compiler.enqueuer.resolution.processedEntities
      .every((MemberElement element) {
    if (whiteList.contains("$element")) return true;
    LibraryInfo info = libraries[element.library.canonicalUri.path];
    bool isAllowedInEmbedded =
        info.isInternal || info.categories.contains(Category.embedded);
    if (!isAllowedInEmbedded) {
      print(
          'Disallowed element: $element from ${element.library.canonicalUri}');
    }
    return isAllowedInEmbedded;
  });
}
