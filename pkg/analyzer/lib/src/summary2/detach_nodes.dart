// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
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

class _Visitor extends GeneralizingElementVisitor2<void> {
  @override
  void visitClassElement(covariant ClassElementImpl element) {
    element.mixinInferenceCallback = null;
    super.visitClassElement(element);
  }

  @override
  void visitConstructorElement(covariant ConstructorElementImpl element) {
    for (var fragment in element.fragments) {
      // Make a copy, so that it is not a NodeList.
      var initializers = fragment.constantInitializers.toFixedList();
      initializers.forEach(_detachNode);

      for (var initializer in initializers) {
        if (initializer is! ConstructorInitializerImpl) continue;
        switch (initializer) {
          case AssertInitializerImpl(:var condition, :var message):
            var conditionReplacement = replaceNotSerializableNode(condition);
            initializer.condition = conditionReplacement;

            if (message != null) {
              var messageReplacement = replaceNotSerializableNode(message);
              initializer.message = messageReplacement;
            }
          case ConstructorFieldInitializerImpl(:var expression):
            var replacement = replaceNotSerializableNode(expression);
            initializer.expression = replacement;
          case RedirectingConstructorInvocationImpl(:var argumentList):
            _sanitizeArguments(argumentList.arguments);
          case SuperConstructorInvocationImpl(:var argumentList):
            _sanitizeArguments(argumentList.arguments);
        }
      }

      fragment.constantInitializers = initializers;
    }
    super.visitConstructorElement(element);
  }

  @override
  void visitElement(Element element) {
    for (var annotation in element.metadata.annotations) {
      var ast = (annotation as ElementAnnotationImpl).annotationAst;
      _detachNode(ast);
      _sanitizeArguments(ast.arguments?.arguments);
    }
    super.visitElement(element);
  }

  @override
  void visitEnumElement(covariant EnumElementImpl element) {
    element.mixinInferenceCallback = null;
    super.visitEnumElement(element);
  }

  @override
  void visitFormalParameterElement(FormalParameterElement element) {
    _detachConstVariable(element);
    super.visitFormalParameterElement(element);
  }

  @override
  void visitMixinElement(covariant MixinElementImpl element) {
    element.mixinInferenceCallback = null;
    super.visitMixinElement(element);
  }

  @override
  void visitPropertyInducingElement(PropertyInducingElement element) {
    for (var fragment in element.fragments) {
      if (fragment is PropertyInducingFragmentImpl) {
        fragment.typeInference = null;
      }
    }
    _detachConstVariable(element);
    super.visitPropertyInducingElement(element);
  }

  void _detachConstVariable(Object element) {
    if (element is VariableElementImpl) {
      for (var fragment in element.fragments) {
        fragment as VariableFragmentImpl;
        var initializer = fragment.constantInitializer;
        if (initializer is ExpressionImpl) {
          _detachNode(initializer);

          initializer = replaceNotSerializableNode(initializer);
          fragment.constantInitializer = initializer;

          ConstantContextForExpressionImpl(fragment, initializer);
        }
      }
      element.resetConstantInitializer();
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
