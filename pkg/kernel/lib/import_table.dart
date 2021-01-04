// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.import_table;

import 'ast.dart';

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
    if (target == null) return;
    Uri referenceUri = referenceLibrary.importUri;
    Uri targetUri = target.importUri;
    if (targetUri == null) {
      throw '$referenceUri cannot refer to library without an import URI';
    }
    // To support using custom-uris in unit tests, we don't check directly
    // whether the scheme is 'file:', but instead we check that is not 'dart:'
    // or 'package:'.
    bool isFileOrCustomScheme(Uri uri) =>
        uri.scheme != '' && uri.scheme != 'package' && uri.scheme != 'dart';
    bool isTargetSchemeFileOrCustom = isFileOrCustomScheme(targetUri);
    bool isReferenceSchemeFileOrCustom = isFileOrCustomScheme(referenceUri);
    if (isTargetSchemeFileOrCustom && isReferenceSchemeFileOrCustom) {
      String relativeUri = relativeUriPath(targetUri, referenceUri);
      table.addImport(target, relativeUri);
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

String relativeUriPath(Uri target, Uri ref) {
  List<String> targetSegments = target.pathSegments;
  List<String> refSegments = ref.pathSegments;
  int to = refSegments.length;
  if (targetSegments.length < to) to = targetSegments.length;
  to--; // The last entry is the filename, here we compare only directories.
  int same = -1;
  for (int i = 0; i < to; i++) {
    if (targetSegments[i] == refSegments[i]) {
      same = i;
    } else {
      break;
    }
  }
  if (same == targetSegments.length - 2 &&
      targetSegments.length == refSegments.length) {
    // Both parts have the same number of segments,
    // and they agree on all directories.
    if (targetSegments.last == "") return ".";
    return targetSegments.last;
  }
  List<String> path = <String>[];
  int oked = same + 1;
  while (oked < refSegments.length - 1) {
    path.add("..");
    oked++;
  }
  path.addAll(targetSegments.skip(same + 1));

  if (path.isEmpty) path.add(".");
  return path.join("/");
}
