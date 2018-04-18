// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/name_filter.dart';

/**
 * Create a [LinkedLibraryBuilder] corresponding to the given [definingUnitUri]
 * and [definingUnit], which should be the defining compilation unit for a
 * library. Compilation units referenced by the defining compilation unit via
 * `part` declarations will be retrieved using [getPart].  Public namespaces
 * for libraries referenced by the defining compilation unit via `import`
 * declarations (and files reachable from them via `part` and `export`
 * declarations) will be retrieved using [getImport].
 */
LinkedLibraryBuilder prelink(
    String definingUnitUri,
    UnlinkedUnit definingUnit,
    GetPartCallback getPart,
    GetImportCallback getImport,
    GetDeclaredVariable getDeclaredVariable) {
  return new _Prelinker(definingUnitUri, definingUnit, getPart, getImport,
          getDeclaredVariable)
      .prelink();
}

/**
 * Return the raw string value of the variable with the given [name],
 * or `null` of the variable is not defined.
 */
typedef String GetDeclaredVariable(String name);

/**
 * Type of the callback used by the prelinker to obtain public namespace
 * information about libraries with the given [absoluteUri] imported by the
 * library to be prelinked (and the transitive closure of parts and exports
 * reachable from those libraries).
 *
 * If no file exists at the given uri, `null` should be returned.
 */
typedef UnlinkedPublicNamespace GetImportCallback(String absoluteUri);

/**
 * Type of the callback used by the prelinker to obtain unlinked summaries of
 * part files of the library to be prelinked.
 *
 * If no file exists at the given uri, `null` should be returned.
 */
typedef UnlinkedUnit GetPartCallback(String absoluteUri);

/**
 * A [_Meaning] representing a class.
 */
class _ClassMeaning extends _Meaning {
  final _Namespace namespace;

  _ClassMeaning(int unit, int dependency, int numTypeParameters, this.namespace)
      : super(unit, ReferenceKind.classOrEnum, dependency, numTypeParameters);
}

/**
 * A node in computing exported namespaces.
 */
class _ExportNamespace {
  static int nextId = 0;

  /**
   * The export namespace, full (with all exports included), or partial (with
   * public namespace, and only some of the exports included).
   */
  final _Namespace namespace;

  /**
   * This field is set to non-zero when we start computing the export namespace
   * for the corresponding library, and is set back to zero when we finish
   * computation.
   */
  int id = 0;

  /**
   * Whether the [namespace] is full, so we don't need chasing exports.
   */
  bool isFull = false;

  _ExportNamespace(this.namespace);
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
 * Mapping from names to corresponding unique [_Meaning]s.
 */
class _Namespace {
  final Set<String> namesWithConflictingDefinitions = new Set<String>();
  final Set<String> libraryNames = new Set<String>();
  final Map<String, _Meaning> map = <String, _Meaning>{};

  /**
   * Return the [_Meaning] of the name, or `null` is not defined.
   */
  _Meaning operator [](String name) {
    return map[name];
  }

  /**
   * Define that the [name] has the given [value].  If the [name] already been
   * defined with a different value, then it becomes undefined.
   */
  void add(String name, _Meaning value) {
    // Already determined to be a conflict.
    if (namesWithConflictingDefinitions.contains(name)) {
      return;
    }

    _Meaning currentValue = map[name];
    if (currentValue == null) {
      map[name] = value;
    } else if (currentValue == value) {
      // The same value, ignore.
    } else {
      // A conflict, remember it, and un-define the name.
      namesWithConflictingDefinitions.add(name);
      map.remove(name);
    }
  }

  /**
   * Return `true` if the [name] was defined before [rememberLibraryNames]
   * invocation.
   */
  bool definesLibraryName(String name) => libraryNames.contains(name);

  /**
   * Return `true` if the [name] is already defined.
   */
  bool definesName(String name) => map.containsKey(name);

  /**
   * Apply [f] to each name-meaning pair.
   */
  void forEach(void f(String key, _Meaning value)) {
    map.forEach(f);
  }

  /**
   * This method should be invoked after defining all names that are defined
   * in a library, before defining imported names.
   */
  void rememberLibraryNames() {
    libraryNames.addAll(map.keys);
  }
}

/**
 * A [_Meaning] representing a prefix introduced by an import directive.
 */
class _PrefixMeaning extends _Meaning {
  final _Namespace namespace = new _Namespace();

  _PrefixMeaning() : super(0, ReferenceKind.prefix, 0, 0);
}

/**
 * Helper class containing temporary data structures needed to prelink a single
 * library.
 */
class _Prelinker {
  final String definingUnitUri;
  final UnlinkedUnit definingUnit;
  final GetPartCallback getPart;
  final GetImportCallback getImport;
  final GetDeclaredVariable getDeclaredVariable;

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
  final _Namespace privateNamespace = new _Namespace()
    ..add('dynamic', new _Meaning(0, ReferenceKind.classOrEnum, 0, 0))
    ..add('void', new _Meaning(0, ReferenceKind.classOrEnum, 0, 0));

  /**
   * List of dependencies of the library being prelinked.  This will be output
   * to [LinkedLibrary.dependencies].
   */
  final List<LinkedDependencyBuilder> dependencies =
      <LinkedDependencyBuilder>[];

  /**
   * Map from the absolute URI of a dependent library to the index of the
   * corresponding entry in [dependencies].
   */
  final Map<String, int> uriToDependency = <String, int>{};

  /**
   * List of public namespaces corresponding to each entry in [dependencies].
   */
  final List<_Namespace> dependencyToPublicNamespace = <_Namespace>[];

  /**
   * Map from absolute URI of a library to its export namespace.
   */
  final Map<String, _ExportNamespace> exportNamespaces = {};

  _Prelinker(this.definingUnitUri, this.definingUnit, this.getPart,
      this.getImport, this.getDeclaredVariable) {
    partCache[definingUnitUri] = definingUnit;
    importCache[definingUnitUri] = definingUnit.publicNamespace;
  }

  /**
   * Compute the public namespace for the library whose URI is reachable from
   * [definingUnit] via [absoluteUri], by aggregating together public namespace
   * information from all of its parts.
   */
  _Namespace aggregatePublicNamespace(String absoluteUri) {
    if (uriToDependency.containsKey(absoluteUri)) {
      return dependencyToPublicNamespace[uriToDependency[absoluteUri]];
    }
    assert(dependencies.length == dependencyToPublicNamespace.length);
    int dependency = dependencies.length;
    uriToDependency[absoluteUri] = dependency;
    List<String> unitUris = getUnitUris(absoluteUri);
    LinkedDependencyBuilder linkedDependency = new LinkedDependencyBuilder(
        uri: absoluteUri,
        parts: unitUris.skip(1).map((uri) => uri ?? '').toList());
    dependencies.add(linkedDependency);

    _Namespace aggregated = new _Namespace();

    for (int unitNum = 0; unitNum < unitUris.length; unitNum++) {
      String unitUri = unitUris[unitNum];
      UnlinkedPublicNamespace importedNamespace = getImportCached(unitUri);
      if (importedNamespace == null) {
        continue;
      }
      for (UnlinkedPublicName name in importedNamespace.names) {
        if (name.kind == ReferenceKind.classOrEnum) {
          _Namespace namespace = new _Namespace();
          name.members.forEach((executable) {
            namespace.add(
                executable.name,
                new _Meaning(
                    unitNum, executable.kind, 0, executable.numTypeParameters));
          });
          aggregated.add(
              name.name,
              new _ClassMeaning(
                  unitNum, dependency, name.numTypeParameters, namespace));
        } else {
          aggregated.add(
              name.name,
              new _Meaning(
                  unitNum, name.kind, dependency, name.numTypeParameters));
        }
      }
    }

    aggregated.rememberLibraryNames();

    dependencyToPublicNamespace.add(aggregated);
    return aggregated;
  }

  /**
   * Compute the export namespace for the library whose URI is reachable from
   * [definingUnit] via [absoluteUri], by aggregating together public namespace
   * information from the library and the transitive closure of its exports.
   */
  _Namespace computeExportNamespace(String absoluteUri) {
    int firstCycleIdOfLastCall = 0;
    _Namespace chaseExports(String absoluteUri) {
      _ExportNamespace exportNamespace = getExportNamespace(absoluteUri);

      // If the export namespace is ready, return it.
      if (exportNamespace.isFull) {
        firstCycleIdOfLastCall = 0;
        return exportNamespace.namespace;
      }

      // If we are computing the export namespace for this library, and we
      // reached here, then we found a cycle.
      if (exportNamespace.id != 0) {
        firstCycleIdOfLastCall = exportNamespace.id;
        return null;
      }

      // Give each library a unique identifier.
      exportNamespace.id = _ExportNamespace.nextId++;

      // Append from exports.
      int firstCycleId = 0;
      UnlinkedPublicNamespace publicNamespace = getImportCached(absoluteUri);
      if (publicNamespace != null) {
        for (UnlinkedExportPublic export in publicNamespace.exports) {
          String unlinkedExportUri =
              _selectUri(export.uri, export.configurations);
          String exportUri = resolveUri(absoluteUri, unlinkedExportUri);
          if (exportUri != null) {
            NameFilter filter =
                new NameFilter.forUnlinkedCombinators(export.combinators);
            _Namespace exported = chaseExports(exportUri);
            exported?.forEach((String name, _Meaning meaning) {
              if (filter.accepts(name) &&
                  !exportNamespace.namespace.definesLibraryName(name)) {
                exportNamespace.namespace.add(name, meaning);
              }
            });
            if (firstCycleIdOfLastCall != 0) {
              if (firstCycleId == 0 || firstCycleId > firstCycleIdOfLastCall) {
                firstCycleId = firstCycleIdOfLastCall;
              }
            }
          }
        }
      }

      // If this library is the first component of the cycle, then we are at
      // the beginning of this cycle, and combination of partial export
      // namespaces of other exported libraries and declarations of this
      // library is the full export namespace of this library.
      if (firstCycleId != 0 && firstCycleId == exportNamespace.id) {
        firstCycleId = 0;
      }

      // We're done with this library, successfully or not.
      exportNamespace.id = 0;

      // If no cycle detected in exports, mark the export namespace as full.
      if (firstCycleId == 0) {
        exportNamespace.isFull = true;
      }

      // Return the full or partial result.
      firstCycleIdOfLastCall = firstCycleId;
      return exportNamespace.namespace;
    }

    _ExportNamespace.nextId = 1;
    return chaseExports(absoluteUri);
  }

  /**
   * Extract all the names defined in [unit] (which is the [unitNum]th unit in
   * the library being prelinked) and store them in [privateNamespace].
   * Excludes names introduced by `import` statements.
   */
  void extractPrivateNames(UnlinkedUnit unit, int unitNum) {
    for (UnlinkedClass cls in unit.classes) {
      _Namespace namespace = new _Namespace();
      cls.fields.forEach((field) {
        if (field.isStatic && field.isConst) {
          namespace.add(field.name,
              new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0));
        }
      });
      cls.executables.forEach((executable) {
        ReferenceKind kind = null;
        if (executable.kind == UnlinkedExecutableKind.constructor) {
          kind = ReferenceKind.constructor;
        } else if (executable.kind == UnlinkedExecutableKind.functionOrMethod &&
            executable.isStatic) {
          kind = ReferenceKind.method;
        } else if (executable.kind == UnlinkedExecutableKind.getter &&
            executable.isStatic) {
          kind = ReferenceKind.propertyAccessor;
        }
        if (kind != null && executable.name.isNotEmpty) {
          namespace.add(executable.name,
              new _Meaning(unitNum, kind, 0, executable.typeParameters.length));
        }
      });
      privateNamespace.add(cls.name,
          new _ClassMeaning(unitNum, 0, cls.typeParameters.length, namespace));
    }
    for (UnlinkedEnum enm in unit.enums) {
      _Namespace namespace = new _Namespace();
      enm.values.forEach((UnlinkedEnumValue value) {
        namespace.add(value.name,
            new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0));
      });
      namespace.add('values',
          new _Meaning(unitNum, ReferenceKind.propertyAccessor, 0, 0));
      privateNamespace.add(
          enm.name, new _ClassMeaning(unitNum, 0, 0, namespace));
    }
    for (UnlinkedExecutable executable in unit.executables) {
      privateNamespace.add(
          executable.name,
          new _Meaning(
              unitNum,
              executable.kind == UnlinkedExecutableKind.functionOrMethod
                  ? ReferenceKind.topLevelFunction
                  : ReferenceKind.topLevelPropertyAccessor,
              0,
              executable.typeParameters.length));
    }
    for (UnlinkedTypedef typedef in unit.typedefs) {
      ReferenceKind kind;
      switch (typedef.style) {
        case TypedefStyle.functionType:
          kind = ReferenceKind.typedef;
          break;
        case TypedefStyle.genericFunctionType:
          kind = ReferenceKind.genericFunctionTypedef;
          break;
      }
      assert(kind != null);
      privateNamespace.add(typedef.name,
          new _Meaning(unitNum, kind, 0, typedef.typeParameters.length));
    }
    for (UnlinkedVariable variable in unit.variables) {
      privateNamespace.add(variable.name,
          new _Meaning(unitNum, ReferenceKind.topLevelPropertyAccessor, 0, 0));
      if (!(variable.isConst || variable.isFinal)) {
        privateNamespace.add(
            variable.name + '=',
            new _Meaning(
                unitNum, ReferenceKind.topLevelPropertyAccessor, 0, 0));
      }
    }
  }

  /**
   * Filter the export namespace for the library whose URI is reachable the
   * given [absoluteUri], retaining only those names accepted by
   * [combinators], and store the resulting names in [result].  Names that
   * already exist in [result] are not overwritten.
   */
  void filterExportNamespace(String absoluteUri,
      List<UnlinkedCombinator> combinators, _Namespace result) {
    _Namespace exportNamespace = computeExportNamespace(absoluteUri);
    if (result == null) {
      // This can happen if the import prefix was shadowed by a local name, so
      // the imported symbols are inaccessible.
      return;
    }
    NameFilter filter = new NameFilter.forUnlinkedCombinators(combinators);
    exportNamespace.forEach((String name, _Meaning meaning) {
      if (filter.accepts(name) && !result.definesLibraryName(name)) {
        result.add(name, meaning);
      }
    });
  }

  /**
   * Return the [_ExportNamespace] for the library with the given [absoluteUri].
   * The export namespace might be full (will all exports included), or
   * partial (with public namespace, and only some of the exports included).
   */
  _ExportNamespace getExportNamespace(String absoluteUri) {
    _ExportNamespace exportNamespace = exportNamespaces[absoluteUri];
    if (exportNamespace == null) {
      _Namespace publicNamespace = aggregatePublicNamespace(absoluteUri);
      exportNamespace = new _ExportNamespace(publicNamespace);
      exportNamespaces[absoluteUri] = exportNamespace;
    }
    return exportNamespace;
  }

  /**
   * Wrapper around [getImport] that caches the return value in [importCache].
   */
  UnlinkedPublicNamespace getImportCached(String absoluteUri) {
    return importCache.putIfAbsent(absoluteUri, () => getImport(absoluteUri));
  }

  /**
   * Wrapper around [getPart] that caches the return value in [partCache] and
   * updates [importCache] appropriately.
   */
  UnlinkedUnit getPartCached(String absoluteUri) {
    return partCache.putIfAbsent(absoluteUri, () {
      UnlinkedUnit unit = getPart(absoluteUri);
      importCache[absoluteUri] = unit?.publicNamespace;
      return unit;
    });
  }

  /**
   * Compute the set of absolute URIs of all the compilation units in the
   * library whose URI is reachable from [definingUnit] via [absoluteUri].
   */
  List<String> getUnitUris(String absoluteUri) {
    List<String> result = <String>[absoluteUri];
    UnlinkedPublicNamespace publicNamespace = getImportCached(absoluteUri);
    if (publicNamespace != null) {
      result.addAll(publicNamespace.parts.map((String uri) {
        return resolveUri(absoluteUri, uri);
      }));
    }
    return result;
  }

  /**
   * Process a single `import` declaration in the library being prelinked.  The
   * return value is the index of the imported library in [dependencies].
   */
  int handleImport(UnlinkedImport import) {
    String unlinkedUri = import.isImplicit
        ? 'dart:core'
        : _selectUri(import.uri, import.configurations);
    String absoluteUri = resolveUri(definingUnitUri, unlinkedUri);

    _Namespace targetNamespace = null;
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
    filterExportNamespace(absoluteUri, import.combinators, targetNamespace);
    return uriToDependency[absoluteUri];
  }

  /**
   * Produce a [LinkedUnit] for the given [unit], by resolving every one of
   * its references.
   */
  LinkedUnitBuilder linkUnit(UnlinkedUnit unit) {
    if (unit == null) {
      return new LinkedUnitBuilder();
    }
    Map<int, _Namespace> prefixNamespaces = <int, _Namespace>{};
    List<LinkedReferenceBuilder> references = <LinkedReferenceBuilder>[];
    for (int i = 0; i < unit.references.length; i++) {
      UnlinkedReference reference = unit.references[i];
      _Namespace namespace;
      if (reference.prefixReference == 0) {
        namespace = privateNamespace;
      } else {
        // Prefix references must always point backward.
        assert(reference.prefixReference < i);
        namespace = prefixNamespaces[reference.prefixReference];
        // Expressions like 'a.b.c.d' cannot be prelinked.
        namespace ??= new _Namespace();
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
    aggregatePublicNamespace(definingUnitUri);

    // Gather up the unlinked summaries for all the compilation units in the
    // library.
    List<String> unitUris = getUnitUris(definingUnitUri);
    List<UnlinkedUnit> units = unitUris.map(getPartCached).toList();

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
    computeExportNamespace(definingUnitUri)
        .forEach((String name, _Meaning meaning) {
      if (!privateNamespace.definesName(name)) {
        exportNames.add(meaning.encodeExportName(name));
      }
    });

    // Fill in prefixes defined in import declarations.
    for (UnlinkedImport import in units[0].imports) {
      if (import.prefixReference != 0) {
        String name = units[0].references[import.prefixReference].name;
        if (!privateNamespace.definesName(name)) {
          privateNamespace.add(name, new _PrefixMeaning());
        }
      }
    }

    // All the names defined so far are library local, they take precedence
    // over anything imported from other libraries.
    privateNamespace.rememberLibraryNames();

    // Fill in imported and exported names.
    List<int> importDependencies =
        definingUnit.imports.map(handleImport).toList();
    List<int> exportDependencies = definingUnit.publicNamespace.exports
        .map((UnlinkedExportPublic exp) {
          String unlinkedUri = _selectUri(exp.uri, exp.configurations);
          String absoluteUri = resolveUri(definingUnitUri, unlinkedUri);
          return uriToDependency[absoluteUri];
        })
        .where((dependency) => dependency != null)
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
   * Resolve [relativeUri] relative to [containingUri].  Return `null` if
   * [relativeUri] is invalid or empty, so cannot be resolved.
   */
  String resolveUri(String containingUri, String relativeUri) {
    if (relativeUri == '') {
      return null;
    }
    try {
      Uri containingUriObj = Uri.parse(containingUri);
      Uri relativeUriObj = Uri.parse(relativeUri);
      return resolveRelativeUri(containingUriObj, relativeUriObj).toString();
    } on FormatException {
      return null;
    }
  }

  /**
   * Return the URI of the first configuration from the given [configurations]
   * which condition is satisfied, or the [defaultUri].
   */
  String _selectUri(
      String defaultUri, List<UnlinkedConfiguration> configurations) {
    for (UnlinkedConfiguration configuration in configurations) {
      if (getDeclaredVariable(configuration.name) == configuration.value) {
        return configuration.uri;
      }
    }
    return defaultUri;
  }
}
