// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src.services.index;

import 'dart:collection';

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A wrapper around an [Element] that implements the [IndexableObject] interface.
 */
class IndexableElement implements IndexableObject {
  /**
   * The element being wrapped.
   */
  final Element element;

  /**
   * Initialize a newly created wrapper to wrap the given [element].
   */
  IndexableElement(this.element) {
    if (element == null) {
      throw new ArgumentError.notNull('element');
    }
  }

  @override
  int get hashCode => element.hashCode;

  @override
  IndexableObjectKind get kind => IndexableElementKind.forElement(element);

  @override
  int get length => element.displayName.length;

  @override
  String get name => element.displayName;

  @override
  int get offset {
    if (element is ConstructorElement) {
      return element.enclosingElement.nameOffset;
    }
    return element.nameOffset;
  }

  @override
  Source get source => element.source;

  @override
  bool operator ==(Object object) =>
      object is IndexableElement && element == object.element;

  @override
  String toString() => element.toString();
}

/**
 * The kind associated with an [IndexableElement].
 */
class IndexableElementKind implements IndexableObjectKind {
  /**
   * A table mapping element kinds to the corresponding indexable element kind.
   */
  static Map<ElementKind, IndexableElementKind> _kindMap =
      new HashMap<ElementKind, IndexableElementKind>();

  /**
   * A table mapping the index of a constructor (in the lexically-ordered list
   * of constructors associated with a class) to the indexable element kind used
   * to represent it.
   */
  static Map<int, IndexableElementKind> _constructorKinds =
      new HashMap<int, IndexableElementKind>();

  @override
  final int index = IndexableObjectKind.nextIndex;

  /**
   * The element kind represented by this index element kind.
   */
  final ElementKind elementKind;

  /**
   * Initialize a newly created kind to have the given [index] and be associated
   * with the given [elementKind].
   */
  IndexableElementKind._(this.elementKind) {
    IndexableObjectKind.register(this);
  }

  /**
   * Return the index of the constructor with this indexable element kind.
   */
  int get constructorIndex {
    for (int index in _constructorKinds.keys) {
      if (_constructorKinds[index] == this) {
        return index;
      }
    }
    return -1;
  }

  @override
  IndexableObject decode(AnalysisContext context, String filePath, int offset) {
    List<Source> unitSources = context.getSourcesWithFullName(filePath);
    for (Source unitSource in unitSources) {
      List<Source> libSources = context.getLibrariesContaining(unitSource);
      for (Source libSource in libSources) {
        CompilationUnitElement unitElement =
            context.getCompilationUnitElement(unitSource, libSource);
        if (unitElement == null) {
          return null;
        }
        if (elementKind == ElementKind.LIBRARY) {
          return new IndexableElement(unitElement.library);
        } else if (elementKind == ElementKind.COMPILATION_UNIT) {
          return new IndexableElement(unitElement);
        } else {
          Element element = unitElement.getElementAt(offset);
          if (element == null) {
            return null;
          }
          if (element is ClassElement &&
              elementKind == ElementKind.CONSTRUCTOR) {
            return new IndexableElement(element.constructors[constructorIndex]);
          }
          if (element is PropertyInducingElement) {
            if (elementKind == ElementKind.GETTER) {
              return new IndexableElement(element.getter);
            }
            if (elementKind == ElementKind.SETTER) {
              return new IndexableElement(element.setter);
            }
          }
          return new IndexableElement(element);
        }
      }
    }
    return null;
  }

  /**
   * Return the indexable element kind representing the given [element].
   */
  static IndexableElementKind forElement(Element element) {
    if (element is ConstructorElement) {
      ClassElement classElement = element.enclosingElement;
      int constructorIndex = classElement.constructors.indexOf(element);
      return _constructorKinds.putIfAbsent(constructorIndex,
          () => new IndexableElementKind._(ElementKind.CONSTRUCTOR));
    }
    ElementKind elementKind = element.kind;
    return _kindMap.putIfAbsent(
        elementKind, () => new IndexableElementKind._(elementKind));
  }
}
