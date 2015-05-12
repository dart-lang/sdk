// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index;

import 'dart:async';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A filter for [Element] names.
 */
typedef bool ElementNameFilter(String name);

/**
 * The interface [Index] defines the behavior of objects that maintain an index
 * storing relations between [Element]s.
 *
 * Any modification operations are executed before any read operation.
 * There is no guarantee about the order in which the [Future]s for read
 * operations will complete.
 */
abstract class Index {
  /**
   * Answers index statistics.
   */
  String get statistics;

  /**
   * Removes from the index all the information.
   */
  void clear();

  /**
   * Asynchronously returns a list containing all of the locations of the
   * elements that have the given [relationship] with the given [element].
   *
   * For example, if the element represents a function and the relationship is
   * the `is-invoked-by` relationship, then the locations will be all of the
   * places where the function is invoked.
   *
   * [element] - the element that has the relationship with the locations to be
   * returned.
   *
   * [relationship] - the relationship between the given element and the
   * locations to be returned.
   */
  Future<List<LocationImpl>> getRelationships(
      Element element, RelationshipImpl relationship);

  /**
   * Returns top-level [Element]s whose names satisfy to [nameFilter].
   */
  List<Element> getTopLevelDeclarations(ElementNameFilter nameFilter);

  /**
   * Processes the given [HtmlUnit] in order to record the relationships.
   *
   * [context] - the [AnalysisContext] in which [HtmlUnit] was resolved.
   * [unit] - the [HtmlUnit] being indexed.
   */
  void indexHtmlUnit(AnalysisContext context, HtmlUnit unit);

  /**
   * Processes the given [CompilationUnit] in order to record the relationships.
   *
   * [context] - the [AnalysisContext] in which [CompilationUnit] was resolved.
   * [unit] - the [CompilationUnit] being indexed.
   */
  void indexUnit(AnalysisContext context, CompilationUnit unit);

  /**
   * Removes from the index all of the information associated with [context].
   *
   * This method should be invoked when [context] is disposed.
   */
  void removeContext(AnalysisContext context);

  /**
   * Removes from the index all of the information associated with elements or
   * locations in [source]. This includes relationships between an element in
   * [source] and any other locations, relationships between any other elements
   * and a location within [source].
   *
   * This method should be invoked when [source] is no longer part of the code
   * base.
   *
   * [context] - the [AnalysisContext] in which [source] being removed
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

  /**
   * Starts the index.
   * Should be called before any other method.
   */
  void run();

  /**
   * Stops the index.
   * After calling this method operations may not be executed.
   */
  void stop();
}

/**
 * Constants used when populating and accessing the index.
 */
class IndexConstants {
  /**
   * Left: the Universe or a Library.
   *   Defines an Element.
   * Right: an Element declaration.
   */
  static final RelationshipImpl DEFINES =
      RelationshipImpl.getRelationship("defines");

  /**
   * Left: class.
   *   Is extended by.
   * Right: other class declaration.
   */
  static final RelationshipImpl IS_EXTENDED_BY =
      RelationshipImpl.getRelationship("is-extended-by");

  /**
   * Left: class.
   *   Is implemented by.
   * Right: other class declaration.
   */
  static final RelationshipImpl IS_IMPLEMENTED_BY =
      RelationshipImpl.getRelationship("is-implemented-by");

  /**
   * Left: class.
   *   Is mixed into.
   * Right: other class declaration.
   */
  static final RelationshipImpl IS_MIXED_IN_BY =
      RelationshipImpl.getRelationship("is-mixed-in-by");

  /**
   * Left: local variable, parameter.
   *   Is read at.
   * Right: location.
   */
  static final RelationshipImpl IS_READ_BY =
      RelationshipImpl.getRelationship("is-read-by");

  /**
   * Left: local variable, parameter.
   *   Is both read and written at.
   * Right: location.
   */
  static final RelationshipImpl IS_READ_WRITTEN_BY =
      RelationshipImpl.getRelationship("is-read-written-by");

  /**
   * Left: local variable, parameter.
   *   Is written at.
   * Right: location.
   */
  static final RelationshipImpl IS_WRITTEN_BY =
      RelationshipImpl.getRelationship("is-written-by");

  /**
   * Left: function, method, variable, getter.
   *   Is invoked at.
   * Right: location.
   */
  static final RelationshipImpl IS_INVOKED_BY =
      RelationshipImpl.getRelationship("is-invoked-by");

  /**
   * Left: function, function type, class, field, method.
   *   Is referenced (and not invoked, read/written) at.
   * Right: location.
   */
  static final RelationshipImpl IS_REFERENCED_BY =
      RelationshipImpl.getRelationship("is-referenced-by");

  /**
   * Left: name element.
   *   Is defined by.
   * Right: concrete element declaration.
   */
  static final RelationshipImpl NAME_IS_DEFINED_BY =
      RelationshipImpl.getRelationship("name-is-defined-by");

  IndexConstants._();
}

/**
 * Instances of the class [LocationImpl] represent a location related to an
 * element.
 *
 * The location is expressed as an offset and length, but the offset is relative
 * to the resource containing the element rather than the start of the element
 * within that resource.
 */
class LocationImpl {
  static const int _FLAG_QUALIFIED = 1 << 0;
  static const int _FLAG_RESOLVED = 1 << 1;

  /**
   * An empty array of locations.
   */
  static const List<LocationImpl> EMPTY_LIST = const <LocationImpl>[];

  /**
   * The element containing this location.
   */
  final Element element;

  /**
   * The offset of this location within the resource containing the element.
   */
  final int offset;

  /**
   * The length of this location.
   */
  final int length;

  /**
   * The flags of this location.
   */
  int _flags;

  /**
   * Initializes a newly created location to be relative to the given element at
   * the given [offset] with the given [length].
   *
   * [element] - the [Element] containing this location.
   * [offset] - the offset within the resource containing [element].
   * [length] - the length of this location
   */
  LocationImpl(this.element, this.offset, this.length,
      {bool isQualified: false, bool isResolved: true}) {
    if (element == null) {
      throw new ArgumentError("element location cannot be null");
    }
    _flags = 0;
    if (isQualified) {
      _flags |= _FLAG_QUALIFIED;
    }
    if (isResolved) {
      _flags |= _FLAG_RESOLVED;
    }
  }

  /**
   * Returns `true` if this location is a qualified reference.
   */
  bool get isQualified => (_flags & _FLAG_QUALIFIED) != 0;

  /**
   * Returns `true` if this location is a resolved reference.
   */
  bool get isResolved => (_flags & _FLAG_RESOLVED) != 0;

  @override
  String toString() {
    String flagsStr = '';
    if (isQualified) {
      flagsStr += ' qualified';
    }
    if (isResolved) {
      flagsStr += ' resolved';
    }
    return '[${offset} - ${(offset + length)}) $flagsStr in ${element}';
  }
}

/**
 * A [LocationImpl] with attached data.
 */
class LocationWithData<D> extends LocationImpl {
  final D data;

  LocationWithData(LocationImpl location, this.data)
      : super(location.element, location.offset, location.length);
}

/**
 * An [Element] which is used to index references to the name without specifying
 * a concrete kind of this name - field, method or something else.
 */
class NameElement extends ElementImpl {
  NameElement(String name) : super(name, -1);

  @override
  ElementKind get kind => ElementKind.NAME;

  @override
  accept(ElementVisitor visitor) => null;
}

/**
 * Relationship between an element and a location. Relationships are identified
 * by a globally unique identifier.
 */
class RelationshipImpl {
  /**
   * A table mapping relationship identifiers to relationships.
   */
  static Map<String, RelationshipImpl> _RELATIONSHIP_MAP = {};

  /**
   * The next artificial hash code.
   */
  static int _NEXT_HASH_CODE = 0;

  /**
   * The artifitial hash code for this object.
   */
  final int _hashCode = _NEXT_HASH_CODE++;

  /**
   * The unique identifier for this relationship.
   */
  final String identifier;

  /**
   * Initialize a newly created relationship with the given unique identifier.
   */
  RelationshipImpl(this.identifier);

  @override
  int get hashCode => _hashCode;

  @override
  String toString() => identifier;

  /**
   * Returns the relationship with the given unique [identifier].
   */
  static RelationshipImpl getRelationship(String identifier) {
    RelationshipImpl relationship = _RELATIONSHIP_MAP[identifier];
    if (relationship == null) {
      relationship = new RelationshipImpl(identifier);
      _RELATIONSHIP_MAP[identifier] = relationship;
    }
    return relationship;
  }
}
