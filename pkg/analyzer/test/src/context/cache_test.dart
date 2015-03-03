// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.driver_test;

import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, CacheState, RetentionPriority;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/task/model.dart';
import 'package:unittest/unittest.dart';

import '../../generated/engine_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisCacheTest);
  runReflectiveTests(CacheEntryTest);
  runReflectiveTests(SdkCachePartitionTest);
  runReflectiveTests(UniversalCachePartitionTest);
  runReflectiveTests(ResultDataTest);
}

@reflectiveTest
class AnalysisCacheTest extends EngineTestCase {
  AnalysisCache createCache({AnalysisContext context,
      RetentionPriority policy: RetentionPriority.LOW}) {
    CachePartition partition = new UniversalCachePartition(
        context, 8, new TestCacheRetentionPolicy(policy));
    return new AnalysisCache(<CachePartition>[partition]);
  }

  void test_astSize_empty() {
    AnalysisCache cache = createCache();
    expect(cache.astSize, 0);
  }

  void test_astSize_nonEmpty() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    AstNode node = new NullLiteral(null);
    AnalysisCache cache = createCache();
    AnalysisTarget target1 = new TestSource('/test1.dart');
    CacheEntry entry1 = new CacheEntry();
    entry1.setValue(result, node);
    AnalysisTarget target2 = new TestSource('/test2.dart');
    CacheEntry entry2 = new CacheEntry();
    entry2.setValue(result, node);
    cache.put(target1, entry1);
    cache.accessedAst(target1);
    cache.put(target2, entry2);
    cache.accessedAst(target2);
    expect(cache.astSize, 2);
  }

  void test_creation() {
    expect(createCache(), isNotNull);
  }

  void test_get() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    expect(cache.get(target), isNull);
  }

  void test_getContextFor() {
    AnalysisContext context = new TestAnalysisContext();
    AnalysisCache cache = createCache(context: context);
    AnalysisTarget target = new TestSource();
    expect(cache.getContextFor(target), context);
  }

  void test_iterator() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    cache.put(target, entry);
    MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(target));
    expect(iterator.value, same(entry));
    expect(iterator.moveNext(), isFalse);
  }

  void test_put() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    expect(cache.get(target), isNull);
    cache.put(target, entry);
    expect(cache.get(target), entry);
  }

  void test_remove() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    cache.remove(target);
  }

  void test_setMaxCacheSize() {
    CachePartition partition = new UniversalCachePartition(
        null, 8, new TestCacheRetentionPolicy(RetentionPriority.MEDIUM));
    AnalysisCache cache = new AnalysisCache(<CachePartition>[partition]);
    ResultDescriptor result = new ResultDescriptor('test', null);
    AstNode node = new NullLiteral(null);
    int size = 6;
    for (int i = 0; i < size; i++) {
      AnalysisTarget target = new TestSource("/test$i.dart");
      CacheEntry entry = new CacheEntry();
      entry.setValue(result, node);
      cache.put(target, entry);
      cache.accessedAst(target);
    }

    void _assertNonFlushedCount(int expectedCount, AnalysisCache cache) {
      int nonFlushedCount = 0;
      MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
      while (iterator.moveNext()) {
        if (iterator.value.getState(result) != CacheState.FLUSHED) {
          nonFlushedCount++;
        }
      }
      expect(nonFlushedCount, expectedCount);
    }

    _assertNonFlushedCount(size, cache);
    int newSize = size - 2;
    partition.maxCacheSize = newSize;
    _assertNonFlushedCount(newSize, cache);
  }

  void test_size() {
    AnalysisCache cache = createCache();
    int size = 4;
    for (int i = 0; i < size; i++) {
      AnalysisTarget target = new TestSource("/test$i.dart");
      cache.put(target, new CacheEntry());
    }
    expect(cache.size(), size);
  }
}

@reflectiveTest
class CacheEntryTest extends EngineTestCase {
  test_explicitlyAdded() {
    CacheEntry entry = new CacheEntry();
    expect(entry.explicitlyAdded, false);
    entry.explicitlyAdded = true;
    expect(entry.explicitlyAdded, true);
  }

  test_fixExceptionState_error_exception() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry();
    entry.setState(result, CacheState.ERROR);
    entry.exception = exception;
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.ERROR);
    expect(entry.exception, exception);
  }

  test_fixExceptionState_error_noException() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setState(result, CacheState.ERROR);
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.ERROR);
    expect(entry.exception, isNotNull);
  }

  test_fixExceptionState_noError_exception() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.exception = new CaughtException(null, null);
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.exception, isNull);
  }

  test_fixExceptionState_noError_noException() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.exception, isNull);
  }

  test_flushAstStructures() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, new NullLiteral(null));
    expect(entry.hasAstStructure, true);
    entry.flushAstStructures();
    expect(entry.hasAstStructure, false);
  }

  test_getState() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    expect(entry.getState(result), CacheState.INVALID);
  }

  test_getValue() {
    String defaultValue = 'value';
    ResultDescriptor result = new ResultDescriptor('test', defaultValue);
    CacheEntry entry = new CacheEntry();
    expect(entry.getValue(result), defaultValue);
  }

  test_hasAstStructure_false() {
    CacheEntry entry = new CacheEntry();
    expect(entry.hasAstStructure, false);
  }

  test_hasAstStructure_true() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, new NullLiteral(null));
    expect(entry.hasAstStructure, true);
  }

  test_hasErrorState_false() {
    CacheEntry entry = new CacheEntry();
    expect(entry.hasErrorState(), false);
  }

  test_hasErrorState_true() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setState(result, CacheState.ERROR);
    expect(entry.hasErrorState(), true);
  }

  test_invalidateAllInformation() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, 'value');
    entry.invalidateAllInformation();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), isNull);
  }

  test_setState_error() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setState(result, CacheState.ERROR);
    expect(entry.getState(result), CacheState.ERROR);
    expect(entry.getValue(result), isNull);
  }

  test_setState_invalid() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setState(result, CacheState.INVALID);
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), isNull);
  }

  test_setState_valid() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    expect(() => entry.setState(result, CacheState.VALID), throwsArgumentError);
  }

  test_setValue() {
    String value = 'value';
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, value);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), value);
  }

  test_toString_empty() {
    CacheEntry entry = new CacheEntry();
    expect(entry.toString(), isNotNull);
  }

  test_toString_nonEmpty() {
    String value = 'value';
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, value);
    expect(entry.toString(), isNotNull);
  }
}

abstract class CachePartitionTest extends EngineTestCase {
  CachePartition createPartition([CacheRetentionPolicy policy = null]);

  void test_creation() {
    expect(createPartition(), isNotNull);
  }

  void test_entrySet() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    partition.put(target, entry);
    Map<AnalysisTarget, CacheEntry> entryMap = partition.map;
    expect(entryMap, hasLength(1));
    AnalysisTarget entryKey = entryMap.keys.first;
    expect(entryKey, target);
    expect(entryMap[entryKey], entry);
  }

  void test_get() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    expect(partition.get(target), isNull);
  }

  void test_put_noFlush() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    partition.put(target, entry);
    expect(partition.get(target), entry);
  }

  void test_remove() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    partition.put(target, entry);
    expect(partition.get(target), entry);
    partition.remove(target);
    expect(partition.get(target), isNull);
  }

  void test_setMaxCacheSize() {
    CachePartition partition =
        createPartition(new TestCacheRetentionPolicy(RetentionPriority.LOW));
    ResultDescriptor result = new ResultDescriptor('result', null);
    NullLiteral node = new NullLiteral(null);
    int size = 6; // Must be <= partition.maxCacheSize
    for (int i = 0; i < size; i++) {
      AnalysisTarget target = new TestSource("/test$i.dart");
      CacheEntry entry = new CacheEntry();
      entry.setValue(result, node);
      partition.put(target, entry);
      partition.accessedAst(target);
    }

    void assertNonFlushedCount(int expectedCount, CachePartition partition) {
      int nonFlushedCount = 0;
      Map<AnalysisTarget, CacheEntry> entryMap = partition.map;
      entryMap.values.forEach((CacheEntry entry) {
        if (entry.getState(result) != CacheState.FLUSHED) {
          nonFlushedCount++;
        }
      });
      expect(nonFlushedCount, expectedCount);
    }

    assertNonFlushedCount(size, partition);
    int newSize = size - 2;
    partition.maxCacheSize = newSize;
    assertNonFlushedCount(newSize, partition);
  }

  void test_size() {
    CachePartition partition = createPartition();
    int size = 4;
    for (int i = 0; i < size; i++) {
      AnalysisTarget target = new TestSource("/test$i.dart");
      partition.put(target, new CacheEntry());
      partition.accessedAst(target);
    }
    expect(partition.size(), size);
  }
}

@reflectiveTest
class ResultDataTest extends EngineTestCase {
  test_creation() {
    String value = 'value';
    ResultData data = new ResultData(new ResultDescriptor('test', value));
    expect(data, isNotNull);
    expect(data.state, CacheState.INVALID);
    expect(data.value, value);
  }
}

@reflectiveTest
class SdkCachePartitionTest extends CachePartitionTest {
  CachePartition createPartition([CacheRetentionPolicy policy = null]) {
    return new SdkCachePartition(null, 8);
  }

  void test_contains_false() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    expect(partition.contains(target), isFalse);
  }

  void test_contains_true() {
    SdkCachePartition partition = new SdkCachePartition(null, 8);
    SourceFactory factory = new SourceFactory(
        [new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    AnalysisTarget target = factory.forUri("dart:core");
    expect(partition.contains(target), isTrue);
  }
}

@reflectiveTest
class TestCacheRetentionPolicy extends CacheRetentionPolicy {
  final RetentionPriority policy;

  TestCacheRetentionPolicy([this.policy = RetentionPriority.MEDIUM]);

  @override
  RetentionPriority getAstPriority(AnalysisTarget target, CacheEntry entry) =>
      policy;
}

@reflectiveTest
class UniversalCachePartitionTest extends CachePartitionTest {
  CachePartition createPartition([CacheRetentionPolicy policy = null]) {
    return new UniversalCachePartition(null, 8, policy);
  }

  void test_contains() {
    UniversalCachePartition partition =
        new UniversalCachePartition(null, 8, null);
    TestSource source = new TestSource();
    expect(partition.contains(source), isTrue);
  }
}
