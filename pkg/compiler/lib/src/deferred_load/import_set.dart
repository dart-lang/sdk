// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'output_unit.dart';

import '../elements/entities.dart';
import '../util/maplet.dart';

/// Indirectly represents a deferred import in an [ImportSet].
///
/// We could directly store the [declaration] in [ImportSet], but adding this
/// class makes some of the import set operations more efficient.
class _DeferredImport {
  final ImportEntity declaration;

  /// Canonical index associated with [declaration]. This is used to efficiently
  /// implement [ImportSetLattice.union].
  final int index;

  _DeferredImport(this.declaration, this.index);
}

/// A compact lattice representation of import sets and subsets.
///
/// We use a graph of nodes to represent elements of the lattice, but only
/// create new nodes on-demand as they are needed by the deferred loading
/// algorithm.
///
/// The constructions of nodes is carefully done by storing imports in a
/// specific order. This ensures that we have a unique and canonical
/// representation for each subset.
class ImportSetLattice {
  /// A map of [ImportEntity] to its initial [ImportSet].
  final Map<ImportEntity, ImportSet> initialSets = {};

  /// Index of deferred imports that defines the canonical order used by the
  /// operations below.
  Map<ImportEntity, _DeferredImport> _importIndex = {};

  /// The canonical instance representing the empty import set.
  ImportSet _emptySet = ImportSet.empty();

  /// The [ImportSet] representing the main output unit.
  ImportSet _mainSet;
  ImportSet get mainSet {
    assert(_mainSet != null && _mainSet.unit != null);
    return _mainSet;
  }

  /// Get the smallest [ImportSet] that contains [import]. When
  /// unconstrained, this [ImportSet] is a singleton [ImportSet] containing
  /// only the supplied [ImportEntity]. However, when constrained the returned
  /// [ImportSet] may contain multiple [ImportEntity]s.
  ImportSet initialSetOf(ImportEntity import) =>
      initialSets[import] ??= _singleton(import);

  /// A private method to generate a true singleton [ImportSet] for a given
  /// [ImportEntity].
  ImportSet _singleton(ImportEntity import) {
    // Ensure we have import in the index.
    return _emptySet._add(_wrap(import));
  }

  /// A helper method to convert a [Set<ImportEntity>] to an [ImportSet].
  ImportSet setOfImportsToImportSet(Set<ImportEntity> setOfImports) {
    List<_DeferredImport> imports = setOfImports.map(_wrap).toList();
    imports.sort((a, b) => a.index - b.index);
    var result = _emptySet;
    for (var import in imports) {
      result = result._add(import);
    }
    return result;
  }

  /// Builds the [mainSet] which contains transitions for all other deferred
  /// imports as well as [mainImport].
  void buildMainSet(ImportEntity mainImport, OutputUnit mainOutputUnit,
      Iterable<ImportEntity> allDeferredImports) {
    _mainSet = setOfImportsToImportSet({mainImport, ...allDeferredImports});
    _mainSet.unit = mainOutputUnit;
    initialSets[mainImport] = _mainSet;
  }

  /// Initializes the [initialSet] map.
  void buildInitialSets(
      Map<ImportEntity, Set<ImportEntity>> initialTransitions) {
    initialTransitions.forEach((import, setOfImports) {
      initialSets[import] = setOfImportsToImportSet(setOfImports);
    });
  }

  /// Get the import set that includes the union of [a] and [b].
  ImportSet union(ImportSet a, ImportSet b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;

    // Create the union by merging the imports in canonical order. The sets are
    // basically lists linked by the `_previous` field in reverse order. We do a
    // merge-like scan 'backwards' removing the biggest element until we hit an
    // empty set or a common prefix, and the add the 'merge-sorted' elements
    // back onto the prefix.
    ImportSet result;
    // 'removed' imports in decreasing canonical order.
    List<_DeferredImport> imports = [];

    while (true) {
      if (a.isEmpty) {
        result = b;
        break;
      }
      if (b.isEmpty || identical(a, b)) {
        result = a;
        break;
      }
      if (a._import.index > b._import.index) {
        imports.add(a._import);
        a = a._previous;
      } else if (b._import.index > a._import.index) {
        imports.add(b._import);
        b = b._previous;
      } else {
        assert(identical(a._import, b._import));
        imports.add(a._import);
        a = a._previous;
        b = b._previous;
      }
    }

    // Add merged elements back in reverse order. It is tempting to pop them off
    // with `removeLast()` but that causes measurable shrinking reallocations.
    for (int i = imports.length - 1; i >= 0; i--) {
      result = result._add(imports[i]);
    }
    return result;
  }

  /// Get the index for an [import] according to the canonical order.
  _DeferredImport _wrap(ImportEntity import) {
    return _importIndex[import] ??=
        _DeferredImport(import, _importIndex.length);
  }
}

/// A canonical set of deferred imports.
class ImportSet {
  /// Last element added to set.
  ///
  /// This set comprises [_import] appended onto [_previous]. *Note*: [_import]
  /// is the last element in the set in the canonical order imposed by
  /// [ImportSetLattice].
  final _DeferredImport _import; // `null` for empty ImportSet
  /// The set containing all previous elements.
  final ImportSet _previous;
  final int length;

  bool get isEmpty => _import == null;
  bool get isNotEmpty => _import != null;

  /// Returns an iterable over the imports in this set in canonical order.
  Iterable<_DeferredImport> collectImports() {
    List<_DeferredImport> result = [];
    ImportSet current = this;
    while (current.isNotEmpty) {
      result.add(current._import);
      current = current._previous;
    }
    assert(result.length == this.length);
    return result.reversed;
  }

  /// Links to other import sets in the lattice by adding one import.
  final Map<_DeferredImport, ImportSet> _transitions = Maplet();

  ImportSet.empty()
      : _import = null,
        _previous = null,
        length = 0;

  ImportSet(this._import, this._previous, this.length);

  /// The output unit corresponding to this set of imports, if any.
  OutputUnit unit;

  /// Create an import set that adds [import] to all the imports on this set.
  /// This assumes that import's canonical order comes after all imports in
  /// this current set. This should only be called from [ImportSetLattice],
  /// since it is where we preserve this invariant.
  ImportSet _add(_DeferredImport import) {
    assert(_import == null || import.index > _import.index);
    return _transitions[import] ??= ImportSet(import, this, length + 1);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('ImportSet(size: $length, ');
    for (var import in collectImports()) {
      sb.write('${import.declaration.name} ');
    }
    sb.write(')');
    return '$sb';
  }
}
