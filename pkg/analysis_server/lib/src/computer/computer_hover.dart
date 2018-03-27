// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show HoverInformation;
import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/utilities/documentation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

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
        if (node is InstanceCreationExpression && node.keyword == null) {
          String prefix = node.isConst ? '(const) ' : '(new) ';
          hover.elementDescription = prefix + hover.elementDescription;
        }
        hover.elementKind = element.kind.displayName;
        hover.isDeprecated = element.hasDeprecated;
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
      {
        AstNode parent = expression.parent;
        DartType staticType = null;
        DartType propagatedType = expression.propagatedType;
        if (element is ParameterElement) {
          staticType = element.type;
        } else if (element == null || element is VariableElement) {
          staticType = expression.staticType;
        }
        if (parent is MethodInvocation && parent.methodName == expression) {
          staticType = parent.staticInvokeType;
          propagatedType = parent.propagatedInvokeType;
          if (staticType != null && staticType.isDynamic) {
            staticType = null;
          }
          if (propagatedType != null && propagatedType.isDynamic) {
            propagatedType = null;
          }
        }
        hover.staticType = _safeToString(staticType);
        hover.propagatedType = _safeToString(propagatedType);
      }
      // done
      return hover;
    }
    // not an expression
    return null;
  }

  String _computeDocumentation(Element element) {
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is ParameterElement) {
      element = element.enclosingElement;
    }
    if (element == null) {
      // This can happen when the code is invalid, such as having a field formal
      // parameter for a field that does not exist.
      return null;
    }
    // The documentation of the element itself.
    if (element.documentationComment != null) {
      return removeDartDocDelimiters(element.documentationComment);
    }
    // Look for documentation comments of overridden members.
    OverriddenElements overridden = findOverriddenElements(element);
    for (Element superElement in []
      ..addAll(overridden.superElements)
      ..addAll(overridden.interfaceElements)) {
      String rawDoc = superElement.documentationComment;
      if (rawDoc != null) {
        Element interfaceClass = superElement.enclosingElement;
        return removeDartDocDelimiters(rawDoc) +
            '\n\nCopied from `${interfaceClass.displayName}`.';
      }
    }
    return null;
  }

  static _safeToString(obj) => obj?.toString();
}
