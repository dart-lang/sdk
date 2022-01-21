// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';

/// Cached data about the documentation associated with the elements declared in
/// a single analysis context.
class DocumentationCache {
  /// A shared instance for elements that have no documentation.
  static final DocumentationWithSummary _emptyDocs =
      DocumentationWithSummary(full: '', summary: '');

  /// The object used to compute the documentation associated with a single
  /// element.
  final DartdocDirectiveInfo dartdocDirectiveInfo;

  /// The documentation associated with the elements that have been cached. The
  /// cache is keyed by the path of the file containing the declaration of the
  /// element and the qualified name of the element.
  final Map<String, Map<String, DocumentationWithSummary>> documentationCache =
      {};

  /// Initialize a newly created cache.
  DocumentationCache(this.dartdocDirectiveInfo);

  /// Fill the cache with data from the [result].
  void cacheFromResult(ResolvedUnitResult result) {
    var compilationUnit = result.unit.declaredElement;
    if (compilationUnit != null) {
      documentationCache.remove(_keyForUnit(compilationUnit));
      _cacheFromElement(compilationUnit);
      for (var library in result.libraryElement.importedLibraries) {
        _cacheLibrary(library);
      }
    }
  }

  /// Return the data cached for the given [element], or `null` if there is no
  /// cached data.
  DocumentationWithSummary? dataFor(Element element) {
    var parent = element.enclosingElement;
    if (parent == null) {
      return null;
    }
    var key = element.name;
    if (key == null) {
      return null;
    }
    if (parent is! CompilationUnitElement) {
      var parentName = parent.name;
      if (parentName == null) {
        return null;
      }
      key = '$parentName.$key';
      parent = parent.enclosingElement;
    }
    if (parent is CompilationUnitElement) {
      var elementMap = documentationCache[_keyForUnit(parent)];
      return elementMap?[key];
    }
    return null;
  }

  /// Fill the cache with data from the [compilationUnit].
  void _cacheFromElement(CompilationUnitElement compilationUnit) {
    var elementMap =
        documentationCache.putIfAbsent(_keyForUnit(compilationUnit), () => {});
    for (var element in compilationUnit.accessors) {
      if (!element.isSynthetic) {
        elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
      }
    }
    for (var element in compilationUnit.enums) {
      var parentKey =
          elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
      if (parentKey != null) {
        for (var member in element.fields) {
          elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
        }
      }
    }
    for (var element in compilationUnit.extensions) {
      var parentKey =
          elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
      if (parentKey != null) {
        for (var member in element.accessors) {
          if (!member.isSynthetic) {
            elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
          }
        }
        for (var member in element.fields) {
          if (!member.isSynthetic) {
            elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
          }
        }
        for (var member in element.methods) {
          elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
        }
      }
    }
    for (var element in compilationUnit.functions) {
      elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
    }
    for (var element in [
      ...compilationUnit.mixins,
      ...compilationUnit.classes
    ]) {
      var parentKey =
          elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
      if (parentKey != null) {
        for (var member in element.accessors) {
          if (!element.isSynthetic) {
            elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
          }
        }
        for (var member in element.fields) {
          if (!element.isSynthetic) {
            elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
          }
        }
        for (var member in element.methods) {
          elementMap.cacheMember(dartdocDirectiveInfo, parentKey, member);
        }
      }
    }
    for (var element in compilationUnit.topLevelVariables) {
      if (!element.isSynthetic) {
        elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
      }
    }
    for (var element in compilationUnit.typeAliases) {
      elementMap.cacheTopLevelElement(dartdocDirectiveInfo, element);
    }
  }

  /// Cache the data for the given [library] and every library exported from it
  /// if it hasn't already been cached.
  void _cacheLibrary(LibraryElement library) {
    if (_hasDataFor(library.definingCompilationUnit)) {
      return;
    }
    for (var unit in library.units) {
      _cacheFromElement(unit);
    }
    for (var exported in library.exportedLibraries) {
      _cacheLibrary(exported);
    }
  }

  /// Return `true` if the cache contains data for the [compilationUnit].
  bool _hasDataFor(CompilationUnitElement compilationUnit) {
    return documentationCache.containsKey(_keyForUnit(compilationUnit));
  }

  /// Return the key used in the [documentationCache] for the [compilationUnit].
  String _keyForUnit(CompilationUnitElement compilationUnit) =>
      compilationUnit.source.fullName;
}

extension on Map<String, DocumentationWithSummary> {
  /// Cache the data associated with the [element], using the given [key].
  DocumentationWithSummary? cacheElement(
      DartdocDirectiveInfo dartdocDirectiveInfo, String key, Element element) {
    var documentation = DartUnitHoverComputer.computeDocumentation(
        dartdocDirectiveInfo, element,
        includeSummary: true);
    if (documentation is DocumentationWithSummary) {
      return this[key] = documentation;
    }
    return this[key] = DocumentationCache._emptyDocs;
  }

  /// Cache the data associated with the [member] element given that the key
  /// associated with the member's parent is [parentKey].
  void cacheMember(DartdocDirectiveInfo dartdocDirectiveInfo, String parentKey,
      Element member) {
    var name = member.name;
    if (name == null) {
      return null;
    }
    cacheElement(dartdocDirectiveInfo, '$parentKey.$name', member);
  }

  /// Cache the data associated with the top-level [element], and return the
  /// [key] used for the element. This does not cache any data associated with
  /// any other elements, including children of the [element].
  String? cacheTopLevelElement(
      DartdocDirectiveInfo dartdocDirectiveInfo, Element element) {
    var key = element.name;
    if (key == null) {
      return null;
    }
    cacheElement(dartdocDirectiveInfo, key, element);
    return key;
  }
}
