// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.store.codec;

import 'dart:collection';

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

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
 * A helper that encodes/decodes [IndexableObject]s to/from integers.
 */
class ElementCodec {
  // TODO(brianwilkerson) Rename this class now that if encodes indexable
  // objects rather than elements.
  final StringCodec _stringCodec;

  ElementCodec(this._stringCodec);

  /**
   * Returns an [IndexableObject] that corresponds to the given identifiers.
   */
  IndexableObject decode(
      AnalysisContext context, int fileId, int offset, int kindId) {
    String filePath = _stringCodec.decode(fileId);
    IndexableObjectKind kind = IndexableObjectKind.getKind(kindId);
    if (kind == null) {
      return null;
    } else if (kind is IndexableNameKind) {
      return new IndexableElement(new NameElement(_stringCodec.decode(offset)));
    }
    return kind.decode(context, filePath, offset);
  }

  /**
   * Returns the first component of the [element] id.
   * In the most cases it is an encoding of the [element]'s file path.
   * If the given [element] is not defined in a file, returns `-1`.
   */
  int encode1(IndexableObject indexable) {
    Source source = indexable.source;
    if (source == null) {
      return -1;
    }
    String filePath = source.fullName;
    return _stringCodec.encode(filePath);
  }

  /**
   * Returns the second component of the [element] id.
   * In the most cases it is the [element]'s name offset.
   */
  int encode2(IndexableObject indexable) {
    if (indexable is IndexableName) {
      String name = indexable.name;
      return _stringCodec.encode(name);
    }
    int offset = indexable.offset;
    if (offset < 0) {
      return _stringCodec.encode(indexable.name);
    }
    return offset;
  }

  /**
   * Returns the third component of the [element] id.
   * In the most cases it is the [element]'s kind.
   */
  int encode3(IndexableObject indexable) {
    return indexable.kind.index;
  }

  /**
   * Returns an integer that corresponds to the name of [element].
   */
  int encodeHash(IndexableObject indexable) {
    // TODO(brianwilkerson) Consider moving this to IndexableObjectKind so that
    // we don't have to break encapsulation.
    String elementName = indexable.name; // was: indexable.displayName;
    int elementNameId = _stringCodec.encode(elementName);
    if (indexable is IndexableElement) {
      LibraryElement libraryElement = indexable.element.library;
      if (libraryElement != null) {
        String libraryPath = libraryElement.source.fullName;
        int libraryPathId = _stringCodec.encode(libraryPath);
        return JenkinsSmiHash.combine(libraryPathId, elementNameId);
      }
    }
    return elementNameId;
  }
}

/**
 * A helper that encodes/decodes [Relationship]s to/from integers.
 */
class RelationshipCodec {
  final StringCodec _stringCodec;

  RelationshipCodec(this._stringCodec);

  RelationshipImpl decode(int idIndex) {
    String id = _stringCodec.decode(idIndex);
    return RelationshipImpl.getRelationship(id);
  }

  int encode(RelationshipImpl relationship) {
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
