// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';

class TopLevelDeclarations {
  final ResolvedUnitResult resolvedUnit;

  TopLevelDeclarations(this.resolvedUnit);

  DriverBasedAnalysisContext get _analysisContext {
    var analysisContext = resolvedUnit.session.analysisContext;
    return analysisContext as DriverBasedAnalysisContext;
  }

  Future<Map<LibraryElement, List<Element>>> withName(String name) async {
    var analysisDriver = _analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(resolvedUnit.path),
    );

    var result = <LibraryElement, List<Element>>{};

    for (var file in fsState.knownFiles.toList()) {
      if (!filter.shouldInclude(file)) {
        continue;
      }

      var libraryElement = analysisDriver.getLibraryByFile(file);
      if (libraryElement == null) {
        continue;
      }

      addElement(result, libraryElement, name);
    }

    return result;
  }

  static void addElement(
    Map<LibraryElement, List<Element>> result,
    LibraryElement libraryElement,
    String name,
  ) {
    var exportNamespace = libraryElement.exportNamespace;
    var element = exportNamespace.get(name);
    if (element != null) {
      // TODO(scheglov) Separate getters and setters.
      if (element is PropertyAccessorElement) {
        element = element.variable;
      }
      (result[libraryElement] ??= []).add(element);
    }
  }
}
