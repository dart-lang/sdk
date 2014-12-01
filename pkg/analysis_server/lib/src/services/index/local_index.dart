// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.local_index;

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/index_contributor.dart' as
    contributors;
import 'package:analysis_server/src/services/index/store/split_store.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A local implementation of [Index].
 */
class LocalIndex extends Index {
  SplitIndexStore _store;

  LocalIndex(NodeManager nodeManager) {
    _store = new SplitIndexStore(nodeManager);
  }

  @override
  String get statistics => _store.statistics;

  @override
  void clear() {
    _store.clear();
  }

  /**
   * Returns a `Future<List<Location>>` that completes with the list of
   * [Location]s of the given [relationship] with the given [element].
   *
   * For example, if the [element] represents a function and the [relationship]
   * is the `is-invoked-by` relationship, then the locations will be all of the
   * places where the function is invoked.
   */
  @override
  Future<List<Location>> getRelationships(Element element,
      Relationship relationship) {
    return _store.getRelationships(element, relationship);
  }

  @override
  void indexHtmlUnit(AnalysisContext context, HtmlUnit unit) {
    contributors.indexHtmlUnit(_store, context, unit);
  }

  @override
  void indexUnit(AnalysisContext context, CompilationUnit unit) {
    contributors.indexDartUnit(_store, context, unit);
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
