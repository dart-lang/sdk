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

  AccessSemantics handleCompoundErroneousSetterAccess(
      Send node,
      Element setter,
      Element getter) {
    assert(invariant(node, Elements.isUnresolved(setter),
        message: "Unexpected erreneous compound setter: $setter."));
    if (getter.isStatic) {
      if (getter.isGetter) {
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_STATIC_SETTER, getter, setter);
      } else if (getter.isField) {
        // TODO(johnniwinther): Handle const field separately.
        assert(invariant(node, getter.isFinal || getter.isConst,
            message: "Field expected to be final or const."));
        return new StaticAccess.finalStaticField(getter);
      } else if (getter.isFunction) {
        return new StaticAccess.staticMethod(getter);
      } else {
        return internalError(node,
            "Unexpected erroneous static compound: getter=$getter");
      }
    } else if (getter.isTopLevel) {
      if (getter.isGetter) {
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_TOPLEVEL_SETTER, getter, setter);
      } else if (getter.isField) {
        // TODO(johnniwinther): Handle const field separately.
        assert(invariant(node, getter.isFinal || getter.isConst,
            message: "Field expected to be final or const."));
        return new StaticAccess.finalTopLevelField(getter);
      } else if (getter.isFunction) {
        return new StaticAccess.topLevelMethod(getter);
      } else {
        return internalError(node,
            "Unexpected erroneous top level compound: getter=$getter");
      }
    } else if (getter.isParameter) {
      assert(invariant(node, getter.isFinal,
          message: "Parameter expected to be final."));
      return new StaticAccess.finalParameter(getter);
    } else if (getter.isLocal) {
      if (getter.isVariable) {
        // TODO(johnniwinther): Handle const variable separately.
        assert(invariant(node, getter.isFinal || getter.isConst,
            message: "Variable expected to be final or const."));
        return new StaticAccess.finalLocalVariable(getter);
      } else if (getter.isFunction) {
        return new StaticAccess.localFunction(getter);
      } else {
        return internalError(node,
            "Unexpected erroneous local compound: getter=$getter");
      }
    } else if (getter.isErroneous) {
      return new StaticAccess.unresolved(getter);
    } else {
      return internalError(node,
          "Unexpected erroneous compound: getter=$getter");
    }
  }

  AccessSemantics handleStaticallyResolvedAccess(
      Send node,
      Element element,
      Element getter,
      {bool isCompound}) {
    if (element == null) {
      assert(invariant(node, isCompound, message:
        "Non-compound static access without element."));
      assert(invariant(node, getter != null, message:
        "Compound static access without element."));
      return handleCompoundErroneousSetterAccess(node, element, getter);
    }
    if (element.isErroneous) {
      if (isCompound) {
        return handleCompoundErroneousSetterAccess(node, element, getter);
      }
      return new StaticAccess.unresolved(element);
    } else if (element.isParameter) {
      if (element.isFinal) {
        return new StaticAccess.finalParameter(element);
      } else {
        return new StaticAccess.parameter(element);
      }
    } else if (element.isLocal) {
      if (element.isFunction) {
        return new StaticAccess.localFunction(element);
      } else if (element.isFinal || element.isConst) {
        return new StaticAccess.finalLocalVariable(element);
      } else {
        return new StaticAccess.localVariable(element);
      }
    } else if (element.isStatic) {
      if (element.isField) {
        if (element.isFinal || element.isConst) {
          // TODO(johnniwinther): Handle const field separately.
          return new StaticAccess.finalStaticField(element);
        }
        return new StaticAccess.staticField(element);
      } else if (element.isGetter) {
        if (isCompound) {
          return new CompoundAccessSemantics(
              CompoundAccessKind.UNRESOLVED_STATIC_SETTER, element, null);
        }
        return new StaticAccess.staticGetter(element);
      } else if (element.isSetter) {
        if (getter != null) {
          CompoundAccessKind accessKind;
          if (getter.isErroneous) {
            accessKind = CompoundAccessKind.UNRESOLVED_STATIC_GETTER;
          } else if (getter.isAbstractField) {
            AbstractFieldElement abstractField = getter;
            if (abstractField.getter == null) {
              accessKind = CompoundAccessKind.UNRESOLVED_STATIC_GETTER;
            } else {
              // TODO(johnniwinther): This might be dead code.
              getter = abstractField.getter;
              accessKind = CompoundAccessKind.STATIC_GETTER_SETTER;
            }
          } else if (getter.isGetter) {
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
        if (element.isFinal || element.isConst) {
          // TODO(johnniwinther): Handle const field separately.
          return new StaticAccess.finalTopLevelField(element);
        }
        return new StaticAccess.topLevelField(element);
      } else if (element.isGetter) {
        return new StaticAccess.topLevelGetter(element);
      } else if (element.isSetter) {
        if (getter != null) {
          CompoundAccessKind accessKind;
          if (getter.isErroneous) {
            accessKind = CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER;
          } else if (getter.isAbstractField) {
            AbstractFieldElement abstractField = getter;
            if (abstractField.getter == null) {
              accessKind = CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER;
            } else {
              // TODO(johnniwinther): This might be dead code.
              getter = abstractField.getter;
              accessKind = CompoundAccessKind.TOPLEVEL_GETTER_SETTER;
            }
          } else if (getter.isGetter) {
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
    SendStructure sendStructure = elements.getSendStructure(node);
    if (sendStructure != null) {
      return sendStructure;
    }

    if (elements.isAssert(node)) {
      return internalError(node, "Unexpected assert.");
    }

    AssignmentOperator assignmentOperator;
    BinaryOperator binaryOperator;
    IncDecOperator incDecOperator;

    if (node.isOperator) {
      String operatorText = node.selector.asOperator().source;
      if (operatorText == 'is') {
        return internalError(node, "Unexpected is test.");
      } else if (operatorText == 'as') {
        return internalError(node, "Unexpected as cast.");
      } else if (operatorText == '&&') {
        return internalError(node, "Unexpected logical and.");
      } else if (operatorText == '||') {
        return internalError(node, "Unexpected logical or.");
      } else if (operatorText == '??') {
        return internalError(node, "Unexpected if-null.");
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
        return internalError(node, "Unexpected unary $operatorText.");
      } else {
        binaryOperator = BinaryOperator.parse(operatorText);
        if (binaryOperator != null) {
          switch (binaryOperator.kind) {
            case BinaryOperatorKind.EQ:
              kind = SendStructureKind.EQ;
              return internalError(node, "Unexpected binary $kind.");
            case BinaryOperatorKind.NOT_EQ:
              kind = SendStructureKind.NOT_EQ;
              return internalError(node, "Unexpected binary $kind.");
            case BinaryOperatorKind.INDEX:
              if (node.isPrefix) {
                kind = SendStructureKind.INDEX_PREFIX;
              } else if (node.isPostfix) {
                kind = SendStructureKind.INDEX_POSTFIX;
              } else if (node.arguments.tail.isEmpty) {
                // a[b]
                kind = SendStructureKind.INDEX;
                return internalError(node, "Unexpected binary $kind.");
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
              return internalError(node, "Unexpected binary $kind.");
          }
        } else {
          return internalError(
              node, "Unexpected invalid binary $operatorText.");
        }
      }
    }
    AccessSemantics semantics = computeAccessSemantics(
        node,
        isSet: kind == SendStructureKind.SET,
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
        switch (semantics.kind) {
          case AccessKind.STATIC_METHOD:
          case AccessKind.SUPER_METHOD:
          case AccessKind.TOPLEVEL_METHOD:
            // TODO(johnniwinther): Should local function also be handled here?
            FunctionElement function = semantics.element;
            FunctionSignature signature = function.functionSignature;
            if (!selector.callStructure.signatureApplies(signature)) {
              return new IncompatibleInvokeStructure(semantics, selector);
            }
            break;
          default:
            break;
        }
        return new InvokeStructure(semantics, selector);
      case SendStructureKind.UNARY:
        return internalError(node, "Unexpected unary.");
      case SendStructureKind.NOT:
        return internalError(node, "Unexpected not.");
      case SendStructureKind.BINARY:
        return internalError(node, "Unexpected binary.");
      case SendStructureKind.INDEX:
        return internalError(node, "Unexpected index.");
      case SendStructureKind.EQ:
        return internalError(node, "Unexpected equals.");
      case SendStructureKind.NOT_EQ:
        return internalError(node, "Unexpected not equals.");
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
                                         {bool isSet: false,
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
          isInvoke || isSet || isCompound ? node.selector : node);
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
        if (isCompound) {
          if (Elements.isUnresolved(getter)) {
            // TODO(johnniwinther): Ensure that [getter] is not null. This
            // happens in the case of missing super getter.
            return new StaticAccess.unresolvedSuper(element);
          } else if (getter.isField) {
            assert(invariant(node, getter.isFinal,
                message: "Super field expected to be final."));
            return new StaticAccess.superFinalField(getter);
          } else if (getter.isFunction) {
            if (node.isIndex) {
              return new CompoundAccessSemantics(
                  CompoundAccessKind.UNRESOLVED_SUPER_SETTER, getter, element);
            } else {
              return new StaticAccess.superMethod(getter);
            }
          } else {
            return new CompoundAccessSemantics(
                CompoundAccessKind.UNRESOLVED_SUPER_SETTER, getter, element);
          }
        } else {
          return new StaticAccess.unresolvedSuper(element);
        }
      } else if (isCompound && Elements.isUnresolved(getter)) {
        // TODO(johnniwinther): Ensure that [getter] is not null. This happens
        // in the case of missing super getter.
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_SUPER_GETTER, getter, element);
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
        } else if (element.isFinal) {
          return new StaticAccess.superFinalField(element);
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
    } else if (node.isConditional) {
      // Conditional sends (e?.x) are treated as dynamic property reads because
      // they are equivalent to do ((a) => a == null ? null : a.x)(e). If `e` is
      // a type `A`, this is equivalent to write `(A).x`.
      return new DynamicAccess.ifNotNullProperty(node.receiver);
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
        return handleStaticallyResolvedAccess(
            node, element, getter, isCompound: isCompound);
      }
    } else {
      bool isDynamicAccess(Element e) => e == null || e.isInstanceMember;

      if (isDynamicAccess(element) &&
           (!isCompound || isDynamicAccess(getter))) {
        if (node.receiver == null || node.receiver.isThis()) {
          return new AccessSemantics.thisProperty();
        } else {
          return new DynamicAccess.dynamicProperty(node.receiver);
        }
      } else if (element != null && element.impliesType) {
        // TODO(johnniwinther): Provide an [ErroneousElement].
        // This happens for code like `C.this`.
        return new StaticAccess.unresolved(null);
      } else {
        return handleStaticallyResolvedAccess(
            node, element, getter, isCompound: isCompound);
      }
    }
  }

  ConstructorAccessSemantics computeConstructorAccessSemantics(
        ConstructorElement constructor,
        CallStructure callStructure,
        DartType type,
        {bool mustBeConstant: false}) {
    if (mustBeConstant && !constructor.isConst) {
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.NON_CONSTANT_CONSTRUCTOR, constructor, type);
    }
    if (constructor.isErroneous) {
      if (constructor is ErroneousElement) {
        ErroneousElement error = constructor;
        if (error.messageKind == MessageKind.CANNOT_FIND_CONSTRUCTOR) {
          return new ConstructorAccessSemantics(
              ConstructorAccessKind.UNRESOLVED_CONSTRUCTOR, constructor, type);
        }
      }
      return new ConstructorAccessSemantics(
          ConstructorAccessKind.UNRESOLVED_TYPE, constructor, type);
    } else if (constructor.isRedirectingFactory) {
      ConstructorElement effectiveTarget = constructor.effectiveTarget;
      if (effectiveTarget == constructor ||
          effectiveTarget.isErroneous ||
          (mustBeConstant && !effectiveTarget.isConst)) {
        return new ConstructorAccessSemantics(
            ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY,
            constructor,
            type);
      }
      ConstructorAccessSemantics effectiveTargetSemantics =
          computeConstructorAccessSemantics(
              effectiveTarget,
              callStructure,
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
    } else {
      if (!callStructure.signatureApplies(constructor.functionSignature)) {
        return new ConstructorAccessSemantics(
            ConstructorAccessKind.INCOMPATIBLE,
            constructor,
            type);
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
  }

  NewStructure computeNewStructure(NewExpression node) {
    Element element = elements[node.send];
    Selector selector = elements.getSelector(node.send);
    DartType type = elements.getType(node);

    ConstructorAccessSemantics constructorAccessSemantics =
        computeConstructorAccessSemantics(
            element, selector.callStructure, type,
            mustBeConstant: node.isConst);
    if (node.isConst) {
      ConstantExpression constant = elements.getConstant(node);
      if (constructorAccessSemantics.isErroneous ||
          constant == null ||
          constant.kind == ConstantExpressionKind.ERRONEOUS) {
        // This is a non-constant constant constructor invocation, like
        // `const Const(method())`.
        constructorAccessSemantics = new ConstructorAccessSemantics(
            ConstructorAccessKind.NON_CONSTANT_CONSTRUCTOR, element, type);
      } else {
        ConstantInvokeKind kind;
        switch (constant.kind) {
          case ConstantExpressionKind.CONSTRUCTED:
            kind = ConstantInvokeKind.CONSTRUCTED;
            break;
          case ConstantExpressionKind.BOOL_FROM_ENVIRONMENT:
            kind = ConstantInvokeKind.BOOL_FROM_ENVIRONMENT;
            break;
          case ConstantExpressionKind.INT_FROM_ENVIRONMENT:
            kind = ConstantInvokeKind.INT_FROM_ENVIRONMENT;
            break;
          case ConstantExpressionKind.STRING_FROM_ENVIRONMENT:
            kind = ConstantInvokeKind.STRING_FROM_ENVIRONMENT;
            break;
          default:
            return internalError(
                node, "Unexpected constant kind $kind: ${constant.getText()}");
        }
        return new ConstInvokeStructure(kind, constant);
      }
    }
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
      InterfaceType supertype = currentClass.supertype;
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
