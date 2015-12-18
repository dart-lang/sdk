// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.store.split_store;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/index_store.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analysis_server/src/services/index/store/collection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart' show CompilationUnit;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/**
 * The implementation of [IndexObjectManager] for indexing
 * [CompilationUnitElement]s.
 */
class DartUnitIndexObjectManager extends IndexObjectManager {
  /**
   * The mapping of library [Source] to the [Source]s of part units.
   */
  Map<AnalysisContext, Map<Source, Set<Source>>> _contextToLibraryToUnits =
      new HashMap<AnalysisContext, Map<Source, Set<Source>>>();

  /**
   * The mapping of unit [Source] to the [Source]s of libraries it is used in.
   */
  Map<AnalysisContext, Map<Source, Set<Source>>> _contextToUnitToLibraries =
      new HashMap<AnalysisContext, Map<Source, Set<Source>>>();

  @override
  String aboutToIndex(AnalysisContext context, Object object) {
    CompilationUnitElement unitElement;
    if (object is CompilationUnit) {
      unitElement = object.element;
    } else if (object is CompilationUnitElement) {
      unitElement = object;
    }
    // validate unit
    if (unitElement == null) {
      return null;
    }
    LibraryElement libraryElement = unitElement.library;
    if (libraryElement == null) {
      return null;
    }
    CompilationUnitElement definingUnitElement =
        libraryElement.definingCompilationUnit;
    if (definingUnitElement == null) {
      return null;
    }
    // prepare sources
    Source library = definingUnitElement.source;
    Source unit = unitElement.source;
    // special handling for the defining library unit
    if (unit == library) {
      // prepare new parts
      HashSet<Source> newParts = new HashSet<Source>();
      for (CompilationUnitElement part in libraryElement.parts) {
        newParts.add(part.source);
      }
      // prepare old parts
      Map<Source, Set<Source>> libraryToUnits =
          _contextToLibraryToUnits[context];
      if (libraryToUnits == null) {
        libraryToUnits = new HashMap<Source, Set<Source>>();
        _contextToLibraryToUnits[context] = libraryToUnits;
      }
      Set<Source> oldParts = libraryToUnits[library];
      // check if some parts are not in the library now
      if (oldParts != null) {
        Set<Source> noParts = oldParts.difference(newParts);
        for (Source noPart in noParts) {
          String nodeName = _getNodeName(library, noPart);
          site.removeNodeByName(context, nodeName);
          site.removeSource(library);
          site.removeSource(noPart);
        }
      }
      // remember new parts
      libraryToUnits[library] = newParts;
    }
    // remember library/unit relations
    _recordUnitInLibrary(context, library, unit);
    _recordLibraryWithUnit(context, library, unit);
    site.addSource(library);
    site.addSource(unit);
    // prepare node
    String nodeName = _getNodeName(library, unit);
    return nodeName;
  }

  @override
  void removeContext(AnalysisContext context) {
    _contextToLibraryToUnits.remove(context);
    _contextToUnitToLibraries.remove(context);
  }

  @override
  void removeSource(AnalysisContext context, Source source) {
    // remove nodes for unit/library pairs
    Map<Source, Set<Source>> unitToLibraries =
        _contextToUnitToLibraries[context];
    if (unitToLibraries != null) {
      Set<Source> libraries = unitToLibraries.remove(source);
      if (libraries != null) {
        for (Source library in libraries) {
          String nodeName = _getNodeName(library, source);
          site.removeNodeByName(context, nodeName);
          site.removeSource(library);
          site.removeSource(source);
        }
      }
    }
    // remove nodes for library/unit pairs
    Map<Source, Set<Source>> libraryToUnits = _contextToLibraryToUnits[context];
    if (libraryToUnits != null) {
      Set<Source> units = libraryToUnits.remove(source);
      if (units != null) {
        for (Source unit in units) {
          String nodeName = _getNodeName(source, unit);
          site.removeNodeByName(context, nodeName);
          site.removeSource(source);
          site.removeSource(unit);
        }
      }
    }
  }

  @override
  void removeSources(AnalysisContext context, SourceContainer container) {
    // remove nodes for unit/library pairs
    Map<Source, Set<Source>> unitToLibraries =
        _contextToUnitToLibraries[context];
    if (unitToLibraries != null) {
      List<Source> units = unitToLibraries.keys.toList();
      for (Source source in units) {
        if (container == null || container.contains(source)) {
          removeSource(context, source);
        }
      }
    }
    // remove nodes for library/unit pairs
    Map<Source, Set<Source>> libraryToUnits = _contextToLibraryToUnits[context];
    if (libraryToUnits != null) {
      List<Source> libraries = libraryToUnits.keys.toList();
      for (Source source in libraries) {
        if (container == null || container.contains(source)) {
          removeSource(context, source);
        }
      }
    }
  }

  String _getNodeName(Source library, Source unit) {
    String libraryName = library != null ? library.fullName : null;
    String unitName = unit.fullName;
    int libraryNameIndex = site.encodeString(libraryName);
    int unitNameIndex = site.encodeString(unitName);
    return 'DartUnitElement_${libraryNameIndex}_$unitNameIndex.index';
  }

  void _recordLibraryWithUnit(
      AnalysisContext context, Source library, Source unit) {
    Map<Source, Set<Source>> libraryToUnits = _contextToLibraryToUnits[context];
    if (libraryToUnits == null) {
      libraryToUnits = new HashMap<Source, Set<Source>>();
      _contextToLibraryToUnits[context] = libraryToUnits;
    }
    Set<Source> units = libraryToUnits[library];
    if (units == null) {
      units = new HashSet<Source>();
      libraryToUnits[library] = units;
    }
    units.add(unit);
  }

  void _recordUnitInLibrary(
      AnalysisContext context, Source library, Source unit) {
    Map<Source, Set<Source>> unitToLibraries =
        _contextToUnitToLibraries[context];
    if (unitToLibraries == null) {
      unitToLibraries = new HashMap<Source, Set<Source>>();
      _contextToUnitToLibraries[context] = unitToLibraries;
    }
    Set<Source> libraries = unitToLibraries[unit];
    if (libraries == null) {
      libraries = new HashSet<Source>();
      unitToLibraries[unit] = libraries;
    }
    libraries.add(library);
  }
}

/**
 * A manager for files content.
 */
abstract class FileManager {
  /**
   * Removes all files.
   */
  void clear();

  /**
   * Deletes the file with the given name.
   */
  void delete(String name);

  /**
   * Returns names of all known nodes.
   */
  List<String> inspect_getAllNodeNames();

  /**
   * Read the entire file contents as a list of bytes.
   */
  Future<List<int>> read(String name);

  /**
   * Write a list of bytes to a file.
   */
  Future write(String name, List<int> bytes);
}

/**
 * A [FileManager] based [NodeManager].
 */
class FileNodeManager implements NodeManager {
  static int _VERSION = 1;

  final FileManager _fileManager;
  final Logger _logger;

  final ContextCodec contextCodec;
  final ElementCodec elementCodec;
  final StringCodec stringCodec;
  final RelationshipCodec _relationshipCodec;

  int _locationCount = 0;

  Map<String, int> _nodeLocationCounts = new HashMap<String, int>();

  FileNodeManager(this._fileManager, this._logger, this.stringCodec,
      this.contextCodec, this.elementCodec, this._relationshipCodec);

  @override
  int get locationCount => _locationCount;

  @override
  void clear() {
    _fileManager.clear();
  }

  @override
  Future<IndexNode> getNode(String name) {
    return _fileManager.read(name).then((List<int> bytes) {
      if (bytes == null) {
        return null;
      }
      _DataInputStream stream = new _DataInputStream(bytes);
      return _readNode(stream);
    }).catchError((exception, stackTrace) {
      _logger.logError('Exception during reading index file $name',
          new CaughtException(exception, stackTrace));
    });
  }

  /**
   * Returns names of all known nodes.
   */
  List<String> inspect_getAllNodeNames() {
    return _fileManager.inspect_getAllNodeNames();
  }

  @override
  IndexNode newNode(AnalysisContext context) =>
      new IndexNode(context, elementCodec, _relationshipCodec);

  @override
  Future putNode(String name, IndexNode node) {
    // update location count
    {
      _locationCount -= _getLocationCount(name);
      int nodeLocationCount = node.locationCount;
      _nodeLocationCounts[name] = nodeLocationCount;
      _locationCount += nodeLocationCount;
    }
    // write the node
    return new Future.microtask(() {
      return ServerPerformanceStatistics.splitStore.makeCurrentWhile(() {
        _DataOutputStream stream = new _DataOutputStream();
        _writeNode(node, stream);
        var bytes = stream.getBytes();
        return _fileManager.write(name, bytes);
      });
    }).catchError((exception, stackTrace) {
      _logger.logError('Exception during reading index file $name',
          new CaughtException(exception, stackTrace));
    });
  }

  @override
  void removeNode(String name) {
    // update location count
    _locationCount -= _getLocationCount(name);
    _nodeLocationCounts.remove(name);
    // remove node
    _fileManager.delete(name);
  }

  int _getLocationCount(String name) {
    int locationCount = _nodeLocationCounts[name];
    return locationCount != null ? locationCount : 0;
  }

  RelationKeyData _readElementRelationKey(_DataInputStream stream) {
    int elementId1 = stream.readInt();
    int elementId2 = stream.readInt();
    int elementId3 = stream.readInt();
    int relationshipId = stream.readInt();
    return new RelationKeyData.forData(
        elementId1, elementId2, elementId3, relationshipId);
  }

  LocationData _readLocationData(_DataInputStream stream) {
    int elementId1 = stream.readInt();
    int elementId2 = stream.readInt();
    int elementId3 = stream.readInt();
    int offset = stream.readInt();
    int length = stream.readInt();
    int flags = stream.readInt();
    return new LocationData.forData(
        elementId1, elementId2, elementId3, offset, length, flags);
  }

  IndexNode _readNode(_DataInputStream stream) {
    // check version
    {
      int version = stream.readInt();
      if (version != _VERSION) {
        throw new StateError('Version $_VERSION expected, but $version found.');
      }
    }
    // context
    int contextId = stream.readInt();
    AnalysisContext context = contextCodec.decode(contextId);
    if (context == null) {
      return null;
    }
    // relations
    Map<RelationKeyData, List<LocationData>> relations =
        new HashMap<RelationKeyData, List<LocationData>>();
    int numRelations = stream.readInt();
    for (int i = 0; i < numRelations; i++) {
      RelationKeyData key = _readElementRelationKey(stream);
      int numLocations = stream.readInt();
      List<LocationData> locations = new List<LocationData>();
      for (int j = 0; j < numLocations; j++) {
        locations.add(_readLocationData(stream));
      }
      relations[key] = locations;
    }
    // create IndexNode
    IndexNode node = new IndexNode(context, elementCodec, _relationshipCodec);
    node.relations = relations;
    return node;
  }

  void _writeElementRelationKey(_DataOutputStream stream, RelationKeyData key) {
    stream.writeInt(key.elementId1);
    stream.writeInt(key.elementId2);
    stream.writeInt(key.elementId3);
    stream.writeInt(key.relationshipId);
  }

  void _writeNode(IndexNode node, _DataOutputStream stream) {
    // version
    stream.writeInt(_VERSION);
    // context
    {
      AnalysisContext context = node.context;
      int contextId = contextCodec.encode(context);
      stream.writeInt(contextId);
    }
    // relations
    Map<RelationKeyData, List<LocationData>> relations = node.relations;
    stream.writeInt(relations.length);
    relations.forEach((key, locations) {
      _writeElementRelationKey(stream, key);
      stream.writeInt(locations.length);
      for (LocationData location in locations) {
        stream.writeInt(location.elementId1);
        stream.writeInt(location.elementId2);
        stream.writeInt(location.elementId3);
        stream.writeInt(location.offset);
        stream.writeInt(location.length);
        stream.writeInt(location.flags);
      }
    });
  }
}

/**
 * A single index file in-memory presentation.
 */
class IndexNode {
  final AnalysisContext context;

  final ElementCodec _elementCodec;
  final RelationshipCodec _relationshipCodec;

  Map<RelationKeyData, List<LocationData>> _relations =
      new HashMap<RelationKeyData, List<LocationData>>();

  IndexNode(this.context, this._elementCodec, this._relationshipCodec);

  /**
   * Returns number of locations in this node.
   */
  int get locationCount {
    int locationCount = 0;
    for (List<LocationData> locations in _relations.values) {
      locationCount += locations.length;
    }
    return locationCount;
  }

  /**
   * Returns the recorded relations.
   */
  Map<RelationKeyData, List<LocationData>> get relations => _relations;

  /**
   * Sets relations data.
   * This method is used during loading data from a storage.
   */
  void set relations(Map<RelationKeyData, List<LocationData>> relations) {
    _relations = relations;
  }

  /**
   * Returns the locations of the elements that have the given relationship with
   * the given element.
   *
   * [element] - the the element that has the relationship with the locations to
   *    be returned.
   * [relationship] - the [RelationshipImpl] between the given [element] and the
   *    locations to be returned
   */
  List<LocationImpl> getRelationships(
      IndexableObject indexable, RelationshipImpl relationship) {
    // prepare key
    RelationKeyData key = new RelationKeyData.forObject(
        _elementCodec, _relationshipCodec, indexable, relationship);
    // find LocationData(s)
    List<LocationData> locationDatas = _relations[key];
    if (locationDatas == null) {
      return LocationImpl.EMPTY_LIST;
    }
    // convert to Location(s)
    List<LocationImpl> locations = <LocationImpl>[];
    for (LocationData locationData in locationDatas) {
      LocationImpl location = locationData.getLocation(context, _elementCodec);
      if (location != null) {
        locations.add(location);
      }
    }
    return locations;
  }

  /**
   * Returns [InspectLocation]s for the element with the given ID.
   */
  List<InspectLocation> inspect_getRelations(String name, int elementId) {
    List<InspectLocation> result = <InspectLocation>[];
    // TODO(scheglov) restore index inspections?
//    _relations.forEach((RelationKeyData key, locations) {
//      if (key.elementId == elementId) {
//        for (LocationData location in locations) {
//          Relationship relationship =
//              _relationshipCodec.decode(key.relationshipId);
//          List<String> path =
//              _elementCodec.inspect_decodePath(location.elementId);
//          result.add(new InspectLocation(name, relationship, path,
//              location.offset, location.length, location.flags));
//        }
//      }
//    });
    return result;
  }

  /**
   * Records that the given [element] and [location] have the given [relationship].
   *
   * [element] - the [Element] that is related to the location.
   * [relationship] - the [RelationshipImpl] between [element] and [location].
   * [location] - the [LocationImpl] where relationship happens.
   */
  void recordRelationship(IndexableObject indexable,
      RelationshipImpl relationship, LocationImpl location) {
    RelationKeyData key = new RelationKeyData.forObject(
        _elementCodec, _relationshipCodec, indexable, relationship);
    // prepare LocationData(s)
    List<LocationData> locationDatas = _relations[key];
    if (locationDatas == null) {
      locationDatas = <LocationData>[];
      _relations[key] = locationDatas;
    }
    // add new LocationData
    locationDatas.add(new LocationData.forObject(_elementCodec, location));
  }
}

/**
 * [SplitIndexStore] uses instances of this class to manager index nodes.
 */
abstract class IndexObjectManager {
  SplitIndexStoreSite site;

  /**
   * Notifies the manager that the given [object] is to be indexed.
   * Returns the name of the index node to put information into.
   */
  String aboutToIndex(AnalysisContext context, Object object);

  /**
   * Notifies the manager that the given [context] is disposed.
   */
  void removeContext(AnalysisContext context);

  /**
   * Notifies the manager that the given [source] is no longer part of
   * the given [context].
   */
  void removeSource(AnalysisContext context, Source source);

  /**
   * Notifies the manager that the sources described by the given [container]
   * are no longer part of the given [context].
   */
  void removeSources(AnalysisContext context, SourceContainer container);
}

class InspectLocation {
  final String nodeName;
  final RelationshipImpl relationship;
  final List<String> path;
  final int offset;
  final int length;
  final int flags;

  InspectLocation(this.nodeName, this.relationship, this.path, this.offset,
      this.length, this.flags);
}

/**
 * A container with information about a [LocationImpl].
 */
class LocationData {
  static const int _FLAG_QUALIFIED = 1 << 0;
  static const int _FLAG_RESOLVED = 1 << 1;

  final int elementId1;
  final int elementId2;
  final int elementId3;
  final int offset;
  final int length;
  final int flags;

  LocationData.forData(this.elementId1, this.elementId2, this.elementId3,
      this.offset, this.length, this.flags);

  LocationData.forObject(ElementCodec elementCodec, LocationImpl location)
      : elementId1 = elementCodec.encode1(location.indexable),
        elementId2 = elementCodec.encode2(location.indexable),
        elementId3 = elementCodec.encode3(location.indexable),
        offset = location.offset,
        length = location.length,
        flags = (location.isQualified ? _FLAG_QUALIFIED : 0) |
            (location.isResolved ? _FLAG_RESOLVED : 0);

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, elementId1);
    hash = JenkinsSmiHash.combine(hash, elementId2);
    hash = JenkinsSmiHash.combine(hash, elementId3);
    hash = JenkinsSmiHash.combine(hash, offset);
    hash = JenkinsSmiHash.combine(hash, length);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object obj) {
    if (obj is! LocationData) {
      return false;
    }
    LocationData other = obj;
    return other.elementId1 == elementId1 &&
        other.elementId2 == elementId2 &&
        other.elementId3 == elementId3 &&
        other.offset == offset &&
        other.length == length &&
        other.flags == flags;
  }

  /**
   * Returns a {@link Location} that is represented by this {@link LocationData}.
   */
  LocationImpl getLocation(AnalysisContext context, ElementCodec elementCodec) {
    IndexableObject indexable =
        elementCodec.decode(context, elementId1, elementId2, elementId3);
    if (indexable == null) {
      return null;
    }
    bool isQualified = (flags & _FLAG_QUALIFIED) != 0;
    bool isResovled = (flags & _FLAG_RESOLVED) != 0;
    return new LocationImpl(indexable, offset, length,
        isQualified: isQualified, isResolved: isResovled);
  }
}

/**
 * A manager for [IndexNode]s.
 */
abstract class NodeManager {
  /**
   * The shared {@link ContextCodec} instance.
   */
  ContextCodec get contextCodec;

  /**
   * The shared {@link ElementCodec} instance.
   */
  ElementCodec get elementCodec;

  /**
   * A number of locations in all nodes.
   */
  int get locationCount;

  /**
   * The shared {@link StringCodec} instance.
   */
  StringCodec get stringCodec;

  /**
   * Removes all nodes.
   */
  void clear();

  /**
   * Returns the {@link IndexNode} with the given name, {@code null} if not found.
   */
  Future<IndexNode> getNode(String name);

  /**
   * Returns a new {@link IndexNode}.
   */
  IndexNode newNode(AnalysisContext context);

  /**
   * Associates the given {@link IndexNode} with the given name.
   */
  void putNode(String name, IndexNode node);

  /**
   * Removes the {@link IndexNode} with the given name.
   */
  void removeNode(String name);
}

/**
 * An [Element] to [LocationImpl] relation key.
 */
class RelationKeyData {
  final int elementId1;
  final int elementId2;
  final int elementId3;
  final int relationshipId;

  RelationKeyData.forData(
      this.elementId1, this.elementId2, this.elementId3, this.relationshipId);

  RelationKeyData.forObject(
      ElementCodec elementCodec,
      RelationshipCodec relationshipCodec,
      IndexableObject indexable,
      RelationshipImpl relationship)
      : elementId1 = elementCodec.encode1(indexable),
        elementId2 = elementCodec.encode2(indexable),
        elementId3 = elementCodec.encode3(indexable),
        relationshipId = relationshipCodec.encode(relationship);

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, elementId1);
    hash = JenkinsSmiHash.combine(hash, elementId2);
    hash = JenkinsSmiHash.combine(hash, elementId3);
    hash = JenkinsSmiHash.combine(hash, relationshipId);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object obj) {
    if (obj is! RelationKeyData) {
      return false;
    }
    RelationKeyData other = obj;
    return other.elementId1 == elementId1 &&
        other.elementId2 == elementId2 &&
        other.elementId3 == elementId3 &&
        other.relationshipId == relationshipId;
  }

  @override
  String toString() {
    return 'Key($elementId2, $elementId2, $elementId3, $relationshipId)';
  }
}

/**
 * An [InternalIndexStore] which keeps index information in separate nodes for
 * each unit.
 */
class SplitIndexStore implements InternalIndexStore {
  /**
   * The [NodeManager] to get/put [IndexNode]s.
   */
  final NodeManager _nodeManager;

  final List<IndexObjectManager> _objectManagers;

  /**
   * The [ContextCodec] to encode/decode [AnalysisContext]s.
   */
  final ContextCodec _contextCodec;

  /**
   * The [ElementCodec] to encode/decode [Element]s.
   */
  final ElementCodec _elementCodec;

  /**
   * The [StringCodec] to encode/decode [String]s.
   */
  final StringCodec _stringCodec;

  /**
   * Information about top-level elements.
   * We need to keep them together to avoid loading of all index nodes.
   *
   * Order of keys: contextId, nodeId.
   */
  final Map<int, Map<int, List<_TopElementData>>> _topDeclarations =
      new Map<int, Map<int, List<_TopElementData>>>();

  int _currentContextId;
  String _currentNodeName;
  int _currentNodeNameId;
  IndexNode _currentNode;

  /**
   * A table mapping element names to the node names that may have relations with elements with
   * these names.
   */
  final Map<RelationshipImpl, IntToIntSetMap> _relToNameMap =
      new HashMap<RelationshipImpl, IntToIntSetMap>();

  /**
   * The set of known [Source]s.
   */
  final Set<Source> _sources = new HashSet<Source>();

  SplitIndexStore(NodeManager _nodeManager, this._objectManagers)
      : _nodeManager = _nodeManager,
        _contextCodec = _nodeManager.contextCodec,
        _elementCodec = _nodeManager.elementCodec,
        _stringCodec = _nodeManager.stringCodec {
    SplitIndexStoreSiteImpl site = new SplitIndexStoreSiteImpl(this);
    for (IndexObjectManager manager in _objectManagers) {
      manager.site = site;
    }
  }

  @override
  String get statistics {
    StringBuffer buf = new StringBuffer();
    buf.write('[');
    buf.write(_nodeManager.locationCount);
    buf.write(' locations, ');
    buf.write(_sources.length);
    buf.write(' sources, ');
    int namesCount = _relToNameMap.values.fold(0, (c, m) => c + m.length);
    buf.write(namesCount);
    buf.write(' names');
    buf.write(']');
    return buf.toString();
  }

  @override
  bool aboutToIndex(AnalysisContext context, Object object) {
    if (context == null || context.isDisposed) {
      return false;
    }
    // try to find a node name
    _currentNodeName = null;
    for (IndexObjectManager manager in _objectManagers) {
      _currentNodeName = manager.aboutToIndex(context, object);
      if (_currentNodeName != null) {
        break;
      }
    }
    if (_currentNodeName == null) {
      return false;
    }
    // prepare node
    _currentNodeNameId = _stringCodec.encode(_currentNodeName);
    _currentNode = _nodeManager.newNode(context);
    _currentContextId = _contextCodec.encode(context);
    // remove top-level information for the current node
    for (Map<int, dynamic> nodeRelations in _topDeclarations.values) {
      nodeRelations.remove(_currentNodeNameId);
    }
    // done
    return true;
  }

  @override
  void cancelIndex() {
    if (_currentNode != null) {
      // remove top-level information for the current node
      for (Map<int, dynamic> nodeRelations in _topDeclarations.values) {
        nodeRelations.remove(_currentNodeNameId);
      }
      // clear fields
      _currentNodeName = null;
      _currentNodeNameId = -1;
      _currentNode = null;
      _currentContextId = -1;
    }
  }

  @override
  void clear() {
    _topDeclarations.clear();
    _nodeManager.clear();
    _relToNameMap.clear();
  }

  @override
  void doneIndex() {
    if (_currentNode != null) {
      _nodeManager.putNode(_currentNodeName, _currentNode);
      _currentNodeName = null;
      _currentNodeNameId = -1;
      _currentNode = null;
      _currentContextId = -1;
    }
  }

  Future<List<LocationImpl>> getRelationships(
      IndexableObject indexable, RelationshipImpl relationship) {
    // prepare node names
    List<int> nodeNameIds;
    {
      int nameId = _elementCodec.encodeHash(indexable);
      IntToIntSetMap nameToNodeNames = _relToNameMap[relationship];
      if (nameToNodeNames != null) {
        nodeNameIds = nameToNodeNames.get(nameId);
      } else {
        nodeNameIds = <int>[];
      }
    }
    // prepare Future(s) for reading each IndexNode
    List<Future<List<LocationImpl>>> nodeFutures =
        <Future<List<LocationImpl>>>[];
    for (int nodeNameId in nodeNameIds) {
      String nodeName = _stringCodec.decode(nodeNameId);
      Future<IndexNode> nodeFuture = _nodeManager.getNode(nodeName);
      Future<List<LocationImpl>> locationsFuture = nodeFuture.then((node) {
        if (node == null) {
          // TODO(scheglov) remove node
          return LocationImpl.EMPTY_LIST;
        }
        return node.getRelationships(indexable, relationship);
      });
      nodeFutures.add(locationsFuture);
    }
    // return Future that merges separate IndexNode Location(s)
    return Future
        .wait(nodeFutures)
        .then((List<List<LocationImpl>> locationsList) {
      List<LocationImpl> allLocations = <LocationImpl>[];
      for (List<LocationImpl> locations in locationsList) {
        allLocations.addAll(locations);
      }
      return allLocations;
    });
  }

  List<Element> getTopLevelDeclarations(ElementNameFilter nameFilter) {
    List<Element> elements = <Element>[];
    _topDeclarations.forEach((contextId, contextLocations) {
      AnalysisContext context = _contextCodec.decode(contextId);
      if (context != null) {
        for (List<_TopElementData> topDataList in contextLocations.values) {
          for (_TopElementData topData in topDataList) {
            if (nameFilter(topData.name)) {
              IndexableObject indexable =
                  topData.getElement(context, _elementCodec);
              if (indexable is IndexableElement) {
                elements.add(indexable.element);
              }
            }
          }
        }
      }
    });
    return elements;
  }

  /**
   * Returns all relations with [Element]s with the given [name].
   */
  Future<Map<List<String>, List<InspectLocation>>> inspect_getElementRelations(
      String name) {
    Map<List<String>, List<InspectLocation>> result =
        <List<String>, List<InspectLocation>>{};
    // TODO(scheglov) restore index inspections?
    return new Future.value(result);
//    // prepare elements
//    Map<int, List<String>> elementMap = _elementCodec.inspect_getElements(name);
//    // prepare relations with each element
//    List<Future> futures = <Future>[];
//    if (_nodeManager is FileNodeManager) {
//      List<String> nodeNames =
//          (_nodeManager as FileNodeManager).inspect_getAllNodeNames();
//      nodeNames.forEach((nodeName) {
//        Future<IndexNode> nodeFuture = _nodeManager.getNode(nodeName);
//        Future relationsFuture = nodeFuture.then((node) {
//          if (node != null) {
//            elementMap.forEach((int elementId, List<String> elementPath) {
//              List<InspectLocation> relations =
//                  node.inspect_getRelations(nodeName, elementId);
//              List<InspectLocation> resultLocations = result[elementPath];
//              if (resultLocations == null) {
//                resultLocations = <InspectLocation>[];
//                result[elementPath] = resultLocations;
//              }
//              resultLocations.addAll(relations);
//            });
//          }
//        });
//        futures.add(relationsFuture);
//      });
//    }
//    // wait for all nodex
//    return Future.wait(futures).then((_) {
//      return result;
//    });
  }

  @override
  void recordRelationship(IndexableObject indexable,
      RelationshipImpl relationship, LocationImpl location) {
    if (indexable == null ||
        (indexable is IndexableElement &&
            indexable.element is MultiplyDefinedElement)) {
      return;
    }
    if (location == null) {
      return;
    }
    // other elements
    _recordNodeNameForElement(indexable, relationship);
    _currentNode.recordRelationship(indexable, relationship, location);
  }

  void recordTopLevelDeclaration(Element element) {
    // in current context
    Map<int, List<_TopElementData>> nodeDeclarations =
        _topDeclarations[_currentContextId];
    if (nodeDeclarations == null) {
      nodeDeclarations = new Map<int, List<_TopElementData>>();
      _topDeclarations[_currentContextId] = nodeDeclarations;
    }
    // in current node
    List<_TopElementData> declarations = nodeDeclarations[_currentNodeNameId];
    if (declarations == null) {
      declarations = <_TopElementData>[];
      nodeDeclarations[_currentNodeNameId] = declarations;
    }
    // record LocationData
    declarations.add(new _TopElementData(
        _elementCodec, element.displayName, new IndexableElement(element)));
  }

  @override
  void removeContext(AnalysisContext context) {
    if (context == null) {
      return;
    }
    // remove sources
    removeSources(context, null);
    // remove context information
    for (IndexObjectManager manager in _objectManagers) {
      manager.removeContext(context);
    }
    _topDeclarations.remove(_contextCodec.encode(context));
    // remove context from codec
    _contextCodec.remove(context);
  }

  @override
  void removeSource(AnalysisContext context, Source source) {
    if (context == null) {
      return;
    }
    for (IndexObjectManager manager in _objectManagers) {
      manager.removeSource(context, source);
    }
  }

  @override
  void removeSources(AnalysisContext context, SourceContainer container) {
    if (context == null) {
      return;
    }
    for (IndexObjectManager manager in _objectManagers) {
      manager.removeSources(context, container);
    }
  }

  void _recordNodeNameForElement(
      IndexableObject indexable, RelationshipImpl relationship) {
    IntToIntSetMap nameToNodeNames = _relToNameMap[relationship];
    if (nameToNodeNames == null) {
      nameToNodeNames = new IntToIntSetMap();
      _relToNameMap[relationship] = nameToNodeNames;
    }
    int nameId = _elementCodec.encodeHash(indexable);
    nameToNodeNames.add(nameId, _currentNodeNameId);
  }

  void _removeNodeByName(AnalysisContext context, String nodeName) {
    int nodeNameId = _stringCodec.encode(nodeName);
    _nodeManager.removeNode(nodeName);
    // remove top-level relations
    {
      int contextId = _contextCodec.encode(context);
      Map<int, dynamic> nodeRelations = _topDeclarations[contextId];
      if (nodeRelations != null) {
        nodeRelations.remove(nodeNameId);
      }
    }
  }
}

/**
 * Interface to [SplitIndexStore] for [IndexObjectManager] implementations.
 */
abstract class SplitIndexStoreSite {
  void addSource(Source source);
  int encodeString(String str);
  void removeNodeByName(AnalysisContext context, String nodeName);
  void removeSource(Source source);
}

/**
 * The implementaiton of [SplitIndexStoreSite].
 */
class SplitIndexStoreSiteImpl implements SplitIndexStoreSite {
  final SplitIndexStore store;

  SplitIndexStoreSiteImpl(this.store);

  @override
  void addSource(Source source) {
    store._sources.add(source);
  }

  @override
  int encodeString(String str) {
    return store._stringCodec.encode(str);
  }

  @override
  void removeNodeByName(AnalysisContext context, String nodeName) {
    store._removeNodeByName(context, nodeName);
  }

  @override
  void removeSource(Source source) {
    store._sources.remove(source);
  }
}

class _DataInputStream {
  ByteData _byteData;
  int _byteOffset = 0;

  _DataInputStream(List<int> bytes) {
    ByteBuffer buffer = new Uint8List.fromList(bytes).buffer;
    _byteData = new ByteData.view(buffer);
  }

  int readInt() {
    int result = _byteData.getInt32(_byteOffset, Endianness.HOST_ENDIAN);
    _byteOffset += 4;
    return result;
  }
}

class _DataOutputStream {
  static const LIST_SIZE = 1024;
  int _size = LIST_SIZE;
  Uint32List _buf = new Uint32List(LIST_SIZE);
  int _pos = 0;

  Uint8List getBytes() {
    return new Uint8List.view(_buf.buffer, 0, _size << 2);
  }

  void writeInt(int value) {
    if (_pos == _size) {
      int newSize = _size << 1;
      Uint32List newBuf = new Uint32List(newSize);
      newBuf.setRange(0, _size, _buf);
      _size = newSize;
      _buf = newBuf;
    }
    _buf[_pos++] = value;
  }
}

class _TopElementData {
  final String name;
  final int elementId1;
  final int elementId2;
  final int elementId3;

  factory _TopElementData(
      ElementCodec elementCodec, String name, IndexableObject indexable) {
    return new _TopElementData._(name, elementCodec.encode1(indexable),
        elementCodec.encode2(indexable), elementCodec.encode3(indexable));
  }

  _TopElementData._(
      this.name, this.elementId1, this.elementId2, this.elementId3);

  IndexableObject getElement(
      AnalysisContext context, ElementCodec elementCodec) {
    return elementCodec.decode(context, elementId1, elementId2, elementId3);
  }
}
