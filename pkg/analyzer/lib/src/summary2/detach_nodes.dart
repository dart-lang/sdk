// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/not_serializable_nodes.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Elements have references to AST nodes, for example initializers of constant
/// variables. These nodes are attached to the whole compilation unit, and
/// the whole token stream for the file. We don't want all this data after
/// linking. So, we need to detach these nodes.
void detachElementsFromNodes(LibraryElementImpl element) {
  element.accept(_Visitor());
}

class _Visitor extends GeneralizingElementVisitor<void> {
  @override
  void visitClassElement(ClassElement element) {
    if (element is ClassElementImpl) {
      element.mixinInferenceCallback = null;
    }
    super.visitClassElement(element);
  }

  @override
  void visitConstructorElement(ConstructorElement element) {
    if (element is ConstructorElementImpl) {
      // Make a copy, so that it is not a NodeList.
      var initializers = element.constantInitializers.toFixedList();
      initializers.forEach(_detachNode);

      for (final initializer in initializers) {
        if (initializer is ConstructorFieldInitializerImpl) {
          final expression = initializer.expression;
          final replacement = replaceNotSerializableNode(expression);
          initializer.expression = replacement;
        } else if (initializer is RedirectingConstructorInvocationImpl) {
          _sanitizeArguments(initializer.argumentList.arguments);
        } else if (initializer is SuperConstructorInvocationImpl) {
          _sanitizeArguments(initializer.argumentList.arguments);
        }
      }

      element.constantInitializers = initializers;
    }
    super.visitConstructorElement(element);
  }

  @override
  void visitElement(Element element) {
    for (final annotation in element.metadata) {
      final ast = (annotation as ElementAnnotationImpl).annotationAst;
      _detachNode(ast);
      _sanitizeArguments(ast.arguments?.arguments);
    }
    super.visitElement(element);
  }

  @override
  void visitEnumElement(EnumElement element) {
    if (element is EnumElementImpl) {
      element.mixinInferenceCallback = null;
    }
    super.visitEnumElement(element);
  }

  @override
  void visitMixinElement(MixinElement element) {
    if (element is MixinElementImpl) {
      element.mixinInferenceCallback = null;
    }
    super.visitMixinElement(element);
  }

  @override
  void visitParameterElement(ParameterElement element) {
    _detachConstVariable(element);
    super.visitParameterElement(element);
  }

  @override
  void visitPropertyInducingElement(PropertyInducingElement element) {
    if (element is PropertyInducingElementImpl) {
      element.typeInference = null;
    }
    _detachConstVariable(element);
    super.visitPropertyInducingElement(element);
  }

  void _detachConstVariable(Element element) {
    if (element is ConstVariableElement) {
      var initializer = element.constantInitializer;
      if (initializer is ExpressionImpl) {
        _detachNode(initializer);

        initializer = replaceNotSerializableNode(initializer);
        element.constantInitializer = initializer;

        ConstantContextForExpressionImpl(element, initializer);
      }
    }
  }

  void _detachNode(AstNode? node) {
    if (node is AstNodeImpl) {
      node.detachFromParent();
      // Also detach from the token stream.
      node.beginToken.previous = null;
      node.endToken.next = null;
    }
  }

  void _sanitizeArguments(List<ExpressionImpl>? arguments) {
    if (arguments != null) {
      for (var i = 0; i < arguments.length; i++) {
        arguments[i] = replaceNotSerializableNode(arguments[i]);
      }
    }
  }
}
