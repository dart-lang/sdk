// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.index.store.codec;

import 'dart:collection';

import 'package:analysis_server/src/services/index/index.dart';
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
 * A helper that encodes/decodes [Element]s to/from integers.
 */
class ElementCodec {
  static const int _CONSTRUCTOR_KIND_BASE = -100;

  final StringCodec _stringCodec;

  ElementCodec(this._stringCodec);

  /**
   * Returns an [Element] that corresponds to the given identifiers.
   */
  Element decode(AnalysisContext context, int fileId, int offset, int kindId) {
    String filePath = _stringCodec.decode(fileId);
    List<Source> unitSources = context.getSourcesWithFullName(filePath);
    for (Source unitSource in unitSources) {
      List<Source> libSources = context.getLibrariesContaining(unitSource);
      for (Source libSource in libSources) {
        CompilationUnitElement unitElement =
            context.getCompilationUnitElement(unitSource, libSource);
        if (unitElement == null) {
          return null;
        }
        if (kindId == ElementKind.LIBRARY.ordinal) {
          return unitElement.library;
        } else if (kindId == ElementKind.COMPILATION_UNIT.ordinal) {
          return unitElement;
        } else {
          Element element = unitElement.getElementAt(offset);
          if (element == null) {
            return null;
          }
          if (element is ClassElement && kindId <= _CONSTRUCTOR_KIND_BASE) {
            int constructorIndex = -1 * (kindId - _CONSTRUCTOR_KIND_BASE);
            return element.constructors[constructorIndex];
          }
          if (element is PropertyInducingElement) {
            if (kindId == ElementKind.GETTER.ordinal) {
              return element.getter;
            }
            if (kindId == ElementKind.SETTER.ordinal) {
              return element.setter;
            }
          }
          return element;
        }
      }
    }
    return null;
  }

  /**
   * Returns the first component of the [element] id.
   * In the most cases it is an encoding of the [element]'s file path.
   * If the given [element] is not defined in a file, returns `-1`.
   */
  int encode1(Element element) {
    Source source = element.source;
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
  int encode2(Element element) {
    if (element is NameElement) {
      String name = element.name;
      return _stringCodec.encode(name);
    }
    if (element is ConstructorElement) {
      return element.enclosingElement.nameOffset;
    }
    return element.nameOffset;
  }

  /**
   * Returns the third component of the [element] id.
   * In the most cases it is the [element]'s kind.
   */
  int encode3(Element element) {
    if (element is ConstructorElement) {
      ClassElement classElement = element.enclosingElement;
      int constructorIndex = classElement.constructors.indexOf(element);
      return _CONSTRUCTOR_KIND_BASE - constructorIndex;
    }
    return element.kind.ordinal;
  }

  /**
   * Returns an integer that corresponds to the name of [element].
   */
  int encodeHash(Element element) {
    String elementName = element.displayName;
    int elementNameId = _stringCodec.encode(elementName);
    LibraryElement libraryElement = element.library;
    if (libraryElement != null) {
      String libraryPath = libraryElement.source.fullName;
      int libraryPathId = _stringCodec.encode(libraryPath);
      return JenkinsSmiHash.combine(libraryPathId, elementNameId);
    } else {
      return elementNameId;
    }
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
