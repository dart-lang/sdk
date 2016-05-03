// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/name_filter.dart';

/**
 * Create a [LinkedLibraryBuilder] corresponding to the given
 * [definingUnit], which should be the defining compilation unit for a library.
 * Compilation units referenced by the defining compilation unit via `part`
 * declarations will be retrieved using [getPart].  Public namespaces for
 * libraries referenced by the defining compilation unit via `import`
 * declarations (and files reachable from them via `part` and `export`
 * declarations) will be retrieved using [getImport].
 */
LinkedLibraryBuilder prelink(UnlinkedUnit definingUnit, GetPartCallback getPart,
    GetImportCallback getImport) {
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
 * part files of the library to be prelinked.  [relativeUri] should be
 * interpreted relative to the defining compilation unit of the library being
 * prelinked.
 *
 * If no file exists at the given uri, `null` should be returned.
 */
typedef UnlinkedUnit GetPartCallback(String relativeUri);

/**
 * A [_Meaning] representing a class.
 */
class _ClassMeaning extends _Meaning {
  final Map<String, _Meaning> namespace;

  _ClassMeaning(int unit, int dependency, int numTypeParameters, this.namespace)
      : super(unit, ReferenceKind.classOrEnum, dependency, numTypeParameters);
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
  final ReferenceKind kind;

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
 * Encode this [_Meaning] as a [LinkedExportName], using the given [name].
 */
  LinkedExportName encodeExportName(String name) {
    return new LinkedExportNameBuilder(
        name: name, dependency: dependency, unit: unit, kind: kind);
  }

/**
   * Encode this [_Meaning] as a [LinkedReference].
   */
  LinkedReferenceBuilder encodeReference() {
    return new LinkedReferenceBuilder(
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

  _PrefixMeaning() : super(0, ReferenceKind.prefix, 0, 0);
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
    'dynamic': new _Meaning(0, ReferenceKind.classOrEnum, 0, 0),
    'void': new _Meaning(0, ReferenceKind.classOrEnum, 0, 0)
  };

  /**
   * List of dependencies of the library being prelinked.  This will be output
   * to [LinkedLibrary.dependencies].
   */
  final List<LinkedDependencyBuilder> dependencies = <LinkedDependencyBuilder>[
    new LinkedDependencyBuilder()
  ];

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
    List<String> unitUris = getUnitUris(relativeUri);
    LinkedDependencyBuilder linkedDependency = new LinkedDependencyBuilder(
        uri: relativeUri, parts: unitUris.sublist(1));
    dependencies.add(linkedDependency);

    Map<String, _Meaning> aggregated = <String, _Meaning>{};

    for (int unitNum = 0; unitNum < unitUris.length; unitNum++) {
      String unitUri = unitUris[unitNum];
      UnlinkedPublicNamespace importedNamespace = getImportCached(unitUri);
      if (importedNamespace == null) {
        continue;
      }
      for (UnlinkedPublicName name in importedNamespace.names) {
        aggregated.putIfAbsent(name.name, () {
          if (name.kind == ReferenceKind.classOrEnum) {
            Map<String, _Meaning> namespace = <String, _Meaning>{};
            name.members.forEach((executable) {
              namespace[executable.name] = new _Meaning(
                  unitNum, executable.kind, 0, executable.numTypeParameters);
            });
            return new _ClassMeaning(
                unitNum, dependency, name.numTypeParameters, namespace);
          }
          return new _Meaning(
              unitNum, name.kind, dependency, name.numTypeParameters);
        });
      }
    }

    dependencyToPublicNamespace.add(aggregated);
    return aggregated;
  }

  /**
   * Compute the export namespace for the library whose URI is reachable from
   * [definingUnit] via [relativeUri], by aggregating together public namespace
   * information from the library and the transitive closure of its exports.
   *
   * If [relativeUri] is `null` (meaning the export namespace of [definingUnit]
   * should be computed), then names defined in [definingUnit] are ignored.
   */
  Map<String, _Meaning> computeExportNamespace(String relativeUri) {
    Map<String, _Meaning> exportNamespace = relativeUri == null
        ? <String, _Meaning>{}
        : aggregatePublicNamespace(relativeUri);
    void chaseExports(
        NameFilter filter, String relativeUri, Set<String> seenUris) {
      if (seenUris.add(relativeUri)) {
        UnlinkedPublicNamespace exportedNamespace =
            getImportCached(relativeUri);
        if (exportedNamespace != null) {
          for (UnlinkedExportPublic export in exportedNamespace.exports) {
            String exportUri = resolveUri(relativeUri, export.uri);
            NameFilter newFilter = filter.merge(
                new NameFilter.forUnlinkedCombinators(export.combinators));
            aggregatePublicNamespace(exportUri)
                .forEach((String name, _Meaning meaning) {
              if (newFilter.accepts(name) &&
                  !exportNamespace.containsKey(name)) {
                exportNamespace[name] = meaning;
              }
            });
            chaseExports(newFilter, exportUri, seenUris);
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
      privateNamespace.putIfAbsent(cls.name, () {
        Map<String, _Meaning> namespace = <String, _Meaning>{};
        cls.fields.forEach((field) {
          if (field.isStatic && field.isConst) {
            namespace[field.name] =
                new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0);
          }
        });
        cls.executables.forEach((executable) {
          ReferenceKind kind = null;
          if (executable.kind == UnlinkedExecutableKind.constructor) {
            kind = ReferenceKind.constructor;
          } else if (executable.kind ==
                  UnlinkedExecutableKind.functionOrMethod &&
              executable.isStatic) {
            kind = ReferenceKind.method;
          } else if (executable.kind == UnlinkedExecutableKind.getter &&
              executable.isStatic) {
            kind = ReferenceKind.propertyAccessor;
          }
          if (kind != null && executable.name.isNotEmpty) {
            namespace[executable.name] = new _Meaning(
                unitNum, kind, 0, executable.typeParameters.length);
          }
        });
        return new _ClassMeaning(
            unitNum, 0, cls.typeParameters.length, namespace);
      });
    }
    for (UnlinkedEnum enm in unit.enums) {
      privateNamespace.putIfAbsent(enm.name, () {
        Map<String, _Meaning> namespace = <String, _Meaning>{};
        enm.values.forEach((UnlinkedEnumValue value) {
          namespace[value.name] =
              new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0);
        });
        namespace['values'] =
            new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0);
        return new _ClassMeaning(unitNum, 0, 0, namespace);
      });
    }
    for (UnlinkedExecutable executable in unit.executables) {
      privateNamespace.putIfAbsent(
          executable.name,
          () => new _Meaning(
              unitNum,
              executable.kind == UnlinkedExecutableKind.functionOrMethod
                  ? ReferenceKind.topLevelFunction
                  : ReferenceKind.topLevelPropertyAccessor,
              0,
              executable.typeParameters.length));
    }
    for (UnlinkedTypedef typedef in unit.typedefs) {
      privateNamespace.putIfAbsent(
          typedef.name,
          () => new _Meaning(unitNum, ReferenceKind.typedef, 0,
              typedef.typeParameters.length));
    }
    for (UnlinkedVariable variable in unit.variables) {
      privateNamespace.putIfAbsent(
          variable.name,
          () => new _Meaning(
              unitNum, ReferenceKind.topLevelPropertyAccessor, 0, 0));
      if (!(variable.isConst || variable.isFinal)) {
        privateNamespace.putIfAbsent(
            variable.name + '=',
            () => new _Meaning(
                unitNum, ReferenceKind.topLevelPropertyAccessor, 0, 0));
      }
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
    NameFilter filter = new NameFilter.forUnlinkedCombinators(combinators);
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
   * Produce a [LinkedUnit] for the given [unit], by resolving every one of
   * its references.
   */
  LinkedUnitBuilder linkUnit(UnlinkedUnit unit) {
    if (unit == null) {
      return new LinkedUnitBuilder();
    }
    Map<int, Map<String, _Meaning>> prefixNamespaces =
        <int, Map<String, _Meaning>>{};
    List<LinkedReferenceBuilder> references = <LinkedReferenceBuilder>[];
    for (int i = 0; i < unit.references.length; i++) {
      UnlinkedReference reference = unit.references[i];
      Map<String, _Meaning> namespace;
      if (reference.prefixReference == 0) {
        namespace = privateNamespace;
      } else {
        // Prefix references must always point backward.
        assert(reference.prefixReference < i);
        namespace = prefixNamespaces[reference.prefixReference];
        // Expressions like 'a.b.c.d' cannot be prelinked.
        namespace ??= const <String, _Meaning>{};
      }
      _Meaning meaning = namespace[reference.name];
      if (meaning != null) {
        if (meaning is _PrefixMeaning) {
          prefixNamespaces[i] = meaning.namespace;
        } else if (meaning is _ClassMeaning) {
          prefixNamespaces[i] = meaning.namespace;
        }
        references.add(meaning.encodeReference());
      } else {
        references
            .add(new LinkedReferenceBuilder(kind: ReferenceKind.unresolved));
      }
    }
    return new LinkedUnitBuilder(references: references);
  }

  /**
   * Form the [LinkedLibrary] for the [definingUnit] that was passed to the
   * constructor.
   */
  LinkedLibraryBuilder prelink() {
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

    // Fill in exported names.  This must be done before filling in prefixes
    // defined in import declarations, because prefixes shouldn't shadow
    // exports.
    List<LinkedExportNameBuilder> exportNames = <LinkedExportNameBuilder>[];
    computeExportNamespace(null).forEach((String name, _Meaning meaning) {
      if (!privateNamespace.containsKey(name)) {
        exportNames.add(meaning.encodeExportName(name));
      }
    });

    // Fill in prefixes defined in import declarations.
    for (UnlinkedImport import in units[0].imports) {
      if (import.prefixReference != 0) {
        privateNamespace.putIfAbsent(
            units[0].references[import.prefixReference].name,
            () => new _PrefixMeaning());
      }
    }

    // Fill in imported and exported names.
    List<int> importDependencies =
        definingUnit.imports.map(handleImport).toList();
    List<int> exportDependencies = definingUnit.publicNamespace.exports
        .map((UnlinkedExportPublic exp) => uriToDependency[exp.uri])
        .toList();

    // Link each compilation unit.
    List<LinkedUnitBuilder> linkedUnits = units.map(linkUnit).toList();

    return new LinkedLibraryBuilder(
        units: linkedUnits,
        dependencies: dependencies,
        importDependencies: importDependencies,
        exportDependencies: exportDependencies,
        exportNames: exportNames,
        numPrelinkedDependencies: dependencies.length);
  }

  /**
   * Resolve [relativeUri] relative to [sourceUri].  Works correctly if
   * [sourceUri] is also relative.
   */
  String resolveUri(String sourceUri, String relativeUri) {
    if (sourceUri == null) {
      return relativeUri;
    } else {
      return resolveRelativeUri(Uri.parse(sourceUri), Uri.parse(relativeUri))
          .toString();
    }
  }
}
