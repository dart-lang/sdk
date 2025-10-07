// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/compilation_unit.dart';
import '../builder/declaration_builders.dart';
import '../builder/prefix_builder.dart';
import 'name_space.dart';

/// Interface for accessing extensions available in the current scope.
///
/// This available extensions come from the current library or from extensions
/// imported into the current scope, possibly through prefixes, and through
/// the extension scope of parent parts.
abstract class ExtensionScope {
  void forEachExtension(void Function(ExtensionBuilder) f);
}

/// Interface for accessing extensions directly declared or imported.
///
/// This is used as a base for computing the nested extension scope in
/// [ExtensionScope].
abstract class Extensions {
  void forEachLocalExtension(void Function(ExtensionBuilder member) f);
}

class ExtensionsBuilder implements Extensions {
  Set<ExtensionBuilder>? _extensions;

  /// Adds [builder] to the extensions in this name space.
  void addExtension(ExtensionBuilder builder) {
    (_extensions ??= {}).add(builder);
  }

  @override
  void forEachLocalExtension(void Function(ExtensionBuilder member) f) {
    _extensions?.forEach(f);
  }
}

final class LibraryExtensions implements Extensions {
  final Set<ExtensionBuilder>? _extensions;

  LibraryExtensions({required Set<ExtensionBuilder> extensions})
    : _extensions = extensions;

  @override
  void forEachLocalExtension(void Function(ExtensionBuilder member) f) {
    _extensions?.forEach(f);
  }
}

abstract class BaseExtensionScope implements ExtensionScope {
  Extensions get _localExtensions;

  ExtensionScope? get _parent;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    _localExtensions.forEachLocalExtension(f);
    _parent?.forEachExtension(f);
  }

  @override
  String toString() => "$runtimeType()";
}

// Coverage-ignore(suite): Not run.
/// Implementation of [ExtensionScope] that includes extensions from a given
/// [Extensions] object.
///
/// This is used for expression compilation to give access to extensions
/// declared in the library that the expression should be resolved in.
class ParentLibraryExtensionScope extends BaseExtensionScope {
  @override
  final Extensions _localExtensions;

  @override
  final ExtensionScope? _parent;

  ParentLibraryExtensionScope(this._localExtensions, {ExtensionScope? parent})
    : _parent = parent;
}

class CompilationUnitImportExtensionScope extends BaseExtensionScope {
  final SourceCompilationUnit _compilationUnit;
  final Extensions _importNameSpace;

  CompilationUnitImportExtensionScope(
    this._compilationUnit,
    this._importNameSpace,
  );

  @override
  Extensions get _localExtensions => _importNameSpace;

  @override
  ExtensionScope? get _parent =>
      _compilationUnit.parentCompilationUnit?.prefixExtensionScope ??
      _compilationUnit.libraryBuilder.parentExtensionScope;
}

class CompilationUnitExtensionScope extends BaseExtensionScope {
  final SourceCompilationUnit _compilationUnit;

  @override
  final ExtensionScope? _parent;

  CompilationUnitExtensionScope(this._compilationUnit, {ExtensionScope? parent})
    : _parent = parent;

  @override
  Extensions get _localExtensions =>
      _compilationUnit.libraryBuilder.libraryExtensions;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtension].
  Set<ExtensionBuilder>? _extensions;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    if (_extensions == null) {
      Set<ExtensionBuilder> extensions = _extensions = <ExtensionBuilder>{};
      _parent?.forEachExtension(extensions.add);
      _localExtensions.forEachLocalExtension(extensions.add);
    }
    _extensions!.forEach(f);
  }
}

class CompilationUnitPrefixExtensionScope implements ExtensionScope {
  final ComputedNameSpace _prefixNameSpace;

  final ExtensionScope _parent;

  CompilationUnitPrefixExtensionScope(
    this._prefixNameSpace, {
    required ExtensionScope parent,
  }) : _parent = parent;

  /// Set of extension declarations in scope. This is computed lazily in
  /// [forEachExtension].
  Set<ExtensionBuilder>? _extensions;

  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {
    if (_extensions == null) {
      Set<ExtensionBuilder> extensions = _extensions = {};
      Iterator<PrefixBuilder> iterator = _prefixNameSpace.filteredIterator();
      while (iterator.moveNext()) {
        iterator.current.forEachExtension((e) {
          extensions.add(e);
        });
      }
      _parent.forEachExtension(extensions.add);
    }
    _extensions!.forEach(f);
  }

  @override
  String toString() => "$runtimeType()";
}
