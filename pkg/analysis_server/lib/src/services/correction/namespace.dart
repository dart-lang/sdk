// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

/// Returns the [Element2] exported from the given [LibraryElement2].
Element2? getExportedElement(LibraryElement2? library, String name) {
  if (library == null) {
    return null;
  }
  var namespace = NamespaceBuilder().createExportNamespaceForLibrary(library);
  return namespace.definedNames2[name];
}

/// Return the [LibraryImport] that is referenced by [prefixNode], or
/// `null` if the node does not reference a prefix or if we cannot determine
/// which import is being referenced.
LibraryImport? getImportElement2(SimpleIdentifier prefixNode) {
  var parent = prefixNode.parent;
  if (parent is ImportDirective) {
    return parent.libraryImport;
  }
  return _getImportElementInfo2(prefixNode);
}

/// Return the [LibraryImport] that declared [prefix] and imports [element].
///
/// [libraryElement] - the [LibraryElement2] where reference is.
/// [prefix] - the import prefix, maybe `null`.
/// [element] - the referenced element.
LibraryImport? _getImportElement2(
  LibraryElement2 libraryElement,
  String prefix,
  Element2 element,
) {
  if (element.enclosingElement2 is! LibraryElement2) {
    return null;
  }
  var usedLibrary = element.library2;
  // find ImportElement that imports used library with used prefix
  List<LibraryImport>? candidates;
  for (var libraryImport in libraryElement.firstFragment.libraryImports2) {
    // required library
    if (libraryImport.importedLibrary2 != usedLibrary) {
      continue;
    }
    // required prefix
    var prefixElement = libraryImport.prefix2?.element;
    if (prefixElement == null) {
      continue;
    }
    if (prefix != prefixElement.name3) {
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

  var importElementsMap = <LibraryImport, Set<Element2>>{};
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
/// [PrefixElement2], maybe `null`.
LibraryImport? _getImportElementInfo2(SimpleIdentifier prefixNode) {
  // prepare environment
  var parent = prefixNode.parent;
  var unit = prefixNode.thisOrAncestorOfType<CompilationUnit>();
  var libraryElement = unit?.declaredFragment?.element;
  if (libraryElement == null) {
    return null;
  }
  // prepare used element
  Element2? usedElement;
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
  return _getImportElement2(libraryElement, prefix, usedElement);
}
