// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';

/**
 * Create a [PrelinkedLibraryBuilder] corresponding to the given
 * [definingUnit], which should be the defining compilation unit for a library.
 * Compilation units referenced by the defining compilation unit via `part`
 * declarations will be retrieved using [getPart].  Public namespaces for
 * libraries referenced by the defining compilation unit via `import`
 * declarations (and files reachable from them via `part` and `export`
 * declarations) will be retrieved using [getImport].
 */
PrelinkedLibraryBuilder prelink(UnlinkedUnit definingUnit,
    GetPartCallback getPart, GetImportCallback getImport) {
  return new _Prelinker(definingUnit, getPart, getImport).prelink();
}

/**
 * Type of the callback used by the prelinker to obtain public namespace
 * information about libraries imported by the library to be prelinked (and
 * the transitive closure of parts and exports reachable from those libraries).
 * [relativeUri] should be interpreted relative to the defining compilation
 * unit of the library being prelinked.
 *
 * If no file exists at the given uri, `null` should be returned.
 */
typedef UnlinkedPublicNamespace GetImportCallback(String relativeUri);

/**
 * Type of the callback used by the prelinker to obtain unlinked summaries of
 * part files of the library to be prelinked.  [relaviteUri] should be
 * interpreted relative to the defining compilation unit of the library being
 * prelinked.
 *
 * If no file exists at the given uri, `null` should be returned.
 */
typedef UnlinkedUnit GetPartCallback(String relativeUri);

/**
 * A [NameFilter] represents the set of filtering rules implied by zero or more
 * combinators in an `export` or `import` statement.
 */
class NameFilter {
  /**
   * A [NameFilter] representing no filtering at all (i.e. no combinators).
   */
  static final NameFilter identity =
      new NameFilter._(hiddenNames: new Set<String>());

  /**
   * If this [NameFilter] accepts a finite number of names and hides all
   * others, the (possibly empty) set of names it accepts.  Otherwise `null`.
   */
  final Set<String> shownNames;

  /**
   * If [shownNames] is `null`, the (possibly empty) set of names not accepted
   * by this filter (all other names are accepted).  If [shownNames] is not
   * `null`, then [hiddenNames] will be `null`.
   */
  final Set<String> hiddenNames;

  /**
   * Create a [NameFilter] based on the given [combinator].
   */
  factory NameFilter.forCombinator(UnlinkedCombinator combinator) {
    if (combinator.shows.isNotEmpty) {
      return new NameFilter._(shownNames: combinator.shows.toSet());
    } else {
      return new NameFilter._(hiddenNames: combinator.hides.toSet());
    }
  }

  /**
   * Create a [NameFilter] based on the given (possibly empty) sequence of
   * [combinators].
   */
  factory NameFilter.forCombinators(List<UnlinkedCombinator> combinators) {
    NameFilter result = identity;
    for (UnlinkedCombinator combinator in combinators) {
      result = result.merge(new NameFilter.forCombinator(combinator));
    }
    return result;
  }

  const NameFilter._({this.shownNames, this.hiddenNames});

  /**
   * Determine if the given [name] is accepted by this [NameFilter].
   */
  bool accepts(String name) {
    if (shownNames != null) {
      return shownNames.contains(name);
    } else {
      return !hiddenNames.contains(name);
    }
  }

  /**
   * Produce a new [NameFilter] by combining this [NameFilter] with another
   * one.  The new [NameFilter] will only accept names that would be accepted
   * by both input filters.
   */
  NameFilter merge(NameFilter other) {
    if (shownNames != null) {
      if (other.shownNames != null) {
        return new NameFilter._(
            shownNames: shownNames.intersection(other.shownNames));
      } else {
        return new NameFilter._(
            shownNames: shownNames.difference(other.hiddenNames));
      }
    } else {
      if (other.shownNames != null) {
        return new NameFilter._(
            shownNames: other.shownNames.difference(hiddenNames));
      } else {
        return new NameFilter._(
            hiddenNames: hiddenNames.union(other.hiddenNames));
      }
    }
  }
}

/**
 * A [_Meaning] stores all the information necessary to find the declaration
 * referred to by a name in a namespace.
 */
class _Meaning {
  /**
   * Which unit in the dependent library contains the declared entity.
   */
  final int unit;

  /**
   * The kind of entity being referred to.
   */
  final PrelinkedReferenceKind kind;

  /**
   * Which of the dependencies of the library being prelinked contains the
   * declared entity.
   */
  final int dependency;

  /**
   * If the entity being referred to is generic, the number of type parameters
   * it accepts.  Otherwise zero.
   */
  final int numTypeParameters;

  _Meaning(this.unit, this.kind, this.dependency, this.numTypeParameters);

  /**
   * Encode this [_Meaning] as a [PrelinkedReference].
   */
  PrelinkedReferenceBuilder encode() {
    return encodePrelinkedReference(
        unit: unit,
        kind: kind,
        dependency: dependency,
        numTypeParameters: numTypeParameters);
  }
}

/**
 * A [_Meaning] representing a prefix introduced by an import directive.
 */
class _PrefixMeaning extends _Meaning {
  final Map<String, _Meaning> namespace = <String, _Meaning>{};

  _PrefixMeaning() : super(0, PrelinkedReferenceKind.prefix, 0, 0);
}

/**
 * Helper class containing temporary data structures needed to prelink a single
 * library.
 *
 * Note: throughout this class, a `null` value for a relative URI represents
 * the defining compilation unit of the library being prelinked.
 */
class _Prelinker {
  final UnlinkedUnit definingUnit;
  final GetPartCallback getPart;
  final GetImportCallback getImport;

  /**
   * Cache of values returned by [getImport].
   */
  final Map<String, UnlinkedPublicNamespace> importCache =
      <String, UnlinkedPublicNamespace>{};

  /**
   * Cache of values returned by [getPart].
   */
  final Map<String, UnlinkedUnit> partCache = <String, UnlinkedUnit>{};

  /**
   * Names defined inside the library being prelinked.
   */
  final Map<String, _Meaning> privateNamespace = <String, _Meaning>{
    '': new _Meaning(0, PrelinkedReferenceKind.classOrEnum, 0, 0)
  };

  /**
   * List of dependencies of the library being prelinked.  This will be output
   * to [PrelinkedLibrary.dependencies].
   */
  final List<PrelinkedDependencyBuilder> dependencies =
      <PrelinkedDependencyBuilder>[encodePrelinkedDependency()];

  /**
   * Map from the relative URI of a dependent library to the index of the
   * corresponding entry in [dependencies].
   */
  final Map<String, int> uriToDependency = <String, int>{null: 0};

  /**
   * List of public namespaces corresponding to each entry in [dependencies].
   */
  final List<Map<String, _Meaning>> dependencyToPublicNamespace =
      <Map<String, _Meaning>>[null];

  _Prelinker(this.definingUnit, this.getPart, this.getImport) {
    partCache[null] = definingUnit;
    importCache[null] = definingUnit.publicNamespace;
  }

  /**
   * Compute the public namespace for the library whose URI is reachable from
   * [definingUnit] via [relativeUri], by aggregating together public namespace
   * information from all of its parts.
   */
  Map<String, _Meaning> aggregatePublicNamespace(String relativeUri) {
    if (uriToDependency.containsKey(relativeUri)) {
      return dependencyToPublicNamespace[uriToDependency[relativeUri]];
    }
    assert(dependencies.length == dependencyToPublicNamespace.length);
    int dependency = dependencies.length;
    uriToDependency[relativeUri] = dependency;
    dependencies.add(encodePrelinkedDependency(uri: relativeUri));

    Map<String, _Meaning> aggregated = <String, _Meaning>{};

    List<String> unitUris = getUnitUris(relativeUri);
    for (int unitNum = 0; unitNum < unitUris.length; unitNum++) {
      String unitUri = unitUris[unitNum];
      UnlinkedPublicNamespace importedNamespace = getImportCached(unitUri);
      if (importedNamespace == null) {
        continue;
      }
      for (UnlinkedPublicName name in importedNamespace.names) {
        aggregated.putIfAbsent(
            name.name,
            () => new _Meaning(
                unitNum, name.kind, dependency, name.numTypeParameters));
      }
    }

    dependencyToPublicNamespace.add(aggregated);
    return aggregated;
  }

  /**
   * Compute the export namespace for the library whose URI is reachable from
   * [definingUnit] via [relativeUri], by aggregating together public namespace
   * information from the library and the transitive closure of its exports.
   */
  Map<String, _Meaning> computeExportNamespace(String relativeUri) {
    Map<String, _Meaning> exportNamespace =
        aggregatePublicNamespace(relativeUri);
    void chaseExports(
        NameFilter filter, String relativeUri, Set<String> seenUris) {
      if (seenUris.add(relativeUri)) {
        UnlinkedPublicNamespace exportedNamespace =
            getImportCached(relativeUri);
        if (exportedNamespace != null) {
          for (UnlinkedExportPublic export in exportedNamespace.exports) {
            String exportUri = resolveUri(relativeUri, export.uri);
            aggregatePublicNamespace(exportUri)
                .forEach((String name, _Meaning meaning) {
              if (filter.accepts(name) && !exportNamespace.containsKey(name)) {
                exportNamespace[name] = meaning;
              }
            });
            chaseExports(
                filter.merge(new NameFilter.forCombinators(export.combinators)),
                exportUri,
                seenUris);
          }
        }
        seenUris.remove(relativeUri);
      }
    }
    chaseExports(NameFilter.identity, relativeUri, new Set<String>());
    return exportNamespace;
  }

  /**
   * Extract all the names defined in [unit] (which is the [unitNum]th unit in
   * the library being prelinked) and store them in [privateNamespace].
   * Excludes names introduced by `import` statements.
   */
  void extractPrivateNames(UnlinkedUnit unit, int unitNum) {
    for (UnlinkedClass cls in unit.classes) {
      privateNamespace.putIfAbsent(
          cls.name,
          () => new _Meaning(unitNum, PrelinkedReferenceKind.classOrEnum, 0,
              cls.typeParameters.length));
    }
    for (UnlinkedEnum enm in unit.enums) {
      privateNamespace.putIfAbsent(
          enm.name,
          () =>
              new _Meaning(unitNum, PrelinkedReferenceKind.classOrEnum, 0, 0));
    }
    for (UnlinkedExecutable executable in unit.executables) {
      privateNamespace.putIfAbsent(
          executable.name,
          () => new _Meaning(unitNum, PrelinkedReferenceKind.other, 0,
              executable.typeParameters.length));
    }
    for (UnlinkedTypedef typedef in unit.typedefs) {
      privateNamespace.putIfAbsent(
          typedef.name,
          () => new _Meaning(unitNum, PrelinkedReferenceKind.typedef, 0,
              typedef.typeParameters.length));
    }
    for (UnlinkedVariable variable in unit.variables) {
      privateNamespace.putIfAbsent(variable.name,
          () => new _Meaning(unitNum, PrelinkedReferenceKind.other, 0, 0));
    }
  }

  /**
   * Filter the export namespace for the library whose URI is reachable from
   * [definingUnit] via [relativeUri], retaining only those names accepted by
   * [combinators], and store the resulting names in [result].  Names that
   * already exist in [result] are not overwritten.
   */
  void filterExportNamespace(String relativeUri,
      List<UnlinkedCombinator> combinators, Map<String, _Meaning> result) {
    Map<String, _Meaning> exportNamespace = computeExportNamespace(relativeUri);
    NameFilter filter = new NameFilter.forCombinators(combinators);
    exportNamespace.forEach((String name, _Meaning meaning) {
      if (filter.accepts(name) && !result.containsKey(name)) {
        result[name] = meaning;
      }
    });
  }

  /**
   * Wrapper around [getImport] that caches the return value in [importCache].
   */
  UnlinkedPublicNamespace getImportCached(String relativeUri) {
    return importCache.putIfAbsent(relativeUri, () => getImport(relativeUri));
  }

  /**
   * Wrapper around [getPart] that caches the return value in [partCache] and
   * updates [importCache] appropriately.
   */
  UnlinkedUnit getPartCached(String relativeUri) {
    return partCache.putIfAbsent(relativeUri, () {
      UnlinkedUnit unit = getPart(relativeUri);
      importCache[relativeUri] = unit?.publicNamespace;
      return unit;
    });
  }

  /**
   * Compute the set of relative URIs of all the compilation units in the
   * library whose URI is reachable from [definingUnit] via [relativeUri].
   */
  List<String> getUnitUris(String relativeUri) {
    List<String> result = <String>[relativeUri];
    UnlinkedPublicNamespace publicNamespace = getImportCached(relativeUri);
    if (publicNamespace != null) {
      result.addAll(publicNamespace.parts
          .map((String uri) => resolveUri(relativeUri, uri)));
    }
    return result;
  }

  /**
   * Process a single `import` declaration in the library being prelinked.  The
   * return value is the index of the imported library in [dependencies].
   */
  int handleImport(UnlinkedImport import) {
    String uri = import.isImplicit ? 'dart:core' : import.uri;
    Map<String, _Meaning> targetNamespace = null;
    if (import.prefixReference != 0) {
      // The name introduced by an import declaration can't have a prefix of
      // its own.
      assert(
          definingUnit.references[import.prefixReference].prefixReference == 0);
      String prefix = definingUnit.references[import.prefixReference].name;
      _Meaning prefixMeaning = privateNamespace[prefix];
      if (prefixMeaning is _PrefixMeaning) {
        targetNamespace = prefixMeaning.namespace;
      }
    } else {
      targetNamespace = privateNamespace;
    }
    filterExportNamespace(uri, import.combinators, targetNamespace);
    return uriToDependency[uri];
  }

  /**
   * Produce a [PrelinkedUnit] for the given [unit], by resolving every one of
   * its references.
   */
  PrelinkedUnitBuilder linkUnit(UnlinkedUnit unit) {
    if (unit == null) {
      return encodePrelinkedUnit();
    }
    Map<int, Map<String, _Meaning>> prefixNamespaces =
        <int, Map<String, _Meaning>>{};
    List<PrelinkedReferenceBuilder> references = <PrelinkedReferenceBuilder>[];
    for (int i = 0; i < unit.references.length; i++) {
      UnlinkedReference reference = unit.references[i];
      Map<String, _Meaning> namespace;
      if (reference.prefixReference != 0) {
        // Prefix references must always point backward.
        assert(reference.prefixReference < i);
        namespace = prefixNamespaces[reference.prefixReference];
        // Prefix references must always point to proper prefixes.
        assert(namespace != null);
      } else {
        namespace = privateNamespace;
      }
      _Meaning meaning = namespace[reference.name];
      if (meaning != null) {
        if (meaning is _PrefixMeaning) {
          prefixNamespaces[i] = meaning.namespace;
        }
        references.add(meaning.encode());
      } else {
        references.add(
            encodePrelinkedReference(kind: PrelinkedReferenceKind.unresolved));
      }
    }
    return encodePrelinkedUnit(references: references);
  }

  /**
   * Form the [PrelinkedLibrary] for the [definingUnit] that was passed to the
   * constructor.
   */
  PrelinkedLibraryBuilder prelink() {
    // Gather up the unlinked summaries for all the compilation units in the
    // library.
    List<UnlinkedUnit> units = getUnitUris(null).map(getPartCached).toList();

    // Create the private namespace for the library by gathering all the names
    // defined in its compilation units.
    for (int unitNum = 0; unitNum < units.length; unitNum++) {
      UnlinkedUnit unit = units[unitNum];
      if (unit != null) {
        extractPrivateNames(unit, unitNum);
      }
    }

    // Fill in prefixes defined in import declarations.
    for (UnlinkedImport import in units[0].imports) {
      if (import.prefixReference != 0) {
        privateNamespace.putIfAbsent(
            units[0].references[import.prefixReference].name,
            () => new _PrefixMeaning());
      }
    }

    // Fill in imported names.
    List<int> importDependencies =
        definingUnit.imports.map(handleImport).toList();

    // Link each compilation unit.
    List<PrelinkedUnitBuilder> linkedUnits = units.map(linkUnit).toList();

    return encodePrelinkedLibrary(
        units: linkedUnits,
        dependencies: dependencies,
        importDependencies: importDependencies);
  }

  /**
   * Resolve [relativeUri] relative to [sourceUri].  Works correctly if
   * [sourceUri] is also relative.
   */
  String resolveUri(String sourceUri, String relativeUri) {
    if (sourceUri == null) {
      return relativeUri;
    } else {
      return Uri.parse(sourceUri).resolve(relativeUri).toString();
    }
  }
}
