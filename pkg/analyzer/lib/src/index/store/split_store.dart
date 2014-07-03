// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.src.index.split_store;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/index/index.dart';
import 'package:analyzer/index/index_store.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/index/store/codec.dart';
import 'package:analyzer/src/index/store/collection.dart';


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
    }).catchError((e, stackTrace) {
      _logger.logError2('Exception during reading index file ${name}',
          new CaughtException(e, stackTrace));
    });
  }

  @override
  IndexNode newNode(AnalysisContext context) => new IndexNode(context,
      elementCodec, _relationshipCodec);

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
      _DataOutputStream stream = new _DataOutputStream();
      _writeNode(node, stream);
      var bytes = stream.getBytes();
      return _fileManager.write(name, bytes);
    }).catchError((e, stackTrace) {
      _logger.logError2('Exception during reading index file ${name}',
          new CaughtException(e, stackTrace));
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
    int elementId = stream.readInt();
    int relationshipId = stream.readInt();
    return new RelationKeyData.forData(elementId, relationshipId);
  }

  LocationData _readLocationData(_DataInputStream stream) {
    int elementId = stream.readInt();
    int offset = stream.readInt();
    int length = stream.readInt();
    return new LocationData.forData(elementId, offset, length);
  }

  IndexNode _readNode(_DataInputStream stream) {
    // check version
    {
      int version = stream.readInt();
      if (version != _VERSION) {
        throw new StateError(
            'Version ${_VERSION} expected, but ${version} found.');
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
    stream.writeInt(key.elementId);
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
        stream.writeInt(location.elementId);
        stream.writeInt(location.offset);
        stream.writeInt(location.length);
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
   * [relationship] - the [Relationship] between the given [element] and the
   *    locations to be returned
   */
  List<Location> getRelationships(Element element, Relationship relationship) {
    // prepare key
    RelationKeyData key = new RelationKeyData.forObject(_elementCodec,
        _relationshipCodec, element, relationship);
    // find LocationData(s)
    List<LocationData> locationDatas = _relations[key];
    if (locationDatas == null) {
      return Location.EMPTY_ARRAY;
    }
    // convert to Location(s)
    List<Location> locations = <Location>[];
    for (LocationData locationData in locationDatas) {
      Location location = locationData.getLocation(context, _elementCodec);
      if (location != null) {
        locations.add(location);
      }
    }
    return locations;
  }

  /**
   * Records that the given [element] and [location] have the given [relationship].
   *
   * [element] - the [Element] that is related to the location.
   * [relationship] - the [Relationship] between [element] and [location].
   * [location] - the [Location] where relationship happens.
   */
  void recordRelationship(Element element, Relationship relationship,
      Location location) {
    RelationKeyData key = new RelationKeyData.forObject(_elementCodec,
        _relationshipCodec, element, relationship);
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
 * A container with information about a [Location].
 */
class LocationData {
  final int elementId;
  final int offset;
  final int length;

  LocationData.forData(this.elementId, this.offset, this.length);

  LocationData.forObject(ElementCodec elementCodec, Location location)
      : elementId = elementCodec.encode(location.element),
        offset = location.offset,
        length = location.length;

  @override
  int get hashCode {
    return 31 * (31 * elementId + offset) + length;
  }

  @override
  bool operator ==(Object obj) {
    if (obj is! LocationData) {
      return false;
    }
    LocationData other = obj;
    return other.elementId == elementId && other.offset == offset &&
        other.length == length;
  }

  /**
   * Returns a {@link Location} that is represented by this {@link LocationData}.
   */
  Location getLocation(AnalysisContext context, ElementCodec elementCodec) {
    Element element = elementCodec.decode(context, elementId);
    if (element == null) {
      return null;
    }
    return new Location(element, offset, length);
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
 * An [Element] to [Location] relation key.
 */
class RelationKeyData {
  final int elementId;
  final int relationshipId;

  RelationKeyData.forData(this.elementId, this.relationshipId);

  RelationKeyData.forObject(ElementCodec elementCodec,
      RelationshipCodec relationshipCodec, Element element, Relationship relationship)
      : elementId = elementCodec.encode(element),
        relationshipId = relationshipCodec.encode(relationship);

  @override
  int get hashCode {
    return 31 * elementId + relationshipId;
  }

  @override
  bool operator ==(Object obj) {
    if (obj is! RelationKeyData) {
      return false;
    }
    RelationKeyData other = obj;
    return other.elementId == elementId && other.relationshipId ==
        relationshipId;
  }
}


/**
 * An [IndexStore] which keeps index information in separate nodes for each unit.
 */
class SplitIndexStore implements IndexStore {
  /**
   * The [ContextCodec] to encode/decode [AnalysisContext]s.
   */
  ContextCodec _contextCodec;

  /**
   * Information about "universe" elements.
   * We need to keep them together to avoid loading of all index nodes.
   *
   * Order of keys: contextId, nodeId, Relationship.
   */
  Map<int, Map<int, Map<Relationship, List<LocationData>>>>
      _contextNodeRelations = new HashMap<int, Map<int, Map<Relationship,
      List<LocationData>>>>();

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

  int _currentContextId = 0;

  IndexNode _currentNode;

  String _currentNodeName;

  int _currentNodeNameId = 0;

  /**
   * The [ElementCodec] to encode/decode [Element]s.
   */
  ElementCodec _elementCodec;

  /**
   * A table mapping element names to the node names that may have relations with elements with
   * these names.
   */
  IntToIntSetMap _nameToNodeNames = new IntToIntSetMap();

  /**
   * The [NodeManager] to get/put [IndexNode]s.
   */
  final NodeManager _nodeManager;

  /**
   * The set of known [Source]s.
   */
  Set<Source> _sources = new HashSet<Source>();

  /**
   * The [StringCodec] to encode/decode [String]s.
   */
  StringCodec _stringCodec;

  SplitIndexStore(this._nodeManager) {
    this._contextCodec = _nodeManager.contextCodec;
    this._elementCodec = _nodeManager.elementCodec;
    this._stringCodec = _nodeManager.stringCodec;
  }

  @override
  String get statistics =>
      '[${_nodeManager.locationCount} locations, ${_sources.length} sources, ${_nameToNodeNames.length} names]';

  @override
  bool aboutToIndexDart(AnalysisContext context,
      CompilationUnitElement unitElement) {
    context = _unwrapContext(context);
    // may be already disposed in other thread
    if (context.isDisposed) {
      return false;
    }
    // validate unit
    if (unitElement == null) {
      return false;
    }
    LibraryElement libraryElement = unitElement.library;
    if (libraryElement == null) {
      return false;
    }
    CompilationUnitElement definingUnitElement =
        libraryElement.definingCompilationUnit;
    if (definingUnitElement == null) {
      return false;
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
          _removeLocations(context, library, noPart);
        }
      }
      // remember new parts
      libraryToUnits[library] = newParts;
    }
    // remember library/unit relations
    _recordUnitInLibrary(context, library, unit);
    _recordLibraryWithUnit(context, library, unit);
    _sources.add(library);
    _sources.add(unit);
    // prepare node
    String libraryName = library.fullName;
    String unitName = unit.fullName;
    int libraryNameIndex = _stringCodec.encode(libraryName);
    int unitNameIndex = _stringCodec.encode(unitName);
    _currentNodeName = '${libraryNameIndex}_${unitNameIndex}.index';
    _currentNodeNameId = _stringCodec.encode(_currentNodeName);
    _currentNode = _nodeManager.newNode(context);
    _currentContextId = _contextCodec.encode(context);
    // remove Universe information for the current node
    for (Map<int, dynamic> nodeRelations in _contextNodeRelations.values) {
      nodeRelations.remove(_currentNodeNameId);
    }
    // done
    return true;
  }

  @override
  bool aboutToIndexHtml(AnalysisContext context, HtmlElement htmlElement) {
    context = _unwrapContext(context);
    // may be already disposed in other thread
    if (context.isDisposed) {
      return false;
    }
    // remove locations
    Source source = htmlElement.source;
    _removeLocations(context, null, source);
    // remember library/unit relations
    _recordUnitInLibrary(context, null, source);
    // prepare node
    String sourceName = source.fullName;
    int sourceNameIndex = _stringCodec.encode(sourceName);
    _currentNodeName = '${sourceNameIndex}.index';
    _currentNodeNameId = _stringCodec.encode(_currentNodeName);
    _currentNode = _nodeManager.newNode(context);
    return true;
  }

  @override
  void clear() {
    _contextNodeRelations.clear();
    _nodeManager.clear();
    _nameToNodeNames.clear();
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

  Future<List<Location>> getRelationships(Element element,
      Relationship relationship) {
    // special support for UniverseElement
    if (identical(element, UniverseElement.INSTANCE)) {
      List<Location> locations = _getRelationshipsUniverse(relationship);
      return new Future.value(locations);
    }
    // prepare node names
    String name = _getElementName(element);
    int nameId = _stringCodec.encode(name);
    List<int> nodeNameIds = _nameToNodeNames.get(nameId);
    // prepare Future(s) for reading each IndexNode
    List<Future<List<Location>>> nodeFutures = <Future<List<Location>>>[];
    for (int nodeNameId in nodeNameIds) {
      String nodeName = _stringCodec.decode(nodeNameId);
      Future<IndexNode> nodeFuture = _nodeManager.getNode(nodeName);
      Future<List<Location>> locationsFuture = nodeFuture.then((node) {
        if (node == null) {
          // TODO(scheglov) remove node
          return Location.EMPTY_ARRAY;
        }
        return node.getRelationships(element, relationship);
      });
      nodeFutures.add(locationsFuture);
    }
    // return Future that merges separate IndexNode Location(s)
    return Future.wait(nodeFutures).then((List<List<Location>> locationsList) {
      List<Location> allLocations = <Location>[];
      for (List<Location> locations in locationsList) {
        allLocations.addAll(locations);
      }
      return allLocations;
    });
  }

  @override
  void recordRelationship(Element element, Relationship relationship,
      Location location) {
    if (element == null || location == null) {
      return;
    }
    // special support for UniverseElement
    if (identical(element, UniverseElement.INSTANCE)) {
      _recordRelationshipUniverse(relationship, location);
      return;
    }
    // other elements
    _recordNodeNameForElement(element);
    _currentNode.recordRelationship(element, relationship, location);
  }

  @override
  void removeContext(AnalysisContext context) {
    context = _unwrapContext(context);
    if (context == null) {
      return;
    }
    // remove sources
    removeSources(context, null);
    // remove context information
    _contextToLibraryToUnits.remove(context);
    _contextToUnitToLibraries.remove(context);
    _contextNodeRelations.remove(_contextCodec.encode(context));
    // remove context from codec
    _contextCodec.remove(context);
  }

  @override
  void removeSource(AnalysisContext context, Source source) {
    context = _unwrapContext(context);
    if (context == null) {
      return;
    }
    // remove nodes for unit/library pairs
    Map<Source, Set<Source>> unitToLibraries =
        _contextToUnitToLibraries[context];
    if (unitToLibraries != null) {
      Set<Source> libraries = unitToLibraries.remove(source);
      if (libraries != null) {
        for (Source library in libraries) {
          _removeLocations(context, library, source);
        }
      }
    }
    // remove nodes for library/unit pairs
    Map<Source, Set<Source>> libraryToUnits = _contextToLibraryToUnits[context];
    if (libraryToUnits != null) {
      Set<Source> units = libraryToUnits.remove(source);
      if (units != null) {
        for (Source unit in units) {
          _removeLocations(context, source, unit);
        }
      }
    }
  }

  @override
  void removeSources(AnalysisContext context, SourceContainer container) {
    context = _unwrapContext(context);
    if (context == null) {
      return;
    }
    // remove nodes for unit/library pairs
    Map<Source, Set<Source>> unitToLibraries =
        _contextToUnitToLibraries[context];
    if (unitToLibraries != null) {
      List<Source> units = new List<Source>.from(unitToLibraries.keys);
      for (Source source in units) {
        if (container == null || container.contains(source)) {
          removeSource(context, source);
        }
      }
    }
    // remove nodes for library/unit pairs
    Map<Source, Set<Source>> libraryToUnits = _contextToLibraryToUnits[context];
    if (libraryToUnits != null) {
      List<Source> libraries = new List<Source>.from(libraryToUnits.keys);
      for (Source source in libraries) {
        if (container == null || container.contains(source)) {
          removeSource(context, source);
        }
      }
    }
  }

  String _getElementName(Element element) => element.name;

  List<Location> _getRelationshipsUniverse(Relationship relationship) {
    List<Location> locations = <Location>[];
    _contextNodeRelations.forEach((contextId, contextRelations) {
      AnalysisContext context = _contextCodec.decode(contextId);
      if (context != null) {
        for (Map<Relationship, List<LocationData>> nodeRelations in
            contextRelations.values) {
          List<LocationData> nodeLocations = nodeRelations[relationship];
          if (nodeLocations != null) {
            for (LocationData locationData in nodeLocations) {
              Location location = locationData.getLocation(context,
                  _elementCodec);
              if (location != null) {
                locations.add(location);
              }
            }
          }
        }
      }
    });
    return locations;
  }

  void _recordLibraryWithUnit(AnalysisContext context, Source library,
      Source unit) {
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

  void _recordNodeNameForElement(Element element) {
    String name = _getElementName(element);
    int nameId = _stringCodec.encode(name);
    _nameToNodeNames.add(nameId, _currentNodeNameId);
  }

  void _recordRelationshipUniverse(Relationship relationship,
      Location location) {
    // in current context
    Map<int, Map<Relationship, List<LocationData>>> nodeRelations =
        _contextNodeRelations[_currentContextId];
    if (nodeRelations == null) {
      nodeRelations = new HashMap<int, Map<Relationship, List<LocationData>>>();
      _contextNodeRelations[_currentContextId] = nodeRelations;
    }
    // in current node
    Map<Relationship, List<LocationData>> relations =
        nodeRelations[_currentNodeNameId];
    if (relations == null) {
      relations = new HashMap<Relationship, List<LocationData>>();
      nodeRelations[_currentNodeNameId] = relations;
    }
    // for the given relationship
    List<LocationData> locations = relations[relationship];
    if (locations == null) {
      locations = <LocationData>[];
      relations[relationship] = locations;
    }
    // record LocationData
    locations.add(new LocationData.forObject(_elementCodec, location));
  }

  void _recordUnitInLibrary(AnalysisContext context, Source library,
      Source unit) {
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

  /**
   * Removes locations recorded in the given library/unit pair.
   */
  void _removeLocations(AnalysisContext context, Source library, Source unit) {
    // remove node
    String libraryName = library != null ? library.fullName : null;
    String unitName = unit.fullName;
    int libraryNameIndex = _stringCodec.encode(libraryName);
    int unitNameIndex = _stringCodec.encode(unitName);
    String nodeName = '${libraryNameIndex}_${unitNameIndex}.index';
    int nodeNameId = _stringCodec.encode(nodeName);
    _nodeManager.removeNode(nodeName);
    // remove source
    _sources.remove(library);
    _sources.remove(unit);
    // remove universe relations
    {
      int contextId = _contextCodec.encode(context);
      Map<int, Object> nodeRelations = _contextNodeRelations[contextId];
      if (nodeRelations != null) {
        nodeRelations.remove(nodeNameId);
      }
    }
  }

  /**
   * When logging is on, [AnalysisEngine] actually creates
   * [InstrumentedAnalysisContextImpl], which wraps [AnalysisContextImpl] used to create
   * actual [Element]s. So, in index we have to unwrap [InstrumentedAnalysisContextImpl]
   * when perform any operation.
   */
  AnalysisContext _unwrapContext(AnalysisContext context) {
    if (context is InstrumentedAnalysisContextImpl) {
      context = (context as InstrumentedAnalysisContextImpl).basis;
    }
    return context;
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
    int result = _byteData.getInt32(_byteOffset);
    _byteOffset += 4;
    return result;
  }
}


class _DataOutputStream {
  BytesBuilder _buffer = new BytesBuilder();

  Uint8List getBytes() {
    return new Uint8List.fromList(_buffer.takeBytes());
  }

  void writeInt(int value) {
    _buffer.addByte((value & 0xFF000000) >> 24);
    _buffer.addByte((value & 0x00FF0000) >> 16);
    _buffer.addByte((value & 0x0000FF00) >> 8);
    _buffer.addByte(value & 0xFF);
  }
}
