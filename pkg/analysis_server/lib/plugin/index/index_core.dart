// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.index.index_core;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Return the integer value that corresponds to the given [string]. The value of
 * [string] may be `null`.
 *
 * Clients are not expected to implement this signature. A function of this type
 * is provided by the framework to clients in order to implement the method
 * [IndexableObjectKind.encodeHash].
 */
typedef int StringToInt(String string);

/**
 * An object that can have a [Relationship] with various [Location]s in a code
 * base. The object is abstractly represented by a [kind] and an [offset] within
 * a file with the [filePath].
 *
 * Clients must ensure that two distinct objects in the same source cannot have
 * the same kind and offset. Failure to do so will make it impossible for
 * clients to identify the model element corresponding to the indexable object.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class IndexableObject {
  /**
   * Return the absolute path of the file containing the indexable object.
   */
  String get filePath;

  /**
   * Return the kind of this object.
   */
  IndexableObjectKind get kind;

  /**
   * Return the offset of the indexable object within its file.
   */
  int get offset;
}

/**
 * The kind associated with an [IndexableObject].
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class IndexableObjectKind<T extends IndexableObject> {
  /**
   * The next available index for a newly created kind of indexable object.
   */
  static int _nextIndex = 0;

  /**
   * A table mapping indexes to object kinds.
   */
  static Map<int, IndexableObjectKind> _registry =
      new HashMap<int, IndexableObjectKind>();

  /**
   * Return the next available index for a newly created kind of indexable
   * object.
   */
  static int get nextIndex => _nextIndex++;

  /**
   * Return the unique index for this kind of indexable object. Implementations
   * should invoke [nextIndex] to allocate an index that cannot be used by any
   * other object kind.
   */
  int get index;

  /**
   * Return the indexable object of this kind that exists in the given
   * [context], in the source with the given [filePath], and at the given
   * [offset].
   */
  T decode(AnalysisContext context, String filePath, int offset);

  /**
   * Returns the hash value that corresponds to the given [indexable].
   *
   * This hash is used to remember buckets with relations of the given
   * [indexable]. Usually the name of the indexable object is encoded
   * using [stringToInt] and mixed with other information to produce the final
   * result.
   *
   * Clients must ensure that the same value is returned for the same object.
   *
   * Returned values must have good selectivity, e.g. if it is possible that
   * there are many different objects with the same name, then additional
   * information should be mixed in, for example the hash of the source that
   * declares the given [indexable].
   *
   * Clients don't have to use name to compute this result, so if an indexable
   * object does not have a name, some other value may be returned, but it still
   * must be always the same for the same object and have good selectivity.
   */
  int encodeHash(StringToInt stringToInt, T indexable);

  /**
   * Return the object kind with the given [index].
   */
  static IndexableObjectKind getKind(int index) {
    return _registry[index];
  }

  /**
   * Register the given object [kind] so that it can be found by it's unique
   * index. The index of the [kind] must not be changed after it is passed to
   * this method.
   */
  static void register(IndexableObjectKind kind) {
    int index = kind.index;
    if (_registry.containsKey(index)) {
      throw new ArgumentError('duplicate index for kind: $index');
    }
    _registry[index] = kind;
  }
}

/**
 * An object used to add relationships to the index.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class IndexContributor {
  /**
   * Contribute relationships existing in the given [object] to the given
   * index [store] in the given [context].
   */
  void contributeTo(IndexStore store, AnalysisContext context, Object object);
}

/**
 * An object that stores information about the relationships between locations
 * in a code base.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class IndexStore {
  /**
   * Remove all of the information from the index.
   */
  void clear();

  /**
   * Return a future that completes with the locations that have the given
   * [relationship] with the given [indexable] object.
   *
   * For example, if the [indexable] object represents a function and the
   * relationship is the `is-invoked-by` relationship, then the returned
   * locations will be all of the places where the function is invoked.
   */
  Future<List<Location>> getRelationships(
      IndexableObject indexable, Relationship relationship);

  /**
   * Record that the given [indexable] object and [location] have the given
   * [relationship].
   *
   * For example, if the [relationship] is the `is-invoked-by` relationship,
   * then the [indexable] object would be the function being invoked and
   * [location] would be the point at which it is invoked. Each indexable object
   * can have the same relationship with multiple locations. In other words, if
   * the following code were executed
   *
   *     recordRelationship(indexable, isReferencedBy, location1);
   *     recordRelationship(indexable, isReferencedBy, location2);
   *
   * (where `location1 != location2`) then both relationships would be
   * maintained in the index and the result of executing
   *
   *     getRelationship(indexable, isReferencedBy);
   *
   * would be a list containing both `location1` and `location2`.
   */
  void recordRelationship(
      IndexableObject indexable, Relationship relationship, Location location);

  /**
   * Remove from the index all of the information associated with the given
   * [context].
   *
   * This method should be invoked when the [context] is disposed.
   */
  void removeContext(AnalysisContext context);

  /**
   * Remove from the index all of the information associated with indexable
   * objects or locations in the given [source]. This includes relationships
   * between an indexable object in [source] and any other locations, as well as
   * relationships between any other indexable objects and locations within
   * the [source].
   *
   * This method should be invoked when [source] is no longer part of the given
   * [context].
   */
  void removeSource(AnalysisContext context, Source source);

  /**
   * Remove from the index all of the information associated with indexable
   * objects or locations in the given sources. This includes relationships
   * between an indexable object in the given sources and any other locations,
   * as well as relationships between any other indexable objects and a location
   * within the given sources.
   *
   * This method should be invoked when the sources described by the given
   * [container] are no longer part of the given [context].
   */
  void removeSources(AnalysisContext context, SourceContainer container);
}

/**
 * Instances of the class [Location] represent a location related to an
 * indexable object.
 *
 * The location is expressed as an offset and length, but the offset is relative
 * to the source containing the indexable object rather than the start of the
 * indexable object within that source.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Location {
  /**
   * An empty list of locations.
   */
  static const List<Location> EMPTY_LIST = const <Location>[];

  /**
   * Return the indexable object containing this location.
   */
  IndexableObject get indexable;

  /**
   * Return `true` if this location is a qualified reference.
   */
  bool get isQualified;

  /**
   * Return `true` if this location is a resolved reference.
   */
  bool get isResolved;

  /**
   * Return the length of this location.
   */
  int get length;

  /**
   * Return the offset of this location within the source containing the
   * indexable object.
   */
  int get offset;
}

/**
 * A relationship between an indexable object and a location. Relationships are
 * identified by a globally unique identifier.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Relationship {
  /**
   * Return a relationship that has the given [identifier]. If the relationship
   * has already been created, then it will be returned, otherwise a new
   * relationship will be created
   */
  factory Relationship(String identifier) =>
      RelationshipImpl.getRelationship(identifier);
}
