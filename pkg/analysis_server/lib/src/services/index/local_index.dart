// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.local_index;

import 'dart:async';

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/store/split_store.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A local implementation of [Index].
 */
class LocalIndex extends Index {
  /**
   * The index contributors used by this index.
   */
  List<IndexContributor> contributors = <IndexContributor>[];

  SplitIndexStore _store;

  LocalIndex(NodeManager nodeManager) {
    // TODO(scheglov) get IndexObjectManager(s) as a parameter
    _store = new SplitIndexStore(
        nodeManager, <IndexObjectManager>[new DartUnitIndexObjectManager()]);
  }

  @override
  String get statistics => _store.statistics;

  @override
  void clear() {
    _store.clear();
  }

  /**
   * Returns all relations with [Element]s with the given [name].
   */
  Future<Map<List<String>, List<InspectLocation>>> findElementsByName(
      String name) {
    return _store.inspect_getElementRelations(name);
  }

  /**
   * Returns a `Future<List<Location>>` that completes with the list of
   * [LocationImpl]s of the given [relationship] with the given [indexable].
   *
   * For example, if the [indexable] represents a function element and the
   * [relationship] is the `is-invoked-by` relationship, then the locations
   * will be all of the places where the function is invoked.
   */
  @override
  Future<List<LocationImpl>> getRelationships(
      IndexableObject indexable, RelationshipImpl relationship) {
    return _store.getRelationships(indexable, relationship);
  }

  @override
  List<Element> getTopLevelDeclarations(ElementNameFilter nameFilter) {
    return _store.getTopLevelDeclarations(nameFilter);
  }

  @override
  void index(AnalysisContext context, Object object) {
    // about to index
    bool mayIndex = _store.aboutToIndex(context, object);
    if (!mayIndex) {
      return;
    }
    // do index
    try {
      for (IndexContributor contributor in contributors) {
        contributor.contributeTo(_store, context, object);
      }
      _store.doneIndex();
    } catch (e) {
      _store.cancelIndex();
      rethrow;
    }
  }

  @override
  void recordRelationship(
      IndexableObject indexable, Relationship relationship, Location location) {
    _store.recordRelationship(indexable, relationship, location);
  }

  @override
  void removeContext(AnalysisContext context) {
    _store.removeContext(context);
  }

  @override
  void removeSource(AnalysisContext context, Source source) {
    _store.removeSource(context, source);
  }

  @override
  void removeSources(AnalysisContext context, SourceContainer container) {
    _store.removeSources(context, container);
  }

  @override
  void run() {
    // NO-OP for the local index
  }

  @override
  void stop() {
    // NO-OP for the local index
  }
}
