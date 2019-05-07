// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/dart/syntactic_scope.dart';
import 'package:meta/meta.dart';

ImportLibraryRequest importLibraryElementImpl({
  @required ResolvedLibraryResult targetResolvedLibrary,
  @required String targetPath,
  @required int targetOffset,
  @required LibraryElement requestedLibrary,
  @required Element requestedElement,
}) {
  var targetLibrary = targetResolvedLibrary.element;

  var requestedLibraryUri = requestedLibrary.source.uri;
  var requestedElementUri = requestedElement.librarySource.uri;
  var requestedName = requestedElement.displayName;

  // If the element is defined in this library, then no prefix needed.
  if (targetLibrary == requestedElement.library) {
    return ImportLibraryRequest(null, null);
  }

  var requestedElements = requestedLibrary.exportNamespace.definedNames;
  _removeEntryForDynamic(requestedElements);

  // Find URIs of all libraries that import the requested name into the target.
  var unprefixedNameUriSet = Set<Uri>();
  for (var import in targetLibrary.imports) {
    var definedNames = import.namespace.definedNames;
    if (import.prefix == null) {
      var element = definedNames[requestedName];
      if (element != null) {
        unprefixedNameUriSet.add(element.librarySource.uri);
      }
    }
  }

  // Find names that will be shadowed by a new unprefixed import.
  var collector = NotSyntacticScopeReferencedNamesCollector(
    targetResolvedLibrary.element,
    requestedElements.keys.toSet(),
  );
  for (var resolvedUnit in targetResolvedLibrary.units) {
    resolvedUnit.unit.accept(collector);
  }

  // Find names that will shadow unprefixed references.
  var scopeNames = Set<String>();
  targetLibrary.accept(_TopLevelNamesCollector(scopeNames));
  for (var resolvedUnit in targetResolvedLibrary.units) {
    if (resolvedUnit.path == targetPath) {
      resolvedUnit.unit.accept(
        SyntacticScopeNamesCollector(scopeNames, targetOffset),
      );
    }
  }

  var canUseUnprefixedImport = true;

  // If a name is inherited, it will be shadowed by a new unprefixed import.
  if (collector.inheritedNames.isNotEmpty) {
    canUseUnprefixedImport = false;
  }

  // If a name is imported, and it is not the same as the one from the
  // requested library, then a new unprefixed import will cause ambiguity.
  for (var name in collector.importedNames.keys) {
    var importedUri = collector.importedNames[name];
    var requestedUri = requestedElements[name]?.librarySource?.uri;
    if (requestedUri != importedUri) {
      canUseUnprefixedImport = false;
      break;
    }
  }

  // If syntactic scope at the offset has the requested name, then the name
  // from an unprefixed import will be shadowed.
  if (scopeNames.contains(requestedName)) {
    canUseUnprefixedImport = false;
  }

  // If the requested name is ambiguous from existing unprefixed imports,
  // or is not the same element as the one from the requested library, then
  // we cannot use unprefixed import.
  if (unprefixedNameUriSet.isNotEmpty) {
    if (unprefixedNameUriSet.length > 1 ||
        unprefixedNameUriSet.first != requestedElementUri) {
      canUseUnprefixedImport = false;
    }
  }

  // Find import prefixes with which the name is ambiguous.
  var ambiguousWithImportPrefixes = Set<String>();
  for (var import in targetLibrary.imports) {
    var definedNames = import.namespace.definedNames;
    if (import.prefix != null) {
      var prefix = import.prefix.name;
      var prefixedName = '$prefix.$requestedName';
      var importedElement = definedNames[prefixedName];
      if (importedElement != null &&
          importedElement.librarySource.uri != requestedElementUri) {
        ambiguousWithImportPrefixes.add(prefix);
      }
    }
  }

  // Check for existing imports of the requested library.
  for (var import in targetLibrary.imports) {
    if (import.importedLibrary?.source?.uri == requestedLibraryUri) {
      var importedNames = import.namespace.definedNames;
      if (import.prefix == null) {
        if (canUseUnprefixedImport &&
            importedNames.containsKey(requestedName)) {
          return ImportLibraryRequest(null, null);
        }
      } else {
        var prefix = import.prefix.name;
        var prefixedName = '$prefix.$requestedName';
        if (importedNames.containsKey(prefixedName) &&
            !ambiguousWithImportPrefixes.contains(prefix)) {
          return ImportLibraryRequest(null, prefix);
        }
      }
    }
  }

  // If the name cannot be used without import prefix, generate one.
  String prefix;
  if (!canUseUnprefixedImport) {
    prefix = 'prefix';
    for (var index = 0;; index++) {
      prefix = 'prefix$index';
      if (!collector.referencedNames.contains(prefix)) {
        break;
      }
    }
  }

  return ImportLibraryRequest(requestedLibraryUri, prefix);
}

/// The type `dynamic` is part of 'dart:core', but has no library.
void _removeEntryForDynamic(Map<String, Element> requestedElements) {
  requestedElements.removeWhere((_, element) {
    if (element.librarySource == null) {
      assert(element.displayName == 'dynamic');
      return true;
    }
    return false;
  });
}

/// Information about a library to import.
class ImportLibraryRequest {
  /// The URI of the library to import, or `null` if the requested library is
  /// already imported, with the [prefix], so no new import is required.
  final Uri uri;

  /// The prefix with which ths requested library is already imported,
  /// or should be imported, or `null` is no prefix is necessary.
  final String prefix;

  ImportLibraryRequest(this.uri, this.prefix);
}

/// Element visitor that collects names of top-level elements.
class _TopLevelNamesCollector extends GeneralizingElementVisitor<void> {
  final Set<String> names;

  _TopLevelNamesCollector(this.names);

  @override
  void visitElement(Element element) {
    if (element is LibraryElement || element is CompilationUnitElement) {
      super.visitElement(element);
    } else if (element is ImportElement) {
      var prefix = element.prefix?.displayName;
      if (prefix != null) {
        names.add(prefix);
      }
    } else if (element.enclosingElement is CompilationUnitElement) {
      names.add(element.displayName);
    }
  }
}
