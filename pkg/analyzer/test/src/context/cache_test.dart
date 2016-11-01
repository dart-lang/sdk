// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.cache_test;

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisCacheTest);
    defineReflectiveTests(CacheEntryTest);
    defineReflectiveTests(CacheFlushManagerTest);
    defineReflectiveTests(SdkCachePartitionTest);
    defineReflectiveTests(UniversalCachePartitionTest);
    defineReflectiveTests(ResultDataTest);
  });
}

AnalysisCache createCache({AnalysisContext context}) {
  CachePartition partition = new UniversalCachePartition(context);
  return new AnalysisCache(<CachePartition>[partition]);
}

class AbstractCacheTest {
  InternalAnalysisContext context;
  AnalysisCache cache;

  void setUp() {
    context = new _InternalAnalysisContextMock();
    when(context.prioritySources).thenReturn([]);
    cache = createCache(context: context);
    when(context.analysisCache).thenReturn(cache);
  }
}

@reflectiveTest
class AnalysisCacheTest extends AbstractCacheTest {
  void test_creation() {
    expect(cache, isNotNull);
  }

  test_flush() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<String> resultA = new ResultDescriptor<String>('A', null);
    ResultDescriptor<String> resultB = new ResultDescriptor<String>('B', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    // put values
    entry.setValue(resultA, 'a', TargetedResult.EMPTY_LIST);
    entry.setValue(resultB, 'b', TargetedResult.EMPTY_LIST);
    expect(cache.getState(target, resultA), CacheState.VALID);
    expect(cache.getState(target, resultB), CacheState.VALID);
    expect(cache.getValue(target, resultA), 'a');
    expect(cache.getValue(target, resultB), 'b');
    // flush A
    cache.flush((target, result) => result == resultA);
    expect(cache.getState(target, resultA), CacheState.FLUSHED);
    expect(cache.getState(target, resultB), CacheState.VALID);
    expect(cache.getValue(target, resultA), isNull);
    expect(cache.getValue(target, resultB), 'b');
  }

  void test_get() {
    AnalysisTarget target = new TestSource();
    expect(cache.get(target), isNull);
  }

  void test_getContextFor() {
    AnalysisTarget target = new TestSource();
    expect(cache.getContextFor(target), context);
  }

  void test_getSourcesWithFullName() {
    String filePath = '/foo/lib/file.dart';
    // no sources
    expect(cache.getSourcesWithFullName(filePath), isEmpty);
    // add source1
    TestSourceWithUri source1 =
        new TestSourceWithUri(filePath, Uri.parse('file://$filePath'));
    cache.put(new CacheEntry(source1));
    expect(cache.getSourcesWithFullName(filePath), unorderedEquals([source1]));
    // add source2
    TestSourceWithUri source2 =
        new TestSourceWithUri(filePath, Uri.parse('package:foo/file.dart'));
    cache.put(new CacheEntry(source2));
    expect(cache.getSourcesWithFullName(filePath),
        unorderedEquals([source1, source2]));
    // remove source1
    cache.remove(source1);
    expect(cache.getSourcesWithFullName(filePath), unorderedEquals([source2]));
    // remove source2
    cache.remove(source2);
    expect(cache.getSourcesWithFullName(filePath), isEmpty);
    // ignored
    cache.remove(source1);
    cache.remove(source2);
    expect(cache.getSourcesWithFullName(filePath), isEmpty);
  }

  void test_getState_hasEntry_flushed() {
    ResultDescriptor result = new ResultDescriptor('result', -1);
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setState(result, CacheState.FLUSHED);
    expect(cache.getState(target, result), CacheState.FLUSHED);
  }

  void test_getState_hasEntry_valid() {
    ResultDescriptor<String> result =
        new ResultDescriptor<String>('result', null);
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setValue(result, '', []);
    expect(cache.getState(target, result), CacheState.VALID);
  }

  void test_getState_noEntry() {
    ResultDescriptor result = new ResultDescriptor('result', -1);
    AnalysisTarget target = new TestSource();
    expect(cache.getState(target, result), CacheState.INVALID);
  }

  void test_getValue_hasEntry_valid() {
    ResultDescriptor<int> result = new ResultDescriptor<int>('result', -1);
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setValue(result, 111, []);
    expect(cache.getValue(target, result), 111);
  }

  void test_getValue_noEntry() {
    ResultDescriptor result = new ResultDescriptor('result', -1);
    AnalysisTarget target = new TestSource();
    expect(cache.getValue(target, result), -1);
  }

  void test_iterator() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    MapIterator<AnalysisTarget, CacheEntry> iterator = cache.iterator();
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(target));
    expect(iterator.value, same(entry));
    expect(iterator.moveNext(), isFalse);
  }

  void test_put() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    expect(cache.get(target), isNull);
    cache.put(entry);
    expect(cache.get(target), entry);
  }

  void test_remove() {
    AnalysisTarget target1 = new TestSource('/a.dart');
    AnalysisTarget target2 = new TestSource('/b.dart');
    AnalysisTarget target3 = new TestSource('/c.dart');
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    CacheEntry entry3 = new CacheEntry(target3);
    cache.put(entry1);
    cache.put(entry2);
    cache.put(entry3);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    // set results, all of them are VALID
    entry1.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry2.setValue(result2, 222, [new TargetedResult(target1, result1)]);
    entry3.setValue(result3, 333, []);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry2.getState(result2), CacheState.VALID);
    expect(entry3.getState(result3), CacheState.VALID);
    expect(entry1.getValue(result1), 111);
    expect(entry2.getValue(result2), 222);
    expect(entry3.getValue(result3), 333);
    // remove entry1, invalidate result2 and remove empty entry2
    expect(cache.remove(target1), entry1);
    expect(cache.get(target1), isNull);
    expect(cache.get(target2), isNull);
    expect(cache.get(target3), entry3);
    expect(entry3.getState(result3), CacheState.VALID);
  }

  void test_remove_invalidateResults_sameTarget() {
    AnalysisTarget target = new TestSource('/a.dart');
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    // remove target, invalidate result2
    expect(cache.remove(target), entry);
    expect(cache.get(target), isNull);
    expect(entry.getState(result2), CacheState.INVALID);
  }

  void test_size() {
    int size = 4;
    for (int i = 0; i < size; i++) {
      AnalysisTarget target = new TestSource("/test$i.dart");
      cache.put(new CacheEntry(target));
    }
    expect(cache.size(), size);
  }

  void test_sources() {
    AnalysisTarget source1 = new TestSource('1.dart');
    AnalysisTarget source2 = new TestSource('2.dart');
    AnalysisTarget target1 = new _TestAnalysisTarget();
    // no entries
    expect(cache.sources, isEmpty);
    // add source1
    cache.put(new CacheEntry(source1));
    expect(cache.sources, unorderedEquals([source1]));
    // add target1
    cache.put(new CacheEntry(target1));
    expect(cache.sources, unorderedEquals([source1]));
    // add source2
    cache.put(new CacheEntry(source2));
    expect(cache.sources, unorderedEquals([source1, source2]));
    // remove source1
    cache.remove(source1);
    expect(cache.sources, unorderedEquals([source2]));
    // remove source2
    cache.remove(source2);
    expect(cache.sources, isEmpty);
  }
}

@reflectiveTest
class CacheEntryTest extends AbstractCacheTest {
  test_dispose() {
    ResultDescriptor<int> descriptor1 =
        new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> descriptor2 =
        new ResultDescriptor<int>('result2', -2);
    AnalysisTarget target1 = new TestSource('1.dart');
    AnalysisTarget target2 = new TestSource('2.dart');
    TargetedResult result1 = new TargetedResult(target1, descriptor1);
    TargetedResult result2 = new TargetedResult(target2, descriptor2);
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    cache.put(entry1);
    cache.put(entry2);
    entry1.setValue(descriptor1, 1, TargetedResult.EMPTY_LIST);
    entry2.setValue(descriptor2, 2, <TargetedResult>[result1]);
    // target2 is listed as dependent in target1
    expect(
        entry1.getResultData(descriptor1).dependentResults, contains(result2));
    // dispose entry2, result2 is removed from result1
    entry2.dispose();
    expect(entry1.getResultData(descriptor1).dependentResults, isEmpty);
  }

  test_explicitlyAdded() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    expect(entry.explicitlyAdded, false);
    entry.explicitlyAdded = true;
    expect(entry.explicitlyAdded, true);
  }

  test_fixExceptionState_error_exception() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setErrorState(exception, <ResultDescriptor>[result]);
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.ERROR);
    expect(entry.exception, exception);
  }

  test_fixExceptionState_noError_exception() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
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
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry(target);
    entry.fixExceptionState();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.exception, isNull);
  }

  test_flush() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<String> resultA = new ResultDescriptor<String>('A', null);
    ResultDescriptor<String> resultB = new ResultDescriptor<String>('B', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    // put values
    entry.setValue(resultA, 'a', TargetedResult.EMPTY_LIST);
    entry.setValue(resultB, 'b', TargetedResult.EMPTY_LIST);
    expect(entry.getState(resultA), CacheState.VALID);
    expect(entry.getState(resultB), CacheState.VALID);
    expect(entry.getValue(resultA), 'a');
    expect(entry.getValue(resultB), 'b');
    // flush A
    entry.flush((target, result) => result == resultA);
    expect(entry.getState(resultA), CacheState.FLUSHED);
    expect(entry.getState(resultB), CacheState.VALID);
    expect(entry.getValue(resultA), isNull);
    expect(entry.getValue(resultB), 'b');
  }

  test_getState() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry(target);
    expect(entry.getState(result), CacheState.INVALID);
  }

  test_getValue_default() {
    AnalysisTarget target = new TestSource();
    String defaultValue = 'value';
    ResultDescriptor result = new ResultDescriptor('test', defaultValue);
    CacheEntry entry = new CacheEntry(target);
    expect(entry.getValue(result), defaultValue);
  }

  test_getValue_flushResults() {
    ResultCachingPolicy<int> cachingPolicy =
        new SimpleResultCachingPolicy<int>(2, 2);
    ResultDescriptor<int> descriptor1 = new ResultDescriptor<int>(
        'result1', null,
        cachingPolicy: cachingPolicy);
    ResultDescriptor<int> descriptor2 = new ResultDescriptor<int>(
        'result2', null,
        cachingPolicy: cachingPolicy);
    ResultDescriptor<int> descriptor3 = new ResultDescriptor<int>(
        'result3', null,
        cachingPolicy: cachingPolicy);
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    {
      entry.setValue(descriptor1, 1, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.VALID);
    }
    {
      entry.setValue(descriptor2, 2, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.VALID);
      expect(entry.getState(descriptor2), CacheState.VALID);
    }
    // get descriptor1, so that descriptor2 will be flushed
    entry.getValue(descriptor1);
    {
      entry.setValue(descriptor3, 3, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.VALID);
      expect(entry.getState(descriptor2), CacheState.FLUSHED);
      expect(entry.getState(descriptor3), CacheState.VALID);
    }
  }

  test_hasErrorState_false() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    expect(entry.hasErrorState(), false);
  }

  test_hasErrorState_true() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setErrorState(exception, <ResultDescriptor>[result]);
    expect(entry.hasErrorState(), true);
  }

  test_invalidateAllInformation() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<String> result =
        new ResultDescriptor<String>('test', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setValue(result, 'value', TargetedResult.EMPTY_LIST);
    entry.invalidateAllInformation();
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), isNull);
  }

  test_setErrorState() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('res1', 1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('res2', 2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('res3', 3);
    // prepare some good state
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
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
    AnalysisTarget target1 = new TestSource('/a.dart');
    AnalysisTarget target2 = new TestSource('/b.dart');
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    cache.put(entry1);
    cache.put(entry2);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    ResultDescriptor<int> result4 = new ResultDescriptor<int>('result4', -4);
    // set results, all of them are VALID
    entry1.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry2.setValue(result2, 222, [new TargetedResult(target1, result1)]);
    entry2.setValue(result3, 333, [new TargetedResult(target2, result2)]);
    entry2.setValue(result4, 444, []);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry2.getState(result2), CacheState.VALID);
    expect(entry2.getState(result3), CacheState.VALID);
    expect(entry2.getState(result4), CacheState.VALID);
    expect(entry1.getValue(result1), 111);
    expect(entry2.getValue(result2), 222);
    expect(entry2.getValue(result3), 333);
    expect(entry2.getValue(result4), 444);
    // set error state
    CaughtException exception = new CaughtException(null, null);
    entry1.setErrorState(exception, <ResultDescriptor>[result1]);
    // result2 and result3 are invalidated, result4 is intact
    expect(entry1.getState(result1), CacheState.ERROR);
    expect(entry2.getState(result2), CacheState.ERROR);
    expect(entry2.getState(result3), CacheState.ERROR);
    expect(entry2.getState(result4), CacheState.VALID);
    expect(entry1.getValue(result1), -1);
    expect(entry2.getValue(result2), -2);
    expect(entry2.getValue(result3), -3);
    expect(entry2.getValue(result4), 444);
    expect(entry1.exception, exception);
    expect(entry2.exception, exception);
  }

  test_setErrorState_noDescriptors() {
    AnalysisTarget target = new TestSource();
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry(target);
    expect(() {
      entry.setErrorState(exception, <ResultDescriptor>[]);
    }, throwsArgumentError);
  }

  test_setErrorState_noException() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry(target);
    expect(() {
      entry.setErrorState(null, <ResultDescriptor>[result]);
    }, throwsArgumentError);
  }

  test_setErrorState_nullDescriptors() {
    AnalysisTarget target = new TestSource();
    CaughtException exception = new CaughtException(null, null);
    CacheEntry entry = new CacheEntry(target);
    expect(() {
      entry.setErrorState(exception, null);
    }, throwsArgumentError);
  }

  test_setState_error() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
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
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', 1);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
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
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', 1);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
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
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', 1);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    // set VALID
    entry.setValue(result, 10, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 10);
    // listen, expect "result" invalidation event
    int numberOfEvents = 0;
    cache.onResultInvalidated.listen((event) {
      numberOfEvents++;
      expect(event.entry, same(entry));
      expect(event.descriptor, same(result));
    });
    // set INVALID
    entry.setState(result, CacheState.INVALID);
    expect(entry.getState(result), CacheState.INVALID);
    expect(entry.getValue(result), 1);
    expect(numberOfEvents, 1);
  }

  test_setState_invalid_dependencyCycle() {
    AnalysisTarget target1 = new TestSource('/a.dart');
    AnalysisTarget target2 = new TestSource('/b.dart');
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    cache.put(entry1);
    cache.put(entry2);
    ResultDescriptor<int> result = new ResultDescriptor<int>('result', -1);
    // Set each result as VALID with a dependency on on the other.
    entry1.setValue(result, 100, [new TargetedResult(target2, result)]);
    entry2.setValue(result, 200, [new TargetedResult(target1, result)]);
    expect(entry1.getState(result), CacheState.VALID);
    expect(entry2.getState(result), CacheState.VALID);
    // Listen, expect entry1.result and entry2.result invalidation events.
    int numberOfEvents = 0;
    bool wasEntry1 = false;
    bool wasEntry2 = false;
    cache.onResultInvalidated.listen((event) {
      numberOfEvents++;
      if (event.entry == entry1) wasEntry1 = true;
      if (event.entry == entry2) wasEntry2 = true;
      expect(event.descriptor, same(result));
    });
    // Invalidate entry1.result; this should cause entry2 to be also
    // cleared without going into an infinite regress.
    entry1.setState(result, CacheState.INVALID);
    expect(cache.get(target1), isNull);
    expect(cache.get(target2), isNull);
    expect(numberOfEvents, 2);
    expect(wasEntry1, isTrue);
    expect(wasEntry2, isTrue);
  }

  test_setState_invalid_invalidateDependent() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    ResultDescriptor<int> result4 = new ResultDescriptor<int>('result4', -4);
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
    // result4 is still valid, so the entry is still in the cache
    expect(cache.get(target), entry);
  }

  test_setState_invalid_keepEmpty_ifExplicitlyAdded() {
    AnalysisTarget target = new TestSource('/a.dart');
    CacheEntry entry = new CacheEntry(target);
    entry.explicitlyAdded = true;
    cache.put(entry);
    ResultDescriptor<int> result = new ResultDescriptor<int>('result1', -1);
    // set results, all of them are VALID
    entry.setValue(result, 111, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), 111);
    // invalidate result, keep entry
    entry.setState(result, CacheState.INVALID);
    expect(cache.get(target), isNotNull);
  }

  test_setState_invalid_removeEmptyEntry() {
    AnalysisTarget target1 = new TestSource('/a.dart');
    AnalysisTarget target2 = new TestSource('/b.dart');
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    cache.put(entry1);
    cache.put(entry2);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    // set results, all of them are VALID
    entry1.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry2.setValue(result2, 222, [new TargetedResult(target1, result1)]);
    entry2.setValue(result3, 333, [new TargetedResult(target2, result2)]);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry2.getState(result2), CacheState.VALID);
    expect(entry2.getState(result3), CacheState.VALID);
    expect(entry1.getValue(result1), 111);
    expect(entry2.getValue(result2), 222);
    expect(entry2.getValue(result3), 333);
    // invalidate result1, remove entry1 & entry2
    entry1.setState(result1, CacheState.INVALID);
    expect(cache.get(target1), isNull);
    expect(cache.get(target2), isNull);
  }

  test_setState_invalid_withDelta_keepDependency() {
    Source target = new TestSource('/test.dart');
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    entry.setValue(result3, 333, [new TargetedResult(target, result2)]);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.VALID);
    // result2 depends on result1
    expect(entry.getResultData(result1).dependentResults,
        unorderedEquals([new TargetedResult(target, result2)]));
    expect(entry.getResultData(result2).dependedOnResults,
        unorderedEquals([new TargetedResult(target, result1)]));
    // record invalidated results
    Set<TargetedResult> reportedInvalidatedResults = new Set<TargetedResult>();
    cache.onResultInvalidated.listen((InvalidatedResult invalidatedResult) {
      reportedInvalidatedResults.add(new TargetedResult(
          invalidatedResult.entry.target, invalidatedResult.descriptor));
    });
    // invalidate result2 with Delta: keep result2, invalidate result3
    entry.setState(result2, CacheState.INVALID,
        delta: new _KeepContinueDelta(target, result2));
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.INVALID);
    // result2 still depends on result1
    expect(entry.getResultData(result1).dependentResults,
        unorderedEquals([new TargetedResult(target, result2)]));
    expect(entry.getResultData(result2).dependedOnResults,
        unorderedEquals([new TargetedResult(target, result1)]));
    // (target, result3) was reported as invalidated
    // (target, result2) was NOT reported
    expect(reportedInvalidatedResults,
        unorderedEquals([new TargetedResult(target, result3)]));
  }

  test_setState_valid() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor result = new ResultDescriptor('test', null);
    CacheEntry entry = new CacheEntry(target);
    expect(() => entry.setState(result, CacheState.VALID), throwsArgumentError);
  }

  test_setValue() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<String> result =
        new ResultDescriptor<String>('test', null);
    String value = 'value';
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setValue(result, value, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result), CacheState.VALID);
    expect(entry.getValue(result), value);
  }

  test_setValue_flushResults() {
    ResultCachingPolicy<int> cachingPolicy =
        new SimpleResultCachingPolicy<int>(2, 2);
    ResultDescriptor<int> descriptor1 = new ResultDescriptor<int>(
        'result1', null,
        cachingPolicy: cachingPolicy);
    ResultDescriptor<int> descriptor2 = new ResultDescriptor<int>(
        'result2', null,
        cachingPolicy: cachingPolicy);
    ResultDescriptor<int> descriptor3 = new ResultDescriptor<int>(
        'result3', null,
        cachingPolicy: cachingPolicy);
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    {
      entry.setValue(descriptor1, 1, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.VALID);
    }
    {
      entry.setValue(descriptor2, 2, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.VALID);
      expect(entry.getState(descriptor2), CacheState.VALID);
    }
    {
      entry.setValue(descriptor3, 3, TargetedResult.EMPTY_LIST);
      expect(entry.getState(descriptor1), CacheState.FLUSHED);
      expect(entry.getState(descriptor2), CacheState.VALID);
      expect(entry.getState(descriptor3), CacheState.VALID);
    }
  }

  test_setValue_flushResults_keepForPrioritySources() {
    ResultCachingPolicy<int> cachingPolicy =
        new SimpleResultCachingPolicy<int>(2, 2);
    ResultDescriptor<int> newResult(String name) =>
        new ResultDescriptor<int>(name, null, cachingPolicy: cachingPolicy);
    ResultDescriptor<int> descriptor1 = newResult('result1');
    ResultDescriptor<int> descriptor2 = newResult('result2');
    ResultDescriptor<int> descriptor3 = newResult('result3');
    TestSource source1 = new TestSource('/a.dart');
    TestSource source2 = new TestSource('/b.dart');
    TestSource source3 = new TestSource('/c.dart');
    AnalysisTarget target1 =
        new _TestAnalysisTarget(librarySource: source1, source: source1);
    AnalysisTarget target2 =
        new _TestAnalysisTarget(librarySource: source2, source: source2);
    AnalysisTarget target3 =
        new _TestAnalysisTarget(librarySource: source3, source: source3);
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    CacheEntry entry3 = new CacheEntry(target3);
    cache.put(entry1);
    cache.put(entry2);
    cache.put(entry3);

    // Set two results.
    entry1.setValue(descriptor1, 1, TargetedResult.EMPTY_LIST);
    entry2.setValue(descriptor2, 2, TargetedResult.EMPTY_LIST);
    expect(entry1.getState(descriptor1), CacheState.VALID);
    expect(entry2.getState(descriptor2), CacheState.VALID);

    // Make source1 priority, so result2 is flushed instead.
    when(context.prioritySources).thenReturn([source1]);
    entry3.setValue(descriptor3, 3, TargetedResult.EMPTY_LIST);
    expect(entry1.getState(descriptor1), CacheState.VALID);
    expect(entry2.getState(descriptor2), CacheState.FLUSHED);
    expect(entry3.getState(descriptor3), CacheState.VALID);
  }

  test_setValue_keepDependent() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    // set result1; result2 is intact
    entry.setValue(result1, 1111, TargetedResult.EMPTY_LIST);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getValue(result1), 1111);
    expect(entry.getValue(result2), 222);
  }

  test_setValue_userBeforeProvider_invalidateProvider_alsoUser() {
    AnalysisTarget target1 = new TestSource('/a.dart');
    AnalysisTarget target2 = new TestSource('/b.dart');
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    cache.put(entry1);
    cache.put(entry2);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    // set results, all of them are VALID
    entry2.setValue(result2, 222, [new TargetedResult(target1, result1)]);
    entry1.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    expect(entry1.getState(result1), CacheState.VALID);
    expect(entry2.getState(result2), CacheState.VALID);
    expect(entry1.getValue(result1), 111);
    expect(entry2.getValue(result2), 222);
    // invalidate result1, should invalidate also result2
    entry1.setState(result1, CacheState.INVALID);
    expect(entry1.getState(result1), CacheState.INVALID);
    expect(entry2.getState(result2), CacheState.INVALID);
  }

  test_setValueIncremental() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    ResultDescriptor<int> result1 = new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> result2 = new ResultDescriptor<int>('result2', -2);
    ResultDescriptor<int> result3 = new ResultDescriptor<int>('result3', -3);
    // set results, all of them are VALID
    entry.setValue(result1, 111, TargetedResult.EMPTY_LIST);
    entry.setValue(result2, 222, [new TargetedResult(target, result1)]);
    entry.setValue(result3, 333, [new TargetedResult(target, result2)]);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.VALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 222);
    expect(entry.getValue(result3), 333);
    // replace result1, keep "dependedOn", invalidate result3
    entry.setValueIncremental(result2, 2222, true);
    expect(entry.getState(result1), CacheState.VALID);
    expect(entry.getState(result2), CacheState.VALID);
    expect(entry.getState(result3), CacheState.INVALID);
    expect(entry.getValue(result1), 111);
    expect(entry.getValue(result2), 2222);
    expect(entry.getValue(result3), -3);
    expect(entry.getResultData(result1).dependentResults,
        unorderedEquals([new TargetedResult(target, result2)]));
    expect(entry.getResultData(result2).dependedOnResults,
        unorderedEquals([new TargetedResult(target, result1)]));
  }

  test_toString_empty() {
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    expect(entry.toString(), isNotNull);
  }

  test_toString_nonEmpty() {
    AnalysisTarget target = new TestSource();
    ResultDescriptor<int> result = new ResultDescriptor<int>('test', null);
    CacheEntry entry = new CacheEntry(target);
    cache.put(entry);
    entry.setValue(result, 42, TargetedResult.EMPTY_LIST);
    expect(entry.toString(), isNotNull);
  }
}

@reflectiveTest
class CacheFlushManagerTest {
  CacheFlushManager manager = new CacheFlushManager(
      new SimpleResultCachingPolicy(15, 3), (AnalysisTarget target) => false);

  test_madeActive() {
    manager.madeActive();
    expect(manager.maxSize, 15);
  }

  test_madeIdle() {
    manager.madeActive();
    AnalysisTarget target = new TestSource();
    // prepare TargetedResult(s)
    List<TargetedResult> results = <TargetedResult>[];
    for (int i = 0; i < 15; i++) {
      ResultDescriptor descriptor = new ResultDescriptor('result$i', null);
      results.add(new TargetedResult(target, descriptor));
    }
    // notify about storing TargetedResult(s)
    for (TargetedResult result in results) {
      manager.resultStored(result, null);
    }
    expect(manager.recentlyUsed, results);
    expect(manager.currentSize, 15);
    // make idle
    List<TargetedResult> resultsToFlush = manager.madeIdle();
    expect(manager.maxSize, 3);
    expect(manager.recentlyUsed, results.skip(15 - 3));
    expect(resultsToFlush, results.take(15 - 3));
  }

  test_new() {
    expect(manager.maxActiveSize, 15);
    expect(manager.maxIdleSize, 3);
    expect(manager.maxSize, 15);
    expect(manager.currentSize, 0);
    expect(manager.recentlyUsed, isEmpty);
  }

  test_resultAccessed() {
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    ResultDescriptor descriptor3 = new ResultDescriptor('result3', null);
    AnalysisTarget target = new TestSource();
    TargetedResult result1 = new TargetedResult(target, descriptor1);
    TargetedResult result2 = new TargetedResult(target, descriptor2);
    TargetedResult result3 = new TargetedResult(target, descriptor3);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    manager.resultStored(result3, null);
    expect(manager.currentSize, 3);
    expect(manager.recentlyUsed, orderedEquals([result1, result2, result3]));
    // access result2
    manager.resultAccessed(result2);
    expect(manager.currentSize, 3);
    expect(manager.recentlyUsed, orderedEquals([result1, result3, result2]));
  }

  test_resultAccessed_negativeMaxSize() {
    manager = new CacheFlushManager(new SimpleResultCachingPolicy(-1, -1),
        (AnalysisTarget target) => false);
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    AnalysisTarget target = new TestSource();
    TargetedResult result1 = new TargetedResult(target, descriptor1);
    TargetedResult result2 = new TargetedResult(target, descriptor2);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    expect(manager.currentSize, 0);
    expect(manager.recentlyUsed, isEmpty);
    // access result2
    manager.resultAccessed(result2);
    expect(manager.currentSize, 0);
    expect(manager.recentlyUsed, isEmpty);
  }

  test_resultAccessed_noSuchResult() {
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    ResultDescriptor descriptor3 = new ResultDescriptor('result3', null);
    AnalysisTarget target = new TestSource();
    TargetedResult result1 = new TargetedResult(target, descriptor1);
    TargetedResult result2 = new TargetedResult(target, descriptor2);
    TargetedResult result3 = new TargetedResult(target, descriptor3);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    expect(manager.currentSize, 2);
    expect(manager.recentlyUsed, orderedEquals([result1, result2]));
    // access result3, no-op
    manager.resultAccessed(result3);
    expect(manager.currentSize, 2);
    expect(manager.recentlyUsed, orderedEquals([result1, result2]));
  }

  test_resultStored() {
    CacheFlushManager manager = new CacheFlushManager(
        new SimpleResultCachingPolicy(3, 3), (AnalysisTarget target) => false);
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    ResultDescriptor descriptor3 = new ResultDescriptor('result3', null);
    ResultDescriptor descriptor4 = new ResultDescriptor('result4', null);
    AnalysisTarget target = new TestSource();
    TargetedResult result1 = new TargetedResult(target, descriptor1);
    TargetedResult result2 = new TargetedResult(target, descriptor2);
    TargetedResult result3 = new TargetedResult(target, descriptor3);
    TargetedResult result4 = new TargetedResult(target, descriptor4);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    manager.resultStored(result3, null);
    expect(manager.currentSize, 3);
    expect(manager.recentlyUsed, orderedEquals([result1, result2, result3]));
    // store result2 again
    {
      List<TargetedResult> resultsToFlush = manager.resultStored(result2, null);
      expect(resultsToFlush, isEmpty);
      expect(manager.currentSize, 3);
      expect(manager.recentlyUsed, orderedEquals([result1, result3, result2]));
    }
    // store result4
    {
      List<TargetedResult> resultsToFlush = manager.resultStored(result4, null);
      expect(resultsToFlush, [result1]);
      expect(manager.currentSize, 3);
      expect(manager.recentlyUsed, orderedEquals([result3, result2, result4]));
      expect(manager.resultSizeMap, {result3: 1, result2: 1, result4: 1});
    }
  }

  test_resultStored_negativeMaxSize() {
    manager = new CacheFlushManager(new SimpleResultCachingPolicy(-1, -1),
        (AnalysisTarget target) => false);
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    AnalysisTarget target = new TestSource();
    TargetedResult result1 = new TargetedResult(target, descriptor1);
    TargetedResult result2 = new TargetedResult(target, descriptor2);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    expect(manager.currentSize, 0);
    expect(manager.recentlyUsed, isEmpty);
  }

  test_targetRemoved() {
    ResultDescriptor descriptor1 = new ResultDescriptor('result1', null);
    ResultDescriptor descriptor2 = new ResultDescriptor('result2', null);
    ResultDescriptor descriptor3 = new ResultDescriptor('result3', null);
    AnalysisTarget target1 = new TestSource('a.dart');
    AnalysisTarget target2 = new TestSource('b.dart');
    TargetedResult result1 = new TargetedResult(target1, descriptor1);
    TargetedResult result2 = new TargetedResult(target2, descriptor2);
    TargetedResult result3 = new TargetedResult(target1, descriptor3);
    manager.resultStored(result1, null);
    manager.resultStored(result2, null);
    manager.resultStored(result3, null);
    expect(manager.currentSize, 3);
    expect(manager.recentlyUsed, orderedEquals([result1, result2, result3]));
    expect(manager.resultSizeMap, {result1: 1, result2: 1, result3: 1});
    // remove target1
    {
      manager.targetRemoved(target1);
      expect(manager.currentSize, 1);
      expect(manager.recentlyUsed, orderedEquals([result2]));
      expect(manager.resultSizeMap, {result2: 1});
    }
    // remove target2
    {
      manager.targetRemoved(target2);
      expect(manager.currentSize, 0);
      expect(manager.recentlyUsed, isEmpty);
      expect(manager.resultSizeMap, isEmpty);
    }
  }
}

abstract class CachePartitionTest extends EngineTestCase {
  CachePartition createPartition();

  void test_creation() {
    expect(createPartition(), isNotNull);
  }

  void test_dispose() {
    CachePartition partition = createPartition();
    Source source1 = new TestSource('/1.dart');
    Source source2 = new TestSource('/2.dart');
    CacheEntry entry1 = new CacheEntry(source1);
    CacheEntry entry2 = new CacheEntry(source2);
    // add two sources
    partition.put(entry1);
    partition.put(entry2);
    expect(partition.entryMap, hasLength(2));
    expect(partition.pathToSource, hasLength(2));
    expect(partition.sources, unorderedEquals([source1, source2]));
    // dispose, no sources
    partition.dispose();
    expect(partition.entryMap, isEmpty);
    expect(partition.pathToSource, isEmpty);
    expect(partition.sources, isEmpty);
  }

  void test_entrySet() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    partition.put(entry);
    Map<AnalysisTarget, CacheEntry> entryMap = partition.entryMap;
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

  void test_put_alreadyInPartition() {
    CachePartition partition1 = createPartition();
    CachePartition partition2 = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    partition1.put(entry);
    expect(() => partition2.put(entry), throwsStateError);
  }

  void test_put_noFlush() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    partition.put(entry);
    expect(partition.get(target), entry);
  }

  void test_remove_absent() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    expect(partition.get(target), isNull);
    expect(partition.remove(target), isNull);
    expect(partition.get(target), isNull);
  }

  void test_remove_present() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    CacheEntry entry = new CacheEntry(target);
    partition.put(entry);
    expect(partition.get(target), entry);
    expect(partition.remove(target), entry);
    expect(partition.get(target), isNull);
  }
}

@reflectiveTest
class PackageCachePartitionTest extends CachePartitionTest {
  MemoryResourceProvider resourceProvider;
  Folder rootFolder;

  CachePartition createPartition() {
    resourceProvider = new MemoryResourceProvider();
    rootFolder = resourceProvider.newFolder('/package/root');
    return new PackageCachePartition(null, rootFolder);
  }

  void test_contains_false() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    expect(partition.isResponsibleFor(target), isFalse);
  }

  void test_contains_true() {
    SdkCachePartition partition = new SdkCachePartition(null);
    SourceFactory factory = new SourceFactory([
      new PackageMapUriResolver(resourceProvider, <String, List<Folder>>{
        'root': <Folder>[rootFolder]
      })
    ]);
    AnalysisTarget target = factory.forUri("package:root/root.dart");
    expect(partition.isResponsibleFor(target), isTrue);
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

  test_flush() {
    ResultDescriptor result = new ResultDescriptor('test', -1);
    ResultData data = new ResultData(result);
    data.state = CacheState.VALID;
    data.value = 123;
    data.flush();
    expect(data.state, CacheState.FLUSHED);
    expect(data.value, -1);
  }
}

@reflectiveTest
class SdkCachePartitionTest extends CachePartitionTest {
  CachePartition createPartition() {
    return new SdkCachePartition(null);
  }

  void test_contains_false() {
    CachePartition partition = createPartition();
    AnalysisTarget target = new TestSource();
    expect(partition.isResponsibleFor(target), isFalse);
  }

  void test_contains_true() {
    SdkCachePartition partition = new SdkCachePartition(null);
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    FolderBasedDartSdk sdk = new FolderBasedDartSdk(resourceProvider,
        FolderBasedDartSdk.defaultSdkDirectory(resourceProvider));
    SourceFactory factory = new SourceFactory([new DartUriResolver(sdk)]);
    AnalysisTarget target = factory.forUri("dart:core");
    expect(partition.isResponsibleFor(target), isTrue);
  }
}

@reflectiveTest
class UniversalCachePartitionTest extends CachePartitionTest {
  CachePartition createPartition() {
    return new UniversalCachePartition(null);
  }

  void test_contains() {
    UniversalCachePartition partition = new UniversalCachePartition(null);
    TestSource source = new TestSource();
    expect(partition.isResponsibleFor(source), isTrue);
  }

  test_dispose() {
    InternalAnalysisContext context = new _InternalAnalysisContextMock();
    CachePartition partition1 = new UniversalCachePartition(context);
    CachePartition partition2 = new UniversalCachePartition(context);
    AnalysisCache cache = new AnalysisCache([partition1, partition2]);
    when(context.analysisCache).thenReturn(cache);
    // configure
    // prepare entries
    ResultDescriptor<int> descriptor1 =
        new ResultDescriptor<int>('result1', -1);
    ResultDescriptor<int> descriptor2 =
        new ResultDescriptor<int>('result2', -2);
    AnalysisTarget target1 = new TestSource('1.dart');
    AnalysisTarget target2 = new TestSource('2.dart');
    TargetedResult result1 = new TargetedResult(target1, descriptor1);
    TargetedResult result2 = new TargetedResult(target2, descriptor2);
    CacheEntry entry1 = new CacheEntry(target1);
    CacheEntry entry2 = new CacheEntry(target2);
    partition1.put(entry1);
    partition2.put(entry2);
    entry1.setValue(descriptor1, 1, TargetedResult.EMPTY_LIST);
    entry2.setValue(descriptor2, 2, <TargetedResult>[result1]);
    // target2 is listed as dependent in target1
    expect(
        entry1.getResultData(descriptor1).dependentResults, contains(result2));
    // dispose
    partition2.dispose();
    expect(partition1.get(target1), same(entry1));
    expect(partition2.get(target2), isNull);
    // result2 is removed from result1
    expect(entry1.getResultData(descriptor1).dependentResults, isEmpty);
  }
}

class _InternalAnalysisContextMock extends TypedMock
    implements InternalAnalysisContext {
  @override
  final AnalysisOptions analysisOptions = new AnalysisOptionsImpl();
}

/**
 * Keep the given [keepDescriptor], invalidate all the other results.
 */
class _KeepContinueDelta implements Delta {
  final Source source;
  final ResultDescriptor keepDescriptor;

  _KeepContinueDelta(this.source, this.keepDescriptor);

  @override
  bool get shouldGatherChanges => false;

  @override
  bool gatherChanges(InternalAnalysisContext context, AnalysisTarget target,
      ResultDescriptor descriptor, Object value) {
    return false;
  }

  @override
  void gatherEnd() {}

  @override
  DeltaResult validate(InternalAnalysisContext context, AnalysisTarget target,
      ResultDescriptor descriptor, Object value) {
    if (descriptor == keepDescriptor) {
      return DeltaResult.KEEP_CONTINUE;
    }
    return DeltaResult.INVALIDATE;
  }
}

class _TestAnalysisTarget implements AnalysisTarget {
  final Source librarySource;
  final Source source;
  _TestAnalysisTarget({this.librarySource, this.source});
}
