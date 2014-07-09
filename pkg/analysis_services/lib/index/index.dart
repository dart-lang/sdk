// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.index;

import 'dart:async';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/html.dart';
import 'package:analyzer/src/generated/source.dart';


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
  Future<List<Location>> getRelationships(Element element,
      Relationship relationship);

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
   * Reference to some closing tag of an XML element.
   */
  static final Relationship ANGULAR_CLOSING_TAG_REFERENCE =
      Relationship.getRelationship("angular-closing-tag-reference");

  /**
   * Reference to some [AngularElement].
   */
  static final Relationship ANGULAR_REFERENCE = Relationship.getRelationship(
      "angular-reference");

  /**
   * The relationship used to indicate that a container (the left-operand)
   * contains the definition of a class at a specific location (the right
   * operand).
   */
  static final Relationship DEFINES_CLASS = Relationship.getRelationship(
      "defines-class");

  /**
   * The relationship used to indicate that a container (the left-operand)
   * contains the definition of a class type alias at a specific location (the
   * right operand).
   */
  static final Relationship DEFINES_CLASS_ALIAS = Relationship.getRelationship(
      "defines-class-alias");

  /**
   * The relationship used to indicate that a container (the left-operand)
   * contains the definition of a function at a specific location (the right
   * operand).
   */
  static final Relationship DEFINES_FUNCTION = Relationship.getRelationship(
      "defines-function");

  /**
   * The relationship used to indicate that a container (the left-operand)
   * contains the definition of a function type at a specific location (the
   * right operand).
   */
  static final Relationship DEFINES_FUNCTION_TYPE =
      Relationship.getRelationship("defines-function-type");

  /**
   * The relationship used to indicate that a container (the left-operand)
   * contains the definition of a method at a specific location (the right
   * operand).
   */
  static final Relationship DEFINES_VARIABLE = Relationship.getRelationship(
      "defines-variable");

  /**
   * The relationship used to indicate that a name (the left-operand) is defined
   * at a specific location (the right operand).
   */
  static final Relationship IS_DEFINED_BY = Relationship.getRelationship(
      "is-defined-by");

  /**
   * The relationship used to indicate that a type (the left-operand) is
   * extended by a type at a specific location (the right operand).
   */
  static final Relationship IS_EXTENDED_BY = Relationship.getRelationship(
      "is-extended-by");

  /**
   * The relationship used to indicate that a type (the left-operand) is
   * implemented by a type at a specific location (the right operand).
   */
  static final Relationship IS_IMPLEMENTED_BY = Relationship.getRelationship(
      "is-implemented-by");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * invoked at a specific location (the right operand). This is used for
   * functions.
   */
  static final Relationship IS_INVOKED_BY = Relationship.getRelationship(
      "is-invoked-by");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * invoked at a specific location (the right operand). This is used for
   * methods.
   */
  static final Relationship IS_INVOKED_BY_QUALIFIED =
      Relationship.getRelationship("is-invoked-by-qualified");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * invoked at a specific location (the right operand). This is used for
   * methods.
   */
  static final Relationship IS_INVOKED_BY_UNQUALIFIED =
      Relationship.getRelationship("is-invoked-by-unqualified");

  /**
   * The relationship used to indicate that a type (the left-operand) is mixed
   * into a type at a specific location (the right operand).
   */
  static final Relationship IS_MIXED_IN_BY = Relationship.getRelationship(
      "is-mixed-in-by");

  /**
   * The relationship used to indicate that a parameter or variable (the
   * left-operand) is read at a specific location (the right operand).
   */
  static final Relationship IS_READ_BY = Relationship.getRelationship(
      "is-read-by");

  /**
   * The relationship used to indicate that a parameter or variable (the
   * left-operand) is both read and modified at a specific location (the right
   * operand).
   */
  static final Relationship IS_READ_WRITTEN_BY = Relationship.getRelationship(
      "is-read-written-by");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * referenced at a specific location (the right operand). This is used for
   * everything except read/write operations for fields, parameters, and
   * variables. Those use either [IS_REFERENCED_BY_QUALIFIED],
   * [IS_REFERENCED_BY_UNQUALIFIED], [IS_READ_BY], [IS_WRITTEN_BY] or
   * [IS_READ_WRITTEN_BY], as appropriate.
   */
  static final Relationship IS_REFERENCED_BY = Relationship.getRelationship(
      "is-referenced-by");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * referenced at a specific location (the right operand). This is used for
   * field accessors and methods.
   */
  static final Relationship IS_REFERENCED_BY_QUALIFIED =
      Relationship.getRelationship("is-referenced-by-qualified");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is referenced at a specific location (the right operand). This is used for
   * qualified resolved references to methods and fields.
   */
  static final Relationship IS_REFERENCED_BY_QUALIFIED_RESOLVED =
      Relationship.getRelationship("is-referenced-by-qualified-resolved");

  /**
   * The relationship used to indicate that an [NameElement] (the left-operand)
   * is referenced at a specific location (the right operand). This is used for
   * qualified unresolved references to methods and fields.
   */
  static final Relationship IS_REFERENCED_BY_QUALIFIED_UNRESOLVED =
      Relationship.getRelationship("is-referenced-by-qualified-unresolved");

  /**
   * The relationship used to indicate that an element (the left-operand) is
   * referenced at a specific location (the right operand). This is used for
   * field accessors and methods.
   */
  static final Relationship IS_REFERENCED_BY_UNQUALIFIED =
      Relationship.getRelationship("is-referenced-by-unqualified");

  /**
   * The relationship used to indicate that a parameter or variable (the
   * left-operand) is modified (assigned to) at a specific location (the right
   * operand).
   */
  static final Relationship IS_WRITTEN_BY = Relationship.getRelationship(
      "is-written-by");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is invoked at a specific location (the right operand). This is used for
   * resolved invocations.
   */
  static final Relationship NAME_IS_INVOKED_BY_RESOLVED =
      Relationship.getRelationship("name-is-invoked-by-resolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is invoked at a specific location (the right operand). This is used for
   * unresolved invocations.
   */
  static final Relationship NAME_IS_INVOKED_BY_UNRESOLVED =
      Relationship.getRelationship("name-is-invoked-by-unresolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is read at a specific location (the right operand).
   */
  static final Relationship NAME_IS_READ_BY_RESOLVED =
      Relationship.getRelationship("name-is-read-by-resolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is read at a specific location (the right operand).
   */
  static final Relationship NAME_IS_READ_BY_UNRESOLVED =
      Relationship.getRelationship("name-is-read-by-unresolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is both read and written at a specific location (the right operand).
   */
  static final Relationship NAME_IS_READ_WRITTEN_BY_RESOLVED =
      Relationship.getRelationship("name-is-read-written-by-resolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is both read and written at a specific location (the right operand).
   */
  static final Relationship NAME_IS_READ_WRITTEN_BY_UNRESOLVED =
      Relationship.getRelationship("name-is-read-written-by-unresolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is written at a specific location (the right operand).
   */
  static final Relationship NAME_IS_WRITTEN_BY_RESOLVED =
      Relationship.getRelationship("name-is-written-by-resolved");

  /**
   * The relationship used to indicate that a [NameElement] (the left-operand)
   * is written at a specific location (the right operand).
   */
  static final Relationship NAME_IS_WRITTEN_BY_UNRESOLVED =
      Relationship.getRelationship("name-is-written-by-unresolved");

  /**
   * An element used to represent the universe.
   */
  static final Element UNIVERSE = UniverseElement.INSTANCE;

  IndexConstants._();
}


/**
 * Instances of the class [Location] represent a location related to an element.
 *
 * The location is expressed as an offset and length, but the offset is relative
 * to the resource containing the element rather than the start of the element
 * within that resource.
 */
class Location {
  /**
   * An empty array of locations.
   */
  static const List<Location> EMPTY_ARRAY = const <Location>[];

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
   * Initializes a newly create location to be relative to the given element at
   * the given [offset] with the given [length].
   *
   * [element] - the [Element] containing this location.
   * [offset] - the offset within the resource containing the [element].
   * [length] - the length of this location
   */
  Location(this.element, this.offset, this.length) {
    if (element == null) {
      throw new ArgumentError("element location cannot be null");
    }
  }

  @override
  String toString() => "[${offset} - ${(offset + length)}) in ${element}";
}


/**
 * A [Location] with attached data.
 */
class LocationWithData<D> extends Location {
  final D data;

  LocationWithData(Location location, this.data) : super(location.element,
      location.offset, location.length);
}


/**
 * An [Element] which is used to index references to the name without specifying
 * a concrete kind of this name - field, method or something else.
 */
class NameElement extends ElementImpl {
  NameElement(String name) : super("name:${name}", -1);

  @override
  ElementKind get kind => ElementKind.NAME;

  @override
  accept(ElementVisitor visitor) => null;
}


/**
 * Relationship between an element and a location. Relationships are identified
 * by a globally unique identifier.
 */
class Relationship {
  /**
   * A table mapping relationship identifiers to relationships.
   */
  static Map<String, Relationship> _RELATIONSHIP_MAP = {};

  /**
   * The unique identifier for this relationship.
   */
  final String identifier;

  /**
   * Initialize a newly created relationship with the given unique identifier.
   */
  Relationship(this.identifier);

  @override
  String toString() => identifier;

  /**
   * Returns the relationship with the given unique [identifier].
   */
  static Relationship getRelationship(String identifier) {
    Relationship relationship = _RELATIONSHIP_MAP[identifier];
    if (relationship == null) {
      relationship = new Relationship(identifier);
      _RELATIONSHIP_MAP[identifier] = relationship;
    }
    return relationship;
  }
}


/**
 * An element to use when we want to request "defines" relations without
 * specifying an exact library.
 */
class UniverseElement extends ElementImpl {
  static final UniverseElement INSTANCE = new UniverseElement._();

  UniverseElement._() : super("--universe--", -1);

  @override
  ElementKind get kind => ElementKind.UNIVERSE;

  @override
  accept(ElementVisitor visitor) => null;
}
