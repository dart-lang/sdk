// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor;

enum SendStructureKind {
  GET,
  SET,
  INVOKE,
  UNARY,
  NOT,
  BINARY,
  EQ,
  NOT_EQ,
  COMPOUND,
  INDEX,
  INDEX_SET,
  COMPOUND_INDEX_SET,
  PREFIX,
  POSTFIX,
  INDEX_PREFIX,
  INDEX_POSTFIX,
}

abstract class SendResolverMixin {
  TreeElements get elements;

  internalError(Spannable spannable, String message);

  AccessSemantics handleStaticallyResolvedAccess(Send node,
                                                 Element element,
                                                 Element getter) {
    if (element.isErroneous) {
      return new StaticAccess.unresolved(element);
    } else if (element.isParameter) {
      return new StaticAccess.parameter(element);
    } else if (element.isLocal) {
      if (element.isFunction) {
        return new StaticAccess.localFunction(element);
      } else {
        return new StaticAccess.localVariable(element);
      }
    } else if (element.isStatic) {
      if (element.isField) {
        return new StaticAccess.staticField(element);
      } else if (element.isGetter) {
        return new StaticAccess.staticGetter(element);
      } else if (element.isSetter) {
        if (getter != null) {
          CompoundAccessKind accessKind;
          if (getter.isGetter) {
            accessKind = CompoundAccessKind.STATIC_GETTER_SETTER;
          } else {
            accessKind = CompoundAccessKind.STATIC_METHOD_SETTER;
          }
          return new CompoundAccessSemantics(
              accessKind, getter, element);
        } else {
          return new StaticAccess.staticSetter(element);
        }
      } else {
        return new StaticAccess.staticMethod(element);
      }
    } else if (element.isTopLevel) {
      if (element.isField) {
        return new StaticAccess.topLevelField(element);
      } else if (element.isGetter) {
        return new StaticAccess.topLevelGetter(element);
      } else if (element.isSetter) {
        if (getter != null) {
          CompoundAccessKind accessKind;
          if (getter.isGetter) {
            accessKind = CompoundAccessKind.TOPLEVEL_GETTER_SETTER;
          } else {
            accessKind = CompoundAccessKind.TOPLEVEL_METHOD_SETTER;
          }
          return new CompoundAccessSemantics(
              accessKind, getter, element);
        } else {
          return new StaticAccess.topLevelSetter(element);
        }
      } else {
        return new StaticAccess.topLevelMethod(element);
      }
    } else {
      return internalError(
          node, "Unhandled resolved property access: $element");
    }
  }

  SendStructure computeSendStructure(Send node) {
    if (elements.isAssert(node)) {
      if (!node.arguments.isEmpty && node.arguments.tail.isEmpty) {
        return const AssertStructure();
      } else {
        return const InvalidAssertStructure();
      }
    }

    AssignmentOperator assignmentOperator;
    UnaryOperator unaryOperator;
    BinaryOperator binaryOperator;
    IncDecOperator incDecOperator;

    if (node.isOperator) {
      String operatorText = node.selector.asOperator().source;
      if (operatorText == 'is') {
        if (node.isIsNotCheck) {
          return new IsNotStructure(
              elements.getType(node.arguments.single.asSend().receiver));
        } else {
          return new IsStructure(elements.getType(node.arguments.single));
        }
      } else if (operatorText == 'as') {
        return new AsStructure(elements.getType(node.arguments.single));
      } else if (operatorText == '&&') {
        return const LogicalAndStructure();
      } else if (operatorText == '||') {
        return const LogicalOrStructure();
      }
    }

    SendStructureKind kind;

    if (node.asSendSet() != null) {
      SendSet sendSet = node.asSendSet();
      String operatorText = sendSet.assignmentOperator.source;
      if (sendSet.isPrefix || sendSet.isPostfix) {
        kind = sendSet.isPrefix
            ? SendStructureKind.PREFIX
            : SendStructureKind.POSTFIX;
        incDecOperator = IncDecOperator.parse(operatorText);
        if (incDecOperator == null) {
          return internalError(
              node, "No inc/dec operator for '$operatorText'.");
        }
      } else {
        assignmentOperator = AssignmentOperator.parse(operatorText);
        if (assignmentOperator != null) {
          switch (assignmentOperator.kind) {
            case AssignmentOperatorKind.ASSIGN:
              kind = SendStructureKind.SET;
              break;
            default:
              kind = SendStructureKind.COMPOUND;
          }
        } else {
          return internalError(
              node, "No assignment operator for '$operatorText'.");
        }
      }
    } else if (!node.isPropertyAccess) {
      kind = SendStructureKind.INVOKE;
    } else {
      kind = SendStructureKind.GET;
    }

    if (node.isOperator) {
      String operatorText = node.selector.asOperator().source;
      if (node.arguments.isEmpty) {
        unaryOperator = UnaryOperator.parse(operatorText);
        if (unaryOperator != null) {
          switch (unaryOperator.kind) {
            case UnaryOperatorKind.NOT:
              kind = SendStructureKind.NOT;
              break;
            default:
              kind = SendStructureKind.UNARY;
              break;
          }
        } else {
          return const InvalidUnaryStructure();
        }
      } else {
        binaryOperator = BinaryOperator.parse(operatorText);
        if (binaryOperator != null) {
          switch (binaryOperator.kind) {
            case BinaryOperatorKind.EQ:
              kind = SendStructureKind.EQ;
              break;
            case BinaryOperatorKind.NOT_EQ:
              if (node.isSuperCall) {
                // `super != foo` is a compile-time error.
                return const InvalidBinaryStructure();
              }
              kind = SendStructureKind.NOT_EQ;
              break;
            case BinaryOperatorKind.INDEX:
              if (node.isPrefix) {
                kind = SendStructureKind.INDEX_PREFIX;
              } else if (node.isPostfix) {
                kind = SendStructureKind.INDEX_POSTFIX;
              } else if (node.arguments.tail.isEmpty) {
                // a[b]
                kind = SendStructureKind.INDEX;
              } else {
                if (kind == SendStructureKind.COMPOUND) {
                  // a[b] += c
                  kind = SendStructureKind.COMPOUND_INDEX_SET;
                } else {
                  // a[b] = c
                  kind = SendStructureKind.INDEX_SET;
                }
              }
              break;
            default:
              kind = SendStructureKind.BINARY;
              break;
          }
        } else {
          return const InvalidBinaryStructure();
        }
      }
    }
    AccessSemantics semantics = computeAccessSemantics(
        node,
        isGetOrSet: kind == SendStructureKind.GET ||
                    kind == SendStructureKind.SET,
        isInvoke: kind == SendStructureKind.INVOKE,
        isCompound: kind == SendStructureKind.COMPOUND ||
                    kind == SendStructureKind.COMPOUND_INDEX_SET ||
                    kind == SendStructureKind.PREFIX ||
                    kind == SendStructureKind.POSTFIX ||
                    kind == SendStructureKind.INDEX_PREFIX ||
                    kind == SendStructureKind.INDEX_POSTFIX);
    if (semantics == null) {
      return internalError(node, 'No semantics for $node');
    }
    Selector selector = elements.getSelector(node);
    switch (kind) {
      case SendStructureKind.GET:
        return new GetStructure(semantics, selector);
      case SendStructureKind.SET:
        return new SetStructure(semantics, selector);
      case SendStructureKind.INVOKE:
        return new InvokeStructure(semantics, selector);
      case SendStructureKind.UNARY:
        return new UnaryStructure(semantics, unaryOperator, selector);
      case SendStructureKind.NOT:
        assert(selector == null);
        return new NotStructure(semantics, selector);
      case SendStructureKind.BINARY:
        return new BinaryStructure(semantics, binaryOperator, selector);
      case SendStructureKind.INDEX:
        return new IndexStructure(semantics, selector);
      case SendStructureKind.EQ:
        return new EqualsStructure(semantics, selector);
      case SendStructureKind.NOT_EQ:
        return new NotEqualsStructure(semantics, selector);
      case SendStructureKind.COMPOUND:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new CompoundStructure(
            semantics,
            assignmentOperator,
            getterSelector,
            selector);
      case SendStructureKind.INDEX_SET:
        return new IndexSetStructure(semantics, selector);
      case SendStructureKind.COMPOUND_INDEX_SET:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new CompoundIndexSetStructure(
            semantics,
            assignmentOperator,
            getterSelector,
            selector);
      case SendStructureKind.INDEX_PREFIX:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new IndexPrefixStructure(
            semantics,
            incDecOperator,
            getterSelector,
            selector);
      case SendStructureKind.INDEX_POSTFIX:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new IndexPostfixStructure(
            semantics,
            incDecOperator,
            getterSelector,
            selector);
      case SendStructureKind.PREFIX:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new PrefixStructure(
            semantics,
            incDecOperator,
            getterSelector,
            selector);
      case SendStructureKind.POSTFIX:
        Selector getterSelector =
            elements.getGetterSelectorInComplexSendSet(node);
        return new PostfixStructure(
            semantics,
            incDecOperator,
            getterSelector,
            selector);
    }
  }

  AccessSemantics computeAccessSemantics(Send node,
                                         {bool isGetOrSet: false,
                                          bool isInvoke: false,
                                          bool isCompound: false}) {
    Element element = elements[node];
    Element getter = isCompound ? elements[node.selector] : null;
    if (elements.isTypeLiteral(node)) {
      DartType dartType = elements.getTypeLiteralType(node);
      // TODO(johnniwinther): Handle deferred constants. There are runtime
      // but not compile-time constants and should have their own
      // [DeferredConstantExpression] class.
      ConstantExpression constant = elements.getConstant(
          isInvoke ? node.selector : node);
      switch (dartType.kind) {
        case TypeKind.INTERFACE:
          return new ConstantAccess.classTypeLiteral(constant);
        case TypeKind.TYPEDEF:
          return new ConstantAccess.typedefTypeLiteral(constant);
        case TypeKind.TYPE_VARIABLE:
          return new StaticAccess.typeParameterTypeLiteral(dartType.element);
        case TypeKind.DYNAMIC:
          return new ConstantAccess.dynamicTypeLiteral(constant);
        default:
          return internalError(node, "Unexpected type literal type: $dartType");
      }
    } else if (node.isSuperCall) {
      if (Elements.isUnresolved(element)) {
        return new StaticAccess.unresolved(element);
      } else if (isCompound && Elements.isUnresolved(getter)) {
        // TODO(johnniwinther): Ensure that [getter] is not null. This happens
        // in the case of missing super getter.
        return new StaticAccess.unresolved(getter);
      } else if (element.isField) {
        if (getter != null && getter != element) {
          CompoundAccessKind accessKind;
          if (getter.isField) {
            accessKind = CompoundAccessKind.SUPER_FIELD_FIELD;
          } else if (getter.isGetter) {
            accessKind = CompoundAccessKind.SUPER_GETTER_FIELD;
          } else {
            return internalError(node,
               "Unsupported super call: $node : $element/$getter.");
          }
          return new CompoundAccessSemantics(accessKind, getter, element);
        }
        return new StaticAccess.superField(element);
      } else if (element.isGetter) {
        return new StaticAccess.superGetter(element);
      } else if (element.isSetter) {
        if (getter != null) {
          CompoundAccessKind accessKind;
          if (getter.isField) {
            accessKind = CompoundAccessKind.SUPER_FIELD_SETTER;
          } else if (getter.isGetter) {
            accessKind = CompoundAccessKind.SUPER_GETTER_SETTER;
          } else {
            accessKind = CompoundAccessKind.SUPER_METHOD_SETTER;
          }
          return new CompoundAccessSemantics(accessKind, getter, element);
        }
        return new StaticAccess.superSetter(element);
      } else if (isCompound) {
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_GETTER_SETTER, getter, element);
      } else {
        return new StaticAccess.superMethod(element);
      }
    } else if (node.isOperator) {
      return new DynamicAccess.dynamicProperty(node.receiver);
    } else if (Elements.isClosureSend(node, element)) {
      if (element == null) {
        if (node.selector.isThis()) {
          return new AccessSemantics.thisAccess();
        } else {
          return new AccessSemantics.expression();
        }
      } else if (Elements.isErroneous(element)) {
        return new StaticAccess.unresolved(element);
      } else {
        return handleStaticallyResolvedAccess(node, element, getter);
      }
    } else {
      if (Elements.isErroneous(element)) {
        return new StaticAccess.unresolved(element);
      } else if (isCompound && Elements.isErroneous(getter)) {
        return new StaticAccess.unresolved(getter);
      } else if (element == null || element.isInstanceMember) {
        if (node.receiver == null || node.receiver.isThis()) {
          return new AccessSemantics.thisProperty();
        } else {
          return new DynamicAccess.dynamicProperty(node.receiver);
        }
      } else if (element.impliesType) {
        // TODO(johnniwinther): Provide an [ErroneousElement].
        // This happens for code like `C.this`.
        return new StaticAccess.unresolved(null);
      } else {
        return handleStaticallyResolvedAccess(node, element, getter);
      }
    }
  }

  ConstructorAccessSemantics computeConstructorAccessSemantics(
        ConstructorElement constructor,
        DartType type) {
    if (constructor.isErroneous) {
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.ERRONEOUS, constructor, type);
    } else if (constructor.isRedirectingFactory) {
      ConstructorElement effectiveTarget = constructor.effectiveTarget;
      if (effectiveTarget == constructor ||
          effectiveTarget.isErroneous) {
        return new ConstructorAccessSemantics(
            ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY,
            constructor,
            type);
      }
      ConstructorAccessSemantics effectiveTargetSemantics =
          computeConstructorAccessSemantics(
              effectiveTarget,
              constructor.computeEffectiveTargetType(type));
      if (effectiveTargetSemantics.isErroneous) {
        return new RedirectingFactoryConstructorAccessSemantics(
            ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY,
            constructor,
            type,
            effectiveTargetSemantics);
      }
      return new RedirectingFactoryConstructorAccessSemantics(
          ConstructorAccessKind.REDIRECTING_FACTORY,
          constructor,
          type,
          effectiveTargetSemantics);
    } else if (constructor.isFactoryConstructor) {
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.FACTORY, constructor, type);
    } else if (constructor.isRedirectingGenerative) {
      if (constructor.enclosingClass.isAbstract) {
          return new ConstructorAccessSemantics(
              ConstructorAccessKind.ABSTRACT, constructor, type);
      }
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.REDIRECTING_GENERATIVE, constructor, type);
    } else if (constructor.enclosingClass.isAbstract) {
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.ABSTRACT, constructor, type);
    } else {
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.GENERATIVE, constructor, type);
    }
  }

  NewStructure computeNewStructure(NewExpression node) {
    if (node.isConst) {
      return new ConstInvokeStructure(elements.getConstant(node));
    }
    Element element = elements[node.send];
    Selector selector = elements.getSelector(node.send);
    DartType type = elements.getType(node);

    ConstructorAccessSemantics constructorAccessSemantics =
        computeConstructorAccessSemantics(element, type);
    return new NewInvokeStructure(constructorAccessSemantics, selector);
  }
}

abstract class DeclStructure<R, A> {
  final FunctionElement element;

  DeclStructure(this.element);

  /// Calls the matching visit method on [visitor] with [node] and [arg].
  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             FunctionExpression node,
             A arg);
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

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             FunctionExpression node,
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
    throw new SpannableAssertionFailure(node,
        "Unhandled constructor declaration kind: ${kind}");
  }
}

class RedirectingFactoryConstructorDeclStructure<R, A>
    extends DeclStructure<R, A> {
  InterfaceType redirectionTargetType;
  ConstructorElement redirectionTarget;

  RedirectingFactoryConstructorDeclStructure(
      ConstructorElement constructor,
      this.redirectionTargetType,
      this.redirectionTarget)
      : super(constructor);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             FunctionExpression node,
             A arg) {
    return visitor.visitRedirectingFactoryConstructorDeclaration(
        node, element, node.parameters,
        redirectionTargetType, redirectionTarget, arg);
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

class FunctionDeclStructure<R, A>
    extends DeclStructure<R, A> {
  final FunctionKind kind;

  FunctionDeclStructure(this.kind, FunctionElement function)
      : super(function);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             FunctionExpression node,
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
        return visitor.visitAbstractGetterDeclaration(
            node, element, arg);
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

  InitializerStructure computeInitializerStructure(Send node) {
    Element element = elements[node];
    if (node.asSendSet() != null) {
      return new FieldInitializerStructure(element);
    } else if (Initializers.isConstructorRedirect(node)) {
      return new ThisConstructorInvokeStructure(
          element, elements.getSelector(node));
    } else if (Initializers.isSuperConstructorCall(node)) {
      return new SuperConstructorInvokeStructure(
          element,
          elements.analyzedElement.enclosingClass.supertype,
          elements.getSelector(node));
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
          list.add(computeParameterStructure(
              node, index++, isRequired: false, isNamed: isNamed));
        }
      } else {
        list.add(computeParameterStructure(node, index++));
      }
    }
    return list;
  }

  ParameterStructure computeParameterStructure(
      VariableDefinitions definitions,
      int index,
      {bool isRequired: true, bool isNamed: false}) {
    Node node = definitions.definitions.nodes.single;
    ParameterElement element = elements[node];
    if (element == null) {
      throw new SpannableAssertionFailure(
          node, "No parameter structure for $node.");
    }
    if (isRequired) {
      return new RequiredParameterStructure(
          definitions, node, element, index);
    } else {
      ConstantExpression defaultValue;
      if (element.initializer != null) {
        defaultValue = elements.getConstant(element.initializer);
      }
      if (isNamed) {
        return new NamedParameterStructure(
            definitions, node, element, defaultValue);
      } else {
        return new OptionalParameterStructure(
            definitions, node, element, defaultValue, index);
      }
    }
  }

  void computeVariableStructures(
      VariableDefinitions definitions,
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
