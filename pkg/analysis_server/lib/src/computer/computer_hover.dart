// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.hover;

import 'package:analysis_server/plugin/protocol/protocol.dart'
    show HoverInformation;
import 'package:analysis_server/src/utilities/documentation.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for the hover at the specified offset of a Dart [CompilationUnit].
 */
class DartUnitHoverComputer {
  final CompilationUnit _unit;
  final int _offset;

  DartUnitHoverComputer(this._unit, this._offset);

  /**
   * Returns the computed hover, maybe `null`.
   */
  HoverInformation compute() {
    AstNode node = new NodeLocator(_offset).searchWithin(_unit);
    if (node == null) {
      return null;
    }
    if (node.parent is TypeName &&
        node.parent.parent is ConstructorName &&
        node.parent.parent.parent is InstanceCreationExpression) {
      node = node.parent.parent.parent;
    }
    if (node.parent is ConstructorName &&
        node.parent.parent is InstanceCreationExpression) {
      node = node.parent.parent;
    }
    if (node is Expression) {
      Expression expression = node;
      HoverInformation hover =
          new HoverInformation(expression.offset, expression.length);
      // element
      Element element = ElementLocator.locate(expression);
      if (element != null) {
        // variable, if synthetic accessor
        if (element is PropertyAccessorElement) {
          PropertyAccessorElement accessor = element;
          if (accessor.isSynthetic) {
            element = accessor.variable;
          }
        }
        // description
        hover.elementDescription = element.toString();
        hover.elementKind = element.kind.displayName;
        // not local element
        if (element.enclosingElement is! ExecutableElement) {
          // containing class
          ClassElement containingClass =
              element.getAncestor((e) => e is ClassElement);
          if (containingClass != null) {
            hover.containingClassDescription = containingClass.displayName;
          }
          // containing library
          LibraryElement library = element.library;
          if (library != null) {
            hover.containingLibraryName = library.name;
            hover.containingLibraryPath = library.source.fullName;
          }
        }

        // documentation
        hover.dartdoc = _computeDocumentation(element);
      }
      // parameter
      hover.parameter = _safeToString(expression.bestParameterElement);
      // types
      if (element == null || element is VariableElement) {
        hover.staticType = _safeToString(expression.staticType);
      }
      hover.propagatedType = _safeToString(expression.propagatedType);
      // done
      return hover;
    }
    // not an expression
    return null;
  }

  String _computeDocumentation(Element element) {
    if (element is ParameterElement) {
      element = element.enclosingElement;
    }
    return removeDartDocDelimiters(element.documentationComment);
  }

  static _safeToString(obj) => obj != null ? obj.toString() : null;
}
