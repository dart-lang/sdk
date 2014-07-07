// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.codec;

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/src/index/store/codec.dart';
import 'package:analysis_testing/mocks.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';


main() {
  groupSep = ' | ';
  group('ContextCodec', () {
    runReflectiveTests(_ContextCodecTest);
  });
  group('ElementCodec', () {
    runReflectiveTests(_ElementCodecTest);
  });
  group('RelationshipCodec', () {
    runReflectiveTests(_RelationshipCodecTest);
  });
  group('StringCodec', () {
    runReflectiveTests(_StringCodecTest);
  });
}


@ReflectiveTestCase()
class _ContextCodecTest {
  ContextCodec codec = new ContextCodec();

  void test_encode_decode() {
    AnalysisContext contextA = new MockAnalysisContext('contextA');
    AnalysisContext contextB = new MockAnalysisContext('contextB');
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
      AnalysisContext context = new MockAnalysisContext('context');
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
      AnalysisContext context = new MockAnalysisContext('context');
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
  AnalysisContext context = new MockAnalysisContext('context');
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    codec = new ElementCodec(stringCodec);
  }

  void test_localLocalVariable() {
    {
      Element element = new MockElement();
      ElementLocation location = new ElementLocationImpl.con3(['main', 'foo@1',
          'bar@2']);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    {
      Element element = new MockElement();
      ElementLocation location = new ElementLocationImpl.con3(['main', 'foo@10',
          'bar@20']);
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
      Element element = new MockElement();
      ElementLocation location = new ElementLocationImpl.con3(['main',
          'foo@42']);
      when(context.getElement(location)).thenReturn(element);
      when(element.location).thenReturn(location);
      int id = codec.encode(element);
      expect(codec.decode(context, id), element);
    }
    {
      Element element = new MockElement();
      ElementLocation location = new ElementLocationImpl.con3(['main',
          'foo@4200']);
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
    Element element = new MockElement();
    ElementLocation location = new ElementLocationImpl.con3(['foo', 'bar']);
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
class _RelationshipCodecTest {
  StringCodec stringCodec = new StringCodec();
  RelationshipCodec codec;

  void setUp() {
    codec = new RelationshipCodec(stringCodec);
  }

  void test_all() {
    Relationship relationship = Relationship.getRelationship('my-relationship');
    int id = codec.encode(relationship);
    expect(codec.decode(id), relationship);
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
