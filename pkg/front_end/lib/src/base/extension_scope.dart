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

final class LibraryExtensions({
  required final Set<ExtensionBuilder>? _extensions,
}) implements Extensions {
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
class ParentLibraryExtensionScope(
  @override final Extensions _localExtensions, {
  @override final ExtensionScope? _parent,
}) extends BaseExtensionScope;

class CompilationUnitImportExtensionScope(
  final SourceCompilationUnit _compilationUnit,
  final Extensions _importNameSpace,
) extends BaseExtensionScope {
  @override
  Extensions get _localExtensions => _importNameSpace;

  @override
  ExtensionScope? get _parent =>
      _compilationUnit.parentCompilationUnit?.prefixExtensionScope ??
      _compilationUnit.libraryBuilder.parentExtensionScope;
}

class CompilationUnitExtensionScope(
  final SourceCompilationUnit _compilationUnit, {
  @override final ExtensionScope? _parent,
}) extends BaseExtensionScope {
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

class CompilationUnitPrefixExtensionScope(
  final ComputedNameSpace _prefixNameSpace, {
  required final ExtensionScope _parent,
}) implements ExtensionScope {
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
