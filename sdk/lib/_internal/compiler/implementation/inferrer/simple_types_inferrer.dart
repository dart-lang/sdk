// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_types_inferrer;

import '../closure.dart' show ClosureClassMap, ClosureScope;
import '../dart_types.dart'
    show DartType, InterfaceType, FunctionType, TypeKind;
import '../elements/elements.dart';
import '../native_handler.dart' as native;
import '../tree/tree.dart';
import '../util/util.dart' show Link, Spannable, Setlet;
import '../types/types.dart'
    show TypesInferrer, FlatTypeMask, TypeMask, ContainerTypeMask,
         ElementTypeMask, TypeSystem, MinimalInferrerEngine;
import 'inferrer_visitor.dart';

// BUG(8802): There's a bug in the analyzer that makes the re-export
// of Selector from dart2jslib.dart fail. For now, we work around that
// by importing universe.dart explicitly and disabling the re-export.
import '../dart2jslib.dart' hide Selector, TypedSelector;
import '../universe/universe.dart' show Selector, SideEffects, TypedSelector;

/**
 * An implementation of [TypeSystem] for [TypeMask].
 */
class TypeMaskSystem implements TypeSystem<TypeMask> {
  final Compiler compiler;
  TypeMaskSystem(this.compiler);

  TypeMask narrowType(TypeMask type,
                      DartType annotation,
                      {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else if (annotation.isVoid) {
      otherType = nullType;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation.element);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type == null) return otherType;
    return type.intersection(otherType, compiler);
  }

  TypeMask computeLUB(TypeMask firstType, TypeMask secondType) {
    if (firstType == null) {
      return secondType;
    } else if (secondType == dynamicType || firstType == dynamicType) {
      return dynamicType;
    } else if (firstType == secondType) {
      return firstType;
    } else {
      TypeMask union = firstType.union(secondType, compiler);
      // TODO(kasperl): If the union isn't nullable it seems wasteful
      // to use dynamic. Fix that.
      return union.containsAll(compiler) ? dynamicType : union;
    }
  }

  TypeMask allocateDiamondPhi(TypeMask firstType, TypeMask secondType) {
    return computeLUB(firstType, secondType);
  }

  TypeMask get dynamicType => compiler.typesTask.dynamicType;
  TypeMask get nullType => compiler.typesTask.nullType;
  TypeMask get intType => compiler.typesTask.intType;
  TypeMask get doubleType => compiler.typesTask.doubleType;
  TypeMask get numType => compiler.typesTask.numType;
  TypeMask get boolType => compiler.typesTask.boolType;
  TypeMask get functionType => compiler.typesTask.functionType;
  TypeMask get listType => compiler.typesTask.listType;
  TypeMask get constListType => compiler.typesTask.constListType;
  TypeMask get fixedListType => compiler.typesTask.fixedListType;
  TypeMask get growableListType => compiler.typesTask.growableListType;
  TypeMask get mapType => compiler.typesTask.mapType;
  TypeMask get constMapType => compiler.typesTask.constMapType;
  TypeMask get stringType => compiler.typesTask.stringType;
  TypeMask get typeType => compiler.typesTask.typeType;
  bool isNull(TypeMask mask) => mask.isEmpty && mask.isNullable;

  TypeMask nonNullSubtype(ClassElement type)
      => new TypeMask.nonNullSubtype(type.declaration);
  TypeMask nonNullSubclass(ClassElement type)
      => new TypeMask.nonNullSubclass(type.declaration);
  TypeMask nonNullExact(ClassElement type)
      => new TypeMask.nonNullExact(type.declaration);
  TypeMask nonNullEmpty() => new TypeMask.nonNullEmpty();

  TypeMask allocateContainer(TypeMask type,
                             Node node,
                             Element enclosing,
                             [TypeMask elementType, int length]) {
    return new ContainerTypeMask(type, node, enclosing, elementType, length);
  }

  Selector newTypedSelector(TypeMask receiver, Selector selector) {
    return new TypedSelector(receiver, selector);
  }

  TypeMask addPhiInput(Element element, TypeMask phiType, TypeMask newType) {
    return computeLUB(phiType, newType);
  }

  TypeMask allocatePhi(Node node, Element element, TypeMask inputType) {
    return inputType;
  }

  TypeMask simplifyPhi(Node node, Element element, TypeMask phiType) {
    return phiType;
  }

  TypeMask refineReceiver(Selector selector, TypeMask receiverType) {
    TypeMask newType = compiler.world.allFunctions.receiverType(selector);
    return receiverType.intersection(newType, compiler);
  }
}

/**
 * Common super class used by [SimpleTypeInferrerVisitor] to propagate
 * type information about visited nodes, as well as to request type
 * information of elements.
 */
abstract class InferrerEngine<T, V extends TypeSystem>
    implements MinimalInferrerEngine<T> {
  final Compiler compiler;
  final V types;
  final Map<Node, T> concreteTypes = new Map<Node, T>();

  InferrerEngine(this.compiler, this.types);

  /**
   * Records the default type of parameter [parameter].
   */
  void setDefaultTypeOfParameter(Element parameter, T type);

  /**
   * Returns the type of [element].
   */
  T typeOfElement(Element element);

  /**
   * Returns the return type of [element].
   */
  T returnTypeOfElement(Element element);

  /**
   * Records that [node] sets final field [element] to be of type [type].
   *
   * [nodeHolder] is the element holder of [node].
   */
  void recordTypeOfFinalField(Node node,
                              Element nodeHolder,
                              Element field,
                              T type);

  /**
   * Records that [node] sets non-final field [element] to be of type
   * [type].
   */
  void recordTypeOfNonFinalField(Spannable node, Element field, T type);

  /**
   * Records that [element] is of type [type]. Returns whether the
   * type is useful for the inferrer.
   */
  bool recordType(Element element, T type);

  /**
   * Records that the return type [element] is of type [type].
   */
  void recordReturnType(Element element, T type);

  /**
   * Registers that [caller] calls [callee] at location [node], with
   * [selector], and [arguments]. Note that [selector] is null for
   * forwarding constructors.
   *
   * [sideEffects] will be updated to incorporate [callee]'s side
   * effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  T registerCalledElement(Spannable node,
                          Selector selector,
                          Element caller,
                          Element callee,
                          ArgumentsTypes<T> arguments,
                          SideEffects sideEffects,
                          bool inLoop);

  /**
   * Registers that [caller] calls [selector] with [receiverType] as
   * receiver, and [arguments].
   *
   * [sideEffects] will be updated to incorporate the potential
   * callees' side effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  T registerCalledSelector(Node node,
                           Selector selector,
                           T receiverType,
                           Element caller,
                           ArgumentsTypes<T> arguments,
                           SideEffects sideEffects,
                           bool inLoop);

  /**
   * Registers that [caller] calls [closure] with [arguments].
   *
   * [sideEffects] will be updated to incorporate the potential
   * callees' side effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  T registerCalledClosure(Node node,
                          Selector selector,
                          T closure,
                          Element caller,
                          ArgumentsTypes<T> arguments,
                          SideEffects sideEffects,
                          bool inLoop);

  /**
   * Returns the callers of [elements].
   */
  Iterable<Element> getCallersOf(Element element);

  /**
   * Notifies to the inferrer that [analyzedElement] can have return
   * type [newType]. [currentType] is the type the [InferrerVisitor]
   * currently found.
   *
   * Returns the new type for [analyzedElement].
   */
  T addReturnTypeFor(Element analyzedElement, T currentType, T newType);

  /**
   * Applies [f] to all elements in the universe that match
   * [selector]. If [f] returns false, aborts the iteration.
   */
  void forEachElementMatching(Selector selector, bool f(Element element)) {
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  /**
   * Update [sideEffects] with the side effects of [callee] being
   * called with [selector].
   */
  void updateSideEffects(SideEffects sideEffects,
                         Selector selector,
                         Element callee) {
    if (callee.isField()) {
      if (callee.isInstanceMember()) {
        if (selector.isSetter()) {
          sideEffects.setChangesInstanceProperty();
        } else if (selector.isGetter()) {
          sideEffects.setDependsOnInstancePropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        if (selector.isSetter()) {
          sideEffects.setChangesStaticProperty();
        } else if (selector.isGetter()) {
          sideEffects.setDependsOnStaticPropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      }
    } else if (callee.isGetter() && !selector.isGetter()) {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    } else {
      sideEffects.add(compiler.world.getSideEffectsOfElement(callee));
    }
  }

  /**
   * Returns the type for [nativeBehavior]. See documentation on
   * [native.NativeBehavior].
   */
  T typeOfNativeBehavior(native.NativeBehavior nativeBehavior) {
    if (nativeBehavior == null) return types.dynamicType;
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return types.dynamicType;
    T returnType;
    for (var type in typesReturned) {
      T mappedType;
      if (type == native.SpecialType.JsObject) {
        mappedType = types.nonNullExact(compiler.objectClass);
      } else if (type.element == compiler.stringClass) {
        mappedType = types.stringType;
      } else if (type.element == compiler.intClass) {
        mappedType = types.intType;
      } else if (type.element == compiler.doubleClass) {
        mappedType = types.doubleType;
      } else if (type.element == compiler.numClass) {
        mappedType = types.numType;
      } else if (type.element == compiler.boolClass) {
        mappedType = types.boolType;
      } else if (type.element == compiler.nullClass) {
        mappedType = types.nullType;
      } else if (type.isVoid) {
        mappedType = types.nullType;
      } else if (type.isDynamic) {
        return types.dynamicType;
      } else if (!compiler.world.hasAnySubtype(type.element)) {
        mappedType = types.nonNullExact(type.element);
      } else {
        ClassElement element = type.element;
        Set<ClassElement> subtypes = compiler.world.subtypesOf(element);
        Set<ClassElement> subclasses = compiler.world.subclassesOf(element);
        if (subclasses != null && subtypes.length == subclasses.length) {
          mappedType = types.nonNullSubclass(element);
        } else {
          mappedType = types.nonNullSubtype(element);
        }
      }
      returnType = types.computeLUB(returnType, mappedType);
      if (returnType == types.dynamicType) {
        break;
      }
    }
    return returnType;
  }

  void updateSelectorInTree(Element owner, Node node, Selector selector) {
    var elements = compiler.enqueuer.resolution.getCachedElements(owner);
    if (node.asSendSet() != null) {
      if (selector.isSetter() || selector.isIndexSet()) {
        elements.setSelector(node, selector);
      } else if (selector.isGetter() || selector.isIndex()) {
        elements.setGetterSelectorInComplexSendSet(node, selector);
      } else {
        assert(selector.isOperator());
        elements.setOperatorSelectorInComplexSendSet(node, selector);
      }
    } else if (node.asSend() != null) {
      elements.setSelector(node, selector);
    } else {
      assert(node.asForIn() != null);
      if (selector.asUntyped == compiler.iteratorSelector) {
        elements.setIteratorSelector(node, selector);
      } else if (selector.asUntyped == compiler.currentSelector) {
        elements.setCurrentSelector(node, selector);
      } else {
        assert(selector.asUntyped == compiler.moveNextSelector);
        elements.setMoveNextSelector(node, selector);
      }
    }
  }

  bool isNativeElement(Element element) {
    if (element.isNative()) return true;
    return element.isMember()
        && element.getEnclosingClass().isNative()
        && element.isField();
  }
}

class SimpleTypeInferrerVisitor<T>
    extends InferrerVisitor<T, InferrerEngine<T, TypeSystem<T>>> {
  T returnType;
  bool visitingInitializers = false;
  bool isConstructorRedirect = false;
  SideEffects sideEffects = new SideEffects.empty();
  final Element outermostElement;
  final InferrerEngine<T, TypeSystem<T>> inferrer;
  final Setlet<Element> capturedVariables = new Setlet<Element>();

  SimpleTypeInferrerVisitor.internal(analyzedElement,
                                     this.outermostElement,
                                     inferrer,
                                     compiler,
                                     locals)
    : super(analyzedElement, inferrer, inferrer.types, compiler, locals),
      this.inferrer = inferrer;

  factory SimpleTypeInferrerVisitor(Element element,
                                    Compiler compiler,
                                    InferrerEngine<T, TypeSystem<T>> inferrer,
                                    [LocalsHandler<T> handler]) {
    Element outermostElement =
        element.getOutermostEnclosingMemberOrTopLevel().implementation;
    assert(outermostElement != null);
    return new SimpleTypeInferrerVisitor<T>.internal(
        element, outermostElement, inferrer, compiler, handler);
  }

  T run() {
    var node = analyzedElement.parseNode(compiler);
    if (analyzedElement.isField() && node.asSendSet() == null) {
      // Eagerly bailout, because computing the closure data only
      // works for functions and field assignments.
      return types.nullType;
    }
    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureClassMap closureData =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            analyzedElement, node, elements);
    closureData.forEachBoxedVariable((variable, field) {
      locals.setCapturedAndBoxed(variable, field);
    });
    if (analyzedElement.isField()) {
      return visit(node.asSendSet().arguments.head);
    }

    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachOptionalParameter((element) {
      Node node = element.parseNode(compiler);
      Send send = node.asSendSet();
      T type = (send == null) ? types.nullType : visit(send.arguments.head);
      inferrer.setDefaultTypeOfParameter(element, type);
    });

    if (analyzedElement.isNative()) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      return types.dynamicType;
    }

    if (analyzedElement.isGenerativeConstructor()) {
      isThisExposed = false;
      signature.forEachParameter((element) {
        T parameterType = inferrer.typeOfElement(element);
        if (element.kind == ElementKind.FIELD_PARAMETER) {
          if (element.fieldElement.modifiers.isFinal()) {
            inferrer.recordTypeOfFinalField(
                node,
                analyzedElement,
                element.fieldElement,
                parameterType);
          } else {
            locals.updateField(element.fieldElement, parameterType);
            inferrer.recordTypeOfNonFinalField(
                element.parseNode(compiler),
                element.fieldElement,
                parameterType);
          }
        }
        locals.update(element, parameterType, node);
      });
      if (analyzedElement.isSynthesized) {
        node = analyzedElement;
        synthesizeForwardingCall(node, analyzedElement.targetConstructor);
      } else {
        visitingInitializers = true;
        visit(node.initializers);
        visitingInitializers = false;
        visit(node.body);
      }
      ClassElement cls = analyzedElement.getEnclosingClass();
      if (!isConstructorRedirect) {
        // Iterate over all instance fields, and give a null type to
        // fields that we haven't initialized for sure.
        cls.forEachInstanceField((_, field) {
          if (field.modifiers.isFinal()) return;
          T type = locals.fieldScope.readField(field);
          if (type == null && field.parseNode(compiler).asSendSet() == null) {
            inferrer.recordTypeOfNonFinalField(node, field, types.nullType);
          }
        });
      }
      returnType = types.nonNullExact(cls);
    } else {
      signature.forEachParameter((element) {
        locals.update(element, inferrer.typeOfElement(element), node);
      });
      visit(node.body);
      if (returnType == null) {
        // No return in the body.
        returnType = locals.seenReturnOrThrow
            ? types.nonNullEmpty()  // Body always throws.
            : types.nullType;
      } else if (!locals.seenReturnOrThrow) {
        // We haven't seen returns on all branches. So the method may
        // also return null.
        returnType = inferrer.addReturnTypeFor(
            analyzedElement, returnType, types.nullType);
      }
    }

    compiler.world.registerSideEffects(analyzedElement, sideEffects);
    assert(breaksFor.isEmpty);
    assert(continuesFor.isEmpty);
    return returnType;
  }

  T visitFunctionExpression(FunctionExpression node) {
    Element element = elements[node];
    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalsHandler closureLocals = new LocalsHandler<T>.from(
        locals, node, useOtherTryBlock: false);
    SimpleTypeInferrerVisitor visitor = new SimpleTypeInferrerVisitor<T>(
        element, compiler, inferrer, closureLocals);
    visitor.run();
    inferrer.recordReturnType(element, visitor.returnType);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure. Note that analyzing the same closure multiple
    // times closure will refine the type of those variables, therefore
    // [:inferrer.typeOf[variable]:] is not necessarilly null, nor the
    // same as [newType].
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    nestedClosureData.forEachCapturedVariable((variable, field) {
      if (!nestedClosureData.isVariableBoxed(variable)) {
        if (variable == nestedClosureData.thisElement) {
          inferrer.recordType(field, thisType);
        }
        // The type is null for type parameters.
        if (locals.locals[variable] == null) return;
        inferrer.recordType(field, locals.locals[variable]);
      }
      capturedVariables.add(variable);
    });

    return types.functionType;
  }

  T visitLiteralList(LiteralList node) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return inferrer.concreteTypes.putIfAbsent(node, () {
      T elementType;
      int length = 0;
      for (Node element in node.elements.nodes) {
        T type = visit(element);
        elementType = elementType == null
            ? types.allocatePhi(null, null, type)
            : types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? types.nonNullEmpty()
          : types.simplifyPhi(null, null, elementType);
      T containerType = node.isConst()
          ? types.constListType
          : types.growableListType;
      return types.allocateContainer(
          containerType,
          node,
          outermostElement,
          elementType,
          length);
    });
  }

  bool isThisOrSuper(Node node) => node.isThis() || node.isSuper();

  void checkIfExposesThis(Selector selector) {
    if (isThisExposed) return;
    inferrer.forEachElementMatching(selector, (element) {
      if (element.isField()) {
        if (!selector.isSetter()
            && element.getEnclosingClass() ==
                    outermostElement.getEnclosingClass()
            && !element.modifiers.isFinal()
            && locals.fieldScope.readField(element) == null
            && element.parseNode(compiler).asSendSet() == null) {
          // If the field is being used before this constructor
          // actually had a chance to initialize it, say it can be
          // null.
          inferrer.recordTypeOfNonFinalField(
              analyzedElement.parseNode(compiler), element,
              types.nullType);
        }
        // Accessing a field does not expose [:this:].
        return true;
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = true;
      return false;
    });
  }

  bool get inInstanceContext {
    return (outermostElement.isInstanceMember() && !outermostElement.isField())
        || outermostElement.isGenerativeConstructor();
  }

  bool treatAsInstanceMember(Element element) {
    return (Elements.isUnresolved(element) && inInstanceContext)
        || (element != null && element.isInstanceMember());
  }

  T visitSendSet(SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      node.visitChildren(this);
      return types.dynamicType;
    }

    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);

    String op = node.assignmentOperator.source;
    bool isIncrementOrDecrement = op == '++' || op == '--';

    T receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        receiverType = thisType;
        isCallOnThis = true;
      }
    } else {
      receiverType = visit(node.receiver);
      isCallOnThis = isThisOrSuper(node.receiver);
    }

    T rhsType;
    T indexType;

    if (isIncrementOrDecrement) {
      rhsType = types.intType;
      if (node.isIndex) indexType = visit(node.arguments.head);
    } else if (node.isIndex) {
      indexType = visit(node.arguments.head);
      rhsType = visit(node.arguments.tail.head);
    } else {
      rhsType = visit(node.arguments.head);
    }

    if (!visitingInitializers && !isThisExposed) {
      for (Node node in node.arguments) {
        if (isThisOrSuper(node)) {
          isThisExposed = true;
          break;
        }
      }
      if (!isThisExposed && isCallOnThis) {
        checkIfExposesThis(
            types.newTypedSelector(receiverType, setterSelector));
        if (getterSelector != null) {
          checkIfExposesThis(
              types.newTypedSelector(receiverType, getterSelector));
        }
      }
    }

    if (node.isIndex) {
      if (op == '=') {
        // [: foo[0] = 42 :]
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType, rhsType], null));
        return rhsType;
      } else {
        // [: foo[0] += 42 :] or [: foo[0]++ :].
        T getterType = handleDynamicSend(
            node,
            getterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType], null));
        T returnType = handleDynamicSend(
            node,
            operatorSelector,
            getterType,
            new ArgumentsTypes<T>([rhsType], null));
        handleDynamicSend(
            node,
            setterSelector,
            receiverType,
            new ArgumentsTypes<T>([indexType, returnType], null));

        if (node.isPostfix) {
          return getterType;
        } else {
          return returnType;
        }
      }
    } else if (op == '=') {
      return handlePlainAssignment(
          node, element, setterSelector, receiverType, rhsType,
          node.arguments.head);
    } else {
      // [: foo++ :] or [: foo += 1 :].
      ArgumentsTypes operatorArguments = new ArgumentsTypes<T>([rhsType], null);
      T getterType;
      T newType;
      if (Elements.isErroneousElement(element)) {
        getterType = types.dynamicType;
        newType = types.dynamicType;
      } else if (Elements.isStaticOrTopLevelField(element)) {
        Element getterElement = elements[node.selector];
        getterType =
            handleStaticSend(node, getterSelector, getterElement, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleStaticSend(
            node, setterSelector, element,
            new ArgumentsTypes<T>([newType], null));
      } else if (Elements.isUnresolved(element)
                 || element.isSetter()
                 || element.isField()) {
        getterType = handleDynamicSend(
            node, getterSelector, receiverType, null);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        handleDynamicSend(node, setterSelector, receiverType,
                          new ArgumentsTypes<T>([newType], null));
      } else if (Elements.isLocal(element)) {
        getterType = locals.use(element);
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
        locals.update(element, newType, node);
      } else {
        // Bogus SendSet, for example [: myMethod += 42 :].
        getterType = types.dynamicType;
        newType = handleDynamicSend(
            node, operatorSelector, getterType, operatorArguments);
      }

      if (node.isPostfix) {
        return getterType;
      } else {
        return newType;
      }
    }
  }

  T handlePlainAssignment(Node node,
                          Element element,
                          Selector setterSelector,
                          T receiverType,
                          T rhsType,
                          Node rhs) {
    ArgumentsTypes arguments = new ArgumentsTypes<T>([rhsType], null);
    if (Elements.isErroneousElement(element)) {
      // Code will always throw.
    } else if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, setterSelector, element, arguments);
    } else if (Elements.isUnresolved(element) || element.isSetter()) {
      handleDynamicSend(
          node, setterSelector, receiverType, arguments);
    } else if (element.isField()) {
      if (element.modifiers.isFinal()) {
        inferrer.recordTypeOfFinalField(
            node, outermostElement, element, rhsType);
      } else {
        if (analyzedElement.isGenerativeConstructor()) {
          locals.updateField(element, rhsType);
        }
        if (visitingInitializers) {
          inferrer.recordTypeOfNonFinalField(node, element, rhsType);
        } else {
          handleDynamicSend(
              node, setterSelector, receiverType, arguments);
        }
      }
    } else if (Elements.isLocal(element)) {
      locals.update(element, rhsType, node);
    }
    return rhsType;
  }

  T visitSuperSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    // TODO(ngeoffray): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    ArgumentsTypes arguments = node.isPropertyAccess
        ? null
        : analyzeArguments(node.arguments);
    if (Elements.isUnresolved(element)
        || !selector.applies(element, compiler)) {
      // Ensure we create a node, to make explicit the call to the
      // `noSuchMethod` handler.
      return handleDynamicSend(node, selector, superType, arguments);
    } else if (node.isPropertyAccess
              || element.isFunction()
              || element.isGenerativeConstructor()) {
      return handleStaticSend(node, selector, element, arguments);
    } else {
      return inferrer.registerCalledClosure(
          node, selector, inferrer.typeOfElement(element),
          outermostElement, arguments, sideEffects, inLoop);
    }
  }

  T visitStaticSend(Send node) {
    if (visitingInitializers && Initializers.isConstructorRedirect(node)) {
      isConstructorRedirect = true;
    }
    Element element = elements[node];
    if (element.isForeign(compiler)) {
      return handleForeignSend(node);
    }
    Selector selector = elements.getSelector(node);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (!selector.applies(element, compiler)) return types.dynamicType;

    T returnType = handleStaticSend(node, selector, element, arguments);
    if (Elements.isGrowableListConstructorCall(element, node, compiler)) {
      return inferrer.concreteTypes.putIfAbsent(
          node, () => types.allocateContainer(
              types.growableListType, node, outermostElement,
              types.nonNullEmpty(), 0));
    } else if (Elements.isFixedListConstructorCall(element, node, compiler)
        || Elements.isFilledListConstructorCall(element, node, compiler)) {

      int initialLength;
      T elementType;
      if (Elements.isFixedListConstructorCall(element, node, compiler)) {
        LiteralInt length = node.arguments.head.asLiteralInt();
        if (length != null) {
          initialLength = length.value;
        }
        elementType = types.nullType;
      } else {
        LiteralInt length = node.arguments.head.asLiteralInt();
        if (length != null) {
          initialLength = length.value;
        }
        elementType = arguments.positional[1];
      }

      return inferrer.concreteTypes.putIfAbsent(
          node, () => types.allocateContainer(
              types.fixedListType, node, outermostElement,
              elementType, initialLength));
    } else if (Elements.isConstructorOfTypedArraySubclass(element, compiler)) {
      int initialLength;
      LiteralInt length = node.arguments.head.asLiteralInt();
      if (length != null) {
        initialLength = length.value;
      }
      T elementType = inferrer.returnTypeOfElement(
          element.getEnclosingClass().lookupMember('[]'));
      return inferrer.concreteTypes.putIfAbsent(
        node, () => types.allocateContainer(
          types.nonNullExact(element.getEnclosingClass()), node,
          outermostElement, elementType, initialLength));
    } else if (element.isFunction() || element.isConstructor()) {
      return returnType;
    } else {
      assert(element.isField() || element.isGetter());
      return inferrer.registerCalledClosure(
          node, selector, inferrer.typeOfElement(element),
          outermostElement, arguments, sideEffects, inLoop);
    }
  }

  T handleForeignSend(Send node) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    String name = selector.name;
    handleStaticSend(node, selector, elements[node], arguments);
    if (name == 'JS') {
      native.NativeBehavior nativeBehavior =
          compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
      sideEffects.add(nativeBehavior.sideEffects);
      return inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == 'JS_OPERATOR_IS_PREFIX'
               || name == 'JS_OPERATOR_AS_PREFIX'
               || name == 'JS_OBJECT_CLASS_NAME'
               || name == 'JS_NULL_CLASS_NAME') {
      return types.stringType;
    } else {
      sideEffects.setAllSideEffects();
      return types.dynamicType;
    }
  }

  ArgumentsTypes analyzeArguments(Link<Node> arguments) {
    List<T> positional = [];
    Map<String, T> named;
    for (var argument in arguments) {
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        argument = namedArgument.expression;
        if (named == null) named = new Map<String, T>();
        named[namedArgument.name.source] = argument.accept(this);
      } else {
        positional.add(argument.accept(this));
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = isThisExposed || argument.isThis();
    }
    return new ArgumentsTypes<T>(positional, named);
  }

  T visitGetterSend(Send node) {
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (Elements.isStaticOrTopLevelField(element)) {
      return handleStaticSend(node, selector, element, null);
    } else if (Elements.isInstanceSend(node, elements)) {
      return visitDynamicSend(node);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      return handleStaticSend(node, selector, element, null);
    } else if (Elements.isErroneousElement(element)) {
      return types.dynamicType;
    } else if (Elements.isLocal(element)) {
      assert(locals.use(element) != null);
      return locals.use(element);
    } else {
      assert(element is PrefixElement);
      return null;
    }
  }

  T visitClosureSend(Send node) {
    assert(node.receiver == null);
    T closure = node.selector.accept(this);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    if (element != null && element.isFunction()) {
      assert(Elements.isLocal(element));
      // This only works for function statements. We need a
      // more sophisticated type system with function types to support
      // more.
      return inferrer.registerCalledElement(
          node, selector, outermostElement, element, arguments,
          sideEffects, inLoop);
    } else {
      return inferrer.registerCalledClosure(
          node, selector, closure, outermostElement, arguments,
          sideEffects, inLoop);
    }
  }

  T handleStaticSend(Node node,
                     Selector selector,
                     Element element,
                     ArgumentsTypes arguments) {
    if (Elements.isUnresolved(element)) return types.dynamicType;
    return inferrer.registerCalledElement(
        node, selector, outermostElement, element, arguments,
        sideEffects, inLoop);
  }

  T handleDynamicSend(Node node,
                      Selector selector,
                      T receiverType,
                      ArgumentsTypes arguments) {
    assert(receiverType != null);
    if (selector.mask != receiverType) {
      selector = (receiverType == types.dynamicType)
          ? selector.asUntyped
          : types.newTypedSelector(receiverType, selector);
      inferrer.updateSelectorInTree(analyzedElement, node, selector);
    }

    // If the receiver of the call is a local, we may know more about
    // its type by refining it with the potential targets of the
    // calls.
    if (node.asSend() != null) {
      Node receiver = node.asSend().receiver;
      if (receiver != null) {
        Element element = elements[receiver];
        if (Elements.isLocal(element) && !capturedVariables.contains(element)) {
          T refinedType = types.refineReceiver(selector, receiverType);
          locals.update(element, refinedType, node);
        }
      }
    }

    return inferrer.registerCalledSelector(
        node, selector, receiverType, outermostElement, arguments,
        sideEffects, inLoop);
  }

  T visitDynamicSend(Send node) {
    Element element = elements[node];
    T receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        isCallOnThis = true;
        receiverType = thisType;
      }
    } else {
      Node receiver = node.receiver;
      isCallOnThis = isThisOrSuper(receiver);
      receiverType = visit(receiver);
    }

    Selector selector = elements.getSelector(node);
    if (!isThisExposed && isCallOnThis) {
      checkIfExposesThis(types.newTypedSelector(receiverType, selector));
    }

    ArgumentsTypes arguments = node.isPropertyAccess
        ? null
        : analyzeArguments(node.arguments);
    if (selector.name == '=='
        || selector.name == '!=') {
      if (types.isNull(receiverType)) {
        potentiallyAddNullCheck(node, node.arguments.head);
        return types.boolType;
      } else if (types.isNull(arguments.positional[0])) {
        potentiallyAddNullCheck(node, node.receiver);
        return types.boolType;
      }
    }
    return handleDynamicSend(node, selector, receiverType, arguments);
  }

  void recordReturnType(T type) {
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  T synthesizeForwardingCall(Spannable node, FunctionElement element) {
    element = element.implementation;
    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.computeSignature(compiler);
    FunctionSignature calleeSignature = element.computeSignature(compiler);
    if (!calleeSignature.isCompatibleWith(signature)) {
      return types.nonNullEmpty();
    }

    List<T> unnamed = <T>[];
    signature.forEachRequiredParameter((Element element) {
      assert(locals.use(element) != null);
      unnamed.add(locals.use(element));
    });

    Map<String, T> named;
    if (signature.optionalParametersAreNamed) {
      named = new Map<String, T>();
      signature.forEachOptionalParameter((Element element) {
        named[element.name] = locals.use(element);
      });
    } else {
      signature.forEachOptionalParameter((Element element) {
        unnamed.add(locals.use(element));
      });
    }

    ArgumentsTypes arguments = new ArgumentsTypes<T>(unnamed, named);
    return inferrer.registerCalledElement(node,
                                          null,
                                          outermostElement,
                                          element,
                                          arguments,
                                          sideEffects,
                                          inLoop);
  }

  T visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      Element element = elements[node.expression];
      if (Elements.isErroneousElement(element)) {
        recordReturnType(types.dynamicType);
      } else {
        // We don't create a selector for redirecting factories, and
        // the send is just a property access. Therefore we must
        // manually create the [ArgumentsTypes] of the call, and
        // manually register [analyzedElement] as a caller of [element].
        T mask = synthesizeForwardingCall(node.expression, element);
        recordReturnType(mask);
      }
    } else {
      Node expression = node.expression;
      recordReturnType(expression == null
          ? types.nullType
          : expression.accept(this));
    }
    locals.seenReturnOrThrow = true;
  }

  T visitForIn(ForIn node) {
    T expressionType = visit(node.expression);
    Selector iteratorSelector = elements.getIteratorSelector(node);
    Selector currentSelector = elements.getCurrentSelector(node);
    Selector moveNextSelector = elements.getMoveNextSelector(node);

    T iteratorType =
        handleDynamicSend(node, iteratorSelector, expressionType, null);
    handleDynamicSend(node, moveNextSelector,
                      iteratorType, new ArgumentsTypes<T>([], null));
    T currentType =
        handleDynamicSend(node, currentSelector, iteratorType, null);

    if (node.expression.isThis()) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      isThisExposed = true;
    }

    Node identifier = node.declaredIdentifier;
    Element element = elements[identifier];
    Selector selector = elements.getSelector(identifier);

    T receiverType;
    if (element != null && element.isInstanceMember()) {
      receiverType = thisType;
    } else {
      receiverType = types.dynamicType;
    }

    handlePlainAssignment(identifier, element, selector,
                          receiverType, currentType,
                          node.expression);
    return handleLoop(node, () {
      visit(node.body);
    });
  }
}
