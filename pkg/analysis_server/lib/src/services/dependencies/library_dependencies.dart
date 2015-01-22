// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.dependencies.library;

import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

class LibraryDependencyCollector {

  final Set<LibraryElement> _visitedLibraries = new Set<LibraryElement>();
  final Set<String> _dependencies = new Set<String>();

  final List<AnalysisContext> _contexts;

  LibraryDependencyCollector(this._contexts);

  Set<String> collectLibraryDependencies() {
    _contexts.forEach(
        (AnalysisContext context) =>
            context.librarySources.forEach(
                (Source source) => _addDependencies(context.getLibraryElement(source))));
    return _dependencies;
  }

  void _addDependencies(LibraryElement libraryElement) {
    if (libraryElement == null) {
      return;
    }
    if (_visitedLibraries.add(libraryElement)) {
      for (CompilationUnitElement cu in libraryElement.units) {
        String path = cu.source.fullName;
        if (path != null) {
          _dependencies.add(path);
        }
      }
      libraryElement.imports.forEach(
          (ImportElement import) => _addDependencies(import.importedLibrary));
      libraryElement.exports.forEach(
          (ExportElement export) => _addDependencies(export.exportedLibrary));
    }
  }
}
