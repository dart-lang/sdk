// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.index.split.store;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/index/split_store.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/index.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('ContextCodec', () {
    runReflectiveTests(_ContextCodecTest);
  });
  group('ElementCodec', () {
    runReflectiveTests(_ElementCodecTest);
  });
  group('FileNodeManager', () {
    runReflectiveTests(_FileNodeManagerTest);
  });
  group('IndexNode', () {
    runReflectiveTests(_IndexNodeTest);
  });
  group('IntToIntSetMap', () {
    runReflectiveTests(_IntToIntSetMapTest);
  });
  group('LocationData', () {
    runReflectiveTests(_LocationDataTest);
  });
  group('RelationKeyData', () {
    runReflectiveTests(_RelationKeyDataTest);
  });
  group('RelationshipCodec', () {
    runReflectiveTests(_RelationshipCodecTest);
  });
  group('SplitIndexStore', () {
    runReflectiveTests(_SplitIndexStoreTest);
  });
  group('StringCodec', () {
    runReflectiveTests(_StringCodecTest);
  });
}


void _assertHasLocation(List<Location> locations, Element element, int offset,
    int length) {
  for (Location location in locations) {
    if ((element == null || location.element == element) && location.offset ==
        offset && location.length == length) {
      return;
    }
  }
  fail('Expected to find Location'
      '(element=$element, offset=$offset, length=$length)');
}


@ReflectiveTestCase()
class _ContextCodecTest {
  ContextCodec codec = new ContextCodec();

  void test_encode_decode() {
    AnalysisContext contextA = new _MockAnalysisContext('contextA');
    AnalysisContext contextB = new _MockAnalysisContext('contextB');
    int idA = codec.encode(contextA);
    int idB = codec.encode(contextB);
    expect(idA, codec.encode(contextA));
    expect(idB, codec.encode(contextB));
    expect(codec.decode(idA), contextA);
    expect(codec.decode(idB), contextB);
  }

  void test_remove() {
    // encode
    {
      AnalysisContext context = new _MockAnalysisContext('context');
      // encode
      int id = codec.encode(context);
      expect(id, 0);
      expect(codec.decode(id), context);
      // remove
      codec.remove(context);
      expect(codec.decode(id), isNull);
    }
    // encode again
    {
      AnalysisContext context = new _MockAnalysisContext('context');
      // encode
      int id = codec.encode(context);
      expect(id, 1);
      expect(codec.decode(id), context);
    }
  }
}


@ReflectiveTestCase()
class _ElementCodecTest {
  ElementCodec codec;
  AnalysisContext context = new _MockAnalysisContext('context');
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    codec = new ElementCodec(stringCodec);
  }

  void test_localLocalVariable() {
    {
      Element element = new _MockElement();
      ElementLocation location = new ElementLocationImpl.con3(["main", "foo@1",
          "bar@2"]);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    {
      Element element = new _MockElement();
      ElementLocation location = new ElementLocationImpl.con3(["main", "foo@10",
          "bar@20"]);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    // check strings, "foo" as a single string, no "foo@1" or "foo@10"
    expect(stringCodec.nameToIndex, hasLength(3));
    expect(stringCodec.nameToIndex, containsPair('main', 0));
    expect(stringCodec.nameToIndex, containsPair('foo', 1));
    expect(stringCodec.nameToIndex, containsPair('bar', 2));
  }

  void test_localVariable() {
    {
      Element element = new _MockElement();
      ElementLocation location = new ElementLocationImpl.con3(["main",
          "foo@42"]);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    {
      Element element = new _MockElement();
      ElementLocation location = new ElementLocationImpl.con3(["main",
          "foo@4200"]);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    // check strings, "foo" as a single string, no "foo@42" or "foo@4200"
    expect(stringCodec.nameToIndex, hasLength(2));
    expect(stringCodec.nameToIndex, containsPair('main', 0));
    expect(stringCodec.nameToIndex, containsPair('foo', 1));
  }

  void test_notLocal() {
    Element element = new _MockElement();
    ElementLocation location = new ElementLocationImpl.con3(["foo", "bar"]);
    when(element.location).thenReturn(location);
    when(context.getElement(location)).thenReturn(element);
    int id = codec.encode(element);
    expect(codec.encode(element), id);
    expect(codec.decode(context, id), element);
    // check strings
    expect(stringCodec.nameToIndex, hasLength(2));
    expect(stringCodec.nameToIndex, containsPair('foo', 0));
    expect(stringCodec.nameToIndex, containsPair('bar', 1));
  }
}


@ReflectiveTestCase()
class _FileNodeManagerTest {
  AnalysisContext context = new _MockAnalysisContext('context');
  ContextCodec contextCodec = new _MockContextCodec();
  int contextId = 13;
  ElementCodec elementCodec = new _MockElementCodec();
  FileManager fileManager = new _MockFileManager();
  _MockLogger logger = new _MockLogger();
  int nextElementId = 0;
  FileNodeManager nodeManager;
  RelationshipCodec relationshipCodec;
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    relationshipCodec = new RelationshipCodec(stringCodec);
    nodeManager = new FileNodeManager(fileManager, logger, stringCodec,
        contextCodec, elementCodec, relationshipCodec);
    when(contextCodec.encode(context)).thenReturn(contextId);
    when(contextCodec.decode(contextId)).thenReturn(context);
  }

  void test_clear() {
    nodeManager.clear();
    verify(fileManager.clear()).once();
  }

  void test_getLocationCount_empty() {
    expect(nodeManager.locationCount, 0);
  }

  void test_getNode_contextNull() {
    String name = "42.index";
    // record bytes
    List<int> bytes;
    when(fileManager.write(name, anyObject)).thenInvoke((name, bs) {
      bytes = bs;
    });
    // put Node
    Future putFuture;
    {
      IndexNode node = new IndexNode(context, elementCodec, relationshipCodec);
      putFuture = nodeManager.putNode(name, node);
    }
    // do in the "put" Future
    putFuture.then((_) {
      // force "null" context
      when(contextCodec.decode(contextId)).thenReturn(null);
      // prepare input bytes
      when(fileManager.read(name)).thenReturn(new Future.value(bytes));
      // get Node
      return nodeManager.getNode(name).then((IndexNode node) {
        expect(node, isNull);
        // no exceptions
        verifyZeroInteractions(logger);
      });
    });
  }

  test_getNode_invalidVersion() {
    String name = "42.index";
    // prepare a stream with an invalid version
    when(fileManager.read(name)).thenReturn(new Future.value([0x01, 0x02, 0x03,
        0x04]));
    // do in the Future
    return nodeManager.getNode(name).then((IndexNode node) {
      // no IndexNode
      expect(node, isNull);
      // failed
      verify(logger.logError2(anyObject, anyObject)).once();
    });
  }

  test_getNode_streamException() {
    String name = "42.index";
    when(fileManager.read(name)).thenReturn(new Future(() {
      return throw new Exception();
    }));
    // do in the Future
    return nodeManager.getNode(name).then((IndexNode node) {
      expect(node, isNull);
      // failed
      verify(logger.logError2(anyString, anyObject)).once();
    });
  }

  test_getNode_streamNull() {
    String name = "42.index";
    when(fileManager.read(name)).thenReturn(new Future.value(null));
    // do in the Future
    return nodeManager.getNode(name).then((IndexNode node) {
      expect(node, isNull);
      // OK
      verifyZeroInteractions(logger);
    });
  }

  void test_newNode() {
    IndexNode node = nodeManager.newNode(context);
    expect(node.context, context);
    expect(node.locationCount, 0);
  }

  test_putNode_getNode() {
    String name = "42.index";
    // record bytes
    List<int> bytes;
    when(fileManager.write(name, anyObject)).thenInvoke((name, bs) {
      bytes = bs;
    });
    // prepare elements
    Element elementA = _mockElement();
    Element elementB = _mockElement();
    Element elementC = _mockElement();
    Relationship relationship = Relationship.getRelationship("my-relationship");
    // put Node
    Future putFuture;
    {
      // prepare relations
      int elementIdA = 0;
      int elementIdB = 1;
      int elementIdC = 2;
      int relationshipId = relationshipCodec.encode(relationship);
      RelationKeyData key = new RelationKeyData.forData(elementIdA,
          relationshipId);
      List<LocationData> locations = [new LocationData.forData(elementIdB, 1,
          10), new LocationData.forData(elementIdC, 2, 20)];
      Map<RelationKeyData, List<LocationData>> relations = {
        key: locations
      };
      // prepare Node
      IndexNode node = new _MockIndexNode();
      when(node.context).thenReturn(context);
      when(node.relations).thenReturn(relations);
      when(node.locationCount).thenReturn(2);
      // put Node
      putFuture = nodeManager.putNode(name, node);
    }
    // do in the Future
    putFuture.then((_) {
      // has locations
      expect(nodeManager.locationCount, 2);
      // prepare input bytes
      when(fileManager.read(name)).thenReturn(new Future.value(bytes));
      // get Node
      return nodeManager.getNode(name).then((IndexNode node) {
        expect(2, node.locationCount);
        {
          List<Location> locations = node.getRelationships(elementA,
              relationship);
          expect(locations, hasLength(2));
          _assertHasLocation(locations, elementB, 1, 10);
          _assertHasLocation(locations, elementC, 2, 20);
        }
      });
    });
  }

  test_putNode_streamException() {
    String name = "42.index";
    Exception exception = new Exception();
    when(fileManager.write(name, anyObject)).thenReturn(new Future(() {
      return throw exception;
    }));
    // prepare IndexNode
    IndexNode node = new _MockIndexNode();
    when(node.context).thenReturn(context);
    when(node.locationCount).thenReturn(0);
    when(node.relations).thenReturn({});
    // try to put
    return nodeManager.putNode(name, node).then((_) {
      // failed
      verify(logger.logError2(anyString, anyObject)).once();
    });
  }

  void test_removeNode() {
    String name = "42.index";
    nodeManager.removeNode(name);
    verify(fileManager.delete(name)).once();
  }

  Element _mockElement() {
    int elementId = nextElementId++;
    Element element = new _MockElement();
    when(elementCodec.encode(element)).thenReturn(elementId);
    when(elementCodec.decode(context, elementId)).thenReturn(element);
    return element;
  }
}


@ReflectiveTestCase()
class _IndexNodeTest {
  AnalysisContext context = new _MockAnalysisContext('context');
  ElementCodec elementCodec = new _MockElementCodec();
  int nextElementId = 0;
  IndexNode node;
  RelationshipCodec relationshipCodec;
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    relationshipCodec = new RelationshipCodec(stringCodec);
    node = new IndexNode(context, elementCodec, relationshipCodec);
  }

  void test_getContext() {
    expect(node.context, context);
  }

  void test_recordRelationship() {
    Element elementA = _mockElement();
    Element elementB = _mockElement();
    Element elementC = _mockElement();
    Relationship relationship = Relationship.getRelationship("my-relationship");
    Location locationA = new Location(elementB, 1, 2);
    Location locationB = new Location(elementC, 10, 20);
    // empty initially
    expect(node.locationCount, 0);
    // record
    node.recordRelationship(elementA, relationship, locationA);
    expect(node.locationCount, 1);
    node.recordRelationship(elementA, relationship, locationB);
    expect(node.locationCount, 2);
    // get relations
    expect(node.getRelationships(elementB, relationship), isEmpty);
    {
      List<Location> locations = node.getRelationships(elementA, relationship);
      expect(locations, hasLength(2));
      _assertHasLocation(locations, null, 1, 2);
      _assertHasLocation(locations, null, 10, 20);
    }
    // verify relations map
    {
      Map<RelationKeyData, List<LocationData>> relations = node.relations;
      expect(relations, hasLength(1));
      List<LocationData> locations = relations.values.first;
      expect(locations, hasLength(2));
    }
  }

  void test_setRelations() {
    Element elementA = _mockElement();
    Element elementB = _mockElement();
    Element elementC = _mockElement();
    Relationship relationship = Relationship.getRelationship("my-relationship");
    // record
    {
      int elementIdA = 0;
      int elementIdB = 1;
      int elementIdC = 2;
      int relationshipId = relationshipCodec.encode(relationship);
      RelationKeyData key = new RelationKeyData.forData(elementIdA,
          relationshipId);
      List<LocationData> locations = [new LocationData.forData(elementIdB, 1,
          10), new LocationData.forData(elementIdC, 2, 20)];
      node.relations = {
        key: locations
      };
    }
    // request
    List<Location> locations = node.getRelationships(elementA, relationship);
    expect(locations, hasLength(2));
    _assertHasLocation(locations, elementB, 1, 10);
    _assertHasLocation(locations, elementC, 2, 20);
  }

  Element _mockElement() {
    int elementId = nextElementId++;
    Element element = new _MockElement();
    when(elementCodec.encode(element)).thenReturn(elementId);
    when(elementCodec.decode(context, elementId)).thenReturn(element);
    return element;
  }
}


@ReflectiveTestCase()
class _IntToIntSetMapTest {
  IntToIntSetMap map = new IntToIntSetMap(32, 0.75);

  void test_clear() {
    map.add(1, 10);
    map.add(2, 20);
    expect(map.length, 2);
    map.clear();
    expect(map.length, 0);
  }

  void test_get() {
    map.add(1, 10);
    map.add(1, 11);
    map.add(1, 12);
    map.add(2, 20);
    map.add(2, 21);
    expect(map.get(1), unorderedEquals([10, 11, 12]));
    expect(map.get(2), unorderedEquals([20, 21]));
  }

  void test_get_no() {
    expect(map.get(3), []);
  }

  void test_length() {
    expect(map.length, 0);
    map.add(1, 10);
    expect(map.length, 1);
    map.add(1, 11);
    expect(map.length, 2);
    map.add(1, 12);
    expect(map.length, 3);
    map.add(2, 20);
    expect(map.length, 4);
    map.add(2, 21);
    expect(map.length, 5);
  }
}


@ReflectiveTestCase()
class _LocationDataTest {
  AnalysisContext context = new _MockAnalysisContext('context');
  ElementCodec elementCodec = new _MockElementCodec();
  StringCodec stringCodec = new StringCodec();

  void test_newForData() {
    Element element = new _MockElement();
    when(elementCodec.decode(context, 0)).thenReturn(element);
    LocationData locationData = new LocationData.forData(0, 1, 2);
    Location location = locationData.getLocation(context, elementCodec);
    expect(location.element, element);
    expect(location.offset, 1);
    expect(location.length, 2);
  }

  void test_newForObject() {
    // prepare Element
    Element element = new _MockElement();
    when(elementCodec.encode(element)).thenReturn(42);
    when(elementCodec.decode(context, 42)).thenReturn(element);
    // create
    Location location = new Location(element, 1, 2);
    LocationData locationData = new LocationData.forObject(elementCodec,
        location);
    // touch 'hashCode'
    locationData.hashCode;
    // ==
    expect(locationData == new LocationData.forData(42, 1, 2), isTrue);
    // getLocation()
    {
      Location newLocation = locationData.getLocation(context, elementCodec);
      expect(location.element, element);
      expect(location.offset, 1);
      expect(location.length, 2);
    }
    // no Element - no Location
    {
      when(elementCodec.decode(context, 42)).thenReturn(null);
      Location newLocation = locationData.getLocation(context, elementCodec);
      expect(newLocation, isNull);
    }
  }
}


/**
 * [Location] has no [==] and [hashCode], so to compare locations by value we
 * need to wrap them into such object.
 */
class _LocationEqualsWrapper {
  final Location location;

  _LocationEqualsWrapper(this.location);

  @override
  int get hashCode {
    return 31 * (31 * location.element.hashCode + location.offset) +
        location.length;
  }

  @override
  bool operator ==(Object other) {
    if (other is _LocationEqualsWrapper) {
      return other.location.offset == location.offset && other.location.length
          == location.length && other.location.element == location.element;
    }
    return false;
  }
}


class _MemoryNodeManager implements NodeManager {
  ContextCodec _contextCodec = new ContextCodec();
  ElementCodec _elementCodec;
  int _locationCount = 0;
  final Map<String, int> _nodeLocationCounts = new HashMap<String, int>();

  final Map<String, IndexNode> _nodes = new HashMap<String, IndexNode>();
  RelationshipCodec _relationshipCodec;
  StringCodec _stringCodec = new StringCodec();

  _MemoryNodeManager() {
    _elementCodec = new ElementCodec(_stringCodec);
    _relationshipCodec = new RelationshipCodec(_stringCodec);
  }

  @override
  ContextCodec get contextCodec {
    return _contextCodec;
  }

  @override
  ElementCodec get elementCodec {
    return _elementCodec;
  }

  @override
  int get locationCount {
    return _locationCount;
  }

  @override
  StringCodec get stringCodec {
    return _stringCodec;
  }

  @override
  void clear() {
    _nodes.clear();
  }

  int getLocationCount(String name) {
    int locationCount = _nodeLocationCounts[name];
    return locationCount != null ? locationCount : 0;
  }

  @override
  Future<IndexNode> getNode(String name) {
    return new Future.value(_nodes[name]);
  }

  bool isEmpty() {
    for (IndexNode node in _nodes.values) {
      Map<RelationKeyData, List<LocationData>> relations = node.relations;
      if (!relations.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  IndexNode newNode(AnalysisContext context) {
    return new IndexNode(context, elementCodec, _relationshipCodec);
  }

  @override
  void putNode(String name, IndexNode node) {
    // update location count
    {
      _locationCount -= getLocationCount(name);
      int nodeLocationCount = node.locationCount;
      _nodeLocationCounts[name] = nodeLocationCount;
      _locationCount += nodeLocationCount;
    }
    // remember the node
    _nodes[name] = node;
  }

  @override
  void removeNode(String name) {
    _nodes.remove(name);
  }
}


class _MockAnalysisContext extends TypedMock implements AnalysisContext {
  String _name;
  _MockAnalysisContext(this._name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


class _MockCompilationUnitElement extends TypedMock implements
    CompilationUnitElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockContextCodec extends TypedMock implements ContextCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockElement extends TypedMock implements Element {
  String _name;
  _MockElement([this._name = '<element>']);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


class _MockElementCodec extends TypedMock implements ElementCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockFileManager extends TypedMock implements FileManager {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockHtmlElement extends TypedMock implements HtmlElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockIndexNode extends TypedMock implements IndexNode {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockInstrumentedAnalysisContextImpl extends TypedMock implements
    InstrumentedAnalysisContextImpl {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockLibraryElement extends TypedMock implements LibraryElement {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockLocation extends TypedMock implements Location {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockLogger extends TypedMock implements Logger {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockRelationshipCodec extends TypedMock implements RelationshipCodec {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class _MockSource extends TypedMock implements Source {
  String _name;
  _MockSource(this._name);
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  String toString() => _name;
}


@ReflectiveTestCase()
class _RelationKeyDataTest {
  AnalysisContext context = new _MockAnalysisContext('context');
  ElementCodec elementCodec = new _MockElementCodec();
  RelationshipCodec relationshipCodec = new _MockRelationshipCodec();
  StringCodec stringCodec = new StringCodec();

  void test_newFromData() {
    RelationKeyData keyData = new RelationKeyData.forData(1, 2);
    // equals
    expect(keyData == this, isFalse);
    expect(keyData == new RelationKeyData.forData(10, 20), isFalse);
    expect(keyData == keyData, isTrue);
    expect(keyData == new RelationKeyData.forData(1, 2), isTrue);
  }

  void test_newFromObjects() {
    // prepare Element
    Element element;
    int elementId = 2;
    {
      element = new _MockElement();
      ElementLocation location = new ElementLocationImpl.con3(["foo", "bar"]);
      when(element.location).thenReturn(location);
      when(context.getElement(location)).thenReturn(element);
      when(elementCodec.encode(element)).thenReturn(elementId);
    }
    // prepare relationship
    Relationship relationship = Relationship.getRelationship("my-relationship");
    int relationshipId = 1;
    when(relationshipCodec.encode(relationship)).thenReturn(relationshipId);
    // create RelationKeyData
    RelationKeyData keyData = new RelationKeyData.forObject(elementCodec,
        relationshipCodec, element, relationship);
    // touch
    keyData.hashCode;
    // equals
    expect(keyData == this, isFalse);
    expect(keyData == new RelationKeyData.forData(10, 20), isFalse);
    expect(keyData == keyData, isTrue);
    expect(keyData == new RelationKeyData.forData(elementId, relationshipId),
        isTrue);
  }
}


@ReflectiveTestCase()
class _RelationshipCodecTest {
  RelationshipCodec codec;
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    codec = new RelationshipCodec(stringCodec);
  }

  void test_all() {
    Relationship relationship = Relationship.getRelationship("my-relationship");
    int id = codec.encode(relationship);
    expect(codec.decode(id), relationship);
  }
}


class _SingleSourceContainer implements SourceContainer {
  final Source _source;
  _SingleSourceContainer(this._source);
  @override
  bool contains(Source source) => source == _source;
}


@ReflectiveTestCase()
class _SplitIndexStoreTest {
  AnalysisContext contextA = new _MockAnalysisContext('contextA');

  AnalysisContext contextB = new _MockAnalysisContext('contextB');

  AnalysisContext contextC = new _MockAnalysisContext('contextC');

  Element elementA = new _MockElement('elementA');
  Element elementB = new _MockElement('elementB');

  Element elementC = new _MockElement('elementC');
  Element elementD = new _MockElement('elementD');
  ElementLocation elementLocationA = new ElementLocationImpl.con3(
      ["/home/user/sourceA.dart", "ClassA"]);
  ElementLocation elementLocationB = new ElementLocationImpl.con3(
      ["/home/user/sourceB.dart", "ClassB"]);
  ElementLocation elementLocationC = new ElementLocationImpl.con3(
      ["/home/user/sourceC.dart", "ClassC"]);
  ElementLocation elementLocationD = new ElementLocationImpl.con3(
      ["/home/user/sourceD.dart", "ClassD"]);
  HtmlElement htmlElementA = new _MockHtmlElement();
  HtmlElement htmlElementB = new _MockHtmlElement();
  LibraryElement libraryElement = new _MockLibraryElement();
  Source librarySource = new _MockSource('librarySource');
  CompilationUnitElement libraryUnitElement = new _MockCompilationUnitElement();
  _MemoryNodeManager nodeManager = new _MemoryNodeManager();
  Relationship relationship = Relationship.getRelationship("test-relationship");
  Source sourceA = new _MockSource('sourceA');
  Source sourceB = new _MockSource('sourceB');
  Source sourceC = new _MockSource('sourceC');
  Source sourceD = new _MockSource('sourceD');
  SplitIndexStore store;
  CompilationUnitElement unitElementA = new _MockCompilationUnitElement();
  CompilationUnitElement unitElementB = new _MockCompilationUnitElement();
  CompilationUnitElement unitElementC = new _MockCompilationUnitElement();
  CompilationUnitElement unitElementD = new _MockCompilationUnitElement();
  void setUp() {
    store = new SplitIndexStore(nodeManager);
    when(contextA.isDisposed).thenReturn(false);
    when(contextB.isDisposed).thenReturn(false);
    when(contextC.isDisposed).thenReturn(false);
    when(contextA.getElement(elementLocationA)).thenReturn(elementA);
    when(contextA.getElement(elementLocationB)).thenReturn(elementB);
    when(contextA.getElement(elementLocationC)).thenReturn(elementC);
    when(contextA.getElement(elementLocationD)).thenReturn(elementD);
    when(sourceA.fullName).thenReturn("/home/user/sourceA.dart");
    when(sourceB.fullName).thenReturn("/home/user/sourceB.dart");
    when(sourceC.fullName).thenReturn("/home/user/sourceC.dart");
    when(sourceD.fullName).thenReturn("/home/user/sourceD.dart");
    when(elementA.context).thenReturn(contextA);
    when(elementB.context).thenReturn(contextA);
    when(elementC.context).thenReturn(contextA);
    when(elementD.context).thenReturn(contextA);
    when(elementA.location).thenReturn(elementLocationA);
    when(elementB.location).thenReturn(elementLocationB);
    when(elementC.location).thenReturn(elementLocationC);
    when(elementD.location).thenReturn(elementLocationD);
    when(elementA.enclosingElement).thenReturn(unitElementA);
    when(elementB.enclosingElement).thenReturn(unitElementB);
    when(elementC.enclosingElement).thenReturn(unitElementC);
    when(elementD.enclosingElement).thenReturn(unitElementD);
    when(elementA.source).thenReturn(sourceA);
    when(elementB.source).thenReturn(sourceB);
    when(elementC.source).thenReturn(sourceC);
    when(elementD.source).thenReturn(sourceD);
    when(elementA.library).thenReturn(libraryElement);
    when(elementB.library).thenReturn(libraryElement);
    when(elementC.library).thenReturn(libraryElement);
    when(elementD.library).thenReturn(libraryElement);
    when(unitElementA.source).thenReturn(sourceA);
    when(unitElementB.source).thenReturn(sourceB);
    when(unitElementC.source).thenReturn(sourceC);
    when(unitElementD.source).thenReturn(sourceD);
    when(unitElementA.library).thenReturn(libraryElement);
    when(unitElementB.library).thenReturn(libraryElement);
    when(unitElementC.library).thenReturn(libraryElement);
    when(unitElementD.library).thenReturn(libraryElement);
    when(htmlElementA.source).thenReturn(sourceA);
    when(htmlElementB.source).thenReturn(sourceB);
    // library
    when(libraryUnitElement.library).thenReturn(libraryElement);
    when(libraryUnitElement.source).thenReturn(librarySource);
    when(libraryElement.source).thenReturn(librarySource);
    when(libraryElement.definingCompilationUnit).thenReturn(libraryUnitElement);
  }
  void test_aboutToIndexDart_disposedContext() {
    when(contextA.isDisposed).thenReturn(true);
    expect(store.aboutToIndexDart(contextA, unitElementA), isFalse);
  }
  void test_aboutToIndexDart_disposedContext_wrapped() {
    when(contextA.isDisposed).thenReturn(true);
    InstrumentedAnalysisContextImpl instrumentedContext =
        new _MockInstrumentedAnalysisContextImpl();
    when(instrumentedContext.basis).thenReturn(contextA);
    expect(store.aboutToIndexDart(instrumentedContext, unitElementA), isFalse);
  }

  void test_aboutToIndexDart_library_first() {
    when(libraryElement.parts).thenReturn(<CompilationUnitElement>[unitElementA,
        unitElementB]);
    {
      store.aboutToIndexDart(contextA, libraryUnitElement);
      store.doneIndex();
    }
    {
      List<Location> locations = store.getRelationships(elementA, relationship);
      assertLocations(locations, []);
    }
  }

  test_aboutToIndexDart_library_secondWithoutOneUnit() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // apply "libraryUnitElement", only with "B"
      when(libraryElement.parts).thenReturn([unitElementB]);
      {
        store.aboutToIndexDart(contextA, libraryUnitElement);
        store.doneIndex();
      }
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, [locationB]);
      });
    });
  }

  void test_aboutToIndexDart_nullLibraryElement() {
    when(unitElementA.library).thenReturn(null);
    expect(store.aboutToIndexDart(contextA, unitElementA), isFalse);
  }

  void test_aboutToIndexDart_nullLibraryUnitElement() {
    when(libraryElement.definingCompilationUnit).thenReturn(null);
    expect(store.aboutToIndexDart(contextA, unitElementA), isFalse);
  }

  void test_aboutToIndexDart_nullUnitElement() {
    expect(store.aboutToIndexDart(contextA, null), isFalse);
  }

  test_aboutToIndexHtml_() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexHtml(contextA, htmlElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexHtml(contextA, htmlElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  void test_aboutToIndexHtml_disposedContext() {
    when(contextA.isDisposed).thenReturn(true);
    expect(store.aboutToIndexHtml(contextA, htmlElementA), isFalse);
  }

  void test_clear() {
    Location locationA = mockLocation(elementA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(elementA, relationship, locationA);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isFalse);
    // clear
    store.clear();
    expect(nodeManager.isEmpty(), isTrue);
  }

  test_getRelationships_empty() {
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      expect(locations, isEmpty);
    });
  }

  void test_getStatistics() {
    // empty initially
    {
      String statistics = store.statistics;
      expect(statistics, contains('0 locations'));
      expect(statistics, contains('0 sources'));
    }
    // add 2 locations
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    {
      String statistics = store.statistics;
      expect(statistics, contains('2 locations'));
      expect(statistics, contains('3 sources'));
    }
  }

  void test_recordRelationship_nullElement() {
    Location locationA = mockLocation(elementA);
    store.recordRelationship(null, relationship, locationA);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isTrue);
  }

  void test_recordRelationship_nullLocation() {
    store.recordRelationship(elementA, relationship, null);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isTrue);
  }

  test_recordRelationship_oneElement_twoNodes() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  test_recordRelationship_oneLocation() {
    Location locationA = mockLocation(elementA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(elementA, relationship, locationA);
    store.doneIndex();
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA]);
    });
  }

  test_recordRelationship_twoLocations() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(elementA, relationship, locationA);
    store.recordRelationship(elementA, relationship, locationB);
    store.doneIndex();
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  test_removeContext() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // remove "A" context
      store.removeContext(contextA);
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeContext_nullContext() {
    store.removeContext(null);
  }

  test_removeSource_library() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    Location locationC = mockLocation(elementC);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordRelationship(elementA, relationship, locationC);
      store.doneIndex();
    }
    // "A", "B" and "C" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB, locationC]);
    }).then((_) {
      // remove "librarySource"
      store.removeSource(contextA, librarySource);
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeSource_nullContext() {
    store.removeSource(null, sourceA);
  }

  test_removeSource_unit() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    Location locationC = mockLocation(elementC);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordRelationship(elementA, relationship, locationC);
      store.doneIndex();
    }
    // "A", "B" and "C" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB, locationC]);
    }).then((_) {
      // remove "A" source
      store.removeSource(contextA, sourceA);
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, [locationB, locationC]);
      });
    });
  }

  test_removeSources_library() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // remove "librarySource"
      store.removeSources(contextA, new _SingleSourceContainer(librarySource));
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeSources_nullContext() {
    store.removeSources(null, null);
  }

  test_removeSources_unit() {
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    Location locationC = mockLocation(elementC);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(elementA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(elementA, relationship, locationB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordRelationship(elementA, relationship, locationC);
      store.doneIndex();
    }
    // "A", "B" and "C" locations
    return store.getRelationshipsAsync(elementA, relationship).then(
        (List<Location> locations) {
      assertLocations(locations, [locationA, locationB, locationC]);
    }).then((_) {
      // remove "A" source
      store.removeSources(contextA, new _SingleSourceContainer(sourceA));
      store.removeSource(contextA, sourceA);
      return store.getRelationshipsAsync(elementA, relationship).then(
          (List<Location> locations) {
        assertLocations(locations, [locationB, locationC]);
      });
    });
  }

  test_universe_aboutToIndex() {
    when(contextA.getElement(elementLocationA)).thenReturn(elementA);
    when(contextB.getElement(elementLocationB)).thenReturn(elementB);
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(UniverseElement.INSTANCE, relationship,
          locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordRelationship(UniverseElement.INSTANCE, relationship,
          locationB);
      store.doneIndex();
    }
    // get relationships
    return store.getRelationshipsAsync(UniverseElement.INSTANCE,
        relationship).then((List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // re-index "unitElementA"
      store.aboutToIndexDart(contextA, unitElementA);
      store.doneIndex();
      return store.getRelationshipsAsync(UniverseElement.INSTANCE,
          relationship).then((List<Location> locations) {
        assertLocations(locations, [locationB]);
      });
    });
  }

  test_universe_removeContext() {
    when(contextA.getElement(elementLocationA)).thenReturn(elementA);
    when(contextB.getElement(elementLocationB)).thenReturn(elementB);
    Location locationA = mockLocation(elementA);
    Location locationB = mockLocation(elementB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(UniverseElement.INSTANCE, relationship,
          locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordRelationship(UniverseElement.INSTANCE, relationship,
          locationB);
      store.doneIndex();
    }
    return store.getRelationshipsAsync(UniverseElement.INSTANCE,
        relationship).then((List<Location> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // remove "contextA"
      store.removeContext(contextA);
      return store.getRelationshipsAsync(UniverseElement.INSTANCE,
          relationship).then((List<Location> locations) {
        assertLocations(locations, [locationB]);
      });
    });
  }

  /**
   * Asserts that the "actual" locations have all the "expected" locations and only them.
   */
  static void assertLocations(List<Location> actual, List<Location> expected) {
    List<_LocationEqualsWrapper> actualWrappers = wrapLocations(actual);
    List<_LocationEqualsWrapper> expectedWrappers = wrapLocations(expected);
    expect(actualWrappers, unorderedEquals(expectedWrappers));
  }

  /**
   * @return the new [Location] mock.
   */
  static Location mockLocation(Element element) {
    Location location = new _MockLocation();
    when(location.element).thenReturn(element);
    when(location.offset).thenReturn(0);
    when(location.length).thenReturn(0);
    return location;
  }

  /**
   * Wraps the given locations into [LocationEqualsWrapper].
   */
  static List<_LocationEqualsWrapper> wrapLocations(List<Location> locations) {
    List<_LocationEqualsWrapper> wrappers = <_LocationEqualsWrapper>[];
    for (Location location in locations) {
      wrappers.add(new _LocationEqualsWrapper(location));
    }
    return wrappers;
  }
}


@ReflectiveTestCase()
class _StringCodecTest {
  StringCodec codec = new StringCodec();

  void test_all() {
    int idA = codec.encode('aaa');
    int idB = codec.encode('bbb');
    expect(codec.decode(idA), 'aaa');
    expect(codec.decode(idB), 'bbb');
  }
}
