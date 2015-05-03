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

AnalysisCache createCache({AnalysisContext context,
    RetentionPriority policy: RetentionPriority.LOW}) {
  CachePartition partition = new UniversalCachePartition(
      context, 8, new TestCacheRetentionPolicy(policy));
  return new AnalysisCache(<CachePartition>[partition]);
}

@reflectiveTest
class AnalysisCacheTest extends EngineTestCase {
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
    entry1.setValue(result, node, TargetedResult.EMPTY_LIST);
    AnalysisTarget target2 = new TestSource('/test2.dart');
    CacheEntry entry2 = new CacheEntry();
    entry2.setValue(result, node, TargetedResult.EMPTY_LIST);
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
      entry.setValue(result, node, TargetedResult.EMPTY_LIST);
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
    entry.setErrorState(exception, <ResultDescriptor>[result]);
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.ERROR);
    expect(entry.exception, exception);
  }

  test_fixExceptionState_noError_exception() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    // set one result to ERROR
    CaughtException exception = new CaughtException(null, null);
    entry.setErrorState(exception, <ResultDescriptor>[result]);
    // set the same result to VALID
    entry.setValue(result, 1, TargetedResult.EMPTY_LIST);
    // fix the exception state
    entry.fixExceptionState();
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
    entry.setValue(result, new NullLiteral(null), TargetedResult.EMPTY_LIST);
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
    entry.setValue(result, new NullLiteral(null), TargetedResult.EMPTY_LIST);
    expect(entry.hasAstStructure, true);
  }

  test_hasErrorState_false() {
    CacheEntry entry = new CacheEntry();
    expect(entry.hasErrorState(), false);
  }

  test_hasErrorState_true() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry();
    entry.setErrorState(exception, <ResultDescriptor>[result]);
    expect(entry.hasErrorState(), true);
  }

  test_invalidateAllInformation() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, 'value', TargetedResult.EMPTY_LIST);
    entry.invalidateAllInformation();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), isNull);
  }

  test_setErrorState() {
    ResultDescriptor result1 = new ResultDescriptor('res1', 1);
    ResultDescriptor result2 = new ResultDescriptor('res2', 2);
    ResultDescriptor result3 = new ResultDescriptor('res3', 3);
    // prepare some good state
    CacheEntry entry = new CacheEntry();
    entry.setValue(result1, 10, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 20, TargetedResult.EMPTY_LIST);
    entry.setValue(result3, 30, TargetedResult.EMPTY_LIST);
    // set error state
    CaughtException exception = new CaughtException(null, null);
    entry.setErrorState(exception, <ResultDescriptor>[result1, result2]);
    // verify
    expect(entry.exception, exception);
    expect(entry.getState(result1), CacheState.ERROR);
    expect(entry.getState(result2), CacheState.ERROR);
    expect(entry.getState(result3), CacheState.VALID);
    expect(entry.getValue(result1), 1);
    expect(entry.getValue(result2), 2);
    expect(entry.getValue(result3), 30);
  }

  test_setErrorState_invalidateDependent() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    cache.put(target, entry);
    ResultDescriptor result1 = new ResultDescriptor('result1', -1);
    ResultDescriptor result2 = new ResultDescriptor('result2', -2);
    ResultDescriptor result3 = new ResultDescriptor('result3', -3);
    ResultDescriptor result4 = new ResultDescriptor('result4', -4);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    entry.setValue(result3, 333, [new TargetedResult(target, result2)]);
    entry.setValue(result4, 444, []);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.VALID);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    expect(entry.getValue(result3), 333);
    expect(entry.getValue(result4), 444);
    // set error state
    CaughtException exception = new CaughtException(null, null);
    entry.setErrorState(exception, <ResultDescriptor>[result1]);
    // result2 and result3 are invalidated, result4 is intact
    expect(entry.getState(result1), CacheState.ERROR);
    expect(entry.getState(result2), CacheState.ERROR);
    expect(entry.getState(result3), CacheState.ERROR);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), -1);
    expect(entry.getValue(result2), -2);
    expect(entry.getValue(result3), -3);
    expect(entry.getValue(result4), 444);
  }

  test_setErrorState_noDescriptors() {
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry();
    expect(() {
      entry.setErrorState(exception, <ResultDescriptor>[]);
    }, throwsArgumentError);
  }

  test_setErrorState_noException() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    expect(() {
      entry.setErrorState(null, <ResultDescriptor>[result]);
    }, throwsArgumentError);
  }

  test_setErrorState_nullDescriptors() {
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry();
    expect(() {
      entry.setErrorState(exception, null);
    }, throwsArgumentError);
  }

  test_setState_error() {
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, 42, TargetedResult.EMPTY_LIST);
    // an invalid state change
    expect(() {
      entry.setState(result, CacheState.ERROR);
    }, throwsArgumentError);
    // no changes
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 42);
  }

  test_setState_flushed() {
    ResultDescriptor result = new ResultDescriptor('test', 1);
    CacheEntry entry = new CacheEntry();
    // set VALID
    entry.setValue(result, 10, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 10);
    // set FLUSHED
    entry.setState(result, CacheState.FLUSHED);
    expect(entry.getState(result), CacheState.FLUSHED);
    expect(entry.getValue(result), 1);
  }

  test_setState_inProcess() {
    ResultDescriptor result = new ResultDescriptor('test', 1);
    CacheEntry entry = new CacheEntry();
    // set VALID
    entry.setValue(result, 10, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 10);
    // set IN_PROCESS
    entry.setState(result, CacheState.IN_PROCESS);
    expect(entry.getState(result), CacheState.IN_PROCESS);
    expect(entry.getValue(result), 10);
  }

  test_setState_invalid() {
    ResultDescriptor result = new ResultDescriptor('test', 1);
    CacheEntry entry = new CacheEntry();
    // set VALID
    entry.setValue(result, 10, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 10);
    // set INVALID
    entry.setState(result, CacheState.INVALID);
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), 1);
  }

  test_setState_invalid_invalidateDependent() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    cache.put(target, entry);
    ResultDescriptor result1 = new ResultDescriptor('result1', -1);
    ResultDescriptor result2 = new ResultDescriptor('result2', -2);
    ResultDescriptor result3 = new ResultDescriptor('result3', -3);
    ResultDescriptor result4 = new ResultDescriptor('result4', -4);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    entry.setValue(result3, 333, [new TargetedResult(target, result2)]);
    entry.setValue(result4, 444, []);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.VALID);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    expect(entry.getValue(result3), 333);
    expect(entry.getValue(result4), 444);
    // invalidate result1, invalidates result2 and result3, result4 is intact
    entry.setState(result1, CacheState.INVALID);
    expect(entry.getState(result1), CacheState.INVALID);
    expect(entry.getState(result2), CacheState.INVALID);
    expect(entry.getState(result3), CacheState.INVALID);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), -1);
    expect(entry.getValue(result2), -2);
    expect(entry.getValue(result3), -3);
    expect(entry.getValue(result4), 444);
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
    entry.setValue(result, value, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), value);
  }

  test_setValue_invalidateDependent() {
    AnalysisCache cache = createCache();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry();
    cache.put(target, entry);
    ResultDescriptor result1 = new ResultDescriptor('result1', -1);
    ResultDescriptor result2 = new ResultDescriptor('result2', -2);
    ResultDescriptor result3 = new ResultDescriptor('result3', -3);
    ResultDescriptor result4 = new ResultDescriptor('result4', -4);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    entry.setValue(result3, 333, [new TargetedResult(target, result2)]);
    entry.setValue(result4, 444, []);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.VALID);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    expect(entry.getValue(result3), 333);
    expect(entry.getValue(result4), 444);
    // set result1, invalidates result2 and result3, result4 is intact
    entry.setValue(result1, 1111, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.INVALID);
    expect(entry.getState(result3), CacheState.INVALID);
    expect(entry.getState(result4), CacheState.VALID);
    expect(entry.getValue(result1), 1111);
    expect(entry.getValue(result2), -2);
    expect(entry.getValue(result3), -3);
    expect(entry.getValue(result4), 444);
  }

  test_setValue_invalidateDependent2() {
    AnalysisCache cache = createCache();
    AnalysisTarget target1 = new TestSource('a');
    AnalysisTarget target2 = new TestSource('b');
    CacheEntry entry1 = new CacheEntry();
    CacheEntry entry2 = new CacheEntry();
    cache.put(target1, entry1);
    cache.put(target2, entry2);
    ResultDescriptor result1 = new ResultDescriptor('result1', -1);
    ResultDescriptor result2 = new ResultDescriptor('result2', -2);
    ResultDescriptor result3 = new ResultDescriptor('result3', -3);
    // set results, all of them are VALID
    entry1.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry1.setValue(result2, 222, [new TargetedResult(target1, result1)]);
    entry2.setValue(result3, 333, [new TargetedResult(target1, result2)]);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry1.getState(result2), CacheState.VALID);
    expect(entry2.getState(result3), CacheState.VALID);
    expect(entry1.getValue(result1), 111);
    expect(entry1.getValue(result2), 222);
    expect(entry2.getValue(result3), 333);
    // set result1, invalidates result2 and result3
    entry1.setValue(result1, 1111, TargetedResult.EMPTY_LIST);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry1.getState(result2), CacheState.INVALID);
    expect(entry2.getState(result3), CacheState.INVALID);
    expect(entry1.getValue(result1), 1111);
    expect(entry1.getValue(result2), -2);
    expect(entry2.getValue(result3), -3);
  }

  test_toString_empty() {
    CacheEntry entry = new CacheEntry();
    expect(entry.toString(), isNotNull);
  }

  test_toString_nonEmpty() {
    String value = 'value';
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry();
    entry.setValue(result, value, TargetedResult.EMPTY_LIST);
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
      entry.setValue(result, node, TargetedResult.EMPTY_LIST);
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
