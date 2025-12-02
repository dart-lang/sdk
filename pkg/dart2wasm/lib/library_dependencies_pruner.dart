// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/library_index.dart';

/// If a deferred library import has this name prefix it isn't used to load
/// anything. It only serves to maintain that any [CheckLibraryIsLoaded] throws
/// if the [LoadLibrary] call was not called.
const unusedDeferredLibraryPrefix = 'unused-';

/// Prunes [Library.dependencies] to contain precisely those imports needed.
///
/// Dart2wasm only uses library dependencies for one purpose, namely for
/// computing deferred loading units. This computation is done based on the
/// import graph and the granularity is on a library level.
///
/// We make the following overvations:
///
///   a) Using a type from a import
///     -> The main wasm module has all Dart runtime type information atm
///     -> No need to import a library to use classes from it in types.
///
///   b) Using a constant from an import
///     -> If we use a [InstanceConstant] / [TearOffConstant] in a library then
///        we have to ensure the enclosing library of the
///        [InstanceConstant.classNode] / [TearOffConstant.target] is imported.
///     -> This ensures that the code for closure/method is available when
///        invoking it.
///     -> Any other constant doesn't require an import.
///
///   c) Using static elements from an import
///     -> If we invoke a constructor, a static method, static getter, super
///        constructor, etc we need to import the target's enclosing library.
///     -> This will guarantee we have the code for target loaded when we perform
///        the call.
///
///   d) Instance/Dynamic invocations, other uses of [Reference]s
///     -> Does not require an import of the [Reference]s enclosing library.
///     -> We have sound type system: If the call is executed we know that the
///        receiver was allocated (and whoever allocated it has ensured - via c)
///        above - that the code for methods of the receiver is loaded).
///
/// So we establish the following invariants
///
///   * We only have imports for [Reference]s which are used for "static"-like
///     calls
///
///   * We import the library containing the definition of a [Reference] and not
///     e.g. a library that may re-export it
///
///   * If a [Reference] was usable via a deferred import (possibly via
///     a deferred library that re-exported the [Reference]) we ensure the newly
///     inserted import will also be deferred.
///
/// The transform will
///
///   * prune [Library.dependencies] to be exact, i.e. have a import iff
///     something is used from the imported library
///
///   * will remove all exports
///
///   * may insert more precise [LoadLibrary]/[CheckLibraryIsLoaded] if we don't
///     use a deferred library directly but things it re-exported
///
void pruneLibraryDependencies(LibraryIndex libraryIndex, Component component) {
  final constantToLibrarySet = _ConstantToLibrarySet();
  for (final library in component.libraries) {
    final usedLibraries =
        _Collector(library, constantToLibrarySet).usedLibraries;
    _ImportPruner(libraryIndex, usedLibraries, library);
  }
  for (final library in component.libraries) {
    library.dependencies.removeWhere((dep) {
      if (dep.isExport) {
        dep.parent = null;
        return true;
      }
      return false;
    });
  }
}

class _ImportPruner extends Transformer {
  final LibraryIndex libraryIndex;

  final Set<Library> usedLibraries;
  final Library library;
  final additionalDeferredImports =
      <LibraryDependency, List<LibraryDependency>>{};

  late final futureImmediate =
      libraryIndex.getConstructor('dart:async', '_Future', 'immediate');

  _ImportPruner(this.libraryIndex, this.usedLibraries, this.library) {
    // Step 1) Prune existing library imports.

    // The set of libraries that we need to import and are already covered via
    // an existing library import.
    final librariesOfExistingImports = <Library>{};

    // Maps a library to all the deferred imports that made this library
    // available.
    final libraryToDeferredImports = <Library, List<LibraryDependency>>{};

    // The new set of imports (possibly smaller - removing unused dependencies,
    // possibly larger - adding used but not yet imported dependencies).
    final prunedDependencies = <LibraryDependency>[];
    for (final dep in library.dependencies) {
      if (dep.isExport) {
        prunedDependencies.add(dep);
        continue;
      }
      if (usedLibraries.contains(dep.targetLibrary)) {
        librariesOfExistingImports.add(dep.targetLibrary);
        prunedDependencies.add(dep);
        continue;
      }

      if (dep.isDeferred) {
        // Although the deferred dependency isn't used, for making sure
        // [CheckLibraryIsLoaded] nodes throw if no preceding
        // [LoadLibrary] was called we have to maintain a dummy import. This
        // will also ensure the exception mentions the right name.
        prunedDependencies.add(dep);
        dep.name = '$unusedDeferredLibraryPrefix${dep.name!}';

        // Loop over all libraries available via the deferred import that are
        // used. The transformer will then issue individual [LoadLibrary] calls
        // to them.
        for (final available in _transitiveLibrarySet(dep.targetLibrary)) {
          if (usedLibraries.contains(available)) {
            libraryToDeferredImports.putIfAbsent(available, () => []).add(dep);
          }
        }
        continue;
      }

      // The [dep] isn't directly used, remove it.
      assert(!dep.isDeferred);
      dep.parent = null;
    }
    library.dependencies = prunedDependencies;

    // Step 2) Add missing imports.
    for (final used in usedLibraries) {
      // Maybe we already import the [used] library.
      if (librariesOfExistingImports.contains(used)) {
        continue;
      }

      // Never emit a library import to `dart:core`, it's special.
      if (used.importUri.scheme == 'dart' && used.importUri.path == 'core') {
        continue;
      }

      // We need to inject a new import of the [used] library.
      final oldDeferredImports = libraryToDeferredImports[used];
      if (oldDeferredImports == null) {
        // This library was not accessible via old deferred imports, so we emit
        // a normal import.
        library.addDependency(LibraryDependency.import(used));
        continue;
      }

      // The library was accessible (via a re-export) from an deferred
      // import. Let's make a new deferred import for that particular library.
      final newDep = LibraryDependency.deferredImport(
          used, 'PreciseDeferredDep-${used.dependencies.length}');
      library.addDependency(newDep);
      for (final oldImport in oldDeferredImports) {
        // Any [LoadLibrary] or [CheckLibraryIsLoaded] node that operated on the
        // old (unused) deferred import needs to cover the [newDep] (possibly in
        // addition to the existing dep (if used) and others).
        additionalDeferredImports.putIfAbsent(oldImport, () => []).add(newDep);
      }
    }

    // We only have to transform the body of the library if any [LoadLibrary] or
    // [CheckLibraryIsLoaded] has to be modified.
    if (additionalDeferredImports.isNotEmpty) {
      library.transformChildren(this);
    }
  }

  @override
  TreeNode visitLoadLibrary(LoadLibrary node) {
    node = super.visitLoadLibrary(node) as LoadLibrary;
    final additional = additionalDeferredImports[node.import];
    if (additional == null) return node;
    return BlockExpression(
        Block([
          // This may be a dummy/unused which we only omit for throwing correct
          // errors if a access (e.g. of a type) is used before the load call.
          ExpressionStatement(node),

          for (final replacement in additional.skip(1))
            ExpressionStatement(LoadLibrary(replacement)),
        ]),
        LoadLibrary(additional.last));
  }

  @override
  TreeNode visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    node = super.visitCheckLibraryIsLoaded(node) as CheckLibraryIsLoaded;
    final additional = additionalDeferredImports[node.import];
    if (additional == null) return node;
    return BlockExpression(
        Block([
          // This may be a dummy/unused which we only omit for throwing correct
          // errors if a access (e.g. of a type) is used before the load call.
          ExpressionStatement(node),

          for (final replacement in additional.skip(1))
            ExpressionStatement(CheckLibraryIsLoaded(replacement)),
        ]),
        CheckLibraryIsLoaded(additional.last));
  }
}

/// Traverses the AST of a [Library] and collects the set of libraries we need
/// to import due to accessing elements "statically" (see
/// [pruneLibraryDependencies] for more information)
class _Collector extends RecursiveVisitor {
  final Library library;
  final _ConstantToLibrarySet constantToLibrarySet;

  /// The libraries that need to be imported.
  final Set<Library> usedLibraries = {};

  _Collector(this.library, this.constantToLibrarySet) {
    library.accept(this);
  }

  @override
  void visitStaticGet(StaticGet node) {
    super.visitStaticGet(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitStaticSet(StaticSet node) {
    super.visitStaticSet(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    super.visitConstructorInvocation(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    super.visitSuperInitializer(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    super.visitRedirectingInitializer(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    super.visitStaticTearOff(node);
    addLibrary(node.target.enclosingLibrary);
  }

  @override
  void defaultDartType(DartType node) {
    // Ignore due to compiler always able to construct runtime type objects when
    // needed (see also [pruneLibraryDependencies]).
  }

  @override
  void visitSupertype(Supertype node) {
    // Ignore due to compiler always able to construct runtime type objects when
    // needed (see also [pruneLibraryDependencies]).
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    usedLibraries.addAll(constantToLibrarySet.librariesFor(node.constant));
  }

  void addLibrary(Library used) {
    if (used != library) {
      usedLibraries.add(used);
    }
  }
}

class _ConstantToLibrarySet {
  final _constantToTransitiveLibraries = <Constant, Set<Library>>{};

  /// Collects the set of libraries one needs to import when accessing
  /// [constant].
  ///
  /// This include enclosing libraries of all [InstanceConstant]s
  /// and [TearOffConstant]s of the transitive constant graph of [constant].
  Set<Library> librariesFor(Constant constant) {
    final existing = _constantToTransitiveLibraries[constant];
    if (existing != null) return existing;

    final transitiveLibraries = <Library>{
      if (constant is InstanceConstant) constant.classNode.enclosingLibrary,
      if (constant is TearOffConstant) constant.target.enclosingLibrary,
      // Collect all transitive libraries for direct child constants.
      for (final childConstant
          in _ChildConstantCollector.directChildrenOf(constant))
        ...librariesFor(childConstant),
    };

    return _constantToTransitiveLibraries[constant] =
        transitiveLibraries.isEmpty ? const <Library>{} : transitiveLibraries;
  }
}

class _ChildConstantCollector extends RecursiveVisitor {
  /// Returns the set of constants referred to by the (possibly composed)
  /// [constant].
  static Set<Constant> directChildrenOf(Constant constant) {
    final children = <Constant>{};
    constant.visitChildren(_ChildConstantCollector._(children));
    return children;
  }

  final Set<Constant> _directChildren;
  _ChildConstantCollector._(this._directChildren);

  @override
  void defaultConstantReference(Constant node) {
    _directChildren.add(node);
  }
}

/// Collects the set of libraries transitively imported via importing [library].
///
/// This includes [library] and any other library it transitively re-exports.
Set<Library> _transitiveLibrarySet(Library library) {
  final transitiveLibrarySet = <Library>{library};
  final worklist = <Library>[library];
  while (worklist.isNotEmpty) {
    final toBeExpanded = worklist.removeLast();
    assert(transitiveLibrarySet.contains(toBeExpanded));
    for (final dep in toBeExpanded.dependencies) {
      if (dep.isExport) {
        final reExportedLibrary = dep.targetLibrary;
        if (transitiveLibrarySet.add(reExportedLibrary)) {
          worklist.add(reExportedLibrary);
        }
      }
    }
  }
  return transitiveLibrarySet;
}
