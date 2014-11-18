// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.store.codec;

import 'dart:collection';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/store/collection.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A helper that encodes/decodes [AnalysisContext]s from/to integers.
 */
class ContextCodec {
  /**
   * A table mapping contexts to their unique indices.
   */
  Map<AnalysisContext, int> _contextToIndex =
      new HashMap<AnalysisContext, int>();

  /**
   * A table mapping indices to the corresponding contexts.
   */
  Map<int, AnalysisContext> _indexToContext =
      new HashMap<int, AnalysisContext>();

  /**
   * The next id to assign.
   */
  int _nextId = 0;

  /**
   * Returns the [AnalysisContext] that corresponds to the given index.
   */
  AnalysisContext decode(int index) => _indexToContext[index];

  /**
   * Returns an unique index for the given [AnalysisContext].
   */
  int encode(AnalysisContext context) {
    int index = _contextToIndex[context];
    if (index == null) {
      index = _nextId++;
      _contextToIndex[context] = index;
      _indexToContext[index] = context;
    }
    return index;
  }

  /**
   * Removes the given [context].
   */
  void remove(AnalysisContext context) {
    int id = _contextToIndex.remove(context);
    if (id != null) {
      _indexToContext.remove(id);
    }
  }
}


/**
 * A helper that encodes/decodes [Element]s to/from integers.
 */
class ElementCodec {
  static const KIND_DART = 0;
  static const KIND_NAME = 1;
  static const KIND_UNKNOWN = 2;

  final StringCodec _stringCodec;
  final ElementKindCodec _kindCodec = new ElementKindCodec();

  /**
   * A table mapping element encodings to a single integer.
   */
  final IntArrayToIntMap _pathToIndex = new IntArrayToIntMap();

  /**
   * A list that works as a mapping of integers to element encodings.
   */
  final List<List<int>> _indexToPath = <List<int>>[];

  ElementCodec(this._stringCodec);

  /**
   * Returns an [Element] that corresponds to the given location.
   *
   * @param context the [AnalysisContext] to find [Element] in
   * @param index an integer corresponding to the [Element]
   * @return the [Element] or `null`
   */
  Element decode(AnalysisContext context, int index) {
    List<int> path = _indexToPath[index];
    int encodingKind = path[0];
    // DART
    if (encodingKind == KIND_DART) {
      String librarySourceEncoding = _stringCodec.decode(path[1]);
      String unitSourceEncoding = _stringCodec.decode(path[2]);
      int nameOffset = path[3];
      ElementKind kind = _kindCodec.decode(path[4]);
      ElementLocation location = new DartElementLocation(
          librarySourceEncoding,
          unitSourceEncoding,
          nameOffset,
          kind);
      return context.getElement(location);
    }
    // NAME - never used as a location, so we are never asked to decode it
    // TODO(scheglov) support for KIND_HTML ?
    return null;
  }

  /**
   * Returns a unique integer that corresponds to the given [Element].
   *
   * If [forKey] is `true` then [element] is a part of a key, so it should use
   * file paths instead of [Element] location URIs.
   */
  int encode(Element element, bool forKey) {
    List<int> path = _getLocationPath(element, forKey);
    int index = _pathToIndex[path];
    if (index == null) {
      index = _indexToPath.length;
      _pathToIndex[path] = index;
      _indexToPath.add(path);
    }
    return index;
  }

  /**
   * Returns an integer that corresponds to an approximated location of [element].
   */
  int encodeHash(Element element) {
    List<int> path = _getLocationPathLimited(element);
    int index = _pathToIndex[path];
    if (index == null) {
      index = _indexToPath.length;
      _pathToIndex[path] = index;
      _indexToPath.add(path);
    }
    return index;
  }

  /**
   * If [usePath] is `true` then [Source] path should be used instead of URI.
   */
  List<int> _getLocationPath(Element element, bool usePath) {
    LibraryElement library = element.library;
    // DynamicElement, NameElement
    if (library == null) {
      int nameId = _stringCodec.encode(element.name);
      return <int>[KIND_NAME, nameId];
    }
    // normal Element
    ElementLocation location = element.location;
    if (location is DartElementLocation) {
      String librarySourceEncoding;
      String unitSourceEncoding;
      if (usePath) {
        unitSourceEncoding = library.source.fullName;
        unitSourceEncoding = element.source.fullName;
      } else {
        librarySourceEncoding = location.librarySourceEncoding;
        unitSourceEncoding = location.unitSourceEncoding;
      }
      int libraryId = _stringCodec.encode(librarySourceEncoding);
      int unitId = _stringCodec.encode(unitSourceEncoding);
      // done
      int nameOffset = location.nameOffset;
      int kindId = _kindCodec.encode(location.kind);
      return <int>[KIND_DART, libraryId, unitId, nameOffset, kindId];
    }
    // unknown
    return <int>[KIND_UNKNOWN];
  }

  /**
   * Returns an approximation of the [element]'s location.
   */
  List<int> _getLocationPathLimited(Element element) {
    String firstComponent;
    {
      LibraryElement libraryElement = element.library;
      if (libraryElement != null) {
        firstComponent = libraryElement.source.fullName;
      } else {
        firstComponent = 'null';
      }
    }
    String lastComponent = element.displayName;
    int firstId = _stringCodec.encode(firstComponent);
    int lastId = _stringCodec.encode(lastComponent);
    return <int>[firstId, lastId];
  }
}


/**
 * A helper that encodes/decodes [ElementKind]s to/from integers.
 */
class ElementKindCodec {
  ElementKind decode(int id) {
    for (ElementKind kind in ElementKind.values) {
      if (kind.ordinal == id) {
        return kind;
      }
    }
    return null;
  }

  int encode(ElementKind kind) {
    return kind.ordinal;
  }
}


/**
 * A helper that encodes/decodes [Relationship]s to/from integers.
 */
class RelationshipCodec {
  final StringCodec _stringCodec;

  RelationshipCodec(this._stringCodec);

  Relationship decode(int idIndex) {
    String id = _stringCodec.decode(idIndex);
    return Relationship.getRelationship(id);
  }

  int encode(Relationship relationship) {
    String id = relationship.identifier;
    return _stringCodec.encode(id);
  }
}


/**
 * A helper that encodes/decodes [String]s from/to integers.
 */
class StringCodec {
  /**
   * A table mapping names to their unique indices.
   */
  final Map<String, int> nameToIndex = new HashMap<String, int>();

  /**
   * A table mapping indices to the corresponding strings.
   */
  final List<String> _indexToName = <String>[];

  /**
   * Returns the [String] that corresponds to the given index.
   */
  String decode(int index) => _indexToName[index];

  /**
   * Returns an unique index for the given [String].
   */
  int encode(String name) {
    int index = nameToIndex[name];
    if (index == null) {
      index = _indexToName.length;
      nameToIndex[name] = index;
      _indexToName.add(name);
    }
    return index;
  }
}
