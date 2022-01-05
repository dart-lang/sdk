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

  /// Return the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name. For getters and setters the
  /// corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> withName(String baseName) async {
    var analysisDriver = _analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(resolvedUnit.path),
    );

    var result = <LibraryElement, Element>{};

    for (var file in fsState.knownFiles.toList()) {
      if (!filter.shouldInclude(file)) {
        continue;
      }

      var libraryElement = analysisDriver.getLibraryByFile(file);
      if (libraryElement == null) {
        continue;
      }

      addElement(result, libraryElement, baseName);
    }

    return result;
  }

  static void addElement(
    Map<LibraryElement, Element> result,
    LibraryElement libraryElement,
    String baseName,
  ) {
    void addSingle(String name) {
      var element = libraryElement.exportNamespace.get(name);
      if (element is PropertyAccessorElement) {
        element = element.variable;
      }
      if (element != null) {
        result[libraryElement] = element;
      }
    }

    addSingle(baseName);
    addSingle('$baseName=');
  }
}
