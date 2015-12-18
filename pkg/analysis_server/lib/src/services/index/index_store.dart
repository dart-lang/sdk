// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index_store;

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A container with information computed by an index - relations between
 * elements.
 */
abstract class InternalIndexStore extends IndexStore {
  /**
   * Answers index statistics.
   */
  String get statistics;

  /**
   * Notifies the index store that we are going to index the given [object].
   *
   * [context] - the [AnalysisContext] in which the [object] being indexed.
   * [object] - the object being indexed.
   *
   * Returns `true` if the given [object] may be indexed, or `false` if
   * belongs to a disposed [AnalysisContext], is not resolved completely, etc.
   */
  bool aboutToIndex(AnalysisContext context, Object object);

  /**
   * Notifies the index store that there was an error during the current
   * indexing, and all the information recorded after the last
   * [aboutToIndex] invocation must be discarded.
   */
  void cancelIndex();

  /**
   * Notifies the index store that the current object indexing is done.
   *
   * If this method is not invoked after corresponding [aboutToIndex]
   * invocation, all recorded information may be lost.
   */
  void doneIndex();

  /**
   * Returns top-level [Element]s whose names satisfy to [nameFilter].
   */
  List<Element> getTopLevelDeclarations(ElementNameFilter nameFilter);

  /**
   * Records the declaration of the given top-level [element].
   */
  void recordTopLevelDeclaration(Element element);
}
