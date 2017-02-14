// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/index/index_unit.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:collection/collection.dart';

/**
 * Return a new [Index] instance that keeps information in memory.
 */
Index createMemoryIndex() {
  return new Index._();
}

/**
 * Return the index of the first occurrence of the [value] in the [sortedList],
 * or `-1` if the [value] is not in the list.
 */
int _findFirstOccurrence(List<int> sortedList, int value) {
  // Find an occurrence.
  int i = binarySearch(sortedList, value);
  if (i == -1) {
    return -1;
  }
  // Find the first occurrence.
  while (i > 0 && sortedList[i - 1] == value) {
    i--;
  }
  return i;
}

/**
 * Interface for storing and requesting relations.
 */
class Index {
  final Map<AnalysisContext, _ContextIndex> _contextIndexMap =
      <AnalysisContext, _ContextIndex>{};

  Index._();

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  Future<List<Location>> getDefinedNames(RegExp regExp, IndexNameKind kind) {
    return _mergeLocations((_ContextIndex index) {
      return index.getDefinedNames(regExp, kind);
    });
  }

  /**
   * Complete with a list of locations where the given [element] has relation
   * of the given [kind].
   */
  Future<List<Location>> getRelations(Element element, IndexRelationKind kind) {
    return _mergeLocations((_ContextIndex index) {
      return index.getRelations(element, kind);
    });
  }

  /**
   * Complete with a list of locations where a class members with the given
   * [name] is referenced with a qualifier, but is not resolved.
   */
  Future<List<Location>> getUnresolvedMemberReferences(String name) {
    return _mergeLocations((_ContextIndex index) {
      return index.getUnresolvedMemberReferences(name);
    });
  }

  /**
   * Index declarations in the given partially resolved [unit].
   */
  void indexDeclarations(CompilationUnit unit) {
    if (unit == null) {
      return;
    }
    CompilationUnitElement compilationUnitElement =
        resolutionMap.elementDeclaredByCompilationUnit(unit);
    if (compilationUnitElement?.library == null) {
      return;
    }
    AnalysisContext context = compilationUnitElement.context;
    _getContextIndex(context).indexDeclarations(unit);
  }

  /**
   * Index the given fully resolved [unit].
   */
  void indexUnit(CompilationUnit unit) {
    if (unit == null) {
      return;
    }
    CompilationUnitElement compilationUnitElement =
        resolutionMap.elementDeclaredByCompilationUnit(unit);
    if (compilationUnitElement?.library == null) {
      return;
    }
    AnalysisContext context = compilationUnitElement.context;
    _getContextIndex(context).indexUnit(unit);
  }

  /**
   * Remove all index information for the given [context].
   */
  void removeContext(AnalysisContext context) {
    _contextIndexMap.remove(context);
  }

  /**
   * Remove index information about the unit in the given [context].
   */
  void removeUnit(
      AnalysisContext context, Source librarySource, Source unitSource) {
    _contextIndexMap[context]?.removeUnit(librarySource, unitSource);
  }

  /**
   * Notify the index that the client is going to stop using it.
   */
  void stop() {}

  /**
   * Return the [_ContextIndex] instance for the given [context].
   */
  _ContextIndex _getContextIndex(AnalysisContext context) {
    return _contextIndexMap.putIfAbsent(context, () {
      return new _ContextIndex(context);
    });
  }

  /**
   * Complete with a list of all results returned by the [callback] for every
   * context specific index.
   */
  Future<List<Location>> _mergeLocations(
      Future<List<Location>> callback(_ContextIndex index)) async {
    List<Location> locations = <Location>[];
    for (_ContextIndex index in _contextIndexMap.values) {
      List<Location> contextLocations = await callback(index);
      locations.addAll(contextLocations);
    }
    return locations;
  }
}

/**
 * Information about location of a single relation in the index.
 *
 * The location is expressed as a library specific unit containing the index
 * relation, offset within this [Source] and  length.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Location {
  /**
   * The [AnalysisContext] containing this location.
   */
  final AnalysisContext context;

  /**
   * The URI of the source of the library containing this location.
   */
  final String libraryUri;

  /**
   * The URI of the source of the unit containing this location.
   */
  final String unitUri;

  /**
   * The kind of usage at this location.
   */
  final IndexRelationKind kind;

  /**
   * The offset of this location within the [unitUri].
   */
  final int offset;

  /**
   * The length of this location.
   */
  final int length;

  /**
   * Is `true` if this location is qualified.
   */
  final bool isQualified;

  /**
   * Is `true` if this location is resolved.
   */
  final bool isResolved;

  Location(this.context, this.libraryUri, this.unitUri, this.kind, this.offset,
      this.length, this.isQualified, this.isResolved);

  @override
  String toString() => 'Location{librarySourceUri: $libraryUri, '
      'unitSourceUri: $unitUri, offset: $offset, length: $length, '
      'isQualified: $isQualified}, isResolved: $isResolved}';
}

/**
 * Opaque identifier of a [PackageIndex].
 */
abstract class PackageIndexId {}

/**
 * Storage of [PackageIndex] objects.
 */
abstract class PackageIndexStore {
  /**
   * Complete with identifiers of all [PackageIndex] objects.
   */
  Future<Iterable<PackageIndexId>> getIds();

  /**
   * Complete with the [PackageIndex] with the given [id].
   */
  Future<PackageIndex> getIndex(PackageIndexId id);

  /**
   * Put the given [indexBuilder] into the store.
   */
  void putIndex(String unitLibraryUri, String unitUnitUri,
      PackageIndexBuilder indexBuilder);
}

/**
 * The [AnalysisContext] specific index.
 */
class _ContextIndex {
  final AnalysisContext context;
  final Map<String, PackageIndex> indexMap = <String, PackageIndex>{};

  _ContextIndex(this.context);

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  Future<List<Location>> getDefinedNames(
      RegExp regExp, IndexNameKind kind) async {
    return _mergeLocations((_PackageIndexRequester requester) {
      return requester.getDefinedNames(context, regExp, kind);
    });
  }

  /**
   * Complete with a list of locations where the given [element] has relation
   * of the given [kind].
   */
  Future<List<Location>> getRelations(Element element, IndexRelationKind kind) {
    return _mergeLocations((_PackageIndexRequester requester) {
      return requester.getRelations(context, element, kind);
    });
  }

  /**
   * Complete with a list of locations where a class members with the given
   * [name] is referenced with a qualifier, but is not resolved.
   */
  Future<List<Location>> getUnresolvedMemberReferences(String name) async {
    return _mergeLocations((_PackageIndexRequester requester) {
      return requester.getUnresolvedMemberReferences(context, name);
    });
  }

  /**
   * Index declarations in the given partially resolved [unit].
   */
  void indexDeclarations(CompilationUnit unit) {
    String key = _getUnitKeyForElement(unit.element);
    if (!indexMap.containsKey(key)) {
      PackageIndexAssembler assembler = new PackageIndexAssembler();
      assembler.indexDeclarations(unit);
      _putUnitIndexBuilder(key, assembler);
    }
  }

  /**
   * Index the given fully resolved [unit].
   */
  void indexUnit(CompilationUnit unit) {
    String key = _getUnitKeyForElement(unit.element);
    PackageIndexAssembler assembler = new PackageIndexAssembler();
    assembler.indexUnit(unit);
    _putUnitIndexBuilder(key, assembler);
  }

  /**
   * Remove index information about the unit.
   */
  void removeUnit(Source librarySource, Source unitSource) {
    String key = _getUnitKeyForSource(librarySource, unitSource);
    indexMap.remove(key);
  }

  String _getUnitKeyForElement(CompilationUnitElement unitElement) {
    Source librarySource = unitElement.library.source;
    Source unitSource = unitElement.source;
    return _getUnitKeyForSource(librarySource, unitSource);
  }

  String _getUnitKeyForSource(Source librarySource, Source unitSource) {
    String unitLibraryUri = librarySource.uri.toString();
    String unitUnitUri = unitSource.uri.toString();
    return '$unitLibraryUri;$unitUnitUri';
  }

  Future<List<Location>> _mergeLocations(
      List<Location> callback(_PackageIndexRequester requester)) async {
    List<Location> locations = <Location>[];
    for (PackageIndex index in indexMap.values) {
      _PackageIndexRequester requester = new _PackageIndexRequester(index);
      List<Location> indexLocations = callback(requester);
      locations.addAll(indexLocations);
    }
    return locations;
  }

  void _putUnitIndexBuilder(String key, PackageIndexAssembler assembler) {
    PackageIndexBuilder indexBuilder = assembler.assemble();
    // Put the index into the map.
    List<int> indexBytes = indexBuilder.toBuffer();
    PackageIndex index = new PackageIndex.fromBuffer(indexBytes);
    indexMap[key] = index;
  }
}

/**
 * Helper for requesting information from a single [PackageIndex].
 */
class _PackageIndexRequester {
  final PackageIndex index;

  _PackageIndexRequester(this.index);

  /**
   * Return the [element]'s identifier in the [index] or `-1` if the
   * [element] is not referenced in the [index].
   */
  int findElementId(Element element) {
    IndexElementInfo info = new IndexElementInfo(element);
    element = info.element;
    // Find the id of the element's unit.
    int unitId = getUnitId(element);
    if (unitId == -1) {
      return -1;
    }
    // Prepare information about the element.
    int unitMemberId = getElementUnitMemberId(element);
    if (unitMemberId == -1) {
      return -1;
    }
    int classMemberId = getElementClassMemberId(element);
    if (classMemberId == -1) {
      return -1;
    }
    int parameterId = getElementParameterId(element);
    if (parameterId == -1) {
      return -1;
    }
    // Try to find the element id using classMemberId, parameterId, and kind.
    int elementId =
        _findFirstOccurrence(index.elementNameUnitMemberIds, unitMemberId);
    if (elementId == -1) {
      return -1;
    }
    for (;
        elementId < index.elementNameUnitMemberIds.length &&
            index.elementNameUnitMemberIds[elementId] == unitMemberId;
        elementId++) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementNameClassMemberIds[elementId] == classMemberId &&
          index.elementNameParameterIds[elementId] == parameterId &&
          index.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }
    return -1;
  }

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  List<Location> getDefinedNames(
      AnalysisContext context, RegExp regExp, IndexNameKind kind) {
    List<Location> locations = <Location>[];
    for (UnitIndex unitIndex in index.units) {
      _UnitIndexRequester requester = new _UnitIndexRequester(this, unitIndex);
      List<Location> unitLocations =
          requester.getDefinedNames(context, regExp, kind);
      locations.addAll(unitLocations);
    }
    return locations;
  }

  /**
   * Return the [element]'s class member name identifier, `null` is not a class
   * member, or `-1` if the [element] is not referenced in the [index].
   */
  int getElementClassMemberId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element.enclosingElement is ClassElement) {
        return getStringId(element.name);
      }
    }
    return getStringId(PackageIndexAssembler.NULL_STRING);
  }

  /**
   * Return the [element]'s class member name identifier, `null` is not a class
   * member, or `-1` if the [element] is not referenced in the [index].
   */
  int getElementParameterId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element is ParameterElement) {
        return getStringId(element.name);
      }
    }
    return getStringId(PackageIndexAssembler.NULL_STRING);
  }

  /**
   * Return the [element]'s top-level name identifier, `0` is the unit, or
   * `-1` if the [element] is not referenced in the [index].
   */
  int getElementUnitMemberId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element.enclosingElement is CompilationUnitElement) {
        return getStringId(element.name);
      }
    }
    return getStringId(PackageIndexAssembler.NULL_STRING);
  }

  /**
   * Complete with a list of locations where the given [element] has relation
   * of the given [kind].
   */
  List<Location> getRelations(
      AnalysisContext context, Element element, IndexRelationKind kind) {
    int elementId = findElementId(element);
    if (elementId == -1) {
      return const <Location>[];
    }
    List<Location> locations = <Location>[];
    for (UnitIndex unitIndex in index.units) {
      _UnitIndexRequester requester = new _UnitIndexRequester(this, unitIndex);
      List<Location> unitLocations =
          requester.getRelations(context, elementId, kind);
      locations.addAll(unitLocations);
    }
    return locations;
  }

  /**
   * Return the identifier of [str] in the [index] or `-1` if [str] is not used
   * in the [index].
   */
  int getStringId(String str) {
    return binarySearch(index.strings, str);
  }

  /**
   * Return the identifier of the [CompilationUnitElement] containing the
   * [element] in the [index] or `-1` if not found.
   */
  int getUnitId(Element element) {
    CompilationUnitElement unitElement =
        PackageIndexAssembler.getUnitElement(element);
    int libraryUriId = getUriId(unitElement.library.source.uri);
    if (libraryUriId == -1) {
      return -1;
    }
    int unitUriId = getUriId(unitElement.source.uri);
    if (unitUriId == -1) {
      return -1;
    }
    for (int i = 0; i < index.unitLibraryUris.length; i++) {
      if (index.unitLibraryUris[i] == libraryUriId &&
          index.unitUnitUris[i] == unitUriId) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Return the URI of the library source of the library specific [unit].
   */
  String getUnitLibraryUri(int unit) {
    int id = index.unitLibraryUris[unit];
    return index.strings[id];
  }

  /**
   * Return the URI of the unit source of the library specific [unit].
   */
  String getUnitUnitUri(int unit) {
    int id = index.unitUnitUris[unit];
    return index.strings[id];
  }

  /**
   * Complete with a list of locations where a class members with the given
   * [name] is referenced with a qualifier, but is not resolved.
   */
  List<Location> getUnresolvedMemberReferences(
      AnalysisContext context, String name) {
    List<Location> locations = <Location>[];
    for (UnitIndex unitIndex in index.units) {
      _UnitIndexRequester requester = new _UnitIndexRequester(this, unitIndex);
      List<Location> unitLocations =
          requester.getUnresolvedMemberReferences(context, name);
      locations.addAll(unitLocations);
    }
    return locations;
  }

  /**
   * Return the identifier of the [uri] in the [index] or `-1` if the [uri] is
   * not used in the [index].
   */
  int getUriId(Uri uri) {
    String str = uri.toString();
    return getStringId(str);
  }
}

/**
 * Helper for requesting information from a single [UnitIndex].
 */
class _UnitIndexRequester {
  final _PackageIndexRequester packageRequester;
  final UnitIndex unitIndex;

  _UnitIndexRequester(this.packageRequester, this.unitIndex);

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  List<Location> getDefinedNames(
      AnalysisContext context, RegExp regExp, IndexNameKind kind) {
    List<Location> locations = <Location>[];
    String unitLibraryUri = null;
    String unitUnitUri = null;
    for (int i = 0; i < unitIndex.definedNames.length; i++) {
      if (unitIndex.definedNameKinds[i] == kind) {
        int nameIndex = unitIndex.definedNames[i];
        String name = packageRequester.index.strings[nameIndex];
        if (regExp.matchAsPrefix(name) != null) {
          unitLibraryUri ??= packageRequester.getUnitLibraryUri(unitIndex.unit);
          unitUnitUri ??= packageRequester.getUnitUnitUri(unitIndex.unit);
          locations.add(new Location(context, unitLibraryUri, unitUnitUri, null,
              unitIndex.definedNameOffsets[i], name.length, false, true));
        }
      }
    }
    return locations;
  }

  /**
   * Return a list of locations where an element with the given [elementId] has
   * relation of the given [kind].
   */
  List<Location> getRelations(
      AnalysisContext context, int elementId, IndexRelationKind kind) {
    // Find the first usage of the element.
    int i = _findFirstOccurrence(unitIndex.usedElements, elementId);
    if (i == -1) {
      return const <Location>[];
    }
    // Create locations for every usage of the element.
    List<Location> locations = <Location>[];
    String unitLibraryUri = null;
    String unitUnitUri = null;
    for (;
        i < unitIndex.usedElements.length &&
            unitIndex.usedElements[i] == elementId;
        i++) {
      if (unitIndex.usedElementKinds[i] == kind) {
        unitLibraryUri ??= packageRequester.getUnitLibraryUri(unitIndex.unit);
        unitUnitUri ??= packageRequester.getUnitUnitUri(unitIndex.unit);
        locations.add(new Location(
            context,
            unitLibraryUri,
            unitUnitUri,
            kind,
            unitIndex.usedElementOffsets[i],
            unitIndex.usedElementLengths[i],
            unitIndex.usedElementIsQualifiedFlags[i],
            true));
      }
    }
    return locations;
  }

  /**
   * Complete with a list of locations where a class members with the given
   * [name] is referenced with a qualifier, but is not resolved.
   */
  List<Location> getUnresolvedMemberReferences(
      AnalysisContext context, String name) {
    // Find the name ID in the package index.
    int nameId = packageRequester.getStringId(name);
    if (nameId == -1) {
      return const <Location>[];
    }
    // Find the first usage of the name.
    int i = _findFirstOccurrence(unitIndex.usedNames, nameId);
    if (i == -1) {
      return const <Location>[];
    }
    // Create locations for every usage of the name.
    List<Location> locations = <Location>[];
    String unitLibraryUri = null;
    String unitUnitUri = null;
    for (;
        i < unitIndex.usedNames.length && unitIndex.usedNames[i] == nameId;
        i++) {
      unitLibraryUri ??= packageRequester.getUnitLibraryUri(unitIndex.unit);
      unitUnitUri ??= packageRequester.getUnitUnitUri(unitIndex.unit);
      locations.add(new Location(
          context,
          unitLibraryUri,
          unitUnitUri,
          unitIndex.usedNameKinds[i],
          unitIndex.usedNameOffsets[i],
          name.length,
          unitIndex.usedNameIsQualifiedFlags[i],
          false));
    }
    return locations;
  }
}
