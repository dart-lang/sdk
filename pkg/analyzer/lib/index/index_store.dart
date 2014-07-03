// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.index_store;

import 'dart:async';

import 'package:analyzer/index/index.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A container with information computed by an index - relations between
 * elements.
 */
abstract class IndexStore {
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
  bool aboutToIndexDart(AnalysisContext context,
      CompilationUnitElement unitElement);

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
   * Removes all of the information.
   */
  void clear();

  /**
   * Notifies that index store that the current Dart or HTML unit indexing is
   * done.
   *
   * If this method is not invoked after corresponding "aboutToIndex*"
   * invocation, all recorded information may be lost.
   */
  void doneIndex();

  /**
   * Returns a [Future] that completes with locations of the elements that have
   * the given [relationship] with the given [element].
   *
   * For example, if the [element] represents a function and the relationship is
   * the `is-invoked-by` relationship, then the returned locations will be all
   * of the places where the function is invoked.
   *
   * [element] - the the [Element] that has the relationship with the locations
   *    to be returned.
   * [relationship] - the [Relationship] between the given element and the
   *    locations to be returned
   */
  Future<List<Location>> getRelationships(Element element,
      Relationship relationship);

  /**
   * Records that the given [element] and [location] have the given
   * [relationship].
   *
   * For example, if the [relationship] is the `is-invoked-by` relationship,
   * then [element] would be the function being invoked and [location] would be
   * the point at which it is referenced. Each element can have the same
   * relationship with multiple locations. In other words, if the following code
   * were executed
   *
   *     recordRelationship(element, isReferencedBy, location1);
   *     recordRelationship(element, isReferencedBy, location2);
   *
   * then both relationships would be maintained in the index and the result of executing
   *
   *     getRelationship(element, isReferencedBy);
   *
   * would be a list containing both `location1` and `location2`.
   *
   * [element] - the [Element] that is related to the location.
   * [relationship] - the [Relationship] between the element and the location.
   * [location] the [Location] where relationship happens.
   */
  void recordRelationship(Element element, Relationship relationship,
      Location location);

  /**
   * Removes from the index all of the information associated with [context].
   *
   * This method should be invoked when [context] is disposed.
   *
   * [context] - the [AnalysisContext] being removed.
   */
  void removeContext(AnalysisContext context);

  /**
   * Removes from the index all of the information associated with elements or
   * locations in [source]. This includes relationships between an element in
   * [source] and any other locations, relationships between any other elements
   * and locations within [source].
   *
   * This method should be invoked when [source] is no longer part of the code
   * base.
   *
   * [context] - the [AnalysisContext] in which [source] being removed.
   * [source] - the [Source] being removed
   */
  void removeSource(AnalysisContext context, Source source);

  /**
   * Removes from the index all of the information associated with elements or
   * locations in the given sources. This includes relationships between an
   * element in the given sources and any other locations, relationships between
   * any other elements and a location within the given sources.
   *
   * This method should be invoked when multiple sources are no longer part of
   * the code base.
   *
   * [context] - the [AnalysisContext] in which [Source]s being removed.
   * [container] - the [SourceContainer] holding the sources being removed.
   */
  void removeSources(AnalysisContext context, SourceContainer container);
}
