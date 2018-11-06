// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';

/// A wrapper around [AnalysisSession] that provides additional utilities.
///
/// The methods in this class that return analysis results will throw an
/// [InconsistentAnalysisException] if the result to be returned might be
/// inconsistent with any previously returned results.
class AnalysisSessionHelper {
  final AnalysisSession session;

  final Map<String, ResolvedLibraryResult> _resolvedLibraries = {};

  AnalysisSessionHelper(this.session);

  /// Return the [ClassElement] with the given [className] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<ClassElement> getClass(String libraryUri, String className) async {
    var libraryElement = await session.getLibraryByUri(libraryUri);
    var element = libraryElement.exportNamespace.get(className);
    if (element is ClassElement) {
      return element;
    } else {
      return null;
    }
  }

  /// Return the declaration of the [element], or `null` is the [element]
  /// is synthetic.
  Future<ElementDeclarationResult> getElementDeclaration(
      Element element) async {
    var libraryPath = element.library.source.fullName;
    var resolvedLibrary = await _getResolvedLibrary(libraryPath);
    return resolvedLibrary.getElementDeclaration(element);
  }

  /// Return the resolved unit that declares the given [element].
  Future<ResolvedUnitResult> getResolvedUnitByElement(Element element) async {
    var libraryPath = element.library.source.fullName;
    var resolvedLibrary = await _getResolvedLibrary(libraryPath);

    var unitPath = element.source.fullName;
    return resolvedLibrary.units.singleWhere((resolvedUnit) {
      return resolvedUnit.path == unitPath;
    });
  }

  /// Return the [PropertyAccessorElement] with the given [name] that is
  /// exported from the library with the given [uri], or `null` if the
  /// library does not export a top-level accessor with such name.
  Future<PropertyAccessorElement> getTopLevelPropertyAccessor(
      String uri, String name) async {
    var libraryElement = await session.getLibraryByUri(uri);
    var element = libraryElement.exportNamespace.get(name);
    if (element is PropertyAccessorElement) {
      return element;
    } else {
      return null;
    }
  }

  /// Return a newly resolved, or cached library with the given [path].
  Future<ResolvedLibraryResult> _getResolvedLibrary(String path) async {
    var result = _resolvedLibraries[path];
    if (result == null) {
      result = await session.getResolvedLibrary(path);
      _resolvedLibraries[path] = result;
    }
    return result;
  }
}
