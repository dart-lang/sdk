// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

/// Returns the [Element] exported from the given [LibraryElement].
Element? getExportedElement(LibraryElement? library, String name) {
  if (library == null) {
    return null;
  }
  library as LibraryElementImpl;
  var namespace = NamespaceBuilder().createExportNamespaceForLibrary(library);
  return namespace.definedNames2[name];
}

/// Return the [LibraryImport] that is referenced by [prefixNode], or
/// `null` if the node does not reference a prefix or if we cannot determine
/// which import is being referenced.
LibraryImport? getImportElement(SimpleIdentifier prefixNode) {
  var parent = prefixNode.parent;
  if (parent is ImportDirective) {
    return parent.libraryImport;
  }
  return _getImportElementInfo(prefixNode);
}

/// Return the [LibraryImport] that declared [prefix] and imports [element].
///
/// [libraryElement] - the [LibraryElement] where reference is.
/// [prefix] - the import prefix, maybe `null`.
/// [element] - the referenced element.
LibraryImport? _getImportElement(
  LibraryElement libraryElement,
  String prefix,
  Element element,
) {
  if (element.enclosingElement is! LibraryElement) {
    return null;
  }
  var usedLibrary = element.library;
  // find ImportElement that imports used library with used prefix
  List<LibraryImport>? candidates;
  for (var libraryImport in libraryElement.firstFragment.libraryImports2) {
    // required library
    if (libraryImport.importedLibrary != usedLibrary) {
      continue;
    }
    // required prefix
    var prefixElement = libraryImport.prefix2?.element;
    if (prefixElement == null) {
      continue;
    }
    if (prefix != prefixElement.name) {
      continue;
    }
    // no combinators => only possible candidate
    if (libraryImport.combinators.isEmpty) {
      return libraryImport;
    }
    // OK, we have candidate
    candidates ??= [];
    candidates.add(libraryImport);
  }
  // no candidates, probably element is defined in this library
  if (candidates == null) {
    return null;
  }
  // one candidate
  if (candidates.length == 1) {
    return candidates[0];
  }

  var importElementsMap = <LibraryImport, Set<Element>>{};
  // ensure that each ImportElement has set of elements
  for (var importElement in candidates) {
    if (importElementsMap.containsKey(importElement)) {
      continue;
    }
    var namespace = importElement.namespace;
    var elements = namespace.definedNames2.values.toSet();
    importElementsMap[importElement] = elements;
  }
  // use import namespace to choose correct one
  for (var entry in importElementsMap.entries) {
    var importElement = entry.key;
    var elements = entry.value;
    if (elements.contains(element)) {
      return importElement;
    }
  }
  // not found
  return null;
}

/// Returns the [LibraryImport] that is referenced by [prefixNode] with a
/// [PrefixElement], maybe `null`.
LibraryImport? _getImportElementInfo(SimpleIdentifier prefixNode) {
  // prepare environment
  var parent = prefixNode.parent;
  var unit = prefixNode.thisOrAncestorOfType<CompilationUnit>();
  var libraryElement = unit?.declaredFragment?.element;
  if (libraryElement == null) {
    return null;
  }
  // prepare used element
  Element? usedElement;
  if (parent is PrefixedIdentifier) {
    var prefixed = parent;
    if (prefixed.prefix == prefixNode) {
      usedElement = prefixed.element;
    }
  } else if (parent is MethodInvocation) {
    var invocation = parent;
    if (invocation.target == prefixNode) {
      usedElement = invocation.methodName.element;
    }
  }
  // we need used Element
  if (usedElement == null) {
    return null;
  }
  // find ImportElement
  var prefix = prefixNode.name;
  return _getImportElement(libraryElement, prefix, usedElement);
}
