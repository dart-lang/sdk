// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue, IterableBase;
import '../dart_types.dart' show DartType, InterfaceType, TypeKind;
import '../elements/elements.dart';
import '../tree/tree.dart' show LiteralList, Node;
import '../types/types.dart' show TypeMask, ContainerTypeMask, TypesInferrer;
import '../universe/universe.dart' show Selector, TypedSelector, SideEffects;
import '../dart2jslib.dart' show Compiler, TreeElementMapping;
import 'inferrer_visitor.dart' show TypeSystem, ArgumentsTypes;
import '../native_handler.dart' as native;
import '../util/util.dart' show Spannable, Setlet;
import 'simple_types_inferrer.dart';
import '../dart2jslib.dart' show invariant;

part 'type_graph_nodes.dart';
part 'container_tracer.dart';

/**
 * A set of selector names that [List] implements, that we know return
 * their element type.
 */
Set<Selector> returnsElementTypeSet = new Set<Selector>.from(
  <Selector>[
    new Selector.getter('first', null),
    new Selector.getter('last', null),
    new Selector.getter('single', null),
    new Selector.call('singleWhere', null, 1),
    new Selector.call('elementAt', null, 1),
    new Selector.index(),
    new Selector.call('removeAt', null, 1),
    new Selector.call('removeLast', null, 0)
  ]);

bool returnsElementType(Selector selector) {
  return (selector.mask != null)
         && selector.mask.isContainer
         && returnsElementTypeSet.contains(selector.asUntyped);
}

class TypeInformationSystem extends TypeSystem<TypeInformation> {
  final Compiler compiler;

  /// [ElementTypeInformation]s for elements.
  final Map<Element, TypeInformation> typeInformations =
      new Map<Element, TypeInformation>();

  /// [ContainerTypeInformation] for allocated containers.
  final Map<Node, TypeInformation> allocatedContainers =
      new Map<Node, TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<TypeMask, TypeInformation> concreteTypes =
      new Map<TypeMask, TypeInformation>();

  /// List of [TypeInformation]s allocated inside method bodies (calls,
  /// narrowing, phis, and containers).
  final List<TypeInformation> allocatedTypes = <TypeInformation>[];

  TypeInformationSystem(this.compiler) {
    nonNullEmptyType = getConcreteTypeFor(const TypeMask.nonNullEmpty());
  }

  TypeInformation nullTypeCache;
  TypeInformation get nullType {
    if (nullTypeCache != null) return nullTypeCache;
    return nullTypeCache = getConcreteTypeFor(compiler.typesTask.nullType);
  }

  TypeInformation intTypeCache;
  TypeInformation get intType {
    if (intTypeCache != null) return intTypeCache;
    return intTypeCache = getConcreteTypeFor(compiler.typesTask.intType);
  }

  TypeInformation doubleTypeCache;
  TypeInformation get doubleType {
    if (doubleTypeCache != null) return doubleTypeCache;
    return doubleTypeCache = getConcreteTypeFor(compiler.typesTask.doubleType);
  }

  TypeInformation numTypeCache;
  TypeInformation get numType {
    if (numTypeCache != null) return numTypeCache;
    return numTypeCache = getConcreteTypeFor(compiler.typesTask.numType);
  }

  TypeInformation boolTypeCache;
  TypeInformation get boolType {
    if (boolTypeCache != null) return boolTypeCache;
    return boolTypeCache = getConcreteTypeFor(compiler.typesTask.boolType);
  }

  TypeInformation functionTypeCache;
  TypeInformation get functionType {
    if (functionTypeCache != null) return functionTypeCache;
    return functionTypeCache =
        getConcreteTypeFor(compiler.typesTask.functionType);
  }

  TypeInformation listTypeCache;
  TypeInformation get listType {
    if (listTypeCache != null) return listTypeCache;
    return listTypeCache = getConcreteTypeFor(compiler.typesTask.listType);
  }

  TypeInformation constListTypeCache;
  TypeInformation get constListType {
    if (constListTypeCache != null) return constListTypeCache;
    return constListTypeCache =
        getConcreteTypeFor(compiler.typesTask.constListType);
  }

  TypeInformation fixedListTypeCache;
  TypeInformation get fixedListType {
    if (fixedListTypeCache != null) return fixedListTypeCache;
    return fixedListTypeCache =
        getConcreteTypeFor(compiler.typesTask.fixedListType);
  }

  TypeInformation growableListTypeCache;
  TypeInformation get growableListType {
    if (growableListTypeCache != null) return growableListTypeCache;
    return growableListTypeCache =
        getConcreteTypeFor(compiler.typesTask.growableListType);
  }

  TypeInformation mapTypeCache;
  TypeInformation get mapType {
    if (mapTypeCache != null) return mapTypeCache;
    return mapTypeCache = getConcreteTypeFor(compiler.typesTask.mapType);
  }

  TypeInformation constMapTypeCache;
  TypeInformation get constMapType {
    if (constMapTypeCache != null) return constMapTypeCache;
    return constMapTypeCache =
        getConcreteTypeFor(compiler.typesTask.constMapType);
  }

  TypeInformation stringTypeCache;
  TypeInformation get stringType {
    if (stringTypeCache != null) return stringTypeCache;
    return stringTypeCache = getConcreteTypeFor(compiler.typesTask.stringType);
  }

  TypeInformation typeTypeCache;
  TypeInformation get typeType {
    if (typeTypeCache != null) return typeTypeCache;
    return typeTypeCache = getConcreteTypeFor(compiler.typesTask.typeType);
  }

  TypeInformation dynamicTypeCache;
  TypeInformation get dynamicType {
    if (dynamicTypeCache != null) return dynamicTypeCache;
    return dynamicTypeCache =
        getConcreteTypeFor(compiler.typesTask.dynamicType);
  }

  TypeInformation nonNullEmptyType;

  TypeInformation computeLUB(TypeInformation firstType,
                             TypeInformation secondType) {
    if (firstType == null) return secondType;
    if (firstType == secondType) return firstType;
    if (firstType == nonNullEmptyType) return secondType;
    if (secondType == nonNullEmptyType) return firstType;
    if (firstType == dynamicType || secondType == dynamicType) {
      return dynamicType;
    }
    return getConcreteTypeFor(
        firstType.type.union(secondType.type, compiler));
  }

  TypeInformation refineReceiver(Selector selector, TypeInformation receiver) {
    if (receiver.type.isExact) return receiver;
    TypeMask otherType = compiler.world.allFunctions.receiverType(selector);
    // If this is refining to nullable subtype of `Object` just return
    // the receiver. We know the narrowing is useless.
    if (otherType.isNullable && otherType.containsAll(compiler)) {
      return receiver;
    }
    TypeInformation newType = new NarrowTypeInformation(receiver, otherType);
    allocatedTypes.add(newType);
    return newType;
  }

  TypeInformation narrowType(TypeInformation type,
                             DartType annotation,
                             {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == compiler.objectClass) return type;
    TypeMask otherType;
    if (annotation.kind == TypeKind.TYPEDEF
        || annotation.kind == TypeKind.FUNCTION) {
      otherType = functionType.type;
    } else if (annotation.kind == TypeKind.TYPE_VARIABLE) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.kind == TypeKind.INTERFACE);
      otherType = new TypeMask.nonNullSubtype(annotation.element);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type.type.isExact) {
      return type;
    } else {
      TypeInformation newType = new NarrowTypeInformation(type, otherType);
      allocatedTypes.add(newType);
      return newType;
    }
  }

  ElementTypeInformation getInferredTypeOf(Element element) {
    element = element.implementation;
    return typeInformations.putIfAbsent(element, () {
      return new ElementTypeInformation(element);
    });
  }

  ConcreteTypeInformation getConcreteTypeFor(TypeMask mask) {
    return concreteTypes.putIfAbsent(mask, () {
      return new ConcreteTypeInformation(mask);
    });
  }

  TypeInformation nonNullSubtype(ClassElement type) {
    return getConcreteTypeFor(new TypeMask.nonNullSubtype(type.declaration));
  }

  TypeInformation nonNullSubclass(ClassElement type) {
    return getConcreteTypeFor(new TypeMask.nonNullSubclass(type.declaration));
  }

  TypeInformation nonNullExact(ClassElement type) {
    return getConcreteTypeFor(new TypeMask.nonNullExact(type.declaration));
  }

  TypeInformation nonNullEmpty() {
    return nonNullEmptyType;
  }

  bool isNull(TypeInformation type) {
    return type == nullType;
  }

  TypeInformation allocateContainer(TypeInformation type,
                                    Node node,
                                    Element enclosing,
                                    [TypeInformation elementType, int length]) {
    bool isTypedArray = (compiler.typedDataClass != null)
        && type.type.satisfies(compiler.typedDataClass, compiler);
    bool isConst = (type.type == compiler.typesTask.constListType);
    bool isFixed = (type.type == compiler.typesTask.fixedListType)
        || isConst
        || isTypedArray;
    bool isElementInferred = isConst || isTypedArray;

    int inferredLength = isFixed ? length : null;
    TypeMask elementTypeMask = isElementInferred
        ? elementType.type
        : dynamicType.type;
    ContainerTypeMask mask = new ContainerTypeMask(
        type.type, node, enclosing, elementTypeMask, inferredLength);
    ElementInContainerTypeInformation element =
        new ElementInContainerTypeInformation(elementType);
    element.inferred = isElementInferred;

    allocatedTypes.add(element);
    return allocatedContainers[node] =
        new ContainerTypeInformation(mask, element, length);
  }

  Selector newTypedSelector(TypeInformation info, Selector selector) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete
        ? new TypedSelector(info.type, selector)
        : selector;
  }

  TypeInformation allocateDiamondPhi(TypeInformation firstInput,
                                     TypeInformation secondInput) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(null, false, null);
    result.addAssignment(firstInput);
    result.addAssignment(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation allocatePhi(Node node,
                                        Element element,
                                        inputType) {
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation
        && inputType.branchNode == node) {
      return inputType;
    }
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(node, true, element);
    allocatedTypes.add(result);
    result.addAssignment(inputType);
    return result;
  }

  TypeInformation simplifyPhi(Node node,
                              Element element,
                              PhiElementTypeInformation phiType) {
    if (phiType.assignments.length == 1) return phiType.assignments.first;
    return phiType;
  }

  PhiElementTypeInformation addPhiInput(Element element,
                                        PhiElementTypeInformation phiType,
                                        TypeInformation newType) {
    phiType.addAssignment(newType);
    return phiType;
  }

  TypeMask computeTypeMask(Iterable<TypeInformation> assignments) {
    return joinTypeMasks(assignments.map((e) => e.type));
  }

  TypeMask joinTypeMasks(Iterable<TypeMask> masks) {
    TypeMask newType = const TypeMask.nonNullEmpty();
    for (TypeMask mask in masks) {
      newType = newType.union(mask, compiler);
    }
    return newType.containsAll(compiler) ? dynamicType.type : newType;
  }
}

/**
 * A work queue for the inferrer. It filters out nodes on
 * which we gave up on inferencing, as well as ensures through
 * [TypeInformation.inQueue] that a node is in the queue only once at
 * a time.
 */
class WorkQueue {
  final Queue<TypeInformation> queue = new Queue<TypeInformation>();

  void add(TypeInformation element) {
    if (element.abandonInferencing) return;
    if (element.inQueue) return;
    queue.addLast(element);
    element.inQueue = true;
  }

  void addAll(Iterable<TypeInformation> all) {
    all.forEach(add);
  }

  TypeInformation remove() {
    TypeInformation element = queue.removeFirst();
    element.inQueue = false;
    return element;
  }

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;
}

/**
 * An inferencing engine that computes a call graph of
 * [TypeInformation] nodes by visiting the AST of the application, and
 * then does the inferencing on the graph.
 *
 * The inferencing is currently done in three steps:
 *
 * 1) Compute the call graph.
 * 2) Refine all nodes in a way that avoids cycles.
 * 3) Refine all nodes.
 *
 */
class TypeGraphInferrerEngine
    extends InferrerEngine<TypeInformation, TypeInformationSystem> {
  final Map<Element, TypeInformation> defaultTypeOfParameter =
      new Map<Element, TypeInformation>();
  final List<CallSiteTypeInformation> allocatedCalls =
      <CallSiteTypeInformation>[];
  final WorkQueue workQueue = new WorkQueue();
  final Element mainElement;

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 5;

  int overallRefineCount = 0;

  TypeGraphInferrerEngine(Compiler compiler, this.mainElement)
        : super(compiler, new TypeInformationSystem(compiler));

  void runOverAllElements() {
    if (compiler.disableTypeInference) return;
    int addedInGraph = 0;
    compiler.progress.reset();

    sortResolvedElements().forEach((Element element) {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Added $addedInGraph elements in inferencing graph.');
        compiler.progress.reset();
      }
      // Force the creation of the [ElementTypeInformation] to ensure it is
      // in the graph.
      types.getInferredTypeOf(element);

      SimpleTypeInferrerVisitor visitor =
          new SimpleTypeInferrerVisitor(element, compiler, this);
      TypeInformation type;
      compiler.withCurrentElement(element, () {
        type = visitor.run();
      });
      addedInGraph++;

      if (element.isField()) {
        Node node = element.parseNode(compiler);
        if (element.modifiers.isFinal() || element.modifiers.isConst()) {
          // If [element] is final and has an initializer, we record
          // the inferred type.
          if (node.asSendSet() != null) {
            recordType(element, type);
          } else if (!element.isInstanceMember()) {
            recordType(element, types.nullType);
          }
        } else if (node.asSendSet() == null) {
          // Only update types of static fields if there is no
          // assignment. Instance fields are dealt with in the constructor.
          if (Elements.isStaticOrTopLevelField(element)) {
            recordTypeOfNonFinalField(node, element, type);
          }
        } else {
          recordTypeOfNonFinalField(node, element, type);
        }
        if (Elements.isStaticOrTopLevelField(element)
            && node.asSendSet() != null
            && !element.modifiers.isConst()) {
          var argument = node.asSendSet().arguments.head;
          // TODO(13429): We could do better here by using the
          // constant handler to figure out if it's a lazy field or not.
          if (argument.asSend() != null
              || (argument.asNewExpression() != null && !argument.isConst())) {
            recordType(element, types.nullType);
          }
        }
      } else {
        recordReturnType(element, type);
      }
    });
    compiler.log('Added $addedInGraph elements in inferencing graph.');

    buildWorkQueue();
    refine();

    // Try to infer element types of lists.
    types.allocatedContainers.values.forEach((ContainerTypeInformation info) {
      if (info.elementType.inferred) return;
      ContainerTracerVisitor tracer = new ContainerTracerVisitor(info, this);
      List<TypeInformation> newAssignments = tracer.run();
      if (newAssignments == null) return;

      info.elementType.inferred = true;
      newAssignments.forEach(info.elementType.addAssignment);
      workQueue.add(info);
      workQueue.add(info.elementType);
    });

    // Reset all nodes that use lists that have been inferred, as well
    // as nodes that use elements fetched from these lists. The
    // workset for a new run of the analysis will be these nodes.
    Set<TypeInformation> seenTypes = new Set<TypeInformation>();
    while (!workQueue.isEmpty) {
      TypeInformation info = workQueue.remove();
      if (seenTypes.contains(info)) continue;
      info.reset(this);
      seenTypes.add(info);
      workQueue.addAll(info.users);
    }

    workQueue.addAll(seenTypes);
    refine();

    if (_VERBOSE) {
      types.allocatedContainers.values.forEach((ContainerTypeInformation info) {
        print('${info.type} '
              'for ${info.originalContainerType.allocationNode} '
              'at ${info.originalContainerType.allocationElement}');
      });
    }

    compiler.log('Inferred $overallRefineCount types.');

    processLoopInformation();
  }

  void processLoopInformation() {
    allocatedCalls.forEach((info) {
      if (!info.inLoop) return;
      if (info is StaticCallSiteTypeInformation) {
        compiler.world.addFunctionCalledInLoop(info.calledElement);
      } else if (info.selector.mask != null
                 && !info.selector.mask.containsAll(compiler)) {
        // For instance methods, we only register a selector called in a
        // loop if it is a typed selector, to avoid marking too many
        // methods as being called from within a loop. This cuts down
        // on the code bloat.
        info.targets.forEach(compiler.world.addFunctionCalledInLoop);
      }
    });
  }

  void refine() {
    while (!workQueue.isEmpty) {
      if (compiler.progress.elapsedMilliseconds > 500) {
        compiler.log('Inferred $overallRefineCount types.');
        compiler.progress.reset();
      }
      TypeInformation info = workQueue.remove();
      TypeMask oldType = info.type;
      TypeMask newType = info.refine(this);
      if ((info.type = newType) != oldType) {
        overallRefineCount++;
        info.refineCount++;
        workQueue.addAll(info.users);
        if (info.hasStableType(this)) {
          info.stabilize(this);
        } else if (info.refineCount > MAX_CHANGE_COUNT) {
          info.giveUp(this);
        }
      }
    }
  }

  void buildWorkQueue() {
    workQueue.addAll(types.typeInformations.values);
    workQueue.addAll(types.allocatedTypes);
    workQueue.addAll(allocatedCalls);
  }

  /**
   * Update the assignments to parameters in the graph. [remove] tells
   * wheter assignments must be added or removed. If [init] is false,
   * parameters are added to the work queue.
   */
  void updateParameterAssignments(TypeInformation caller,
                                  Element callee,
                                  ArgumentsTypes arguments,
                                  Selector selector,
                                  {bool remove, bool init: false}) {
    if (callee.name == Compiler.NO_SUCH_METHOD) return;
    if (callee.isField()) {
      if (selector.isSetter()) {
        ElementTypeInformation info = types.getInferredTypeOf(callee);
        if (remove) {
          info.removeAssignment(arguments.positional[0]);
        } else {
          info.addAssignment(arguments.positional[0]);
        }
        if (!init) workQueue.add(info);
      }
    } else if (callee.isGetter()) {
      return;
    } else if (selector != null && selector.isGetter()) {
      if (!remove) {
        FunctionElement function = callee.implementation;
        FunctionSignature signature = function.computeSignature(compiler);
        signature.forEachParameter((Element parameter) {
          ElementTypeInformation info = types.getInferredTypeOf(parameter);
          info.giveUp(this);
          if (!init) workQueue.addAll(info.users);
        });
      }
    } else {
      FunctionElement function = callee.implementation;
      FunctionSignature signature = function.computeSignature(compiler);
      int parameterIndex = 0;
      bool visitingRequiredParameter = true;
      signature.forEachParameter((Element parameter) {
        if (parameter == signature.firstOptionalParameter) {
          visitingRequiredParameter = false;
        }
        TypeInformation type = visitingRequiredParameter
            ? arguments.positional[parameterIndex]
            : signature.optionalParametersAreNamed
              ? arguments.named[parameter.name]
              : parameterIndex < arguments.positional.length
                  ? arguments.positional[parameterIndex]
                  : null;
        if (type == null) type = getDefaultTypeOfParameter(parameter);
        TypeInformation info = types.getInferredTypeOf(parameter);
        if (remove) {
          info.removeAssignment(type);
        } else {
          info.addAssignment(type);
        }
        parameterIndex++;
        if (!init) workQueue.add(info);
      });
    }
  }

  void setDefaultTypeOfParameter(Element parameter, TypeInformation type) {
    assert(parameter.enclosingElement.isImplementation);
    TypeInformation existing = defaultTypeOfParameter[parameter];
    defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOf(parameter);
    if (!info.abandonInferencing && existing != null && existing != type) {
      // Replace references to [existing] to use [type] instead.
      if (parameter.enclosingElement.isInstanceMember()) {
        ParameterAssignments assignments = info.assignments;
        int count = assignments.assignments[existing];
        if (count == null) return;
        type.addUser(info);
        assignments.assignments[type] = count;
        assignments.assignments.remove(existing);
      } else {
        List<TypeInformation> assignments = info.assignments;
        for (int i = 0; i < assignments.length; i++) {
          if (assignments[i] == existing) {
            info.assignments[i] = type;
            type.addUser(info);
          }
        }
      }
    }
  }

  TypeInformation getDefaultTypeOfParameter(Element parameter) {
    return defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new ConcreteTypeInformation(types.dynamicType.type);
    });
  }

  TypeInformation typeOfElement(Element element) {
    if (element is FunctionElement) return types.functionType;
    return types.getInferredTypeOf(element);
  }

  TypeInformation returnTypeOfElement(Element element) {
    if (element is !FunctionElement) return types.dynamicType;
    return types.getInferredTypeOf(element);
  }

  void recordTypeOfFinalField(Spannable node,
                              Element analyzed,
                              Element element,
                              TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  void recordTypeOfNonFinalField(Spannable node,
                                 Element element,
                                 TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  bool recordType(Element element, TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
    return false;
  }

  void recordReturnType(Element element, TypeInformation type) {
    TypeInformation info = types.getInferredTypeOf(element);
    if (element.name == '==') {
      info.addAssignment(types.boolType);
    }
    // TODO(ngeoffray): Clean up. We do these checks because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (type == null) return;
    if (info.assignments.isEmpty) info.addAssignment(type);
  }

  TypeInformation addReturnTypeFor(Element element,
                                   TypeInformation unused,
                                   TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOf(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element.isGenerativeConstructor()) return type;
    type.addAssignment(newType);
    return type;
  }

  TypeInformation registerCalledElement(Spannable node,
                                        Selector selector,
                                        Element caller,
                                        Element callee,
                                        ArgumentsTypes arguments,
                                        SideEffects sideEffects,
                                        bool inLoop) {
    CallSiteTypeInformation info = new StaticCallSiteTypeInformation(
          node, caller, callee, selector, arguments, inLoop);
    info.addToGraph(this);
    allocatedCalls.add(info);
    updateSideEffects(sideEffects, selector, callee);
    return info;
  }

  TypeInformation registerCalledSelector(Node node,
                                         Selector selector,
                                         TypeInformation receiverType,
                                         Element caller,
                                         ArgumentsTypes arguments,
                                         SideEffects sideEffects,
                                         bool inLoop) {
    if (selector.isClosureCall()) {
      return registerCalledClosure(
          node, selector, receiverType, caller, arguments, sideEffects, inLoop);
    }

    compiler.world.allFunctions.filter(selector).forEach((callee) {
      updateSideEffects(sideEffects, selector, callee);
    });

    CallSiteTypeInformation info = new DynamicCallSiteTypeInformation(
          node, caller, selector, receiverType, arguments, inLoop);

    info.addToGraph(this);
    allocatedCalls.add(info);
    return info;
  }

  TypeInformation registerCalledClosure(Node node,
                                        Selector selector,
                                        TypeInformation closure,
                                        Element caller,
                                        ArgumentsTypes arguments,
                                        SideEffects sideEffects,
                                        bool inLoop) {
    sideEffects.setDependsOnSomething();
    sideEffects.setAllSideEffects();
    CallSiteTypeInformation info = new ClosureCallSiteTypeInformation(
          node, caller, selector, closure, arguments, inLoop);
    info.addToGraph(this);
    allocatedCalls.add(info);
    return info;
  }

  // Sorts the resolved elements by size. We do this for this inferrer
  // to get the same results for [ContainerTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<Element> sortResolvedElements() {
    int max = 0;
    Map<int, Setlet<Element>> methodSizes = new Map<int, Setlet<Element>>();
    compiler.enqueuer.resolution.resolvedElements.forEach(
      (Element element, TreeElementMapping mapping) {
        element = element.implementation;
        if (element.impliesType()) return;
        assert(invariant(element,
            element.isField() ||
            element.isFunction() ||
            element.isGenerativeConstructor() ||
            element.isGetter() ||
            element.isSetter(),
            message: 'Unexpected element kind: ${element.kind}'));
        // TODO(ngeoffray): Not sure why the resolver would put a null
        // mapping.
        if (mapping == null) return;
        if (element.isAbstract(compiler)) return;
        // Put the other operators in buckets by length, later to be added in
        // length order.
        int length = mapping.selectors.length;
        max = length > max ? length : max;
        Setlet<Element> set = methodSizes.putIfAbsent(
            length, () => new Setlet<Element>());
        set.add(element);
    });

    List<Element> result = <Element>[];
    for (int i = 0; i <= max; i++) {
      Setlet<Element> set = methodSizes[i];
      if (set != null) result.addAll(set);
    }
    return result;
  }

  void clear() {
    allocatedCalls.clear();
    defaultTypeOfParameter.clear();
    types.typeInformations.values.forEach((info) => info.clear());
    types.allocatedTypes.clear();
    types.concreteTypes.clear();
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return types.getInferredTypeOf(element).callers.keys;
  }

  /**
   * Returns the type of [element] when being called with [selector].
   */
  TypeInformation typeOfElementWithSelector(Element element,
                                            Selector selector) {
    if (element.name == Compiler.NO_SUCH_METHOD
        && selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfElement(element);
    } else if (selector.isGetter()) {
      if (element.isFunction()) {
        // [functionType] is null if the inferrer did not run.
        return types.functionType == null
            ? types.dynamicType
            : types.functionType;
      } else if (element.isField()) {
        return typeOfElement(element);
      } else if (Elements.isUnresolved(element)) {
        return types.dynamicType;
      } else {
        assert(element.isGetter());
        return returnTypeOfElement(element);
      }
    } else if (element.isGetter() || element.isField()) {
      assert(selector.isCall() || selector.isSetter());
      return types.dynamicType;
    } else {
      return returnTypeOfElement(element);
    }
  }
}

class TypeGraphInferrer implements TypesInferrer {
  TypeGraphInferrerEngine inferrer;
  final Compiler compiler;
  TypeGraphInferrer(Compiler this.compiler);

  String get name => 'Graph inferrer';

  void analyzeMain(Element main) {
    inferrer = new TypeGraphInferrerEngine(compiler, main);
    inferrer.runOverAllElements();
  }

  TypeMask getReturnTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    // Currently, closure calls return dynamic.
    if (element is! FunctionElement) return compiler.typesTask.dynamicType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    if (element is FunctionElement) return compiler.typesTask.functionType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeOfNode(Element owner, Node node) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return inferrer.types.allocatedContainers[node].type;
  }

  TypeMask getTypeOfSelector(Selector selector) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall()) return compiler.typesTask.dynamicType;
    if (selector.isSetter() || selector.isIndexSet()) {
      return compiler.typesTask.dynamicType;
    }
    if (returnsElementType(selector)) {
      ContainerTypeMask mask = selector.mask;
      TypeMask elementType = mask.elementType;
      return elementType == null ? compiler.typesTask.dynamicType : elementType;
    }

    TypeMask result = const TypeMask.nonNullEmpty();
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element element in elements) {
      TypeMask type =
          inferrer.typeOfElementWithSelector(element, selector).type;
      result = result.union(type, compiler);
    }
    return result;
  }

  Iterable<TypeMask> get containerTypes {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.types.allocatedContainers.values.map((info) => info.type);
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOf(element);
  }

  void clear() {
    inferrer.clear();
  }
}
