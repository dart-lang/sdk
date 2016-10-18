// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_types_inferrer;

import '../closure.dart' show ClosureClassMap;
import '../common.dart';
import '../common/names.dart' show Selectors;
import '../compiler.dart' show Compiler;
import '../constants/values.dart' show ConstantValue, IntConstantValue;
import '../core_types.dart' show CoreClasses, CoreTypes;
import '../dart_types.dart' show DartType;
import '../elements/elements.dart';
import '../js_backend/js_backend.dart' as js;
import '../native/native.dart' as native;
import '../resolution/operators.dart' as op;
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart' as ast;
import '../types/types.dart' show TypeMask;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart' show Link, Setlet;
import '../world.dart' show ClosedWorld;
import 'inferrer_visitor.dart';

/**
 * Common super class used by [SimpleTypeInferrerVisitor] to propagate
 * type information about visited nodes, as well as to request type
 * information of elements.
 */
abstract class InferrerEngine<T, V extends TypeSystem>
    implements MinimalInferrerEngine<T> {
  final Compiler compiler;
  final ClosedWorld closedWorld;
  final V types;
  final Map<ast.Node, T> concreteTypes = new Map<ast.Node, T>();
  final Set<Element> generativeConstructorsExposingThis = new Set<Element>();

  InferrerEngine(Compiler compiler, this.types)
      : this.compiler = compiler,
        this.closedWorld = compiler.closedWorld;

  CoreClasses get coreClasses => compiler.coreClasses;

  CoreTypes get coreTypes => compiler.coreTypes;

  /**
   * Records the default type of parameter [parameter].
   */
  void setDefaultTypeOfParameter(ParameterElement parameter, T type);

  /**
   * This helper breaks abstractions but is currently required to work around
   * the wrong modelling of default values of optional parameters of
   * synthetic constructors.
   *
   * TODO(johnniwinther): Remove once default values of synthetic parameters
   * are fixed.
   */
  bool hasAlreadyComputedTypeOfParameterDefault(ParameterElement paramemter);

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
  void recordTypeOfFinalField(
      ast.Node node, Element nodeHolder, Element field, T type);

  /**
   * Records that [node] sets non-final field [element] to be of type
   * [type].
   */
  void recordTypeOfNonFinalField(Spannable node, Element field, T type);

  /**
   * Records that [element] is of type [type].
   */
  void recordType(Element element, T type);

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
  T registerCalledElement(
      Spannable node,
      Selector selector,
      TypeMask mask,
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
  T registerCalledSelector(
      ast.Node node,
      Selector selector,
      TypeMask mask,
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
  T registerCalledClosure(
      ast.Node node,
      Selector selector,
      TypeMask mask,
      T closure,
      Element caller,
      ArgumentsTypes<T> arguments,
      SideEffects sideEffects,
      bool inLoop);

  /**
   * Registers a call to await with an expression of type [argumentType] as
   * argument.
   */
  T registerAwait(ast.Node node, T argumentType);

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
   * [selector] and [mask]. If [f] returns false, aborts the iteration.
   */
  void forEachElementMatching(
      Selector selector, TypeMask mask, bool f(Element element)) {
    Iterable<Element> elements =
        compiler.closedWorld.allFunctions.filter(selector, mask);
    for (Element e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  /**
   * Update [sideEffects] with the side effects of [callee] being
   * called with [selector].
   */
  void updateSideEffects(
      SideEffects sideEffects, Selector selector, Element callee) {
    if (callee.isField) {
      if (callee.isInstanceMember) {
        if (selector.isSetter) {
          sideEffects.setChangesInstanceProperty();
        } else if (selector.isGetter) {
          sideEffects.setDependsOnInstancePropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        if (selector.isSetter) {
          sideEffects.setChangesStaticProperty();
        } else if (selector.isGetter) {
          sideEffects.setDependsOnStaticPropertyStore();
        } else {
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      }
    } else if (callee.isGetter && !selector.isGetter) {
      sideEffects.setAllSideEffects();
      sideEffects.setDependsOnSomething();
    } else {
      sideEffects
          .add(compiler.inferenceWorld.getCurrentlyKnownSideEffects(callee));
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
        mappedType = types.nonNullExact(coreClasses.objectClass);
      } else if (type == coreTypes.stringType) {
        mappedType = types.stringType;
      } else if (type == coreTypes.intType) {
        mappedType = types.intType;
      } else if (type == coreTypes.numType || type == coreTypes.doubleType) {
        // Note: the backend double class is specifically for non-integer
        // doubles, and a native behavior returning 'double' does not guarantee
        // a non-integer return type, so we return the number type for those.
        mappedType = types.numType;
      } else if (type == coreTypes.boolType) {
        mappedType = types.boolType;
      } else if (type == coreTypes.nullType) {
        mappedType = types.nullType;
      } else if (type.isVoid) {
        mappedType = types.nullType;
      } else if (type.isDynamic) {
        return types.dynamicType;
      } else {
        mappedType = types.nonNullSubtype(type.element);
      }
      returnType = types.computeLUB(returnType, mappedType);
      if (returnType == types.dynamicType) {
        break;
      }
    }
    return returnType;
  }

  // TODO(johnniwinther): Pass the [ResolvedAst] instead of [owner].
  void updateSelectorInTree(
      AstElement owner, Spannable node, Selector selector, TypeMask mask) {
    ast.Node astNode = node;
    TreeElements elements = owner.resolvedAst.elements;
    if (astNode.asSendSet() != null) {
      if (selector.isSetter || selector.isIndexSet) {
        elements.setTypeMask(node, mask);
      } else if (selector.isGetter || selector.isIndex) {
        elements.setGetterTypeMaskInComplexSendSet(node, mask);
      } else {
        assert(selector.isOperator);
        elements.setOperatorTypeMaskInComplexSendSet(node, mask);
      }
    } else if (astNode.asSend() != null) {
      elements.setTypeMask(node, mask);
    } else {
      assert(astNode.asForIn() != null);
      if (selector == Selectors.iterator) {
        elements.setIteratorTypeMask(node, mask);
      } else if (selector == Selectors.current) {
        elements.setCurrentTypeMask(node, mask);
      } else {
        assert(selector == Selectors.moveNext);
        elements.setMoveNextTypeMask(node, mask);
      }
    }
  }

  bool isNativeElement(Element element) {
    return compiler.backend.isNative(element);
  }

  void analyze(ResolvedAst resolvedAst, ArgumentsTypes arguments);

  bool checkIfExposesThis(Element element) {
    element = element.implementation;
    return generativeConstructorsExposingThis.contains(element);
  }

  void recordExposesThis(Element element, bool exposesThis) {
    element = element.implementation;
    if (exposesThis) {
      generativeConstructorsExposingThis.add(element);
    }
  }
}

/// [SimpleTypeInferrerVisitor] can be thought of as a type-inference graph
/// builder for a single element.
///
/// Calling [run] will start the work of visiting the body of the code to
/// construct a set of infernece-nodes that abstractly represent what the code
/// is doing.
///
/// This visitor is parameterized by an [InferenceEngine], which internally
/// decides how to represent inference nodes.
class SimpleTypeInferrerVisitor<T>
    extends InferrerVisitor<T, InferrerEngine<T, TypeSystem<T>>> {
  T returnType;
  bool visitingInitializers = false;
  bool isConstructorRedirect = false;
  bool seenSuperConstructorCall = false;
  SideEffects sideEffects = new SideEffects.empty();
  final Element outermostElement;
  final InferrerEngine<T, TypeSystem<T>> inferrer;
  final Setlet<Entity> capturedVariables = new Setlet<Entity>();

  SimpleTypeInferrerVisitor.internal(
      AstElement analyzedElement,
      ResolvedAst resolvedAst,
      this.outermostElement,
      inferrer,
      compiler,
      locals)
      : super(analyzedElement, resolvedAst, inferrer, inferrer.types, compiler,
            locals),
        this.inferrer = inferrer {
    assert(outermostElement != null);
  }

  SimpleTypeInferrerVisitor(Element element, ResolvedAst resolvedAst,
      Compiler compiler, InferrerEngine<T, TypeSystem<T>> inferrer,
      [LocalsHandler<T> handler])
      : this.internal(
            element,
            resolvedAst,
            element.outermostEnclosingMemberOrTopLevel.implementation,
            inferrer,
            compiler,
            handler);

  void analyzeSuperConstructorCall(
      AstElement target, ArgumentsTypes arguments) {
    ResolvedAst resolvedAst = target.resolvedAst;
    inferrer.analyze(resolvedAst, arguments);
    isThisExposed = isThisExposed || inferrer.checkIfExposesThis(target);
  }

  T run() {
    var node;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      node = resolvedAst.node;
    }
    ast.Expression initializer;
    if (analyzedElement.isField) {
      initializer = resolvedAst.body;
      if (initializer == null) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return types.nullType;
      }
    }
    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureClassMap closureData =
        compiler.closureToClassMapper.getClosureToClassMapping(resolvedAst);
    closureData.forEachCapturedVariable((variable, field) {
      locals.setCaptured(variable, field);
    });
    closureData.forEachBoxedVariable((variable, field) {
      locals.setCapturedAndBoxed(variable, field);
    });
    if (analyzedElement.isField) {
      return visit(initializer);
    }

    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.functionSignature;
    signature.forEachOptionalParameter((ParameterElement element) {
      ast.Expression defaultValue = element.initializer;
      // TODO(25566): The default value of a parameter of a redirecting factory
      // constructor comes from the corresponding parameter of the target.

      // If this is a default value from a different context (because
      // the current function is synthetic, e.g., a constructor from
      // a mixin application), we have to start a new inferrer visitor
      // with the correct context.
      // TODO(johnniwinther): Remove once function signatures are fixed.
      SimpleTypeInferrerVisitor visitor = this;
      if (inferrer.hasAlreadyComputedTypeOfParameterDefault(element)) return;
      if (element.functionDeclaration != analyzedElement) {
        visitor = new SimpleTypeInferrerVisitor(element.functionDeclaration,
            element.functionDeclaration.resolvedAst, compiler, inferrer);
      }
      T type =
          (defaultValue == null) ? types.nullType : visitor.visit(defaultValue);
      inferrer.setDefaultTypeOfParameter(element, type);
    });

    if (compiler.backend.isNative(analyzedElement)) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      return types.dynamicType;
    }

    if (analyzedElement.isGenerativeConstructor) {
      isThisExposed = false;
      signature.forEachParameter((ParameterElement element) {
        T parameterType = inferrer.typeOfElement(element);
        if (element.isInitializingFormal) {
          InitializingFormalElement initializingFormal = element;
          if (initializingFormal.fieldElement.isFinal) {
            inferrer.recordTypeOfFinalField(node, analyzedElement,
                initializingFormal.fieldElement, parameterType);
          } else {
            locals.updateField(initializingFormal.fieldElement, parameterType);
            inferrer.recordTypeOfNonFinalField(initializingFormal.node,
                initializingFormal.fieldElement, parameterType);
          }
        }
        locals.update(element, parameterType, node);
      });
      ClassElement cls = analyzedElement.enclosingClass;
      Spannable spannable = node;
      if (analyzedElement.isSynthesized) {
        spannable = analyzedElement;
        ConstructorElement constructor = analyzedElement;
        synthesizeForwardingCall(spannable, constructor.definingConstructor);
      } else {
        visitingInitializers = true;
        if (node.initializers != null) {
          for (ast.Node initializer in node.initializers) {
            ast.SendSet fieldInitializer = initializer.asSendSet();
            if (fieldInitializer != null) {
              handleSendSet(fieldInitializer);
            } else {
              Element element = elements[initializer];
              handleConstructorSend(initializer, element);
            }
          }
        }
        visitingInitializers = false;
        // For a generative constructor like: `Foo();`, we synthesize
        // a call to the default super constructor (the one that takes
        // no argument). Resolution ensures that such a constructor
        // exists.
        if (!isConstructorRedirect &&
            !seenSuperConstructorCall &&
            !cls.isObject) {
          FunctionElement target = cls.superclass.lookupDefaultConstructor();
          ArgumentsTypes arguments = new ArgumentsTypes([], {});
          analyzeSuperConstructorCall(target, arguments);
          inferrer.registerCalledElement(node, null, null, outermostElement,
              target.implementation, arguments, sideEffects, inLoop);
        }
        visit(node.body);
        inferrer.recordExposesThis(analyzedElement, isThisExposed);
      }
      if (!isConstructorRedirect) {
        // Iterate over all instance fields, and give a null type to
        // fields that we haven't initialized for sure.
        cls.forEachInstanceField((_, FieldElement field) {
          if (field.isFinal) return;
          T type = locals.fieldScope.readField(field);
          ResolvedAst resolvedAst = field.resolvedAst;
          if (type == null && resolvedAst.body == null) {
            inferrer.recordTypeOfNonFinalField(
                spannable, field, types.nullType);
          }
        });
      }
      if (analyzedElement.isGenerativeConstructor && cls.isAbstract) {
        if (compiler.closedWorld.isDirectlyInstantiated(cls)) {
          returnType = types.nonNullExact(cls);
        } else if (compiler.closedWorld.isIndirectlyInstantiated(cls)) {
          returnType = types.nonNullSubclass(cls);
        } else {
          // TODO(johnniwinther): Avoid analyzing [analyzedElement] in this
          // case; it's never called.
          returnType = types.nonNullEmpty();
        }
      } else {
        returnType = types.nonNullExact(cls);
      }
    } else {
      signature.forEachParameter((LocalParameterElement element) {
        locals.update(element, inferrer.typeOfElement(element), node);
      });
      visit(node.body);
      switch (function.asyncMarker) {
        case AsyncMarker.SYNC:
          if (returnType == null) {
            // No return in the body.
            returnType = locals.seenReturnOrThrow
                ? types.nonNullEmpty() // Body always throws.
                : types.nullType;
          } else if (!locals.seenReturnOrThrow) {
            // We haven't seen returns on all branches. So the method may
            // also return null.
            returnType = inferrer.addReturnTypeFor(
                analyzedElement, returnType, types.nullType);
          }
          break;

        case AsyncMarker.SYNC_STAR:
          // TODO(asgerf): Maybe make a ContainerTypeMask for these? The type
          //               contained is the method body's return type.
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.syncStarIterableType);
          break;

        case AsyncMarker.ASYNC:
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.asyncFutureType);
          break;

        case AsyncMarker.ASYNC_STAR:
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.asyncStarStreamType);
          break;
      }
    }

    compiler.inferenceWorld.registerSideEffects(analyzedElement, sideEffects);
    assert(breaksFor.isEmpty);
    assert(continuesFor.isEmpty);
    return returnType;
  }

  T visitFunctionExpression(ast.FunctionExpression node) {
    // We loose track of [this] in closures (see issue 20840). To be on
    // the safe side, we mark [this] as exposed here. We could do better by
    // analyzing the closure.
    // TODO(herhut): Analyze whether closure exposes this.
    isThisExposed = true;
    LocalFunctionElement element = elements.getFunctionDefinition(node);
    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalsHandler closureLocals =
        new LocalsHandler<T>.from(locals, node, useOtherTryBlock: false);
    SimpleTypeInferrerVisitor visitor = new SimpleTypeInferrerVisitor<T>(
        element, element.resolvedAst, compiler, inferrer, closureLocals);
    visitor.run();
    inferrer.recordReturnType(element, visitor.returnType);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure.
    ClosureClassMap nestedClosureData = compiler.closureToClassMapper
        .getClosureToClassMapping(element.resolvedAst);
    nestedClosureData.forEachCapturedVariable((variable, field) {
      if (!nestedClosureData.isVariableBoxed(variable)) {
        if (variable == nestedClosureData.thisLocal) {
          inferrer.recordType(field, thisType);
        }
        // The type is null for type parameters.
        if (locals.locals[variable] == null) return;
        inferrer.recordType(field, locals.locals[variable]);
      }
      capturedVariables.add(variable);
    });

    return inferrer.concreteTypes.putIfAbsent(node, () {
      return types.allocateClosure(node, element);
    });
  }

  T visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element =
        elements.getFunctionDefinition(node.function);
    T type = inferrer.concreteTypes.putIfAbsent(node.function, () {
      return types.allocateClosure(node.function, element);
    });
    locals.update(element, type, node);
    visit(node.function);
    return type;
  }

  T visitStringInterpolation(ast.StringInterpolation node) {
    // Interpolation could have any effects since it could call any toString()
    // method.
    // TODO(sra): This could be modelled by a call to toString() but with a
    // guaranteed String return type.  Interpolation of known types would get
    // specialized effects.  This would not currently be effective since the JS
    // code in the toString methods for intercepted primitive types is assumed
    // to have all effects.  Effect annotations on JS code would be needed to
    // get the benefit.
    sideEffects.setAllSideEffects();
    return super.visitStringInterpolation(node);
  }

  T visitLiteralList(ast.LiteralList node) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return inferrer.concreteTypes.putIfAbsent(node, () {
      T elementType;
      int length = 0;
      for (ast.Node element in node.elements.nodes) {
        T type = visit(element);
        elementType = elementType == null
            ? types.allocatePhi(null, null, type)
            : types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? types.nonNullEmpty()
          : types.simplifyPhi(null, null, elementType);
      T containerType =
          node.isConst ? types.constListType : types.growableListType;
      return types.allocateList(
          containerType, node, outermostElement, elementType, length);
    });
  }

  T visitLiteralMap(ast.LiteralMap node) {
    return inferrer.concreteTypes.putIfAbsent(node, () {
      ast.NodeList entries = node.entries;
      List<T> keyTypes = [];
      List<T> valueTypes = [];

      for (ast.LiteralMapEntry entry in entries) {
        keyTypes.add(visit(entry.key));
        valueTypes.add(visit(entry.value));
      }

      T type = node.isConst ? types.constMapType : types.mapType;
      return types.allocateMap(
          type, node, outermostElement, keyTypes, valueTypes);
    });
  }

  bool isThisOrSuper(ast.Node node) => node.isThis() || node.isSuper();

  bool isInClassOrSubclass(Element element) {
    ClassElement cls = outermostElement.enclosingClass.declaration;
    ClassElement enclosing = element.enclosingClass.declaration;
    return compiler.closedWorld.isSubclassOf(enclosing, cls);
  }

  void checkIfExposesThis(Selector selector, TypeMask mask) {
    if (isThisExposed) return;
    inferrer.forEachElementMatching(selector, mask, (element) {
      if (element.isField) {
        ResolvedAst elementResolvedAst = element.resolvedAst;
        if (!selector.isSetter &&
            isInClassOrSubclass(element) &&
            !element.isFinal &&
            locals.fieldScope.readField(element) == null &&
            elementResolvedAst.body == null) {
          // If the field is being used before this constructor
          // actually had a chance to initialize it, say it can be
          // null.
          inferrer.recordTypeOfNonFinalField(
              resolvedAst.node, element, types.nullType);
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
    return (outermostElement.isInstanceMember && !outermostElement.isField) ||
        outermostElement.isGenerativeConstructor;
  }

  bool treatAsInstanceMember(Element element) {
    return (Elements.isUnresolved(element) && inInstanceContext) ||
        (element != null && element.isInstanceMember);
  }

  @override
  T handleSendSet(ast.SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType) {
      node.visitChildren(this);
      return types.dynamicType;
    }

    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);
    TypeMask getterMask = elements.getGetterTypeMaskInComplexSendSet(node);
    TypeMask operatorMask = elements.getOperatorTypeMaskInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = elements.getTypeMask(node);

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
      if (node.receiver != null) {
        Element receiver = elements[node.receiver];
        if (receiver is! PrefixElement && receiver is! ClassElement) {
          // TODO(johnniwinther): Avoid blindly recursing on the receiver.
          receiverType = visit(node.receiver);
        }
      }
      isCallOnThis = isThisOrSuper(node.receiver);
    }

    T rhsType;

    if (isIncrementOrDecrement) {
      rhsType = types.uint31Type;
      if (node.isIndex) visit(node.arguments.head);
    } else if (node.isIndex) {
      visit(node.arguments.head);
      rhsType = visit(node.arguments.tail.head);
    } else {
      rhsType = visit(node.arguments.head);
    }

    if (!visitingInitializers && !isThisExposed) {
      for (ast.Node node in node.arguments) {
        if (isThisOrSuper(node)) {
          isThisExposed = true;
          break;
        }
      }
      if (!isThisExposed && isCallOnThis) {
        checkIfExposesThis(
            setterSelector, types.newTypedSelector(receiverType, setterMask));
        if (getterSelector != null) {
          checkIfExposesThis(
              getterSelector, types.newTypedSelector(receiverType, getterMask));
        }
      }
    }

    if (node.isIndex) {
      return internalError(node, "Unexpected index operation");
    } else if (op == '=') {
      return handlePlainAssignment(node, element, setterSelector, setterMask,
          receiverType, rhsType, node.arguments.head);
    } else {
      // [foo ??= bar], [: foo++ :] or [: foo += 1 :].
      T getterType;
      T newType;

      if (Elements.isMalformed(element)) return types.dynamicType;

      if (Elements.isStaticOrTopLevelField(element)) {
        Element getterElement = elements[node.selector];
        getterType = handleStaticSend(
            node, getterSelector, getterMask, getterElement, null);
      } else if (Elements.isUnresolved(element) ||
          element.isSetter ||
          element.isField) {
        getterType = handleDynamicSend(
            node, getterSelector, getterMask, receiverType, null);
      } else if (element.isLocal) {
        LocalElement local = element;
        getterType = locals.use(local);
      } else {
        // Bogus SendSet, for example [: myMethod += 42 :].
        getterType = types.dynamicType;
      }

      if (op == '??=') {
        newType = types.allocateDiamondPhi(getterType, rhsType);
      } else {
        Selector operatorSelector =
            elements.getOperatorSelectorInComplexSendSet(node);
        newType = handleDynamicSend(node, operatorSelector, operatorMask,
            getterType, new ArgumentsTypes<T>([rhsType], null));
      }

      if (Elements.isStaticOrTopLevelField(element)) {
        handleStaticSend(node, setterSelector, setterMask, element,
            new ArgumentsTypes<T>([newType], null));
      } else if (Elements.isUnresolved(element) ||
          element.isSetter ||
          element.isField) {
        handleDynamicSend(node, setterSelector, setterMask, receiverType,
            new ArgumentsTypes<T>([newType], null));
      } else if (element.isLocal) {
        locals.update(element, newType, node);
      }

      return node.isPostfix ? getterType : newType;
    }
  }

  /// Handle compound index set, like `foo[0] += 42` or `foo[0]++`.
  T handleCompoundIndexSet(
      ast.SendSet node, T receiverType, T indexType, T rhsType) {
    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);
    TypeMask getterMask = elements.getGetterTypeMaskInComplexSendSet(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    TypeMask operatorMask = elements.getOperatorTypeMaskInComplexSendSet(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = elements.getTypeMask(node);

    T getterType = handleDynamicSend(node, getterSelector, getterMask,
        receiverType, new ArgumentsTypes<T>([indexType], null));

    T returnType;
    if (node.isIfNullAssignment) {
      returnType = types.allocateDiamondPhi(getterType, rhsType);
    } else {
      returnType = handleDynamicSend(node, operatorSelector, operatorMask,
          getterType, new ArgumentsTypes<T>([rhsType], null));
    }
    handleDynamicSend(node, setterSelector, setterMask, receiverType,
        new ArgumentsTypes<T>([indexType, returnType], null));

    if (node.isPostfix) {
      return getterType;
    } else {
      return returnType;
    }
  }

  /// Handle compound prefix/postfix operations, like `a[0]++`.
  T handleCompoundPrefixPostfix(ast.Send node, T receiverType, T indexType) {
    return handleCompoundIndexSet(
        node, receiverType, indexType, types.uint31Type);
  }

  @override
  T visitIndexPostfix(ast.Send node, ast.Node receiver, ast.Node index,
      op.IncDecOperator operator, _) {
    T receiverType = visit(receiver);
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, receiverType, indexType);
  }

  @override
  T visitIndexPrefix(ast.Send node, ast.Node receiver, ast.Node index,
      op.IncDecOperator operator, _) {
    T receiverType = visit(receiver);
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, receiverType, indexType);
  }

  @override
  T visitCompoundIndexSet(ast.SendSet node, ast.Node receiver, ast.Node index,
      op.AssignmentOperator operator, ast.Node rhs, _) {
    T receiverType = visit(receiver);
    T indexType = visit(index);
    T rhsType = visit(rhs);
    return handleCompoundIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  T visitIndexSetIfNull(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    T receiverType = visit(receiver);
    T indexType = visit(index);
    T rhsType = visit(rhs);
    return handleCompoundIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  T visitSuperIndexPrefix(ast.Send node, MethodElement getter,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitSuperIndexPostfix(ast.Send node, MethodElement getter,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  /// Handle compound super index set, like `super[42] =+ 2`.
  T handleSuperCompoundIndexSet(
      ast.SendSet node, ast.Node index, ast.Node rhs) {
    T receiverType = superType;
    T indexType = visit(index);
    T rhsType = visit(rhs);
    return handleCompoundIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  T visitSuperCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      MethodElement setter,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitSuperIndexSetIfNull(ast.SendSet node, MethodElement getter,
      MethodElement setter, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperCompoundIndexSet(ast.Send node, Element element,
      ast.Node index, op.AssignmentOperator operator, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperIndexSetIfNull(
      ast.Send node, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperGetterCompoundIndexSet(
      ast.SendSet node,
      Element element,
      MethodElement setter,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperGetterIndexSetIfNull(ast.SendSet node, Element element,
      MethodElement setter, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperSetterCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperSetterIndexSetIfNull(ast.SendSet node,
      MethodElement getter, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperIndexPrefix(ast.Send node, Element element,
      ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitUnresolvedSuperGetterIndexPrefix(ast.SendSet node, Element element,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitUnresolvedSuperSetterIndexPrefix(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitUnresolvedSuperIndexPostfix(ast.Send node, Element element,
      ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitUnresolvedSuperGetterIndexPostfix(ast.SendSet node, Element element,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  @override
  T visitUnresolvedSuperSetterIndexPostfix(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    T indexType = visit(index);
    return handleCompoundPrefixPostfix(node, superType, indexType);
  }

  /// Handle index set, like `foo[0] = 42`.
  T handleIndexSet(ast.SendSet node, T receiverType, T indexType, T rhsType) {
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = elements.getTypeMask(node);
    handleDynamicSend(node, setterSelector, setterMask, receiverType,
        new ArgumentsTypes<T>([indexType, rhsType], null));
    return rhsType;
  }

  @override
  T visitIndexSet(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    T receiverType = visit(receiver);
    T indexType = visit(index);
    T rhsType = visit(rhs);
    return handleIndexSet(node, receiverType, indexType, rhsType);
  }

  /// Handle super index set, like `super[42] = true`.
  T handleSuperIndexSet(ast.SendSet node, ast.Node index, ast.Node rhs) {
    T receiverType = superType;
    T indexType = visit(index);
    T rhsType = visit(rhs);
    return handleIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  T visitSuperIndexSet(ast.SendSet node, FunctionElement function,
      ast.Node index, ast.Node rhs, _) {
    return handleSuperIndexSet(node, index, rhs);
  }

  @override
  T visitUnresolvedSuperIndexSet(
      ast.SendSet node, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperIndexSet(node, index, rhs);
  }

  T handlePlainAssignment(
      ast.Node node,
      Element element,
      Selector setterSelector,
      TypeMask setterMask,
      T receiverType,
      T rhsType,
      ast.Node rhs) {
    ArgumentsTypes arguments = new ArgumentsTypes<T>([rhsType], null);
    if (Elements.isMalformed(element)) {
      // Code will always throw.
    } else if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, setterSelector, setterMask, element, arguments);
    } else if (Elements.isUnresolved(element) || element.isSetter) {
      if (analyzedElement.isGenerativeConstructor &&
          (node.asSendSet() != null) &&
          (node.asSendSet().receiver != null) &&
          node.asSendSet().receiver.isThis()) {
        Iterable<Element> targets = compiler.closedWorld.allFunctions.filter(
            setterSelector, types.newTypedSelector(thisType, setterMask));
        // We just recognized a field initialization of the form:
        // `this.foo = 42`. If there is only one target, we can update
        // its type.
        if (targets.length == 1) {
          Element single = targets.first;
          if (single.isField) {
            locals.updateField(single, rhsType);
          }
        }
      }
      handleDynamicSend(
          node, setterSelector, setterMask, receiverType, arguments);
    } else if (element.isField) {
      if (element.isFinal) {
        inferrer.recordTypeOfFinalField(
            node, outermostElement, element, rhsType);
      } else {
        if (analyzedElement.isGenerativeConstructor) {
          locals.updateField(element, rhsType);
        }
        if (visitingInitializers) {
          inferrer.recordTypeOfNonFinalField(node, element, rhsType);
        } else {
          handleDynamicSend(
              node, setterSelector, setterMask, receiverType, arguments);
        }
      }
    } else if (element.isLocal) {
      locals.update(element, rhsType, node);
    }
    return rhsType;
  }

  /// Handle a super access or invocation that results in a `noSuchMethod` call.
  T handleErroneousSuperSend(ast.Send node) {
    ArgumentsTypes arguments =
        node.isPropertyAccess ? null : analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    // Ensure we create a node, to make explicit the call to the
    // `noSuchMethod` handler.
    return handleDynamicSend(node, selector, mask, superType, arguments);
  }

  /// Handle a .call invocation on the values retrieved from the super
  /// [element]. For instance `super.foo(bar)` where `foo` is a field or getter.
  T handleSuperClosureCall(
      ast.Send node, Element element, ast.NodeList arguments) {
    ArgumentsTypes argumentTypes = analyzeArguments(arguments.nodes);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    return inferrer.registerCalledClosure(
        node,
        selector,
        mask,
        inferrer.typeOfElement(element),
        outermostElement,
        argumentTypes,
        sideEffects,
        inLoop);
  }

  /// Handle an invocation of super [method].
  T handleSuperMethodInvoke(
      ast.Send node, MethodElement method, ArgumentsTypes arguments) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, method, arguments);
  }

  /// Handle access to a super field or getter [element].
  T handleSuperGet(ast.Send node, Element element) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, element, null);
  }

  @override
  T visitUnresolvedSuperIndex(
      ast.Send node, Element element, ast.Node index, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitUnresolvedSuperUnary(
      ast.Send node, op.UnaryOperator operator, Element element, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitUnresolvedSuperBinary(ast.Send node, Element element,
      op.BinaryOperator operator, ast.Node argument, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitUnresolvedSuperGet(ast.Send node, Element element, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitSuperSetterGet(ast.Send node, MethodElement setter, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitSuperGetterSet(ast.Send node, MethodElement getter, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitUnresolvedSuperSet(ast.Send node, Element element, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitUnresolvedSuperInvoke(
      ast.Send node, Element element, ast.Node argument, Selector selector, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitSuperFieldGet(ast.Send node, FieldElement field, _) {
    return handleSuperGet(node, field);
  }

  @override
  T visitSuperGetterGet(ast.Send node, MethodElement method, _) {
    return handleSuperGet(node, method);
  }

  @override
  T visitSuperMethodGet(ast.Send node, MethodElement method, _) {
    return handleSuperGet(node, method);
  }

  @override
  T visitSuperFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperClosureCall(node, field, arguments);
  }

  @override
  T visitSuperGetterInvoke(ast.Send node, MethodElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperClosureCall(node, getter, arguments);
  }

  @override
  T visitSuperMethodInvoke(ast.Send node, MethodElement method,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(arguments.nodes));
  }

  @override
  T visitSuperSetterInvoke(ast.Send node, FunctionElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  T visitSuperIndex(ast.Send node, MethodElement method, ast.Node index, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  T visitSuperEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    // TODO(johnniwinther): Special case ==.
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  T visitSuperNotEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    // TODO(johnniwinther): Special case !=.
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  T visitSuperBinary(ast.Send node, MethodElement method,
      op.BinaryOperator operator, ast.Node argument, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  T visitSuperUnary(
      ast.Send node, op.UnaryOperator operator, MethodElement method, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  T visitSuperMethodIncompatibleInvoke(ast.Send node, MethodElement method,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleErroneousSuperSend(node);
  }

  // Try to find the length given to a fixed array constructor call.
  int findLength(ast.Send node) {
    ast.Node firstArgument = node.arguments.head;
    Element element = elements[firstArgument];
    ast.LiteralInt length = firstArgument.asLiteralInt();
    if (length != null) {
      return length.value;
    } else if (element != null &&
        element.isField &&
        Elements.isStaticOrTopLevelField(element) &&
        compiler.closedWorld.fieldNeverChanges(element)) {
      FieldElement fieldElement = element;
      ConstantValue value =
          compiler.backend.constants.getConstantValue(fieldElement.constant);
      if (value != null && value.isInt) {
        IntConstantValue intValue = value;
        return intValue.primitiveValue;
      }
    }
    return null;
  }

  T visitAwait(ast.Await node) {
    T futureType = node.expression.accept(this);
    return inferrer.registerAwait(node, futureType);
  }

  @override
  T handleTypeLiteralInvoke(ast.NodeList arguments) {
    // This is reached when users forget to put a `new` in front of a type
    // literal. The emitter will generate an actual call (even though it is
    // likely invalid), and for that it needs to have the arguments processed
    // as well.
    analyzeArguments(arguments.nodes);
    return super.handleTypeLiteralInvoke(arguments);
  }

  /// Handle constructor invocation of [constructor].
  T handleConstructorSend(ast.Send node, ConstructorElement constructor) {
    ConstructorElement target = constructor.implementation;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (visitingInitializers) {
      if (ast.Initializers.isConstructorRedirect(node)) {
        isConstructorRedirect = true;
      } else if (ast.Initializers.isSuperConstructorCall(node)) {
        seenSuperConstructorCall = true;
        analyzeSuperConstructorCall(constructor, arguments);
      }
    }
    // If we are looking at a new expression on a forwarding factory, we have to
    // forward the call to the effective target of the factory.
    // TODO(herhut): Remove the loop once effectiveTarget forwards to patches.
    while (target.isFactoryConstructor) {
      if (!target.isRedirectingFactory) break;
      target = target.effectiveTarget.implementation;
    }
    if (compiler.backend.isForeign(target)) {
      return handleForeignSend(node, target);
    }
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    // In erroneous code the number of arguments in the selector might not
    // match the function element.
    // TODO(polux): return nonNullEmpty and check it doesn't break anything
    if (!selector.applies(target) ||
        (mask != null &&
            !mask.canHit(target, selector, compiler.closedWorld))) {
      return types.dynamicType;
    }

    T returnType = handleStaticSend(node, selector, mask, target, arguments);
    if (Elements.isGrowableListConstructorCall(constructor, node, compiler)) {
      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.growableListType, node,
              outermostElement, types.nonNullEmpty(), 0));
    } else if (Elements.isFixedListConstructorCall(
            constructor, node, compiler) ||
        Elements.isFilledListConstructorCall(constructor, node, compiler)) {
      int length = findLength(node);
      T elementType =
          Elements.isFixedListConstructorCall(constructor, node, compiler)
              ? types.nullType
              : arguments.positional[1];

      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.fixedListType, node, outermostElement,
              elementType, length));
    } else if (Elements.isConstructorOfTypedArraySubclass(
        constructor, compiler)) {
      int length = findLength(node);
      T elementType = inferrer
          .returnTypeOfElement(target.enclosingClass.lookupMember('[]'));
      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.nonNullExact(target.enclosingClass),
              node, outermostElement, elementType, length));
    } else {
      return returnType;
    }
  }

  @override
  T bulkHandleNew(ast.NewExpression node, _) {
    Element element = elements[node.send];
    return handleConstructorSend(node.send, element);
  }

  @override
  T errorNonConstantConstructorInvoke(ast.NewExpression node, Element element,
      DartType type, ast.NodeList arguments, CallStructure callStructure, _) {
    return bulkHandleNew(node, _);
  }

  /// Handle invocation of a top level or static field or getter [element].
  T handleStaticFieldOrGetterInvoke(ast.Send node, Element element) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    handleStaticSend(node, selector, mask, element, arguments);
    return inferrer.registerCalledClosure(
        node,
        selector,
        mask,
        inferrer.typeOfElement(element),
        outermostElement,
        arguments,
        sideEffects,
        inLoop);
  }

  /// Handle invocation of a top level or static [function].
  T handleStaticFunctionInvoke(ast.Send node, MethodElement function) {
    if (compiler.backend.isForeign(function)) {
      return handleForeignSend(node, function);
    }
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, function, arguments);
  }

  /// Handle an static invocation of an unresolved target or with incompatible
  /// arguments to a resolved target.
  T handleInvalidStaticInvoke(ast.Send node) {
    analyzeArguments(node.arguments);
    return types.dynamicType;
  }

  @override
  T visitStaticFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, field);
  }

  @override
  T visitStaticFunctionInvoke(ast.Send node, MethodElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFunctionInvoke(node, function);
  }

  @override
  T visitStaticFunctionIncompatibleInvoke(ast.Send node, MethodElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  T visitStaticGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, getter);
  }

  @override
  T visitTopLevelFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, field);
  }

  @override
  T visitTopLevelFunctionInvoke(ast.Send node, MethodElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFunctionInvoke(node, function);
  }

  @override
  T visitTopLevelFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  T visitTopLevelGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, getter);
  }

  @override
  T visitStaticSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  T visitTopLevelSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  T visitUnresolvedInvoke(ast.Send node, Element element,
      ast.NodeList arguments, Selector selector, _) {
    return handleInvalidStaticInvoke(node);
  }

  T handleForeignSend(ast.Send node, Element element) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    String name = element.name;
    handleStaticSend(node, selector, mask, element, arguments);
    if (name == 'JS' || name == 'JS_EMBEDDED_GLOBAL' || name == 'JS_BUILTIN') {
      native.NativeBehavior nativeBehavior = elements.getNativeData(node);
      sideEffects.add(nativeBehavior.sideEffects);
      return inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == 'JS_OPERATOR_AS_PREFIX' || name == 'JS_STRING_CONCAT') {
      return types.stringType;
    } else {
      sideEffects.setAllSideEffects();
      return types.dynamicType;
    }
  }

  ArgumentsTypes analyzeArguments(Link<ast.Node> arguments) {
    List<T> positional = [];
    Map<String, T> named;
    for (var argument in arguments) {
      ast.NamedArgument namedArgument = argument.asNamedArgument();
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

  /// Read a local variable, function or parameter.
  T handleLocalGet(ast.Send node, LocalElement local) {
    assert(locals.use(local) != null);
    return locals.use(local);
  }

  /// Read a static or top level field.
  T handleStaticFieldGet(ast.Send node, FieldElement field) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, field, null);
  }

  /// Invoke a static or top level getter.
  T handleStaticGetterGet(ast.Send node, MethodElement getter) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, getter, null);
  }

  /// Closurize a static or top level function.
  T handleStaticFunctionGet(ast.Send node, MethodElement function) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return handleStaticSend(node, selector, mask, function, null);
  }

  @override
  T visitDynamicPropertyGet(ast.Send node, ast.Node receiver, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  T visitIfNotNullDynamicPropertyGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  T visitLocalVariableGet(ast.Send node, LocalVariableElement variable, _) {
    return handleLocalGet(node, variable);
  }

  @override
  T visitParameterGet(ast.Send node, ParameterElement parameter, _) {
    return handleLocalGet(node, parameter);
  }

  @override
  T visitLocalFunctionGet(ast.Send node, LocalFunctionElement function, _) {
    return handleLocalGet(node, function);
  }

  @override
  T visitStaticFieldGet(ast.Send node, FieldElement field, _) {
    return handleStaticFieldGet(node, field);
  }

  @override
  T visitStaticFunctionGet(ast.Send node, MethodElement function, _) {
    return handleStaticFunctionGet(node, function);
  }

  @override
  T visitStaticGetterGet(ast.Send node, FunctionElement getter, _) {
    return handleStaticGetterGet(node, getter);
  }

  @override
  T visitThisPropertyGet(ast.Send node, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  T visitTopLevelFieldGet(ast.Send node, FieldElement field, _) {
    return handleStaticFieldGet(node, field);
  }

  @override
  T visitTopLevelFunctionGet(ast.Send node, MethodElement function, _) {
    return handleStaticFunctionGet(node, function);
  }

  @override
  T visitTopLevelGetterGet(ast.Send node, FunctionElement getter, _) {
    return handleStaticGetterGet(node, getter);
  }

  @override
  T visitStaticSetterGet(ast.Send node, MethodElement setter, _) {
    return types.dynamicType;
  }

  @override
  T visitTopLevelSetterGet(ast.Send node, MethodElement setter, _) {
    return types.dynamicType;
  }

  @override
  T visitUnresolvedGet(ast.Send node, Element element, _) {
    return types.dynamicType;
  }

  /// Handle .call invocation on [closure].
  T handleCallInvoke(ast.Send node, T closure) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    return inferrer.registerCalledClosure(node, selector, mask, closure,
        outermostElement, arguments, sideEffects, inLoop);
  }

  @override
  T visitExpressionInvoke(ast.Send node, ast.Node expression,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, expression.accept(this));
  }

  @override
  T visitThisInvoke(
      ast.Send node, ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, thisType);
  }

  @override
  T visitParameterInvoke(ast.Send node, ParameterElement parameter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, locals.use(parameter));
  }

  @override
  T visitLocalVariableInvoke(ast.Send node, LocalVariableElement variable,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, locals.use(variable));
  }

  @override
  T visitLocalFunctionInvoke(ast.Send node, LocalFunctionElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    ArgumentsTypes argumentTypes = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    // This only works for function statements. We need a
    // more sophisticated type system with function types to support
    // more.
    return inferrer.registerCalledElement(node, selector, mask,
        outermostElement, function, argumentTypes, sideEffects, inLoop);
  }

  @override
  T visitLocalFunctionIncompatibleInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    analyzeArguments(node.arguments);
    return types.dynamicType;
  }

  T handleStaticSend(ast.Node node, Selector selector, TypeMask mask,
      Element element, ArgumentsTypes arguments) {
    assert(!element.isFactoryConstructor ||
        !(element as ConstructorElement).isRedirectingFactory);
    // Erroneous elements may be unresolved, for example missing getters.
    if (Elements.isUnresolved(element)) return types.dynamicType;
    // TODO(herhut): should we follow redirecting constructors here? We would
    // need to pay attention if the constructor is pointing to an erroneous
    // element.
    return inferrer.registerCalledElement(node, selector, mask,
        outermostElement, element, arguments, sideEffects, inLoop);
  }

  T handleDynamicSend(ast.Node node, Selector selector, TypeMask mask,
      T receiverType, ArgumentsTypes arguments) {
    assert(receiverType != null);
    if (types.selectorNeedsUpdate(receiverType, mask)) {
      mask = receiverType == types.dynamicType
          ? null
          : types.newTypedSelector(receiverType, mask);
      inferrer.updateSelectorInTree(analyzedElement, node, selector, mask);
    }

    // If the receiver of the call is a local, we may know more about
    // its type by refining it with the potential targets of the
    // calls.
    ast.Send send = node.asSend();
    if (send != null) {
      ast.Node receiver = send.receiver;
      if (receiver != null) {
        Element element = elements[receiver];
        if (Elements.isLocal(element) && !capturedVariables.contains(element)) {
          T refinedType = types.refineReceiver(
              selector, mask, receiverType, send.isConditional);
          locals.update(element, refinedType, node);
        }
      }
    }

    return inferrer.registerCalledSelector(node, selector, mask, receiverType,
        outermostElement, arguments, sideEffects, inLoop);
  }

  T handleDynamicInvoke(ast.Send node) {
    return _handleDynamicSend(node);
  }

  T handleDynamicGet(ast.Send node) {
    return _handleDynamicSend(node);
  }

  T _handleDynamicSend(ast.Send node) {
    Element element = elements[node];
    T receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        isCallOnThis = true;
        receiverType = thisType;
      }
    } else {
      ast.Node receiver = node.receiver;
      isCallOnThis = isThisOrSuper(receiver);
      receiverType = visit(receiver);
    }

    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    if (!isThisExposed && isCallOnThis) {
      checkIfExposesThis(selector, types.newTypedSelector(receiverType, mask));
    }

    ArgumentsTypes arguments =
        node.isPropertyAccess ? null : analyzeArguments(node.arguments);
    if (selector.name == '==' || selector.name == '!=') {
      if (types.isNull(receiverType)) {
        potentiallyAddNullCheck(node, node.arguments.head);
        return types.boolType;
      } else if (types.isNull(arguments.positional[0])) {
        potentiallyAddNullCheck(node, node.receiver);
        return types.boolType;
      }
    }
    return handleDynamicSend(node, selector, mask, receiverType, arguments);
  }

  void recordReturnType(T type) {
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  T synthesizeForwardingCall(Spannable node, FunctionElement element) {
    element = element.implementation;
    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.functionSignature;
    FunctionSignature calleeSignature = element.functionSignature;
    if (!calleeSignature.isCompatibleWith(signature)) {
      return types.nonNullEmpty();
    }

    List<T> unnamed = <T>[];
    signature.forEachRequiredParameter((ParameterElement element) {
      assert(locals.use(element) != null);
      unnamed.add(locals.use(element));
    });

    Map<String, T> named;
    if (signature.optionalParametersAreNamed) {
      named = new Map<String, T>();
      signature.forEachOptionalParameter((ParameterElement element) {
        named[element.name] = locals.use(element);
      });
    } else {
      signature.forEachOptionalParameter((ParameterElement element) {
        unnamed.add(locals.use(element));
      });
    }

    ArgumentsTypes arguments = new ArgumentsTypes<T>(unnamed, named);
    return inferrer.registerCalledElement(node, null, null, outermostElement,
        element, arguments, sideEffects, inLoop);
  }

  T visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    Element element = elements.getRedirectingTargetConstructor(node);
    if (Elements.isMalformed(element)) {
      recordReturnType(types.dynamicType);
    } else {
      // We don't create a selector for redirecting factories, and
      // the send is just a property access. Therefore we must
      // manually create the [ArgumentsTypes] of the call, and
      // manually register [analyzedElement] as a caller of [element].
      T mask = synthesizeForwardingCall(node.constructorReference, element);
      recordReturnType(mask);
    }
    locals.seenReturnOrThrow = true;
    return null;
  }

  T visitReturn(ast.Return node) {
    ast.Node expression = node.expression;
    recordReturnType(
        expression == null ? types.nullType : expression.accept(this));
    locals.seenReturnOrThrow = true;
    return null;
  }

  T handleForInLoop(ast.ForIn node, T iteratorType, Selector currentSelector,
      TypeMask currentMask, Selector moveNextSelector, TypeMask moveNextMask) {
    handleDynamicSend(node, moveNextSelector, moveNextMask, iteratorType,
        new ArgumentsTypes<T>.empty());
    T currentType = handleDynamicSend(node, currentSelector, currentMask,
        iteratorType, new ArgumentsTypes<T>.empty());

    if (node.expression.isThis()) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      isThisExposed = true;
    }

    ast.Node identifier = node.declaredIdentifier;
    Element element = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);
    TypeMask mask = elements.getTypeMask(identifier);

    T receiverType;
    if (element != null && element.isInstanceMember) {
      receiverType = thisType;
    } else {
      receiverType = types.dynamicType;
    }

    handlePlainAssignment(identifier, element, selector, mask, receiverType,
        currentType, node.expression);
    return handleLoop(node, () {
      visit(node.body);
    });
  }

  T visitAsyncForIn(ast.AsyncForIn node) {
    T expressionType = visit(node.expression);

    Selector currentSelector = Selectors.current;
    TypeMask currentMask = elements.getCurrentTypeMask(node);
    Selector moveNextSelector = Selectors.moveNext;
    TypeMask moveNextMask = elements.getMoveNextTypeMask(node);

    js.JavaScriptBackend backend = compiler.backend;
    Element ctor = backend.helpers.streamIteratorConstructor;

    /// Synthesize a call to the [StreamIterator] constructor.
    T iteratorType = handleStaticSend(
        node, null, null, ctor, new ArgumentsTypes<T>([expressionType], null));

    return handleForInLoop(node, iteratorType, currentSelector, currentMask,
        moveNextSelector, moveNextMask);
  }

  T visitSyncForIn(ast.SyncForIn node) {
    T expressionType = visit(node.expression);
    Selector iteratorSelector = Selectors.iterator;
    TypeMask iteratorMask = elements.getIteratorTypeMask(node);
    Selector currentSelector = Selectors.current;
    TypeMask currentMask = elements.getCurrentTypeMask(node);
    Selector moveNextSelector = Selectors.moveNext;
    TypeMask moveNextMask = elements.getMoveNextTypeMask(node);

    T iteratorType = handleDynamicSend(node, iteratorSelector, iteratorMask,
        expressionType, new ArgumentsTypes<T>.empty());

    return handleForInLoop(node, iteratorType, currentSelector, currentMask,
        moveNextSelector, moveNextMask);
  }
}
