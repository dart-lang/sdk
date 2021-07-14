// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Cached data about the extensions defined in a single analysis context.
class ExtensionCache {
  /// A set containing the paths of the compilation units that have been cached.
  /// The set is used to prevent caching the same data multiple times.
  final Set<String> processedUnits = {};

  /// A map from the name of a non-static public extension member to the set of
  /// paths to libraries defining an extension member with that name.
  final Map<String, Set<UnitInLibrary>> membersByName = {};

  /// Initialize a newly created cache.
  ExtensionCache();

  /// Fill the cache with data from the [result].
  void cacheFromResult(ResolvedUnitResult result) {
    var element = result.unit.declaredElement;
    if (element != null) {
      _cacheFromElement(element);
      for (var library in result.libraryElement.importedLibraries) {
        _cacheLibrary(library);
      }
    }
  }

  /// Fill the cache with data from the [compilationUnit].
  void _cacheFromElement(CompilationUnitElement compilationUnit) {
    // Record that we've cached data for the compilation unit.
    var unitPath = _keyForUnit(compilationUnit);
    processedUnits.add(unitPath);

    // Flush any data that was previously cached for the compilation unit.
    for (var set in membersByName.values) {
      set.removeWhere((element) => element.unitPath == unitPath);
    }

    // Cache the data for the compilation unit.
    var libraryPath = compilationUnit.librarySource.fullName;
    for (var extension in compilationUnit.extensions) {
      var extensionName = extension.name;
      if (extensionName != null && !Identifier.isPrivateName(extensionName)) {
        for (var member in extension.accessors) {
          if (!member.isSynthetic) {
            _recordMember(unitPath, libraryPath, member.displayName);
          }
        }
        for (var member in extension.fields) {
          if (!member.isSynthetic) {
            _recordMember(unitPath, libraryPath, member.name);
          }
        }
        for (var member in extension.methods) {
          _recordMember(unitPath, libraryPath, member.name);
        }
      }
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
    return processedUnits.contains(_keyForUnit(compilationUnit));
  }

  /// Return the key used in the [extensionCache] for the [compilationUnit].
  String _keyForUnit(CompilationUnitElement compilationUnit) =>
      compilationUnit.source.fullName;

  /// Record that an extension member with the given [name] is defined in the
  /// compilation unit with the [unitPath] in the library with the
  /// [libraryPath].
  void _recordMember(String unitPath, String libraryPath, String name) {
    membersByName
        .putIfAbsent(name, () => {})
        .add(UnitInLibrary(unitPath, libraryPath));
  }
}

/// A representation of a compilation unit in a library.
class UnitInLibrary {
  final String unitPath;
  final String libraryPath;

  UnitInLibrary(this.unitPath, this.libraryPath);
}
