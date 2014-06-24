// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library index;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/index/store/codec.dart';
import 'package:analysis_server/src/index/store/separate_file_manager.dart';
import 'package:analysis_server/src/index/store/split_store.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/index.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * An implementation of [Index] with [SplitIndexStore].
 */
class LocalSplitIndex extends Index {
  SplitIndexStore _store;

  LocalSplitIndex(Directory directory) {
    var fileManager = new SeparateFileManager(directory);
    var stringCodec = new StringCodec();
    var nodeManager = new FileNodeManager(fileManager,
        AnalysisEngine.instance.logger, stringCodec, new ContextCodec(),
        new ElementCodec(stringCodec), new RelationshipCodec(stringCodec));
    _store = new SplitIndexStore(nodeManager);
  }

  @override
  String get statistics => _store.statistics;

  @override
  void clear() {
    _store.clear();
  }

  @override
  void getRelationships(Element element, Relationship relationship,
      RelationshipCallback callback) {
    // TODO(scheglov) update Index API to use asynchronous interface
    callback.hasRelationships(element, relationship, Location.EMPTY_ARRAY);
  }

  /**
   * Returns a `Future<List<Location>>` that completes with the list of
   * [Location]s of the given [relationship] with the given [element].
   *
   * For example, if the [element] represents a function and the [relationship]
   * is the `is-invoked-by` relationship, then the locations will be all of the
   * places where the function is invoked.
   */
  Future<List<Location>> getRelationshipsAsync(Element element,
      Relationship relationship) {
    return _store.getRelationshipsAsync(element, relationship);
  }

  @override
  void indexHtmlUnit(AnalysisContext context, HtmlUnit unit) {
    if (unit == null) {
      return;
    }
    if (unit.element == null) {
      return;
    }
    new IndexHtmlUnitOperation(_store, context, unit).performOperation();
  }

  @override
  void indexUnit(AnalysisContext context, CompilationUnit unit) {
    if (unit == null) {
      return;
    }
    if (unit.element == null) {
      return;
    }
    new IndexUnitOperation(_store, context, unit).performOperation();
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
    // NO-OP if in the same isolate
  }

  @override
  void stop() {
    // NO-OP if in the same isolate
  }
}
