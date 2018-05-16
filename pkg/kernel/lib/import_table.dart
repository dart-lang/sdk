// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.import_table;

import 'ast.dart';
import 'package:path/path.dart' as path;

abstract class ImportTable {
  int getImportIndex(Library library);
}

class ComponentImportTable implements ImportTable {
  final Map<Library, int> _libraryIndex = <Library, int>{};

  ComponentImportTable(Component component) {
    for (int i = 0; i < component.libraries.length; ++i) {
      _libraryIndex[component.libraries[i]] = i;
    }
  }

  int getImportIndex(Library library) => _libraryIndex[library] ?? -1;
}

class LibraryImportTable implements ImportTable {
  final List<String> _importPaths = <String>[];
  final List<Library> _importedLibraries = <Library>[];
  final Map<Library, int> _libraryIndex = <Library, int>{};

  factory LibraryImportTable(Library lib) {
    return new _ImportTableBuilder(lib).build();
  }

  LibraryImportTable.empty();

  /// The list of imports.
  ///
  /// Should not be modified directly, as the index map would go out of sync.
  List<String> get importPaths => _importPaths;

  List<Library> get importedLibraries => _importedLibraries;

  int addImport(Library target, String importPath) {
    int index = _libraryIndex[target];
    if (index != null) return index;
    index = _importPaths.length;
    _importPaths.add(importPath);
    _importedLibraries.add(target);
    _libraryIndex[target] = index;
    return index;
  }

  /// Returns the index of the given import, or -1 if not found.
  int getImportIndex(Library library) {
    return _libraryIndex[library] ?? -1;
  }

  String getImportPath(Library library) {
    return _importPaths[getImportIndex(library)];
  }
}

/// Builds the import table for a given library.
class _ImportTableBuilder extends RecursiveVisitor {
  final LibraryImportTable table = new LibraryImportTable.empty();
  final Library referenceLibrary;

  LibraryImportTable build() {
    referenceLibrary.accept(this);
    return table;
  }

  _ImportTableBuilder(this.referenceLibrary) {
    table.addImport(referenceLibrary, '');
  }

  void addLibraryImport(Library target) {
    if (target == referenceLibrary) return; // Self-reference is special.
    var referenceUri = referenceLibrary.importUri;
    var targetUri = target.importUri;
    if (targetUri == null) {
      throw '$referenceUri cannot refer to library without an import URI';
    }
    // To support using custom-uris in unit tests, we don't check directly
    // whether the scheme is 'file:', but instead we check that is not 'dart:'
    // or 'package:'.
    bool isFileOrCustomScheme(uri) =>
        uri.scheme != '' && uri.scheme != 'package' && uri.scheme != 'dart';
    bool isTargetSchemeFileOrCustom = isFileOrCustomScheme(targetUri);
    bool isReferenceSchemeFileOrCustom = isFileOrCustomScheme(referenceUri);
    if (isTargetSchemeFileOrCustom && isReferenceSchemeFileOrCustom) {
      var targetDirectory = path.dirname(targetUri.path);
      var currentDirectory = path.dirname(referenceUri.path);
      var relativeDirectory =
          path.relative(targetDirectory, from: currentDirectory);
      var filename = path.basename(targetUri.path);
      table.addImport(target, '$relativeDirectory/$filename');
    } else if (isTargetSchemeFileOrCustom) {
      // Cannot import a file:URI from a dart:URI or package:URI.
      // We may want to remove this restriction, but for now it's just a sanity
      // check.
      throw '$referenceUri cannot refer to application library $targetUri';
    } else {
      table.addImport(target, target.importUri.toString());
    }
  }

  visitClassReference(Class node) {
    addLibraryImport(node.enclosingLibrary);
  }

  visitLibrary(Library node) {
    super.visitLibrary(node);
    for (Reference exportedReference in node.additionalExports) {
      addLibraryImport(exportedReference.node.parent);
    }
  }

  defaultMemberReference(Member node) {
    addLibraryImport(node.enclosingLibrary);
  }

  visitName(Name name) {
    if (name.library != null) {
      addLibraryImport(name.library);
    }
  }
}
