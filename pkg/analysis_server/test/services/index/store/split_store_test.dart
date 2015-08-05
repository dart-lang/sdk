// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.split_store;

import 'dart:async';

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analysis_server/src/services/index/store/memory_node_manager.dart';
import 'package:analysis_server/src/services/index/store/split_store.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../../../mocks.dart';
import '../../../utils.dart';
import 'mocks.dart';
import 'single_source_container.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(_FileNodeManagerTest);
  defineReflectiveTests(_IndexNodeTest);
  defineReflectiveTests(_LocationDataTest);
  defineReflectiveTests(_RelationKeyDataTest);
  defineReflectiveTests(_SplitIndexStoreTest);
}

void _assertHasLocation(List<LocationImpl> locations, IndexableElement element,
    int offset, int length,
    {bool isQualified: false, bool isResolved: true}) {
  for (LocationImpl location in locations) {
    if ((element == null || location.indexable == element) &&
        location.offset == offset &&
        location.length == length &&
        location.isQualified == isQualified &&
        location.isResolved == isResolved) {
      return;
    }
  }
  fail('Expected to find Location'
      '(element=$element, offset=$offset, length=$length)');
}

void _assertHasLocationQ(List<LocationImpl> locations, IndexableElement element,
    int offset, int length) {
  _assertHasLocation(locations, element, offset, length, isQualified: true);
}

@reflectiveTest
class _FileNodeManagerTest {
  MockLogger logger = new MockLogger();
  StringCodec stringCodec = new StringCodec();
  RelationshipCodec relationshipCodec;

  AnalysisContext context = new MockAnalysisContext('context');
  ContextCodec contextCodec = new MockContextCodec();
  int contextId = 13;

  ElementCodec elementCodec = new MockElementCodec();
  int nextElementId = 0;

  FileNodeManager nodeManager;
  FileManager fileManager = new _MockFileManager();

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
    String name = '42.index';
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
    String name = '42.index';
    // prepare a stream with an invalid version
    when(fileManager.read(name))
        .thenReturn(new Future.value([0x01, 0x02, 0x03, 0x04]));
    // do in the Future
    return nodeManager.getNode(name).then((IndexNode node) {
      // no IndexNode
      expect(node, isNull);
      // failed
      verify(logger.logError(anyObject, anyObject)).once();
    });
  }

  test_getNode_streamException() {
    String name = '42.index';
    when(fileManager.read(name)).thenReturn(new Future(() {
      return throw new Exception();
    }));
    // do in the Future
    return nodeManager.getNode(name).then((IndexNode node) {
      expect(node, isNull);
      // failed
      verify(logger.logError(anyString, anyObject)).once();
    });
  }

  test_getNode_streamNull() {
    String name = '42.index';
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
    String name = '42.index';
    // record bytes
    List<int> bytes;
    when(fileManager.write(name, anyObject)).thenInvoke((name, bs) {
      bytes = bs;
    });
    // prepare elements
    IndexableElement elementA = _mockElement();
    IndexableElement elementB = _mockElement();
    IndexableElement elementC = _mockElement();
    RelationshipImpl relationship =
        RelationshipImpl.getRelationship('my-relationship');
    // put Node
    Future putFuture;
    {
      // prepare relations
      int relationshipId = relationshipCodec.encode(relationship);
      RelationKeyData key =
          new RelationKeyData.forData(0, 1, 2, relationshipId);
      List<LocationData> locations = [
        new LocationData.forData(3, 4, 5, 1, 10, 2),
        new LocationData.forData(6, 7, 8, 2, 20, 3)
      ];
      Map<RelationKeyData, List<LocationData>> relations = {key: locations};
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
          List<LocationImpl> locations =
              node.getRelationships(elementA, relationship);
          expect(locations, hasLength(2));
          _assertHasLocation(locations, elementB, 1, 10);
          _assertHasLocationQ(locations, elementC, 2, 20);
        }
      });
    });
  }

  test_putNode_streamException() {
    String name = '42.index';
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
      verify(logger.logError(anyString, anyObject)).once();
    });
  }

  void test_removeNode() {
    String name = '42.index';
    nodeManager.removeNode(name);
    verify(fileManager.delete(name)).once();
  }

  IndexableElement _mockElement() {
    int id1 = nextElementId++;
    int id2 = nextElementId++;
    int id3 = nextElementId++;
    Element element = new MockElement();
    IndexableObject indexable = new IndexableElement(element);
    when(elementCodec.encode1(indexable)).thenReturn(id1);
    when(elementCodec.encode2(indexable)).thenReturn(id2);
    when(elementCodec.encode3(indexable)).thenReturn(id3);
    when(elementCodec.decode(context, id1, id2, id3)).thenReturn(indexable);
    return indexable;
  }
}

@reflectiveTest
class _IndexNodeTest {
  AnalysisContext context = new MockAnalysisContext('context');
  ElementCodec elementCodec = new MockElementCodec();
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
    IndexableElement elementA = _mockElement();
    IndexableElement elementB = _mockElement();
    IndexableElement elementC = _mockElement();
    RelationshipImpl relationship =
        RelationshipImpl.getRelationship('my-relationship');
    LocationImpl locationA = new LocationImpl(elementB, 1, 2);
    LocationImpl locationB = new LocationImpl(elementC, 10, 20);
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
      List<LocationImpl> locations =
          node.getRelationships(elementA, relationship);
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
    IndexableElement elementA = _mockElement();
    IndexableElement elementB = _mockElement();
    IndexableElement elementC = _mockElement();
    RelationshipImpl relationship =
        RelationshipImpl.getRelationship('my-relationship');
    // record
    {
      int relationshipId = relationshipCodec.encode(relationship);
      RelationKeyData key =
          new RelationKeyData.forData(0, 1, 2, relationshipId);
      List<LocationData> locations = [
        new LocationData.forData(3, 4, 5, 1, 10, 2),
        new LocationData.forData(6, 7, 8, 2, 20, 3)
      ];
      node.relations = {key: locations};
    }
    // request
    List<LocationImpl> locations =
        node.getRelationships(elementA, relationship);
    expect(locations, hasLength(2));
    _assertHasLocation(locations, elementB, 1, 10);
    _assertHasLocationQ(locations, elementC, 2, 20);
  }

  IndexableElement _mockElement() {
    int id1 = nextElementId++;
    int id2 = nextElementId++;
    int id3 = nextElementId++;
    Element element = new MockElement();
    IndexableElement indexable = new IndexableElement(element);
    when(elementCodec.encode1(indexable)).thenReturn(id1);
    when(elementCodec.encode2(indexable)).thenReturn(id2);
    when(elementCodec.encode3(indexable)).thenReturn(id3);
    when(elementCodec.decode(context, id1, id2, id3)).thenReturn(indexable);
    return indexable;
  }
}

@reflectiveTest
class _LocationDataTest {
  AnalysisContext context = new MockAnalysisContext('context');
  ElementCodec elementCodec = new MockElementCodec();
  StringCodec stringCodec = new StringCodec();

  void test_newForData() {
    Element element = new MockElement();
    IndexableElement indexable = new IndexableElement(element);
    when(elementCodec.decode(context, 11, 12, 13)).thenReturn(indexable);
    LocationData locationData = new LocationData.forData(11, 12, 13, 1, 2, 0);
    LocationImpl location = locationData.getLocation(context, elementCodec);
    expect(location.indexable, indexable);
    expect(location.offset, 1);
    expect(location.length, 2);
    expect(location.isQualified, isFalse);
    expect(location.isResolved, isFalse);
  }

  void test_newForObject() {
    // prepare Element
    Element element = new MockElement();
    IndexableElement indexable = new IndexableElement(element);
    when(elementCodec.encode1(indexable)).thenReturn(11);
    when(elementCodec.encode2(indexable)).thenReturn(12);
    when(elementCodec.encode3(indexable)).thenReturn(13);
    when(elementCodec.decode(context, 11, 12, 13)).thenReturn(indexable);
    // create
    LocationImpl location = new LocationImpl(indexable, 1, 2);
    LocationData locationData =
        new LocationData.forObject(elementCodec, location);
    // touch 'hashCode'
    locationData.hashCode;
    // ==
    expect(
        locationData == new LocationData.forData(11, 12, 13, 1, 2, 2), isTrue);
    // getLocation()
    {
      LocationImpl newLocation =
          locationData.getLocation(context, elementCodec);
      expect(newLocation.indexable, indexable);
      expect(newLocation.offset, 1);
      expect(newLocation.length, 2);
    }
    // no Element - no Location
    {
      when(elementCodec.decode(context, 11, 12, 13)).thenReturn(null);
      LocationImpl newLocation =
          locationData.getLocation(context, elementCodec);
      expect(newLocation, isNull);
    }
  }
}

/**
 * [LocationImpl] has no [==] and [hashCode], so to compare locations by value we
 * need to wrap them into such object.
 */
class _LocationEqualsWrapper {
  final LocationImpl location;

  _LocationEqualsWrapper(this.location);

  @override
  int get hashCode {
    return 31 * (31 * location.indexable.hashCode + location.offset) +
        location.length;
  }

  @override
  bool operator ==(Object other) {
    if (other is _LocationEqualsWrapper) {
      return other.location.offset == location.offset &&
          other.location.length == location.length &&
          other.location.indexable == location.indexable;
    }
    return false;
  }
}

class _MockFileManager extends TypedMock implements FileManager {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockIndexNode extends TypedMock implements IndexNode {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@reflectiveTest
class _RelationKeyDataTest {
  AnalysisContext context = new MockAnalysisContext('context');
  ElementCodec elementCodec = new MockElementCodec();
  RelationshipCodec relationshipCodec = new MockRelationshipCodec();
  StringCodec stringCodec = new StringCodec();

  void test_newFromData() {
    RelationKeyData keyData = new RelationKeyData.forData(11, 12, 13, 2);
    // equals
    expect(keyData == this, isFalse);
    expect(keyData == new RelationKeyData.forData(11, 12, 13, 20), isFalse);
    expect(keyData == keyData, isTrue);
    expect(keyData == new RelationKeyData.forData(11, 12, 13, 2), isTrue);
  }

  void test_newFromObjects() {
    // prepare Element
    IndexableElement indexable;
    {
      Element element = new MockElement();
      indexable = new IndexableElement(element);
      ElementLocation location = new ElementLocationImpl.con3(['foo', 'bar']);
      when(element.location).thenReturn(location);
      when(context.getElement(location)).thenReturn(indexable);
      when(elementCodec.encode1(indexable)).thenReturn(11);
      when(elementCodec.encode2(indexable)).thenReturn(12);
      when(elementCodec.encode3(indexable)).thenReturn(13);
    }
    // prepare relationship
    RelationshipImpl relationship =
        RelationshipImpl.getRelationship('my-relationship');
    int relationshipId = 1;
    when(relationshipCodec.encode(relationship)).thenReturn(relationshipId);
    // create RelationKeyData
    RelationKeyData keyData = new RelationKeyData.forObject(
        elementCodec, relationshipCodec, indexable, relationship);
    // touch
    keyData.hashCode;
    // equals
    expect(keyData == this, isFalse);
    expect(keyData == new RelationKeyData.forData(11, 12, 13, 20), isFalse);
    expect(keyData == keyData, isTrue);
    expect(keyData == new RelationKeyData.forData(11, 12, 13, relationshipId),
        isTrue);
  }
}

@reflectiveTest
class _SplitIndexStoreTest {
  AnalysisContext contextA = new MockAnalysisContext('contextA');
  AnalysisContext contextB = new MockAnalysisContext('contextB');
  AnalysisContext contextC = new MockAnalysisContext('contextC');

  Element elementA = new MockElement('elementA');
  Element elementB = new MockElement('elementB');
  Element elementC = new MockElement('elementC');
  Element elementD = new MockElement('elementD');

  IndexableElement indexableA;
  IndexableElement indexableB;
  IndexableElement indexableC;
  IndexableElement indexableD;

  HtmlElement htmlElementA = new MockHtmlElement();
  HtmlElement htmlElementB = new MockHtmlElement();
  LibraryElement libraryElement = new MockLibraryElement();
  Source librarySource = new MockSource('librarySource');
  CompilationUnitElement libraryUnitElement = new MockCompilationUnitElement();
  ElementCodec elementCodec = new MockElementCodec();
  MemoryNodeManager nodeManager = new MemoryNodeManager();
  RelationshipImpl relationship =
      RelationshipImpl.getRelationship('test-relationship');
  Source sourceA = new MockSource('sourceA');
  Source sourceB = new MockSource('sourceB');
  Source sourceC = new MockSource('sourceC');
  Source sourceD = new MockSource('sourceD');
  SplitIndexStore store;
  CompilationUnitElement unitElementA = new MockCompilationUnitElement();
  CompilationUnitElement unitElementB = new MockCompilationUnitElement();
  CompilationUnitElement unitElementC = new MockCompilationUnitElement();
  CompilationUnitElement unitElementD = new MockCompilationUnitElement();

  void setUp() {
    indexableA = new IndexableElement(elementA);
    indexableB = new IndexableElement(elementB);
    indexableC = new IndexableElement(elementC);
    indexableD = new IndexableElement(elementD);

    nodeManager.elementCodec = elementCodec;
    store = new SplitIndexStore(nodeManager);
    when(elementCodec.encode1(indexableA)).thenReturn(11);
    when(elementCodec.encode2(indexableA)).thenReturn(12);
    when(elementCodec.encode3(indexableA)).thenReturn(13);
    when(elementCodec.encode1(indexableB)).thenReturn(21);
    when(elementCodec.encode2(indexableB)).thenReturn(22);
    when(elementCodec.encode3(indexableB)).thenReturn(23);
    when(elementCodec.encode1(indexableC)).thenReturn(31);
    when(elementCodec.encode2(indexableC)).thenReturn(32);
    when(elementCodec.encode3(indexableC)).thenReturn(33);
    when(elementCodec.encode1(indexableD)).thenReturn(41);
    when(elementCodec.encode2(indexableD)).thenReturn(42);
    when(elementCodec.encode3(indexableD)).thenReturn(43);
    when(elementCodec.decode(contextA, 11, 12, 13)).thenReturn(indexableA);
    when(elementCodec.decode(contextA, 21, 22, 23)).thenReturn(indexableB);
    when(elementCodec.decode(contextA, 31, 32, 33)).thenReturn(indexableC);
    when(elementCodec.decode(contextA, 41, 42, 43)).thenReturn(indexableD);
    when(contextA.isDisposed).thenReturn(false);
    when(contextB.isDisposed).thenReturn(false);
    when(contextC.isDisposed).thenReturn(false);
    when(librarySource.fullName).thenReturn('/home/user/librarySource.dart');
    when(sourceA.fullName).thenReturn('/home/user/sourceA.dart');
    when(sourceB.fullName).thenReturn('/home/user/sourceB.dart');
    when(sourceC.fullName).thenReturn('/home/user/sourceC.dart');
    when(sourceD.fullName).thenReturn('/home/user/sourceD.dart');
    when(elementA.context).thenReturn(contextA);
    when(elementB.context).thenReturn(contextA);
    when(elementC.context).thenReturn(contextA);
    when(elementD.context).thenReturn(contextA);
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

  Future test_aboutToIndexDart_library_first() {
    when(libraryElement.parts)
        .thenReturn(<CompilationUnitElement>[unitElementA, unitElementB]);
    {
      store.aboutToIndexDart(contextA, libraryUnitElement);
      store.doneIndex();
    }
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, []);
    });
  }

  test_aboutToIndexDart_library_secondWithoutOneUnit() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
      // apply "libraryUnitElement", only with "B"
      when(libraryElement.parts).thenReturn([unitElementB]);
      {
        store.aboutToIndexDart(contextA, libraryUnitElement);
        store.doneIndex();
      }
    }).then((_) {
      return store
          .getRelationships(indexableA, relationship)
          .then((List<LocationImpl> locations) {
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
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexHtml(contextA, htmlElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexHtml(contextA, htmlElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  void test_aboutToIndexHtml_disposedContext() {
    when(contextA.isDisposed).thenReturn(true);
    expect(store.aboutToIndexHtml(contextA, htmlElementA), isFalse);
  }

  test_cancelIndexDart() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(indexableA, relationship, locationA);
    store.recordRelationship(indexableA, relationship, locationB);
    store.recordTopLevelDeclaration(elementA);
    store.cancelIndexDart();
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, []);
      expect(store.getTopLevelDeclarations((name) => true), isEmpty);
    });
  }

  void test_clear() {
    LocationImpl locationA = mockLocation(indexableA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(indexableA, relationship, locationA);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isFalse);
    // clear
    store.clear();
    expect(nodeManager.isEmpty(), isTrue);
  }

  test_getRelationships_empty() {
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
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
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    {
      String statistics = store.statistics;
      expect(statistics, contains('2 locations'));
      expect(statistics, contains('3 sources'));
    }
  }

  void test_recordRelationship_multiplyDefinedElement() {
    Element multiplyElement =
        new MultiplyDefinedElementImpl(contextA, <Element>[elementA, elementB]);
    LocationImpl location = mockLocation(indexableA);
    store.recordRelationship(
        new IndexableElement(multiplyElement), relationship, location);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isTrue);
  }

  void test_recordRelationship_nullElement() {
    LocationImpl locationA = mockLocation(indexableA);
    store.recordRelationship(null, relationship, locationA);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isTrue);
  }

  void test_recordRelationship_nullLocation() {
    store.recordRelationship(indexableA, relationship, null);
    store.doneIndex();
    expect(nodeManager.isEmpty(), isTrue);
  }

  test_recordRelationship_oneElement_twoNodes() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  test_recordRelationship_oneLocation() {
    LocationImpl locationA = mockLocation(indexableA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(indexableA, relationship, locationA);
    store.doneIndex();
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA]);
    });
  }

  test_recordRelationship_twoLocations() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableA);
    store.aboutToIndexDart(contextA, unitElementA);
    store.recordRelationship(indexableA, relationship, locationA);
    store.recordRelationship(indexableA, relationship, locationB);
    store.doneIndex();
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
    });
  }

  test_removeContext() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
      // remove "A" context
      store.removeContext(contextA);
    }).then((_) {
      return store
          .getRelationships(indexableA, relationship)
          .then((List<LocationImpl> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeContext_nullContext() {
    store.removeContext(null);
  }

  test_removeSource_library() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    LocationImpl locationC = mockLocation(indexableC);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordRelationship(indexableA, relationship, locationC);
      store.doneIndex();
    }
    // "A", "B" and "C" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB, locationC]);
    }).then((_) {
      // remove "librarySource"
      store.removeSource(contextA, librarySource);
      return store
          .getRelationships(indexableA, relationship)
          .then((List<LocationImpl> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeSource_nullContext() {
    store.removeSource(null, sourceA);
  }

  test_removeSource_unit() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    LocationImpl locationC = mockLocation(indexableC);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordRelationship(indexableA, relationship, locationC);
      store.doneIndex();
    }
    // "A", "B" and "C" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB, locationC]);
    }).then((_) {
      // remove "A" source
      store.removeSource(contextA, sourceA);
      return store
          .getRelationships(indexableA, relationship)
          .then((List<LocationImpl> locations) {
        assertLocations(locations, [locationB, locationC]);
      });
    });
  }

  test_removeSources_library() {
    LocationImpl locationA = mockLocation(indexableA);
    LocationImpl locationB = mockLocation(indexableB);
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordRelationship(indexableA, relationship, locationA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordRelationship(indexableA, relationship, locationB);
      store.doneIndex();
    }
    // "A" and "B" locations
    return store
        .getRelationships(indexableA, relationship)
        .then((List<LocationImpl> locations) {
      assertLocations(locations, [locationA, locationB]);
    }).then((_) {
      // remove "librarySource"
      store.removeSources(contextA, new SingleSourceContainer(librarySource));
      return store
          .getRelationships(indexableA, relationship)
          .then((List<LocationImpl> locations) {
        assertLocations(locations, []);
      });
    });
  }

  void test_removeSources_nullContext() {
    store.removeSources(null, null);
  }

  void test_removeSources_unit() {
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordTopLevelDeclaration(elementA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementB);
      store.recordTopLevelDeclaration(elementB);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextA, unitElementC);
      store.recordTopLevelDeclaration(elementC);
      store.doneIndex();
    }
    // A, B, C elements
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementA, elementB, elementC]));
    }
    // remove "A" source
    store.removeSources(contextA, new SingleSourceContainer(sourceA));
    store.removeSource(contextA, sourceA);
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementB, elementC]));
    }
  }

  void test_universe_aboutToIndex() {
    when(elementCodec.decode(contextA, 11, 12, 13))
        .thenReturn(new IndexableElement(elementA));
    when(elementCodec.decode(contextB, 21, 22, 23))
        .thenReturn(new IndexableElement(elementB));
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordTopLevelDeclaration(elementA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordTopLevelDeclaration(elementB);
      store.doneIndex();
    }
    // elementA, elementB
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementA, elementB]));
    }
    // re-index "unitElementA"
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.doneIndex();
    }
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementB]));
    }
  }

  void test_universe_clear() {
    when(elementCodec.decode(contextA, 11, 12, 13))
        .thenReturn(new IndexableElement(elementA));
    when(elementCodec.decode(contextB, 21, 22, 23))
        .thenReturn(new IndexableElement(elementB));
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordTopLevelDeclaration(elementA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordTopLevelDeclaration(elementB);
      store.doneIndex();
    }
    // elementA, elementB
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementA, elementB]));
    }
    // clear
    store.clear();
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, isEmpty);
    }
  }

  void test_universe_removeContext() {
    when(elementCodec.decode(contextA, 11, 12, 13))
        .thenReturn(new IndexableElement(elementA));
    when(elementCodec.decode(contextB, 21, 22, 23))
        .thenReturn(new IndexableElement(elementB));
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordTopLevelDeclaration(elementA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordTopLevelDeclaration(elementB);
      store.doneIndex();
    }
    // elementA, elementB
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementA, elementB]));
    }
    // remove "contextA"
    store.removeContext(contextA);
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementB]));
    }
  }

  void test_universe_removeSource() {
    when(elementCodec.decode(contextA, 11, 12, 13))
        .thenReturn(new IndexableElement(elementA));
    when(elementCodec.decode(contextB, 21, 22, 23))
        .thenReturn(new IndexableElement(elementB));
    {
      store.aboutToIndexDart(contextA, unitElementA);
      store.recordTopLevelDeclaration(elementA);
      store.doneIndex();
    }
    {
      store.aboutToIndexDart(contextB, unitElementB);
      store.recordTopLevelDeclaration(elementB);
      store.doneIndex();
    }
    // elementA, elementB
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementA, elementB]));
    }
    // remove "sourceA"
    store.removeSource(contextA, sourceA);
    {
      List<Element> elements = store.getTopLevelDeclarations(anyName);
      expect(elements, unorderedEquals([elementB]));
    }
  }

  static bool anyName(String name) => true;

  /**
   * Asserts that the [actual] locations have all the [expected] locations and
   * only them.
   */
  static void assertLocations(
      List<LocationImpl> actual, List<LocationImpl> expected) {
    List<_LocationEqualsWrapper> actualWrappers = wrapLocations(actual);
    List<_LocationEqualsWrapper> expectedWrappers = wrapLocations(expected);
    expect(actualWrappers, unorderedEquals(expectedWrappers));
  }

  /**
   * @return the new [LocationImpl] mock.
   */
  static LocationImpl mockLocation(IndexableElement indexable) {
    LocationImpl location = new MockLocation();
    when(location.indexable).thenReturn(indexable);
    when(location.offset).thenReturn(0);
    when(location.length).thenReturn(0);
    when(location.isQualified).thenReturn(true);
    when(location.isResolved).thenReturn(true);
    return location;
  }

  /**
   * Wraps the given locations into [LocationEqualsWrapper].
   */
  static List<_LocationEqualsWrapper> wrapLocations(
      List<LocationImpl> locations) {
    List<_LocationEqualsWrapper> wrappers = <_LocationEqualsWrapper>[];
    for (LocationImpl location in locations) {
      wrappers.add(new _LocationEqualsWrapper(location));
    }
    return wrappers;
  }
}
