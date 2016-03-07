// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/index_unit.dart';
import 'package:collection/collection.dart';

/**
 * Return a new [Index2] instance that keeps information in memory.
 */
Index2 createMemoryIndex2() {
  _MemoryPackageIndexStore store = new _MemoryPackageIndexStore();
  return new Index2(store);
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
class Index2 {
  final PackageIndexStore _store;

  Index2(this._store);

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  Future<List<Location>> getDefinedNames(
      RegExp regExp, IndexNameKind kind) async {
    List<Location> locations = <Location>[];
    Iterable<PackageIndexId> ids = await _store.getIds();
    for (PackageIndexId id in ids) {
      PackageIndex index = await _store.getIndex(id);
      _PackageIndexRequester requester = new _PackageIndexRequester(index);
      List<Location> packageLocations = requester.getDefinedNames(regExp, kind);
      locations.addAll(packageLocations);
    }
    return locations;
  }

  /**
   * Complete with a list of locations where the given [element] has relation
   * of the given [kind].
   */
  Future<List<Location>> getRelations(
      Element element, IndexRelationKind kind) async {
    List<Location> locations = <Location>[];
    Iterable<PackageIndexId> ids = await _store.getIds();
    for (PackageIndexId id in ids) {
      PackageIndex index = await _store.getIndex(id);
      _PackageIndexRequester requester = new _PackageIndexRequester(index);
      List<Location> packageLocations = requester.getRelations(element, kind);
      locations.addAll(packageLocations);
    }
    return locations;
  }

  /**
   * Index the given fully resolved [unit].
   */
  void indexUnit(CompilationUnit unit) {
    PackageIndexAssembler assembler = new PackageIndexAssembler();
    assembler.index(unit);
    PackageIndexBuilder indexBuilder = assembler.assemble();
    String unitLibraryUri = unit.element.library.source.uri.toString();
    String unitUnitUri = unit.element.source.uri.toString();
    _store.putIndex(unitLibraryUri, unitUnitUri, indexBuilder);
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
   * The URI of the source of the library containing this location.
   */
  final String libraryUri;

  /**
   * The URI of the source of the unit containing this location.
   */
  final String unitUri;

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

  Location(this.libraryUri, this.unitUri, this.offset, this.length,
      this.isQualified);

  @override
  String toString() => 'Location{librarySourceUri: $libraryUri, '
      'unitSourceUri: $unitUri, offset: $offset, length: $length, '
      'isQualified: $isQualified}';
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
 * A [PackageIndexId] for [_MemoryPackageIndexStore].
 */
class _MemoryPackageIndexId implements PackageIndexId {
  final String key;

  _MemoryPackageIndexId(this.key);
}

/**
 * A [PackageIndexStore] that keeps objects in memory;
 */
class _MemoryPackageIndexStore implements PackageIndexStore {
  final Map<String, PackageIndex> indexMap = <String, PackageIndex>{};

  @override
  Future<Iterable<PackageIndexId>> getIds() async {
    return indexMap.keys.map((key) => new _MemoryPackageIndexId(key));
  }

  @override
  Future<PackageIndex> getIndex(PackageIndexId id) async {
    return indexMap[(id as _MemoryPackageIndexId).key];
  }

  @override
  putIndex(String unitLibraryUri, String unitUnitUri,
      PackageIndexBuilder indexBuilder) {
    List<int> indexBytes = indexBuilder.toBuffer();
    PackageIndex index = new PackageIndex.fromBuffer(indexBytes);
    String key = '$unitLibraryUri;$unitUnitUri';
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
   * Return the [element]'s identifier in the [index] or `null` if the
   * [element] is not referenced in the [index].
   */
  int findElementId(Element element) {
    // Find the id of the element's unit.
    int unitId = getUnitId(element);
    if (unitId == null) {
      return null;
    }
    // Prepare the offset of the element.
    int offset = element.nameOffset;
    if (element is LibraryElement || element is CompilationUnitElement) {
      offset = 0;
    }
    // Find the first occurrence of an element with the same offset.
    int elementId = _findFirstOccurrence(index.elementOffsets, offset);
    if (elementId == -1) {
      return null;
    }
    // Try to find the element id using offset, unit and kind.
    IndexSyntheticElementKind kind =
        PackageIndexAssembler.getIndexElementKind(element);
    for (;
        elementId < index.elementOffsets.length &&
            index.elementOffsets[elementId] == offset;
        elementId++) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementKinds[elementId] == kind) {
        return elementId;
      }
    }
    return null;
  }

  /**
   * Complete with a list of locations where elements of the given [kind] with
   * names satisfying the given [regExp] are defined.
   */
  List<Location> getDefinedNames(RegExp regExp, IndexNameKind kind) {
    List<Location> locations = <Location>[];
    for (UnitIndex unitIndex in index.units) {
      _UnitIndexRequester requester = new _UnitIndexRequester(this, unitIndex);
      List<Location> unitLocations = requester.getDefinedNames(regExp, kind);
      locations.addAll(unitLocations);
    }
    return locations;
  }

  /**
   * Complete with a list of locations where the given [element] has relation
   * of the given [kind].
   */
  List<Location> getRelations(Element element, IndexRelationKind kind) {
    int elementId = findElementId(element);
    if (elementId == null) {
      return const <Location>[];
    }
    List<Location> locations = <Location>[];
    for (UnitIndex unitIndex in index.units) {
      _UnitIndexRequester requester = new _UnitIndexRequester(this, unitIndex);
      List<Location> unitLocations = requester.getRelations(elementId, kind);
      locations.addAll(unitLocations);
    }
    return locations;
  }

  /**
   * Return the identifier of [str] in the [index] or `-1` if [str] is not used
   * in the [index].
   */
  int getStringId(String str) {
    return index.strings.indexOf(str);
  }

  /**
   * Return the identifier of the [CompilationUnitElement] containing the
   * [element] in the [index] or `-1` if not found.
   */
  int getUnitId(Element element) {
    CompilationUnitElement unitElement =
        PackageIndexAssembler.getUnitElement(element);
    int libraryUriId = getUriId(unitElement.library.source.uri);
    int unitUriId = getUriId(unitElement.source.uri);
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
  List<Location> getDefinedNames(RegExp regExp, IndexNameKind kind) {
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
          locations.add(new Location(unitLibraryUri, unitUnitUri,
              unitIndex.definedNameOffsets[i], name.length, false));
        }
      }
    }
    return locations;
  }

  /**
   * Return a list of locations where an element with the given [elementId] has
   * relation of the given [kind].
   */
  List<Location> getRelations(int elementId, IndexRelationKind kind) {
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
            unitLibraryUri,
            unitUnitUri,
            unitIndex.usedElementOffsets[i],
            unitIndex.usedElementLengths[i],
            unitIndex.usedElementIsQualifiedFlags[i]));
      }
    }
    return locations;
  }
}
