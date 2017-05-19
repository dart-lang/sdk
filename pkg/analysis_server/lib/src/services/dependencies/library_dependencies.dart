// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

class LibraryDependencyCollector {
  final Set<LibraryElement> _visitedLibraries = new Set<LibraryElement>();
  final Set<String> _dependencies = new Set<String>();

  final Iterable<AnalysisContext> _contexts;

  LibraryDependencyCollector(this._contexts);

  Map<String, Map<String, List<String>>> calculatePackageMap(
      Map<Folder, AnalysisContext> folderMap) {
    Map<AnalysisContext, Folder> contextMap = _reverse(folderMap);
    Map<String, Map<String, List<String>>> result =
        new Map<String, Map<String, List<String>>>();
    for (AnalysisContext context in _contexts) {
      Map<String, List<Folder>> packageMap = context.sourceFactory.packageMap;
      if (packageMap != null) {
        Map<String, List<String>> map = new Map<String, List<String>>();
        packageMap.forEach((String name, List<Folder> folders) =>
            map[name] = new List.from(folders.map((Folder f) => f.path)));
        result[contextMap[context].path] = map;
      }
    }
    return result;
  }

  Set<String> collectLibraryDependencies() {
    _contexts.forEach((AnalysisContext context) => context.librarySources
        .forEach((Source source) =>
            _addDependencies(context.getLibraryElement(source))));
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

  Map<AnalysisContext, Folder> _reverse(Map<Folder, AnalysisContext> map) {
    Map<AnalysisContext, Folder> reverseMap =
        new Map<AnalysisContext, Folder>();
    map.forEach((Folder f, AnalysisContext c) => reverseMap[c] = f);
    return reverseMap;
  }
}
