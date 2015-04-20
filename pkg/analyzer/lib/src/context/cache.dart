// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context.cache;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, CacheState, InternalAnalysisContext, RetentionPriority;
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:analyzer/task/model.dart';

/**
 * An LRU cache of results produced by analysis.
 */
class AnalysisCache {
  /**
   * A flag used to control whether trace information should be produced when
   * the content of the cache is modified.
   */
  static bool _TRACE_CHANGES = false;

  /**
   * An array containing the partitions of which this cache is comprised.
   */
  final List<CachePartition> _partitions;

  /**
   * Initialize a newly created cache to have the given [partitions]. The
   * partitions will be searched in the order in which they appear in the array,
   * so the most specific partition (usually an [SdkCachePartition]) should be
   * first and the most general (usually a [UniversalCachePartition]) last.
   */
  AnalysisCache(this._partitions);

  /**
   * Return the number of entries in this cache that have an AST associated with
   * them.
   */
  int get astSize => _partitions[_partitions.length - 1].astSize;

  // TODO(brianwilkerson) Implement or delete this.
//  /**
//   * Return information about each of the partitions in this cache.
//   */
//  List<AnalysisContextStatistics_PartitionData> get partitionData {
//    int count = _partitions.length;
//    List<AnalysisContextStatistics_PartitionData> data =
//        new List<AnalysisContextStatistics_PartitionData>(count);
//    for (int i = 0; i < count; i++) {
//      CachePartition partition = _partitions[i];
//      data[i] = new AnalysisContextStatisticsImpl_PartitionDataImpl(
//          partition.astSize,
//          partition.map.length);
//    }
//    return data;
//  }

  /**
   * Record that the AST associated with the given [target] was just read from
   * the cache.
   */
  void accessedAst(AnalysisTarget target) {
    // TODO(brianwilkerson) Extract this logic to a helper method (here and
    // elsewhere)
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        _partitions[i].accessedAst(target);
        return;
      }
    }
  }

  /**
   * Return the entry associated with the given [target].
   */
  CacheEntry get(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        return _partitions[i].get(target);
      }
    }
    //
    // We should never get to this point because the last partition should
    // always be a universal partition, except in the case of the SDK context,
    // in which case the target should always be part of the SDK.
    //
    return null;
  }

  /**
   * Return the context to which the given [target] was explicitly added.
   */
  InternalAnalysisContext getContextFor(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        return _partitions[i].context;
      }
    }
    //
    // We should never get to this point because the last partition should
    // always be a universal partition, except in the case of the SDK context,
    // in which case the target should always be part of the SDK.
    //
    // TODO(brianwilkerson) Throw an exception here.
    AnalysisEngine.instance.logger.logInformation(
        'Could not find context for $target',
        new CaughtException(new AnalysisException(), null));
    return null;
  }

  /**
   * Return an iterator returning all of the map entries mapping targets to
   * cache entries.
   */
  MapIterator<AnalysisTarget, CacheEntry> iterator() {
    int count = _partitions.length;
    List<Map<AnalysisTarget, CacheEntry>> maps = new List<Map>(count);
    for (int i = 0; i < count; i++) {
      maps[i] = _partitions[i].map;
    }
    return new MultipleMapIterator<AnalysisTarget, CacheEntry>(maps);
  }

  /**
   * Associate the given [entry] with the given [target].
   */
  void put(AnalysisTarget target, CacheEntry entry) {
    entry.fixExceptionState();
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        if (_TRACE_CHANGES) {
          CacheEntry oldEntry = _partitions[i].get(target);
          if (oldEntry == null) {
            AnalysisEngine.instance.logger
                .logInformation('Added a cache entry for $target.');
          } else {
            AnalysisEngine.instance.logger
                .logInformation('Modified the cache entry for $target.');
//                'Diff = ${entry.getDiff(oldEntry)}');
          }
        }
        _partitions[i].put(target, entry);
        return;
      }
    }
    // TODO(brianwilkerson) Handle the case where no partition was found,
    // possibly by throwing an exception.
  }

  /**
   * Remove all information related to the given [target] from this cache.
   */
  void remove(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        if (_TRACE_CHANGES) {
          AnalysisEngine.instance.logger
              .logInformation('Removed the cache entry for $target.');
        }
        _partitions[i].remove(target);
        return;
      }
    }
  }

  /**
   * Record that the AST associated with the given [target] was just removed
   * from the cache.
   */
  void removedAst(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        _partitions[i].removedAst(target);
        return;
      }
    }
  }

  /**
   * Return the number of targets that are mapped to cache entries.
   */
  int size() {
    int size = 0;
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      size += _partitions[i].size();
    }
    return size;
  }

  /**
   * Record that the AST associated with the given [target] was just stored to
   * the cache.
   */
  void storedAst(AnalysisTarget target) {
    int count = _partitions.length;
    for (int i = 0; i < count; i++) {
      if (_partitions[i].contains(target)) {
        _partitions[i].storedAst(target);
        return;
      }
    }
  }
}

/**
 * The information cached by an analysis context about an individual target.
 */
class CacheEntry {
  /**
   * The index of the flag indicating whether the source was explicitly added to
   * the context or whether the source was implicitly added because it was
   * referenced by another source.
   */
  static int _EXPLICITLY_ADDED_FLAG = 0;

  /**
   * The most recent time at which the state of the target matched the state
   * represented by this entry.
   */
  int modificationTime = 0;

  /**
   * The exception that caused one or more values to have a state of
   * [CacheState.ERROR].
   */
  CaughtException _exception;

  /**
   * A bit-encoding of boolean flags associated with this entry's target.
   */
  int _flags = 0;

  /**
   * A table mapping result descriptors to the cached values of those results.
   */
  Map<ResultDescriptor, ResultData> _resultMap =
      new HashMap<ResultDescriptor, ResultData>();

  /**
   * The exception that caused one or more values to have a state of
   * [CacheState.ERROR].
   */
  CaughtException get exception => _exception;

  /**
   * Return `true` if the source was explicitly added to the context or `false`
   * if the source was implicitly added because it was referenced by another
   * source.
   */
  bool get explicitlyAdded => _getFlag(_EXPLICITLY_ADDED_FLAG);

  /**
   * Set whether the source was explicitly added to the context to match the
   * [explicitlyAdded] flag.
   */
  void set explicitlyAdded(bool explicitlyAdded) {
    _setFlag(_EXPLICITLY_ADDED_FLAG, explicitlyAdded);
  }

  /**
   * Return `true` if this entry contains at least one result whose value is an
   * AST structure.
   */
  bool get hasAstStructure {
    for (ResultData data in _resultMap.values) {
      if (data.value is AstNode || data.value is XmlNode) {
        return true;
      }
    }
    return false;
  }

  /**
   * Fix the state of the [exception] to match the current state of the entry.
   */
  void fixExceptionState() {
    if (!hasErrorState()) {
      _exception = null;
    }
  }

  /**
   * Mark any AST structures associated with this cache entry as being flushed.
   */
  void flushAstStructures() {
    _resultMap.forEach((ResultDescriptor descriptor, ResultData data) {
      if (data.value is AstNode || data.value is XmlNode) {
        _validateStateChange(descriptor, CacheState.FLUSHED);
        data.state = CacheState.FLUSHED;
        data.value = descriptor.defaultValue;
      }
    });
  }

  /**
   * Return the state of the result represented by the given [descriptor].
   */
  CacheState getState(ResultDescriptor descriptor) {
    ResultData data = _resultMap[descriptor];
    if (data == null) {
      return CacheState.INVALID;
    }
    return data.state;
  }

  /**
   * Return the value of the result represented by the given [descriptor], or
   * the default value for the result if this entry does not have a valid value.
   */
  /*<V>*/ dynamic /*V*/ getValue(ResultDescriptor /*<V>*/ descriptor) {
    ResultData data = _resultMap[descriptor];
    if (data == null) {
      return descriptor.defaultValue;
    }
    return data.value;
  }

  /**
   * Return `true` if the state of any data value is [CacheState.ERROR].
   */
  bool hasErrorState() {
    for (ResultData data in _resultMap.values) {
      if (data.state == CacheState.ERROR) {
        return true;
      }
    }
    return false;
  }

  /**
   * Invalidate all of the information associated with this entry's target.
   */
  void invalidateAllInformation() {
    _resultMap.clear();
    _exception = null;
  }

  /**
   * Return `true` if the state of the result represented by the given
   * [descriptor] is [CacheState.INVALID].
   */
  bool isInvalid(ResultDescriptor descriptor) =>
      getState(descriptor) == CacheState.INVALID;

  /**
   * Return `true` if the state of the result represented by the given
   * [descriptor] is [CacheState.VALID].
   */
  bool isValid(ResultDescriptor descriptor) =>
      getState(descriptor) == CacheState.VALID;

  /**
   * Set the [CacheState.ERROR] state for given [descriptors], their values to
   * the corresponding default values, and remember the [exception] that caused
   * this state.
   */
  void setErrorState(
      CaughtException exception, List<ResultDescriptor> descriptors) {
    if (descriptors == null || descriptors.isEmpty) {
      throw new ArgumentError('at least one descriptor is expected');
    }
    if (exception == null) {
      throw new ArgumentError('an exception is expected');
    }
    this._exception = exception;
    for (ResultDescriptor descriptor in descriptors) {
      ResultData data = _getResultData(descriptor);
      data.state = CacheState.ERROR;
      data.value = descriptor.defaultValue;
    }
  }

  /**
   * Set the state of the result represented by the given [descriptor] to the
   * given [state].
   */
  void setState(ResultDescriptor descriptor, CacheState state) {
    if (state == CacheState.ERROR) {
      throw new ArgumentError('use setErrorState() to set the state to ERROR');
    }
    if (state == CacheState.VALID) {
      throw new ArgumentError('use setValue() to set the state to VALID');
    }
    _validateStateChange(descriptor, state);
    if (state == CacheState.INVALID) {
      _resultMap.remove(descriptor);
    } else {
      ResultData data = _getResultData(descriptor);
      data.state = state;
      if (state != CacheState.IN_PROCESS) {
        //
        // If the state is in-process, we can leave the current value in the
        // cache for any 'get' methods to access.
        //
        data.value = descriptor.defaultValue;
      }
    }
  }

  /**
   * Set the value of the result represented by the given [descriptor] to the
   * given [value].
   */
  /*<V>*/ void setValue(ResultDescriptor /*<V>*/ descriptor, dynamic /*V*/
      value) {
    _validateStateChange(descriptor, CacheState.VALID);
    ResultData data = _getResultData(descriptor);
    data.state = CacheState.VALID;
    data.value = value == null ? descriptor.defaultValue : value;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    _writeOn(buffer);
    return buffer.toString();
  }

  /**
   * Return the value of the flag with the given [index].
   */
  bool _getFlag(int index) => BooleanArray.get(_flags, index);

  /**
   * Look up the [ResultData] of [descriptor], or add a new one if it isn't
   * there.
   */
  ResultData _getResultData(ResultDescriptor descriptor) {
    return _resultMap.putIfAbsent(descriptor, () => new ResultData(descriptor));
  }

  /**
   * Set the value of the flag with the given [index] to the given [value].
   */
  void _setFlag(int index, bool value) {
    _flags = BooleanArray.set(_flags, index, value);
  }

  /**
   * If the state of the value described by the given [descriptor] is changing
   * from ERROR to anything else, capture the information. This is an attempt to
   * discover the underlying cause of a long-standing bug.
   */
  void _validateStateChange(ResultDescriptor descriptor, CacheState newState) {
    // TODO(brianwilkerson) Decide whether we still want to capture this data.
//    if (descriptor != CONTENT) {
//      return;
//    }
//    ResultData data = resultMap[CONTENT];
//    if (data != null && data.state == CacheState.ERROR) {
//      String message =
//          'contentState changing from ${data.state} to $newState';
//      InstrumentationBuilder builder =
//          Instrumentation.builder2('CacheEntry-validateStateChange');
//      builder.data3('message', message);
//      //builder.data('source', source.getFullName());
//      builder.record(new CaughtException(new AnalysisException(message), null));
//      builder.log();
//    }
  }

  /**
   * Write a textual representation of this entry to the given [buffer]. The
   * result should only be used for debugging purposes.
   */
  void _writeOn(StringBuffer buffer) {
    buffer.write('time = ');
    buffer.write(modificationTime);
    List<ResultDescriptor> results = _resultMap.keys.toList();
    results.sort((ResultDescriptor first, ResultDescriptor second) =>
        first.toString().compareTo(second.toString()));
    for (ResultDescriptor result in results) {
      ResultData data = _resultMap[result];
      buffer.write('; ');
      buffer.write(result.toString());
      buffer.write(' = ');
      buffer.write(data..state);
    }
  }
}

/**
 * A single partition in an LRU cache of information related to analysis.
 */
abstract class CachePartition {
  /**
   * The context that owns this partition. Multiple contexts can reference a
   * partition, but only one context can own it.
   */
  final InternalAnalysisContext context;

  /**
   * The maximum number of sources for which AST structures should be kept in
   * the cache.
   */
  int _maxCacheSize = 0;

  /**
   * The policy used to determine which results to remove from the cache.
   */
  final CacheRetentionPolicy _retentionPolicy;

  /**
   * A table mapping the targets belonging to this partition to the information
   * known about those targets.
   */
  HashMap<AnalysisTarget, CacheEntry> _targetMap =
      new HashMap<AnalysisTarget, CacheEntry>();

  /**
   * A list containing the most recently accessed targets with the most recently
   * used at the end of the list. When more targets are added than the maximum
   * allowed then the least recently used target will be removed and will have
   * it's cached AST structure flushed.
   */
  List<AnalysisTarget> _recentlyUsed = <AnalysisTarget>[];

  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context]. The partition will maintain at most [_maxCacheSize] AST
   * structures in the cache, using the [_retentionPolicy] to determine which
   * AST structures to flush.
   */
  CachePartition(this.context, this._maxCacheSize, this._retentionPolicy);

  /**
   * Return the number of entries in this partition that have an AST associated
   * with them.
   */
  int get astSize {
    int astSize = 0;
    int count = _recentlyUsed.length;
    for (int i = 0; i < count; i++) {
      AnalysisTarget target = _recentlyUsed[i];
      CacheEntry entry = _targetMap[target];
      if (entry.hasAstStructure) {
        astSize++;
      }
    }
    return astSize;
  }

  /**
   * Return a table mapping the targets known to the context to the information
   * known about the target.
   *
   * <b>Note:</b> This method is only visible for use by [AnalysisCache] and
   * should not be used for any other purpose.
   */
  Map<AnalysisTarget, CacheEntry> get map => _targetMap;

  /**
   * Return the maximum size of the cache.
   */
  int get maxCacheSize => _maxCacheSize;

  /**
   * Set the maximum size of the cache to the given [size].
   */
  void set maxCacheSize(int size) {
    _maxCacheSize = size;
    while (_recentlyUsed.length > _maxCacheSize) {
      if (!_flushAstFromCache()) {
        break;
      }
    }
  }

  /**
   * Record that the AST associated with the given [target] was just read from
   * the cache.
   */
  void accessedAst(AnalysisTarget target) {
    if (_recentlyUsed.remove(target)) {
      _recentlyUsed.add(target);
      return;
    }
    while (_recentlyUsed.length >= _maxCacheSize) {
      if (!_flushAstFromCache()) {
        break;
      }
    }
    _recentlyUsed.add(target);
  }

  /**
   * Return `true` if the given [target] is contained in this partition.
   */
  // TODO(brianwilkerson) Rename this to something more meaningful, such as
  // isResponsibleFor.
  bool contains(AnalysisTarget target);

  /**
   * Return the entry associated with the given [target].
   */
  CacheEntry get(AnalysisTarget target) => _targetMap[target];

  /**
   * Return an iterator returning all of the map entries mapping targets to
   * cache entries.
   */
  MapIterator<AnalysisTarget, CacheEntry> iterator() =>
      new SingleMapIterator<AnalysisTarget, CacheEntry>(_targetMap);

  /**
   * Associate the given [entry] with the given [target].
   */
  void put(AnalysisTarget target, CacheEntry entry) {
    entry.fixExceptionState();
    _targetMap[target] = entry;
  }

  /**
   * Remove all information related to the given [target] from this cache.
   */
  void remove(AnalysisTarget target) {
    _recentlyUsed.remove(target);
    _targetMap.remove(target);
  }

  /**
   * Record that the AST associated with the given [target] was just removed
   * from the cache.
   */
  void removedAst(AnalysisTarget target) {
    _recentlyUsed.remove(target);
  }

  /**
   * Return the number of targets that are mapped to cache entries.
   */
  int size() => _targetMap.length;

  /**
   * Record that the AST associated with the given [target] was just stored to
   * the cache.
   */
  void storedAst(AnalysisTarget target) {
    if (_recentlyUsed.contains(target)) {
      return;
    }
    while (_recentlyUsed.length >= _maxCacheSize) {
      if (!_flushAstFromCache()) {
        break;
      }
    }
    _recentlyUsed.add(target);
  }

  /**
   * Attempt to flush one AST structure from the cache. Return `true` if a
   * structure was flushed.
   */
  bool _flushAstFromCache() {
    AnalysisTarget removedTarget = _removeAstToFlush();
    if (removedTarget == null) {
      return false;
    }
    CacheEntry entry = _targetMap[removedTarget];
    entry.flushAstStructures();
    return true;
  }

  /**
   * Remove and return one target from the list of recently used targets whose
   * AST structure can be flushed from the cache,  or `null` if none of the
   * targets can be removed. The target that will be returned will be the target
   * that has been unreferenced for the longest period of time but that is not a
   * priority for analysis.
   */
  AnalysisTarget _removeAstToFlush() {
    int targetToRemove = -1;
    for (int i = 0; i < _recentlyUsed.length; i++) {
      AnalysisTarget target = _recentlyUsed[i];
      RetentionPriority priority =
          _retentionPolicy.getAstPriority(target, _targetMap[target]);
      if (priority == RetentionPriority.LOW) {
        return _recentlyUsed.removeAt(i);
      } else if (priority == RetentionPriority.MEDIUM && targetToRemove < 0) {
        targetToRemove = i;
      }
    }
    if (targetToRemove < 0) {
      // This happens if the retention policy returns a priority of HIGH for all
      // of the targets that have been recently used. This is the case, for
      // example, when the list of priority sources is bigger than the current
      // cache size.
      return null;
    }
    return _recentlyUsed.removeAt(targetToRemove);
  }
}

/**
 * A policy objecy that determines how important it is for data to be retained
 * in the analysis cache.
 */
abstract class CacheRetentionPolicy {
  /**
   * Return the priority of retaining the AST structure for the given [target]
   * in the given [entry].
   */
  // TODO(brianwilkerson) Find a more general mechanism, probably based on task
  // descriptors, to determine which data is still needed for analysis and which
  // can be removed from the cache. Ideally we could (a) remove the need for
  // this class and (b) be able to flush all result data (not just AST's).
  RetentionPriority getAstPriority(AnalysisTarget target, CacheEntry entry);
}

/**
 * A retention policy that will keep AST's in the cache if there is analysis
 * information that needs to be computed for a source, where the computation is
 * dependent on having the AST.
 */
class DefaultRetentionPolicy implements CacheRetentionPolicy {
  /**
   * An instance of this class that can be shared.
   */
  static const DefaultRetentionPolicy POLICY = const DefaultRetentionPolicy();

  /**
   * Initialize a newly created instance of this class.
   */
  const DefaultRetentionPolicy();

  // TODO(brianwilkerson) Implement or delete this.
//  /**
//   * Return `true` if there is analysis information in the given entry that needs to be
//   * computed, where the computation is dependent on having the AST.
//   *
//   * @param dartEntry the entry being tested
//   * @return `true` if there is analysis information that needs to be computed from the AST
//   */
//  bool astIsNeeded(DartEntry dartEntry) =>
//      dartEntry.hasInvalidData(DartEntry.HINTS) ||
//          dartEntry.hasInvalidData(DartEntry.LINTS) ||
//          dartEntry.hasInvalidData(DartEntry.VERIFICATION_ERRORS) ||
//          dartEntry.hasInvalidData(DartEntry.RESOLUTION_ERRORS);

  @override
  RetentionPriority getAstPriority(AnalysisTarget target, CacheEntry entry) {
    // TODO(brianwilkerson) Implement or replace this.
//    if (sourceEntry is DartEntry) {
//      DartEntry dartEntry = sourceEntry;
//      if (astIsNeeded(dartEntry)) {
//        return RetentionPriority.MEDIUM;
//      }
//    }
//    return RetentionPriority.LOW;
    return RetentionPriority.MEDIUM;
  }
}

/**
 * The data about a single analysis result that is stored in a [CacheEntry].
 */
// TODO(brianwilkerson) Consider making this a generic class so that the value
// can be typed.
class ResultData {
  /**
   * The state of the cached value.
   */
  CacheState state;

  /**
   * The value being cached, or the default value for the result if there is no
   * value (for example, when the [state] is [CacheState.INVALID]).
   */
  Object value;

  /**
   * Initialize a newly created result holder to represent the value of data
   * described by the given [descriptor].
   */
  ResultData(ResultDescriptor descriptor) {
    state = CacheState.INVALID;
    value = descriptor.defaultValue;
  }
}

/**
 * A cache partition that contains all of the targets in the SDK.
 */
class SdkCachePartition extends CachePartition {
  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context]. The partition will maintain at most [maxCacheSize] AST
   * structures in the cache.
   */
  SdkCachePartition(InternalAnalysisContext context, int maxCacheSize)
      : super(context, maxCacheSize, DefaultRetentionPolicy.POLICY);

  @override
  bool contains(AnalysisTarget target) {
    Source source = target.source;
    return source != null && source.isInSystemLibrary;
  }
}

/**
 * A cache partition that contains all targets not contained in other partitions.
 */
class UniversalCachePartition extends CachePartition {
  /**
   * Initialize a newly created cache partition, belonging to the given
   * [context]. The partition will maintain at most [maxCacheSize] AST
   * structures in the cache, using the [retentionPolicy] to determine which
   * AST structures to flush.
   */
  UniversalCachePartition(InternalAnalysisContext context, int maxCacheSize,
      CacheRetentionPolicy retentionPolicy)
      : super(context, maxCacheSize, retentionPolicy);

  @override
  bool contains(AnalysisTarget target) => true;
}
