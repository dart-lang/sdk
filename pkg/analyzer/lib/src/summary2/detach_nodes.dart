// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
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
          case AssertInitializerImpl(:var condition2, :var message2):
            var conditionReplacement = replaceNotSerializableExpression(
              condition2,
            );
            initializer.condition2 = conditionReplacement;

            if (message2 != null) {
              var messageReplacement = replaceNotSerializableExpression(
                message2,
              );
              initializer.message2 = messageReplacement;
            }
          case ConstructorFieldInitializerImpl(:var expression2):
            var replacement = replaceNotSerializableExpression(expression2);
            initializer.expression2 = replacement;
            AstNodeImpl.linkNodeTokens(initializer);
          case RedirectingConstructorInvocationImpl(:var argumentList):
            _sanitizeArguments(argumentList.arguments2);
          case SuperConstructorInvocationImpl(:var argumentList):
            _sanitizeArguments(argumentList.arguments2);
        }
      }

      fragment.constantInitializers = initializers;
    }
    super.visitConstructorElement(element);
  }

  @override
  void visitElement(Element element) {
    _detachMetadata(element.metadata);
    super.visitElement(element);
  }

  @override
  void visitEnumElement(covariant EnumElementImpl element) {
    element.mixinInferenceCallback = null;
    super.visitEnumElement(element);
  }

  @override
  void visitExecutableElement(covariant ExecutableElementImpl element) {
    // A formal parameter that only an augmenting fragment declares is not in
    // `formalParameters`, so `children` does not reach it. The other formal
    // parameters are in `children`, and `super` visits them.
    for (var formalParameter in element.formalParametersIncludingRecovery) {
      if (formalParameter.firstFragment.isOriginOtherFragmentOfEnclosing) {
        formalParameter.accept(this);
      }
    }
    super.visitExecutableElement(element);
  }

  @override
  void visitFormalParameterElement(FormalParameterElement element) {
    _detachConstVariable(element);
    super.visitFormalParameterElement(element);
  }

  @override
  void visitLibraryElement(covariant LibraryElementImpl element) {
    // Directives are not elements, so `children` does not include them.
    for (var fragment in element.fragments) {
      for (var import in fragment.libraryImports) {
        _detachMetadata(import.metadata);
      }
      for (var export in fragment.libraryExports) {
        _detachMetadata(export.metadata);
      }
      for (var partInclude in fragment.parts) {
        _detachMetadata(partInclude.metadata);
      }
    }
    super.visitLibraryElement(element);
  }

  @override
  void visitMixinElement(covariant MixinElementImpl element) {
    element.mixinInferenceCallback = null;
    super.visitMixinElement(element);
  }

  @override
  void visitPropertyInducingElement(
    covariant PropertyInducingElementImpl element,
  ) {
    element.typeInference = null;
    _detachConstVariable(element);
    super.visitPropertyInducingElement(element);
  }

  void _detachConstVariable(Object element) {
    if (element is VariableElementImpl) {
      for (var fragment in element.fragments) {
        var initializer = fragment.constantInitializer2;
        if (initializer is ExpressionImpl) {
          _detachNode(initializer);

          initializer = replaceNotSerializableExpression(initializer);
          fragment.constantInitializer2 = initializer;

          ConstantContextForExpressionImpl(fragment, initializer);
        }
      }
      element.resetConstantInitializer();
    }
  }

  void _detachMetadata(Metadata metadata) {
    for (var annotation in metadata.annotations) {
      var ast = (annotation as ElementAnnotationImpl).annotationAst;
      _detachNode(ast);
      if (ast.expression case ConstructorInvocationImpl(:var argumentList)) {
        _sanitizeArguments(argumentList.arguments2);
      }
    }
  }

  void _detachNode(AstNode? node) {
    if (node is AstNodeImpl) {
      node.detachFromParent();
      // Also detach from the token stream.
      node.beginToken.previous = null;
      node.endToken.next = null;
      for (Token? token = node.beginToken; token != null; token = token.next) {
        if (token is SimpleToken) {
          token.precedingComments = null;
        }
      }
    }
  }

  void _sanitizeArguments(List<ArgumentImpl>? arguments) {
    if (arguments != null) {
      for (var (i, argument) in arguments.indexed) {
        switch (argument) {
          case ExpressionImpl():
            arguments[i] = replaceNotSerializableExpression(argument);
          case NamedArgumentImpl():
            argument.argumentExpression2 = replaceNotSerializableExpression(
              argument.argumentExpression2,
            );
        }
      }
    }
  }
}
