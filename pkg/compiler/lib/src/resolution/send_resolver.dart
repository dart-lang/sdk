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

