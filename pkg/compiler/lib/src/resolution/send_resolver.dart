// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.semantics_visitor.resolver;

import '../common.dart';
import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import 'semantic_visitor.dart';
import 'send_structure.dart';
import 'tree_elements.dart';

abstract class DeclStructure<R, A> {
  final FunctionElement element;

  DeclStructure(this.element);

  /// Calls the matching visit method on [visitor] with [node] and [arg].
  R dispatch(
      SemanticDeclarationVisitor<R, A> visitor, FunctionExpression node, A arg);
}

enum ConstructorKind {
  GENERATIVE,
  REDIRECTING_GENERATIVE,
  FACTORY,
  REDIRECTING_FACTORY,
}

class ConstructorDeclStructure<R, A> extends DeclStructure<R, A> {
  final ConstructorKind kind;

  ConstructorDeclStructure(this.kind, ConstructorElement constructor)
      : super(constructor);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, FunctionExpression node,
      A arg) {
    switch (kind) {
      case ConstructorKind.GENERATIVE:
        return visitor.visitGenerativeConstructorDeclaration(
            node, element, node.parameters, node.initializers, node.body, arg);
      case ConstructorKind.REDIRECTING_GENERATIVE:
        return visitor.visitRedirectingGenerativeConstructorDeclaration(
            node, element, node.parameters, node.initializers, arg);
      case ConstructorKind.FACTORY:
        return visitor.visitFactoryConstructorDeclaration(
            node, element, node.parameters, node.body, arg);
      default:
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Unhandled constructor declaration kind: ${kind}");
  }
}

class RedirectingFactoryConstructorDeclStructure<R, A>
    extends DeclStructure<R, A> {
  ResolutionInterfaceType redirectionTargetType;
  ConstructorElement redirectionTarget;

  RedirectingFactoryConstructorDeclStructure(ConstructorElement constructor,
      this.redirectionTargetType, this.redirectionTarget)
      : super(constructor);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, FunctionExpression node,
      A arg) {
    return visitor.visitRedirectingFactoryConstructorDeclaration(node, element,
        node.parameters, redirectionTargetType, redirectionTarget, arg);
  }
}

enum FunctionKind {
  TOP_LEVEL_GETTER,
  TOP_LEVEL_SETTER,
  TOP_LEVEL_FUNCTION,
  STATIC_GETTER,
  STATIC_SETTER,
  STATIC_FUNCTION,
  ABSTRACT_GETTER,
  ABSTRACT_SETTER,
  ABSTRACT_METHOD,
  INSTANCE_GETTER,
  INSTANCE_SETTER,
  INSTANCE_METHOD,
  LOCAL_FUNCTION,
  CLOSURE,
}

class FunctionDeclStructure<R, A> extends DeclStructure<R, A> {
  final FunctionKind kind;

  FunctionDeclStructure(this.kind, FunctionElement function) : super(function);

  // ignore: MISSING_RETURN
  R dispatch(SemanticDeclarationVisitor<R, A> visitor, FunctionExpression node,
      A arg) {
    switch (kind) {
      case FunctionKind.TOP_LEVEL_GETTER:
        return visitor.visitTopLevelGetterDeclaration(
            node, element, node.body, arg);
      case FunctionKind.TOP_LEVEL_SETTER:
        return visitor.visitTopLevelSetterDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.TOP_LEVEL_FUNCTION:
        return visitor.visitTopLevelFunctionDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.STATIC_GETTER:
        return visitor.visitStaticGetterDeclaration(
            node, element, node.body, arg);
      case FunctionKind.STATIC_SETTER:
        return visitor.visitStaticSetterDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.STATIC_FUNCTION:
        return visitor.visitStaticFunctionDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.ABSTRACT_GETTER:
        return visitor.visitAbstractGetterDeclaration(node, element, arg);
      case FunctionKind.ABSTRACT_SETTER:
        return visitor.visitAbstractSetterDeclaration(
            node, element, node.parameters, arg);
      case FunctionKind.ABSTRACT_METHOD:
        return visitor.visitAbstractMethodDeclaration(
            node, element, node.parameters, arg);
      case FunctionKind.INSTANCE_GETTER:
        return visitor.visitInstanceGetterDeclaration(
            node, element, node.body, arg);
      case FunctionKind.INSTANCE_SETTER:
        return visitor.visitInstanceSetterDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.INSTANCE_METHOD:
        return visitor.visitInstanceMethodDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionDeclaration(
            node, element, node.parameters, node.body, arg);
      case FunctionKind.CLOSURE:
        return visitor.visitClosureDeclaration(
            node, element, node.parameters, node.body, arg);
    }
  }
}

abstract class DeclarationResolverMixin {
  TreeElements get elements;

  internalError(Spannable spannable, String message);

  ConstructorKind computeConstructorKind(ConstructorElement constructor) {
    if (constructor.isRedirectingFactory) {
      return ConstructorKind.REDIRECTING_FACTORY;
    } else if (constructor.isFactoryConstructor) {
      return ConstructorKind.FACTORY;
    } else if (constructor.isRedirectingGenerative) {
      return ConstructorKind.REDIRECTING_GENERATIVE;
    } else {
      return ConstructorKind.GENERATIVE;
    }
  }

  DeclStructure computeFunctionStructure(FunctionExpression node) {
    FunctionElement element = elements.getFunctionDefinition(node);
    if (element.isConstructor) {
      ConstructorElement constructor = element;
      ConstructorKind kind = computeConstructorKind(constructor);
      if (kind == ConstructorKind.REDIRECTING_FACTORY) {
        return new RedirectingFactoryConstructorDeclStructure(
            constructor,
            elements.getType(node.body),
            constructor.immediateRedirectionTarget);
      } else {
        return new ConstructorDeclStructure(kind, element);
      }
    } else {
      FunctionKind kind;
      if (element.isLocal) {
        if (element.name.isEmpty) {
          kind = FunctionKind.CLOSURE;
        } else {
          kind = FunctionKind.LOCAL_FUNCTION;
        }
      } else if (element.isInstanceMember) {
        if (element.isGetter) {
          kind = element.isAbstract
              ? FunctionKind.ABSTRACT_GETTER
              : FunctionKind.INSTANCE_GETTER;
        } else if (element.isSetter) {
          kind = element.isAbstract
              ? FunctionKind.ABSTRACT_SETTER
              : FunctionKind.INSTANCE_SETTER;
        } else {
          kind = element.isAbstract
              ? FunctionKind.ABSTRACT_METHOD
              : FunctionKind.INSTANCE_METHOD;
        }
      } else if (element.isStatic) {
        if (element.isGetter) {
          kind = FunctionKind.STATIC_GETTER;
        } else if (element.isSetter) {
          kind = FunctionKind.STATIC_SETTER;
        } else {
          kind = FunctionKind.STATIC_FUNCTION;
        }
      } else if (element.isTopLevel) {
        if (element.isGetter) {
          kind = FunctionKind.TOP_LEVEL_GETTER;
        } else if (element.isSetter) {
          kind = FunctionKind.TOP_LEVEL_SETTER;
        } else {
          kind = FunctionKind.TOP_LEVEL_FUNCTION;
        }
      } else {
        return internalError(node, "Unhandled function expression.");
      }
      return new FunctionDeclStructure(kind, element);
    }
  }

  InitializersStructure computeInitializersStructure(FunctionExpression node) {
    List<InitializerStructure> initializers = <InitializerStructure>[];
    NodeList list = node.initializers;
    bool constructorInvocationSeen = false;
    if (list != null) {
      for (Node initializer in list) {
        InitializerStructure structure =
            computeInitializerStructure(initializer);
        if (structure.isConstructorInvoke) {
          constructorInvocationSeen = true;
        }
        initializers.add(structure);
      }
    }
    if (!constructorInvocationSeen) {
      ConstructorElement currentConstructor = elements[node];
      ClassElement currentClass = currentConstructor.enclosingClass;
      ResolutionInterfaceType supertype = currentClass.supertype;
      if (supertype != null) {
        ClassElement superclass = supertype.element;
        ConstructorElement superConstructor =
            superclass.lookupDefaultConstructor();
        initializers.add(new ImplicitSuperConstructorInvokeStructure(
            node, superConstructor, supertype));
      }
    }
    return new InitializersStructure(initializers);
  }

  InitializerStructure computeInitializerStructure(Send node) {
    Element element = elements[node];
    if (node.asSendSet() != null) {
      return new FieldInitializerStructure(node, element);
    } else if (Initializers.isConstructorRedirect(node)) {
      return new ThisConstructorInvokeStructure(
          node, element, elements.getSelector(node).callStructure);
    } else if (Initializers.isSuperConstructorCall(node)) {
      return new SuperConstructorInvokeStructure(
          node,
          element,
          elements.analyzedElement.enclosingClass.supertype,
          elements.getSelector(node).callStructure);
    }
    return internalError(node, "Unhandled initializer.");
  }

  List<ParameterStructure> computeParameterStructures(NodeList parameters) {
    List<ParameterStructure> list = <ParameterStructure>[];
    int index = 0;
    for (Node node in parameters) {
      NodeList optionalParameters = node.asNodeList();
      if (optionalParameters != null) {
        bool isNamed = optionalParameters.beginToken.stringValue == '{';
        for (Node node in optionalParameters) {
          list.add(computeParameterStructure(node, index++,
              isRequired: false, isNamed: isNamed));
        }
      } else {
        list.add(computeParameterStructure(node, index++));
      }
    }
    return list;
  }

  ParameterStructure computeParameterStructure(
      VariableDefinitions definitions, int index,
      {bool isRequired: true, bool isNamed: false}) {
    Node node = definitions.definitions.nodes.single;
    ParameterElement element = elements[node];
    if (element == null) {
      throw new SpannableAssertionFailure(
          node, "No parameter structure for $node.");
    }
    if (isRequired) {
      return new RequiredParameterStructure(definitions, node, element, index);
    } else {
      // TODO(johnniwinther): Should we differentiate between implicit (null)
      // and explicit values? What about optional parameters on redirecting
      // factories?
      if (isNamed) {
        return new NamedParameterStructure(
            definitions, node, element, element.constant);
      } else {
        return new OptionalParameterStructure(
            definitions, node, element, element.constant, index);
      }
    }
  }

  void computeVariableStructures(VariableDefinitions definitions,
      void callback(Node node, VariableStructure structure)) {
    for (Node node in definitions.definitions) {
      callback(definitions, computeVariableStructure(node));
    }
  }

  VariableStructure computeVariableStructure(Node node) {
    VariableElement element = elements[node];
    VariableKind kind;
    if (element.isLocal) {
      kind = VariableKind.LOCAL_VARIABLE;
    } else if (element.isInstanceMember) {
      kind = VariableKind.INSTANCE_FIELD;
    } else if (element.isStatic) {
      kind = VariableKind.STATIC_FIELD;
    } else if (element.isTopLevel) {
      kind = VariableKind.TOP_LEVEL_FIELD;
    } else {
      return internalError(node, "Unexpected variable $element.");
    }
    if (element.isConst) {
      ConstantExpression constant = elements.getConstant(element.initializer);
      return new ConstantVariableStructure(kind, node, element, constant);
    } else {
      return new NonConstantVariableStructure(kind, node, element);
    }
  }
}
