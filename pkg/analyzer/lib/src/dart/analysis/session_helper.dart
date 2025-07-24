// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  /// Returns the [ClassElement] with the given [className] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<ClassElement?> getClass(String libraryUri, String className) async {
    var libraryResult = await session.getLibraryByUri(libraryUri);
    if (libraryResult is LibraryElementResult) {
      var element = libraryResult.element.exportNamespace.get2(className);
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
  }

  @Deprecated('Use [getClass] instead.')
  Future<ClassElement?> getClass2(String libraryUri, String className) async {
    return await getClass(libraryUri, className);
  }

  /// Return the [EnumElement] with the given [className] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<EnumElement?> getEnum(String libraryUri, String className) async {
    var libraryResult = await session.getLibraryByUri(libraryUri);
    if (libraryResult is LibraryElementResult) {
      var element = libraryResult.element.exportNamespace.get2(className);
      if (element is EnumElement) {
        return element;
      }
    }
    return null;
  }

  /// Returns the [ClassElement] with the given [className] that is exported
  /// from the Flutter widgets library, or `null` if the library does not export
  /// a class with such name.
  Future<ClassElement?> getFlutterClass(String className) =>
      getClass('package:flutter/widgets.dart', className);

  /// Returns the declaration of the [fragment].
  ///
  /// Returns `null` if the [fragment] is synthetic, or is declared in a file
  /// that is not a part of a library.
  Future<FragmentDeclarationResult?> getFragmentDeclaration(
    Fragment fragment,
  ) async {
    var libraryPath = fragment.libraryFragment!.source.fullName;
    var resolvedLibrary = await _getResolvedLibrary(libraryPath);
    return resolvedLibrary?.getFragmentDeclaration(fragment);
  }

  /// Return the [MixinElement] with the given [name] that is exported
  /// from the library with the given [libraryUri], or `null` if the library
  /// does not export a class with such name.
  Future<MixinElement?> getMixin(String libraryUri, String name) async {
    var libraryResult = await session.getLibraryByUri(libraryUri);
    if (libraryResult is LibraryElementResult) {
      var element = libraryResult.element.exportNamespace.get2(name);
      if (element is MixinElement) {
        return element;
      }
    }
    return null;
  }

  /// Returns the resolved unit that declares the given [element].
  Future<ResolvedUnitResult?> getResolvedUnitByElement(Element element) async {
    var libraryPath = element.library!.firstFragment.source.fullName;
    var resolvedLibrary = await _getResolvedLibrary(libraryPath);
    if (resolvedLibrary == null) {
      return null;
    }

    var unitPath = element.firstFragment.libraryFragment!.source.fullName;
    return resolvedLibrary.units.singleWhere(
      (resolvedUnit) => resolvedUnit.path == unitPath,
    );
  }

  /// Returns the [PropertyAccessorElement] with the given [name] that is
  /// exported from the library with the given [uri].
  ///
  /// Returns `null` if the library does not export a top-level accessor with
  /// that name.
  Future<PropertyAccessorElement?> getTopLevelPropertyAccessor(
    String uri,
    String name,
  ) async {
    var libraryResult = await session.getLibraryByUri(uri);
    if (libraryResult is LibraryElementResult) {
      var element = libraryResult.element.exportNamespace.get2(name);
      if (element is PropertyAccessorElement) {
        return element;
      }
    }
    return null;
  }

  /// Return a newly resolved, or cached library with the given [path].
  Future<ResolvedLibraryResult?> _getResolvedLibrary(String path) async {
    var result = _resolvedLibraries[path];
    if (result == null) {
      var some = await session.getResolvedLibraryContaining(path);
      if (some is ResolvedLibraryResult) {
        result = _resolvedLibraries[path] = some;
      }
    }
    return result;
  }
}
