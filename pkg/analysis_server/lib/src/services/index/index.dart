// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index;

import 'dart:async';

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A filter for [Element] names.
 */
typedef bool ElementNameFilter(String name);

/**
 * The interface [Index] defines the behavior of objects that maintain an index
 * storing relations between indexable objects.
 *
 * Any modification operations are executed before any read operation.
 * There is no guarantee about the order in which the [Future]s for read
 * operations will complete.
 */
abstract class Index implements IndexStore {
  /**
   * Set the index contributors used by this index to the given list of
   * [contributors].
   */
  void set contributors(List<IndexContributor> contributors);

  /**
   * Answers index statistics.
   */
  String get statistics;

  /**
   * Returns top-level [Element]s whose names satisfy to [nameFilter].
   */
  List<Element> getTopLevelDeclarations(ElementNameFilter nameFilter);

  /**
   * Processes the given [object] in order to record the relationships.
   *
   * [context] - the [AnalysisContext] in which the [object] being indexed.
   * [object] - the object being indexed.
   */
  void index(AnalysisContext context, Object object);

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
 * An [Element] which is used to index references to the name without specifying
 * a concrete kind of this name - field, method or something else.
 */
class IndexableName implements IndexableObject {
  /**
   * The name to be indexed.
   */
  final String name;

  /**
   * Initialize a newly created indexable name to represent the given [name].
   */
  IndexableName(this.name);

  @override
  String get filePath => null;

  @override
  IndexableNameKind get kind => IndexableNameKind.INSTANCE;

  @override
  int get offset {
    return -1;
  }

  @override
  bool operator ==(Object object) =>
      object is IndexableName && object.name == name;

  @override
  String toString() => name;
}

/**
 * The kind of an indexable name.
 */
class IndexableNameKind implements IndexableObjectKind<IndexableName> {
  /**
   * The unique instance of this class.
   */
  static final IndexableNameKind INSTANCE =
      new IndexableNameKind._(IndexableObjectKind.nextIndex);

  /**
   * The index uniquely identifying this kind.
   */
  final int index;

  /**
   * Initialize a newly created kind to have the given [index].
   */
  IndexableNameKind._(this.index) {
    IndexableObjectKind.register(this);
  }

  @override
  IndexableName decode(AnalysisContext context, String filePath, int offset) {
    throw new UnsupportedError(
        'Indexable names cannot be decoded through their kind');
  }

  @override
  int encodeHash(StringToInt stringToInt, IndexableName indexable) {
    String name = indexable.name;
    return stringToInt(name);
  }
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
   *   Has ancestor (extended or implemented, directly or indirectly).
   * Right: other class declaration.
   */
  static final RelationshipImpl HAS_ANCESTOR =
      RelationshipImpl.getRelationship("has-ancestor");

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
class LocationImpl implements Location {
  static const int _FLAG_QUALIFIED = 1 << 0;
  static const int _FLAG_RESOLVED = 1 << 1;

  /**
   * An empty array of locations.
   */
  static const List<LocationImpl> EMPTY_LIST = const <LocationImpl>[];

  /**
   * The indexable object containing this location.
   */
  final IndexableObject indexable;

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
   * Initializes a newly created location to be relative to the given
   * [indexable] object at the given [offset] with the given [length].
   */
  LocationImpl(this.indexable, this.offset, this.length,
      {bool isQualified: false, bool isResolved: true}) {
    if (indexable == null) {
      throw new ArgumentError("indexable object cannot be null");
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
   * The element containing this location.
   */
  @deprecated
  Element get element {
    if (indexable is IndexableElement) {
      return (indexable as IndexableElement).element;
    }
    return null;
  }

  @override
  bool get isQualified => (_flags & _FLAG_QUALIFIED) != 0;

  @override
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
    return '[$offset - ${offset + length}) $flagsStr in $indexable';
  }
}

/**
 * A [LocationImpl] with attached data.
 */
class LocationWithData<D> extends LocationImpl {
  final D data;

  LocationWithData(LocationImpl location, this.data)
      : super(location.indexable, location.offset, location.length);
}

/**
 * Relationship between an element and a location. Relationships are identified
 * by a globally unique identifier.
 */
class RelationshipImpl implements Relationship {
  /**
   * A table mapping relationship identifiers to relationships.
   */
  static Map<String, RelationshipImpl> _RELATIONSHIP_MAP = {};

  /**
   * The next artificial hash code.
   */
  static int _NEXT_HASH_CODE = 0;

  /**
   * The artificial hash code for this object.
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
