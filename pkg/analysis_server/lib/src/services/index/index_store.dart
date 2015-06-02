// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index_store;

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/src/generated/element.dart';
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
   * Notifies the index store that we are going to index an unit with the given
   * [unitElement].
   *
   * If the unit is a part of a library, then all its locations are removed.
   *
   * If it is a defining compilation unit of a library, then index store also
   * checks if some previously indexed parts of the library are not parts of the
   * library anymore, and clears their information.
   *
   * [context] - the [AnalysisContext] in which unit being indexed.
   * [unitElement] - the element of the unit being indexed.
   *
   * Returns `true` if the given [unitElement] may be indexed, or `false` if
   * belongs to a disposed [AnalysisContext], is not resolved completely, etc.
   */
  bool aboutToIndexDart(
      AnalysisContext context, CompilationUnitElement unitElement);

  /**
   * Notifies the index store that we are going to index an unit with the given
   * [htmlElement].
   *
   * [context] - the [AnalysisContext] in which unit being indexed.
   * [htmlElement] - the [HtmlElement] being indexed.
   *
   * Returns `true` if the given [htmlElement] may be indexed, or `false` if
   * belongs to a disposed [AnalysisContext], is not resolved completely, etc.
   */
  bool aboutToIndexHtml(AnalysisContext context, HtmlElement htmlElement);

  /**
   * Notifies the index store that there was an error during the current Dart
   * indexing, and all the information recorded after the last
   * [aboutToIndexDart] invocation must be discarded.
   */
  void cancelIndexDart();

  /**
   * Notifies the index store that the current Dart or HTML unit indexing is
   * done.
   *
   * If this method is not invoked after corresponding "aboutToIndex*"
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
