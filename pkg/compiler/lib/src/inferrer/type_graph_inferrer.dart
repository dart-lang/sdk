// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue;

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../compiler.dart' show Compiler;
import '../constants/expressions.dart' show ConstantExpression;
import '../constants/values.dart';
import '../dart_types.dart' show DartType;
import '../elements/elements.dart';
import '../js_backend/js_backend.dart' show Annotations, JavaScriptBackend;
import '../resolution/tree_elements.dart' show TreeElementMapping;
import '../tree/dartstring.dart' show DartString;
import '../tree/tree.dart' as ast show Node, LiteralBool, TryStatement;
import '../types/constants.dart' show computeTypeMask;
import '../types/masks.dart'
    show CommonMasks, ContainerTypeMask, MapTypeMask, TypeMask;
import '../types/types.dart' show TypesInferrer;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart' show Setlet;
import '../world.dart' show ClosedWorld;
import 'closure_tracer.dart';
import 'debug.dart' as debug;
import 'inferrer_visitor.dart' show ArgumentsTypes, TypeSystem;
import 'list_tracer.dart';
import 'map_tracer.dart';
import 'simple_types_inferrer.dart';
import 'type_graph_dump.dart';
import 'type_graph_nodes.dart';

class TypeInformationSystem extends TypeSystem<TypeInformation> {
  final Compiler compiler;
  final ClosedWorld closedWorld;
  final CommonMasks commonMasks;

  /// [ElementTypeInformation]s for elements.
  final Map<Element, TypeInformation> typeInformations =
      new Map<Element, TypeInformation>();

  /// [ListTypeInformation] for allocated lists.
  final Map<ast.Node, TypeInformation> allocatedLists =
      new Map<ast.Node, TypeInformation>();

  /// [MapTypeInformation] for allocated Maps.
  final Map<ast.Node, TypeInformation> allocatedMaps =
      new Map<ast.Node, TypeInformation>();

  /// Closures found during the analysis.
  final Set<TypeInformation> allocatedClosures = new Set<TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<TypeMask, TypeInformation> concreteTypes =
      new Map<TypeMask, TypeInformation>();

  /// List of [TypeInformation]s allocated inside method bodies (calls,
  /// narrowing, phis, and containers).
  final List<TypeInformation> allocatedTypes = <TypeInformation>[];

  Iterable<TypeInformation> get allTypes => [
        typeInformations.values,
        allocatedLists.values,
        allocatedMaps.values,
        allocatedClosures,
        concreteTypes.values,
        allocatedTypes
      ].expand((x) => x);

  TypeInformationSystem(Compiler compiler, this.commonMasks)
      : this.compiler = compiler,
        this.closedWorld = compiler.closedWorld {
    nonNullEmptyType = getConcreteTypeFor(const TypeMask.nonNullEmpty());
  }

  /// Used to group [TypeInformation] nodes by the element that triggered their
  /// creation.
  MemberTypeInformation _currentMember = null;
  MemberTypeInformation get currentMember => _currentMember;

  void withMember(MemberElement element, action) {
    assert(invariant(element, _currentMember == null,
        message: "Already constructing graph for $_currentMember."));
    _currentMember = getInferredTypeOf(element);
    action();
    _currentMember = null;
  }

  TypeInformation nullTypeCache;
  TypeInformation get nullType {
    if (nullTypeCache != null) return nullTypeCache;
    return nullTypeCache = getConcreteTypeFor(commonMasks.nullType);
  }

  TypeInformation intTypeCache;
  TypeInformation get intType {
    if (intTypeCache != null) return intTypeCache;
    return intTypeCache = getConcreteTypeFor(commonMasks.intType);
  }

  TypeInformation uint32TypeCache;
  TypeInformation get uint32Type {
    if (uint32TypeCache != null) return uint32TypeCache;
    return uint32TypeCache = getConcreteTypeFor(commonMasks.uint32Type);
  }

  TypeInformation uint31TypeCache;
  TypeInformation get uint31Type {
    if (uint31TypeCache != null) return uint31TypeCache;
    return uint31TypeCache = getConcreteTypeFor(commonMasks.uint31Type);
  }

  TypeInformation positiveIntTypeCache;
  TypeInformation get positiveIntType {
    if (positiveIntTypeCache != null) return positiveIntTypeCache;
    return positiveIntTypeCache =
        getConcreteTypeFor(commonMasks.positiveIntType);
  }

  TypeInformation doubleTypeCache;
  TypeInformation get doubleType {
    if (doubleTypeCache != null) return doubleTypeCache;
    return doubleTypeCache = getConcreteTypeFor(commonMasks.doubleType);
  }

  TypeInformation numTypeCache;
  TypeInformation get numType {
    if (numTypeCache != null) return numTypeCache;
    return numTypeCache = getConcreteTypeFor(commonMasks.numType);
  }

  TypeInformation boolTypeCache;
  TypeInformation get boolType {
    if (boolTypeCache != null) return boolTypeCache;
    return boolTypeCache = getConcreteTypeFor(commonMasks.boolType);
  }

  TypeInformation functionTypeCache;
  TypeInformation get functionType {
    if (functionTypeCache != null) return functionTypeCache;
    return functionTypeCache = getConcreteTypeFor(commonMasks.functionType);
  }

  TypeInformation listTypeCache;
  TypeInformation get listType {
    if (listTypeCache != null) return listTypeCache;
    return listTypeCache = getConcreteTypeFor(commonMasks.listType);
  }

  TypeInformation constListTypeCache;
  TypeInformation get constListType {
    if (constListTypeCache != null) return constListTypeCache;
    return constListTypeCache = getConcreteTypeFor(commonMasks.constListType);
  }

  TypeInformation fixedListTypeCache;
  TypeInformation get fixedListType {
    if (fixedListTypeCache != null) return fixedListTypeCache;
    return fixedListTypeCache = getConcreteTypeFor(commonMasks.fixedListType);
  }

  TypeInformation growableListTypeCache;
  TypeInformation get growableListType {
    if (growableListTypeCache != null) return growableListTypeCache;
    return growableListTypeCache =
        getConcreteTypeFor(commonMasks.growableListType);
  }

  TypeInformation mapTypeCache;
  TypeInformation get mapType {
    if (mapTypeCache != null) return mapTypeCache;
    return mapTypeCache = getConcreteTypeFor(commonMasks.mapType);
  }

  TypeInformation constMapTypeCache;
  TypeInformation get constMapType {
    if (constMapTypeCache != null) return constMapTypeCache;
    return constMapTypeCache = getConcreteTypeFor(commonMasks.constMapType);
  }

  TypeInformation stringTypeCache;
  TypeInformation get stringType {
    if (stringTypeCache != null) return stringTypeCache;
    return stringTypeCache = getConcreteTypeFor(commonMasks.stringType);
  }

  TypeInformation typeTypeCache;
  TypeInformation get typeType {
    if (typeTypeCache != null) return typeTypeCache;
    return typeTypeCache = getConcreteTypeFor(commonMasks.typeType);
  }

  TypeInformation dynamicTypeCache;
  TypeInformation get dynamicType {
    if (dynamicTypeCache != null) return dynamicTypeCache;
    return dynamicTypeCache = getConcreteTypeFor(commonMasks.dynamicType);
  }

  TypeInformation asyncFutureTypeCache;
  TypeInformation get asyncFutureType {
    if (asyncFutureTypeCache != null) return asyncFutureTypeCache;
    return asyncFutureTypeCache =
        getConcreteTypeFor(commonMasks.asyncFutureType);
  }

  TypeInformation syncStarIterableTypeCache;
  TypeInformation get syncStarIterableType {
    if (syncStarIterableTypeCache != null) return syncStarIterableTypeCache;
    return syncStarIterableTypeCache =
        getConcreteTypeFor(commonMasks.syncStarIterableType);
  }

  TypeInformation asyncStarStreamTypeCache;
  TypeInformation get asyncStarStreamType {
    if (asyncStarStreamTypeCache != null) return asyncStarStreamTypeCache;
    return asyncStarStreamTypeCache =
        getConcreteTypeFor(commonMasks.asyncStarStreamType);
  }

  TypeInformation nonNullEmptyType;

  TypeInformation stringLiteralType(DartString value) {
    return new StringLiteralTypeInformation(value, commonMasks.stringType);
  }

  TypeInformation boolLiteralType(ast.LiteralBool value) {
    return new BoolLiteralTypeInformation(value, commonMasks.boolType);
  }

  TypeInformation computeLUB(
      TypeInformation firstType, TypeInformation secondType) {
    if (firstType == null) return secondType;
    if (firstType == secondType) return firstType;
    if (firstType == nonNullEmptyType) return secondType;
    if (secondType == nonNullEmptyType) return firstType;
    if (firstType == dynamicType || secondType == dynamicType) {
      return dynamicType;
    }
    return getConcreteTypeFor(
        firstType.type.union(secondType.type, closedWorld));
  }

  bool selectorNeedsUpdate(TypeInformation info, TypeMask mask) {
    return info.type != mask;
  }

  TypeInformation refineReceiver(Selector selector, TypeMask mask,
      TypeInformation receiver, bool isConditional) {
    if (receiver.type.isExact) return receiver;
    TypeMask otherType =
        compiler.closedWorld.allFunctions.receiverType(selector, mask);
    // Conditional sends (a?.b) can still narrow the possible types of `a`,
    // however, we still need to consider that `a` may be null.
    if (isConditional) {
      // Note: we don't check that receiver.type.isNullable here because this is
      // called during the graph construction.
      otherType = otherType.nullable();
    }
    // If this is refining to nullable subtype of `Object` just return
    // the receiver. We know the narrowing is useless.
    if (otherType.isNullable && otherType.containsAll(closedWorld)) {
      return receiver;
    }
    assert(TypeMask.assertIsNormalized(otherType, closedWorld));
    TypeInformation newType = new NarrowTypeInformation(receiver, otherType);
    allocatedTypes.add(newType);
    return newType;
  }

  TypeInformation narrowType(TypeInformation type, DartType annotation,
      {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == closedWorld.coreClasses.objectClass &&
        isNullable) {
      return type;
    }
    TypeMask otherType;
    if (annotation.isTypedef || annotation.isFunctionType) {
      otherType = functionType.type;
    } else if (annotation.isTypeVariable) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.isInterfaceType);
      otherType = annotation.element == closedWorld.coreClasses.objectClass
          ? dynamicType.type.nonNullable()
          : new TypeMask.nonNullSubtype(annotation.element, closedWorld);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type.type.isExact) {
      return type;
    } else {
      assert(TypeMask.assertIsNormalized(otherType, closedWorld));
      TypeInformation newType = new NarrowTypeInformation(type, otherType);
      allocatedTypes.add(newType);
      return newType;
    }
  }

  TypeInformation narrowNotNull(TypeInformation type) {
    if (type.type.isExact && !type.type.isNullable) {
      return type;
    }
    TypeInformation newType =
        new NarrowTypeInformation(type, dynamicType.type.nonNullable());
    allocatedTypes.add(newType);
    return newType;
  }

  ElementTypeInformation getInferredTypeOf(Element element) {
    element = element.implementation;
    return typeInformations.putIfAbsent(element, () {
      return new ElementTypeInformation(element, this);
    });
  }

  ConcreteTypeInformation getConcreteTypeFor(TypeMask mask) {
    assert(mask != null);
    return concreteTypes.putIfAbsent(mask, () {
      return new ConcreteTypeInformation(mask);
    });
  }

  String getInferredSignatureOf(FunctionElement function) {
    ElementTypeInformation info = getInferredTypeOf(function);
    FunctionElement impl = function.implementation;
    FunctionSignature signature = impl.functionSignature;
    var res = "";
    signature.forEachParameter((Element parameter) {
      TypeInformation type = getInferredTypeOf(parameter);
      res += "${res.isEmpty ? '(' : ', '}${type.type} ${parameter.name}";
    });
    res += ") -> ${info.type}";
    return res;
  }

  TypeInformation nonNullSubtype(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullSubtype(type.declaration, closedWorld));
  }

  TypeInformation nonNullSubclass(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullSubclass(type.declaration, closedWorld));
  }

  TypeInformation nonNullExact(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullExact(type.declaration, closedWorld));
  }

  TypeInformation nonNullEmpty() {
    return nonNullEmptyType;
  }

  bool isNull(TypeInformation type) {
    return type == nullType;
  }

  TypeInformation allocateList(
      TypeInformation type, ast.Node node, Element enclosing,
      [TypeInformation elementType, int length]) {
    ClassElement typedDataClass = compiler.commonElements.typedDataClass;
    bool isTypedArray = typedDataClass != null &&
        closedWorld.isInstantiated(typedDataClass) &&
        type.type.satisfies(typedDataClass, closedWorld);
    bool isConst = (type.type == commonMasks.constListType);
    bool isFixed =
        (type.type == commonMasks.fixedListType) || isConst || isTypedArray;
    bool isElementInferred = isConst || isTypedArray;

    int inferredLength = isFixed ? length : null;
    TypeMask elementTypeMask =
        isElementInferred ? elementType.type : dynamicType.type;
    ContainerTypeMask mask = new ContainerTypeMask(
        type.type, node, enclosing, elementTypeMask, inferredLength);
    ElementInContainerTypeInformation element =
        new ElementInContainerTypeInformation(currentMember, elementType);
    element.inferred = isElementInferred;

    allocatedTypes.add(element);
    return allocatedLists[node] =
        new ListTypeInformation(currentMember, mask, element, length);
  }

  TypeInformation allocateClosure(ast.Node node, Element element) {
    TypeInformation result =
        new ClosureTypeInformation(currentMember, node, element);
    allocatedClosures.add(result);
    return result;
  }

  TypeInformation allocateMap(
      ConcreteTypeInformation type, ast.Node node, Element element,
      [List<TypeInformation> keyTypes, List<TypeInformation> valueTypes]) {
    assert(keyTypes.length == valueTypes.length);
    bool isFixed = (type.type == commonMasks.constMapType);

    TypeMask keyType, valueType;
    if (isFixed) {
      keyType = keyTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, closedWorld));
      valueType = valueTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, closedWorld));
    } else {
      keyType = valueType = dynamicType.type;
    }
    MapTypeMask mask =
        new MapTypeMask(type.type, node, element, keyType, valueType);

    TypeInformation keyTypeInfo =
        new KeyInMapTypeInformation(currentMember, null);
    TypeInformation valueTypeInfo =
        new ValueInMapTypeInformation(currentMember, null);
    allocatedTypes.add(keyTypeInfo);
    allocatedTypes.add(valueTypeInfo);

    MapTypeInformation map =
        new MapTypeInformation(currentMember, mask, keyTypeInfo, valueTypeInfo);

    for (int i = 0; i < keyTypes.length; ++i) {
      TypeInformation newType =
          map.addEntryAssignment(keyTypes[i], valueTypes[i], true);
      if (newType != null) allocatedTypes.add(newType);
    }

    // Shortcut: If we already have a first approximation of the key/value type,
    // start propagating it early.
    if (isFixed) map.markAsInferred();

    allocatedMaps[node] = map;
    return map;
  }

  TypeMask newTypedSelector(TypeInformation info, TypeMask mask) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete ? info.type : mask;
  }

  TypeInformation allocateDiamondPhi(
      TypeInformation firstInput, TypeInformation secondInput) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(currentMember, null, false, null);
    result.addAssignment(firstInput);
    result.addAssignment(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation _addPhi(
      ast.Node node, Local variable, inputType, bool isLoop) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(currentMember, node, isLoop, variable);
    allocatedTypes.add(result);
    result.addAssignment(inputType);
    return result;
  }

  PhiElementTypeInformation allocatePhi(
      ast.Node node, Local variable, inputType) {
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation &&
        inputType.branchNode == node &&
        inputType.branchNode is ast.TryStatement) {
      return inputType;
    }
    return _addPhi(node, variable, inputType, false);
  }

  PhiElementTypeInformation allocateLoopPhi(
      ast.Node node, Local variable, inputType) {
    return _addPhi(node, variable, inputType, true);
  }

  TypeInformation simplifyPhi(
      ast.Node node, Local variable, PhiElementTypeInformation phiType) {
    assert(phiType.branchNode == node);
    if (phiType.assignments.length == 1) return phiType.assignments.first;
    return phiType;
  }

  PhiElementTypeInformation addPhiInput(Local variable,
      PhiElementTypeInformation phiType, TypeInformation newType) {
    phiType.addAssignment(newType);
    return phiType;
  }

  TypeMask computeTypeMask(Iterable<TypeInformation> assignments) {
    return joinTypeMasks(assignments.map((e) => e.type));
  }

  TypeMask joinTypeMasks(Iterable<TypeMask> masks) {
    var dynamicType = commonMasks.dynamicType;
    // Optimization: we are iterating over masks twice, but because `masks` is a
    // mapped iterable, we save the intermediate results to avoid computing them
    // again.
    var list = [];
    for (TypeMask mask in masks) {
      // Don't do any work on computing unions if we know that after all that
      // work the result will be `dynamic`.
      // TODO(sigmund): change to `mask == dynamicType` so we can continue to
      // track the non-nullable bit.
      if (mask.containsAll(closedWorld)) return dynamicType;
      list.add(mask);
    }

    TypeMask newType = null;
    for (TypeMask mask in list) {
      newType = newType == null ? mask : newType.union(mask, closedWorld);
      // Likewise - stop early if we already reach dynamic.
      if (newType.containsAll(closedWorld)) return dynamicType;
    }

    return newType ?? const TypeMask.nonNullEmpty();
  }
}

/**
 * A work queue for the inferrer. It filters out nodes that are tagged as
 * [TypeInformation.doNotEnqueue], as well as ensures through
 * [TypeInformation.inQueue] that a node is in the queue only once at
 * a time.
 */
class WorkQueue {
  final Queue<TypeInformation> queue = new Queue<TypeInformation>();

  void add(TypeInformation element) {
    if (element.doNotEnqueue) return;
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
 */
class TypeGraphInferrerEngine
    extends InferrerEngine<TypeInformation, TypeInformationSystem> {
  final Map<Element, TypeInformation> defaultTypeOfParameter =
      new Map<Element, TypeInformation>();
  final List<CallSiteTypeInformation> allocatedCalls =
      <CallSiteTypeInformation>[];
  final WorkQueue workQueue = new WorkQueue();
  final Element mainElement;
  final CommonMasks commonMasks;
  final Set<Element> analyzedElements = new Set<Element>();

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 6;

  int overallRefineCount = 0;
  int addedInGraph = 0;

  TypeGraphInferrerEngine(
      Compiler compiler, CommonMasks commonMasks, this.mainElement)
      : commonMasks = commonMasks,
        super(compiler, new TypeInformationSystem(compiler, commonMasks));

  JavaScriptBackend get backend => compiler.backend;
  Annotations get annotations => backend.annotations;
  DiagnosticReporter get reporter => compiler.reporter;

  /**
   * A set of selector names that [List] implements, that we know return
   * their element type.
   */
  final Set<Selector> returnsListElementTypeSet =
      new Set<Selector>.from(<Selector>[
    new Selector.getter(const PublicName('first')),
    new Selector.getter(const PublicName('last')),
    new Selector.getter(const PublicName('single')),
    new Selector.call(const PublicName('singleWhere'), CallStructure.ONE_ARG),
    new Selector.call(const PublicName('elementAt'), CallStructure.ONE_ARG),
    new Selector.index(),
    new Selector.call(const PublicName('removeAt'), CallStructure.ONE_ARG),
    new Selector.call(const PublicName('removeLast'), CallStructure.NO_ARGS)
  ]);

  bool returnsListElementType(Selector selector, TypeMask mask) {
    return mask != null &&
        mask.isContainer &&
        returnsListElementTypeSet.contains(selector);
  }

  bool returnsMapValueType(Selector selector, TypeMask mask) {
    return mask != null && mask.isMap && selector.isIndex;
  }

  void analyzeListAndEnqueue(ListTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    ListTracerVisitor tracer = new ListTracerVisitor(info, this);
    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    info.elementType.inferred = true;
    TypeMask fixedListType = commonMasks.fixedListType;
    if (info.originalType.forwardTo == fixedListType) {
      info.checksGrowable = tracer.callsGrowableMethod;
    }
    tracer.assignments.forEach(info.elementType.addAssignment);
    // Enqueue the list for later refinement
    workQueue.add(info);
    workQueue.add(info.elementType);
  }

  void analyzeMapAndEnqueue(MapTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;
    MapTracerVisitor tracer = new MapTracerVisitor(info, this);

    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    for (int i = 0; i < tracer.keyAssignments.length; ++i) {
      TypeInformation newType = info.addEntryAssignment(
          tracer.keyAssignments[i], tracer.valueAssignments[i]);
      if (newType != null) workQueue.add(newType);
    }
    for (TypeInformation map in tracer.mapAssignments) {
      workQueue.addAll(info.addMapAssignment(map));
    }

    info.markAsInferred();
    workQueue.add(info.keyType);
    workQueue.add(info.valueType);
    workQueue.addAll(info.typeInfoMap.values);
    workQueue.add(info);
  }

  void runOverAllElements() {
    if (compiler.disableTypeInference) return;
    if (compiler.options.verbose) {
      compiler.progress.reset();
    }
    sortResolvedAsts().forEach((ResolvedAst resolvedAst) {
      if (compiler.shouldPrintProgress) {
        reporter.log('Added $addedInGraph elements in inferencing graph.');
        compiler.progress.reset();
      }
      // This also forces the creation of the [ElementTypeInformation] to ensure
      // it is in the graph.
      types.withMember(
          resolvedAst.element.implementation, () => analyze(resolvedAst, null));
    });
    reporter.log('Added $addedInGraph elements in inferencing graph.');

    TypeGraphDump dump = debug.PRINT_GRAPH ? new TypeGraphDump(this) : null;

    dump?.beforeAnalysis();
    buildWorkQueue();
    refine();

    // Try to infer element types of lists and compute their escape information.
    types.allocatedLists.values.forEach((ListTypeInformation info) {
      analyzeListAndEnqueue(info);
    });

    // Try to infer the key and value types for maps and compute the values'
    // escape information.
    types.allocatedMaps.values.forEach((MapTypeInformation info) {
      analyzeMapAndEnqueue(info);
    });

    Set<FunctionElement> bailedOutOn = new Set<FunctionElement>();

    // Trace closures to potentially infer argument types.
    types.allocatedClosures.forEach((info) {
      void trace(
          Iterable<FunctionElement> elements, ClosureTracerVisitor tracer) {
        tracer.run();
        if (!tracer.continueAnalyzing) {
          elements.forEach((FunctionElement e) {
            compiler.inferenceWorld.registerMightBePassedToApply(e);
            if (debug.VERBOSE) print("traced closure $e as ${true} (bail)");
            e.functionSignature.forEachParameter((parameter) {
              types
                  .getInferredTypeOf(parameter)
                  .giveUp(this, clearAssignments: false);
            });
          });
          bailedOutOn.addAll(elements);
          return;
        }
        elements
            .where((e) => !bailedOutOn.contains(e))
            .forEach((FunctionElement e) {
          e.functionSignature.forEachParameter((parameter) {
            var info = types.getInferredTypeOf(parameter);
            info.maybeResume();
            workQueue.add(info);
          });
          if (tracer.tracedType.mightBePassedToFunctionApply) {
            compiler.inferenceWorld.registerMightBePassedToApply(e);
          }
          if (debug.VERBOSE) {
            print("traced closure $e as "
                "${compiler.inferenceWorld
                    .getCurrentlyKnownMightBePassedToApply(e)}");
          }
        });
      }

      if (info is ClosureTypeInformation) {
        Iterable<FunctionElement> elements = [info.element];
        trace(elements, new ClosureTracerVisitor(elements, info, this));
      } else if (info is CallSiteTypeInformation) {
        if (info is StaticCallSiteTypeInformation &&
            info.selector != null &&
            info.selector.isCall) {
          // This is a constructor call to a class with a call method. So we
          // need to trace the call method here.
          assert(info.calledElement.isConstructor);
          ClassElement cls = info.calledElement.enclosingClass;
          FunctionElement callMethod = cls.lookupMember(Identifiers.call);
          assert(invariant(cls, callMethod != null));
          Iterable<FunctionElement> elements = [callMethod];
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        } else {
          // We only are interested in functions here, as other targets
          // of this closure call are not a root to trace but an intermediate
          // for some other function.
          Iterable<FunctionElement> elements = new List<FunctionElement>.from(
              info.callees.where((e) => e.isFunction));
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        }
      } else {
        assert(info is ElementTypeInformation);
        trace([info.element],
            new StaticTearOffClosureTracerVisitor(info.element, info, this));
      }
    });

    dump?.beforeTracing();

    // Reset all nodes that use lists/maps that have been inferred, as well
    // as nodes that use elements fetched from these lists/maps. The
    // workset for a new run of the analysis will be these nodes.
    Set<TypeInformation> seenTypes = new Set<TypeInformation>();
    while (!workQueue.isEmpty) {
      TypeInformation info = workQueue.remove();
      if (seenTypes.contains(info)) continue;
      // If the node cannot be reset, we do not need to update its users either.
      if (!info.reset(this)) continue;
      seenTypes.add(info);
      workQueue.addAll(info.users);
    }

    workQueue.addAll(seenTypes);
    refine();

    if (debug.PRINT_SUMMARY) {
      types.allocatedLists.values.forEach((ListTypeInformation info) {
        print('${info.type} '
            'for ${info.originalType.allocationNode} '
            'at ${info.originalType.allocationElement} '
            'after ${info.refineCount}');
      });
      types.allocatedMaps.values.forEach((MapTypeInformation info) {
        print('${info.type} '
            'for ${info.originalType.allocationNode} '
            'at ${info.originalType.allocationElement} '
            'after ${info.refineCount}');
      });
      types.allocatedClosures.forEach((TypeInformation info) {
        if (info is ElementTypeInformation) {
          print('${types.getInferredSignatureOf(info.element)} for '
              '${info.element}');
        } else if (info is ClosureTypeInformation) {
          print('${types.getInferredSignatureOf(info.element)} for '
              '${info.element}');
        } else if (info is DynamicCallSiteTypeInformation) {
          for (Element target in info.targets) {
            if (target is FunctionElement) {
              print('${types.getInferredSignatureOf(target)} for ${target}');
            } else {
              print('${types.getInferredTypeOf(target).type} for ${target}');
            }
          }
        } else if (info is StaticCallSiteTypeInformation) {
          ClassElement cls = info.calledElement.enclosingClass;
          FunctionElement callMethod = cls.lookupMember(Identifiers.call);
          print('${types.getInferredSignatureOf(callMethod)} for ${cls}');
        } else {
          print('${info.type} for some unknown kind of closure');
        }
      });
      analyzedElements.forEach((Element elem) {
        TypeInformation type = types.getInferredTypeOf(elem);
        print('${elem} :: ${type} from ${type.assignments} ');
      });
    }
    dump?.afterAnalysis();

    reporter.log('Inferred $overallRefineCount types.');

    processLoopInformation();
  }

  void analyze(ResolvedAst resolvedAst, ArgumentsTypes arguments) {
    AstElement element = resolvedAst.element.implementation;
    if (analyzedElements.contains(element)) return;
    analyzedElements.add(element);

    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor(element, resolvedAst, compiler, this);
    TypeInformation type;
    reporter.withCurrentElement(element, () {
      type = visitor.run();
    });
    addedInGraph++;

    if (element.isField) {
      VariableElement fieldElement = element;
      ast.Node node = resolvedAst.node;
      ast.Node initializer = resolvedAst.body;
      if (element.isFinal || element.isConst) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (resolvedAst.body != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            ConstantExpression constant = fieldElement.constant;
            if (constant != null) {
              ConstantValue value =
                  compiler.backend.constants.getConstantValue(constant);
              if (value != null) {
                if (value.isFunction) {
                  FunctionConstantValue functionConstant = value;
                  type = types.allocateClosure(node, functionConstant.element);
                } else {
                  // Although we might find a better type, we have to keep
                  // the old type around to ensure that we get a complete view
                  // of the type graph and do not drop any flow edges.
                  TypeMask refinedType = computeTypeMask(compiler, value);
                  assert(TypeMask.assertIsNormalized(refinedType, closedWorld));
                  type = new NarrowTypeInformation(type, refinedType);
                  types.allocatedTypes.add(type);
                }
              } else {
                assert(invariant(
                    fieldElement,
                    fieldElement.isInstanceMember ||
                        constant.isImplicit ||
                        constant.isPotential,
                    message: "Constant expression without value: "
                        "${constant.toStructuredText()}."));
              }
            }
          }
          recordType(element, type);
        } else if (!element.isInstanceMember) {
          recordType(element, types.nullType);
        }
      } else if (initializer == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (Elements.isStaticOrTopLevelField(element)) {
          recordTypeOfNonFinalField(node, element, type);
        }
      } else {
        recordTypeOfNonFinalField(node, element, type);
      }
      if (Elements.isStaticOrTopLevelField(element) &&
          resolvedAst.body != null &&
          !element.isConst) {
        var argument = resolvedAst.body;
        // TODO(13429): We could do better here by using the
        // constant handler to figure out if it's a lazy field or not.
        if (argument.asSend() != null ||
            (argument.asNewExpression() != null && !argument.isConst)) {
          recordType(element, types.nullType);
        }
      }
    } else {
      recordReturnType(element, type);
    }
  }

  void processLoopInformation() {
    allocatedCalls.forEach((info) {
      if (!info.inLoop) return;
      if (info is StaticCallSiteTypeInformation) {
        compiler.inferenceWorld.addFunctionCalledInLoop(info.calledElement);
      } else if (info.mask != null &&
          !info.mask.containsAll(compiler.closedWorld)) {
        // For instance methods, we only register a selector called in a
        // loop if it is a typed selector, to avoid marking too many
        // methods as being called from within a loop. This cuts down
        // on the code bloat.
        info.targets.forEach(compiler.inferenceWorld.addFunctionCalledInLoop);
      }
    });
  }

  void refine() {
    while (!workQueue.isEmpty) {
      if (compiler.shouldPrintProgress) {
        reporter.log('Inferred $overallRefineCount types.');
        compiler.progress.reset();
      }
      TypeInformation info = workQueue.remove();
      TypeMask oldType = info.type;
      TypeMask newType = info.refine(this);
      // Check that refinement has not accidentially changed the type.
      assert(oldType == info.type);
      if (info.abandonInferencing) info.doNotEnqueue = true;
      if ((info.type = newType) != oldType) {
        overallRefineCount++;
        info.refineCount++;
        if (info.refineCount > MAX_CHANGE_COUNT) {
          if (debug.ANOMALY_WARN) {
            print("ANOMALY WARNING: max refinement reached for $info");
          }
          info.giveUp(this);
          info.type = info.refine(this);
          info.doNotEnqueue = true;
        }
        workQueue.addAll(info.users);
        if (info.hasStableType(this)) {
          info.stabilize(this);
        }
      }
    }
  }

  void buildWorkQueue() {
    workQueue.addAll(types.typeInformations.values);
    workQueue.addAll(types.allocatedTypes);
    workQueue.addAll(types.allocatedClosures);
    workQueue.addAll(allocatedCalls);
  }

  /**
   * Update the assignments to parameters in the graph. [remove] tells
   * wheter assignments must be added or removed. If [init] is false,
   * parameters are added to the work queue.
   */
  void updateParameterAssignments(TypeInformation caller, Element callee,
      ArgumentsTypes arguments, Selector selector, TypeMask mask,
      {bool remove, bool addToQueue: true}) {
    if (callee.name == Identifiers.noSuchMethod_) return;
    if (callee.isField) {
      if (selector.isSetter) {
        ElementTypeInformation info = types.getInferredTypeOf(callee);
        if (remove) {
          info.removeAssignment(arguments.positional[0]);
        } else {
          info.addAssignment(arguments.positional[0]);
        }
        if (addToQueue) workQueue.add(info);
      }
    } else if (callee.isGetter) {
      return;
    } else if (selector != null && selector.isGetter) {
      // We are tearing a function off and thus create a closure.
      assert(callee.isFunction);
      MemberTypeInformation info = types.getInferredTypeOf(callee);
      if (remove) {
        info.closurizedCount--;
      } else {
        info.closurizedCount++;
        if (Elements.isStaticOrTopLevel(callee)) {
          types.allocatedClosures.add(info);
        } else {
          // We add the call-site type information here so that we
          // can benefit from further refinement of the selector.
          types.allocatedClosures.add(caller);
        }
        FunctionElement function = callee.implementation;
        FunctionSignature signature = function.functionSignature;
        signature.forEachParameter((Element parameter) {
          ParameterTypeInformation info = types.getInferredTypeOf(parameter);
          info.tagAsTearOffClosureParameter(this);
          if (addToQueue) workQueue.add(info);
        });
      }
    } else {
      FunctionElement function = callee.implementation;
      FunctionSignature signature = function.functionSignature;
      int parameterIndex = 0;
      bool visitingRequiredParameter = true;
      signature.forEachParameter((Element parameter) {
        if (signature.hasOptionalParameters &&
            parameter == signature.optionalParameters.first) {
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
        if (addToQueue) workQueue.add(info);
      });
    }
  }

  /**
   * Sets the type of a parameter's default value to [type]. If the global
   * mapping in [defaultTypeOfParameter] already contains a type, it must be
   * a [PlaceholderTypeInformation], which will be replaced. All its uses are
   * updated.
   */
  void setDefaultTypeOfParameter(
      ParameterElement parameter, TypeInformation type) {
    assert(parameter.functionDeclaration.isImplementation);
    TypeInformation existing = defaultTypeOfParameter[parameter];
    defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOf(parameter);
    if (existing != null && existing is PlaceholderTypeInformation) {
      // Replace references to [existing] to use [type] instead.
      if (parameter.functionDeclaration.isInstanceMember) {
        ParameterAssignments assignments = info.assignments;
        assignments.replace(existing, type);
      } else {
        List<TypeInformation> assignments = info.assignments;
        for (int i = 0; i < assignments.length; i++) {
          if (assignments[i] == existing) {
            assignments[i] = type;
          }
        }
      }
      // Also forward all users.
      type.addUsersOf(existing);
    } else {
      assert(existing == null);
    }
  }

  /**
   * Returns the [TypeInformation] node for the default value of a parameter.
   * If this is queried before it is set by [setDefaultTypeOfParameter], a
   * [PlaceholderTypeInformation] is returned, which will later be replaced
   * by the actual node when [setDefaultTypeOfParameter] is called.
   *
   * Invariant: After graph construction, no [PlaceholderTypeInformation] nodes
   *            should be present and a default type for each parameter should
   *            exist.
   */
  TypeInformation getDefaultTypeOfParameter(Element parameter) {
    return defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new PlaceholderTypeInformation(types.currentMember);
    });
  }

  /**
   * Helper to inspect the [TypeGraphInferrer]'s state. To be removed by
   * TODO(johnniwinther) once synthetic parameters get their own default
   * values.
   */
  bool hasAlreadyComputedTypeOfParameterDefault(Element parameter) {
    TypeInformation seen = defaultTypeOfParameter[parameter];
    return (seen != null && seen is! PlaceholderTypeInformation);
  }

  TypeInformation typeOfElement(Element element) {
    if (element is FunctionElement) return types.functionType;
    return types.getInferredTypeOf(element);
  }

  TypeInformation returnTypeOfElement(Element element) {
    if (element is! FunctionElement) return types.dynamicType;
    return types.getInferredTypeOf(element);
  }

  void recordTypeOfFinalField(
      Spannable node, Element analyzed, Element element, TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  void recordTypeOfNonFinalField(
      Spannable node, Element element, TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  void recordType(Element element, TypeInformation type) {
    types.getInferredTypeOf(element).addAssignment(type);
  }

  void recordReturnType(Element element, TypeInformation type) {
    TypeInformation info = types.getInferredTypeOf(element);
    if (element.name == '==') {
      // Even if x.== doesn't return a bool, 'x == null' evaluates to 'false'.
      info.addAssignment(types.boolType);
    }
    // TODO(ngeoffray): Clean up. We do these checks because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (type == null) return;
    if (info.assignments.isEmpty) info.addAssignment(type);
  }

  TypeInformation addReturnTypeFor(
      Element element, TypeInformation unused, TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOf(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element.isGenerativeConstructor) return type;
    type.addAssignment(newType);
    return type;
  }

  TypeInformation registerCalledElement(
      Spannable node,
      Selector selector,
      TypeMask mask,
      Element caller,
      Element callee,
      ArgumentsTypes arguments,
      SideEffects sideEffects,
      bool inLoop) {
    CallSiteTypeInformation info = new StaticCallSiteTypeInformation(
        types.currentMember,
        node,
        caller,
        callee,
        selector,
        mask,
        arguments,
        inLoop);
    // If this class has a 'call' method then we have essentially created a
    // closure here. Register it as such so that it is traced.
    if (selector != null && selector.isCall && callee.isConstructor) {
      ClassElement cls = callee.enclosingClass.declaration;
      if (cls.callType != null) {
        types.allocatedClosures.add(info);
      }
    }
    info.addToGraph(this);
    allocatedCalls.add(info);
    updateSideEffects(sideEffects, selector, callee);
    return info;
  }

  TypeInformation registerCalledSelector(
      ast.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation receiverType,
      Element caller,
      ArgumentsTypes arguments,
      SideEffects sideEffects,
      bool inLoop) {
    if (selector.isClosureCall) {
      return registerCalledClosure(node, selector, mask, receiverType, caller,
          arguments, sideEffects, inLoop);
    }

    compiler.closedWorld.allFunctions.filter(selector, mask).forEach((callee) {
      updateSideEffects(sideEffects, selector, callee);
    });

    CallSiteTypeInformation info = new DynamicCallSiteTypeInformation(
        types.currentMember,
        node,
        caller,
        selector,
        mask,
        receiverType,
        arguments,
        inLoop);

    info.addToGraph(this);
    allocatedCalls.add(info);
    return info;
  }

  TypeInformation registerAwait(ast.Node node, TypeInformation argument) {
    AwaitTypeInformation info =
        new AwaitTypeInformation(types.currentMember, node);
    info.addAssignment(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  TypeInformation registerCalledClosure(
      ast.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation closure,
      Element caller,
      ArgumentsTypes arguments,
      SideEffects sideEffects,
      bool inLoop) {
    sideEffects.setDependsOnSomething();
    sideEffects.setAllSideEffects();
    CallSiteTypeInformation info = new ClosureCallSiteTypeInformation(
        types.currentMember,
        node,
        caller,
        selector,
        mask,
        closure,
        arguments,
        inLoop);
    info.addToGraph(this);
    allocatedCalls.add(info);
    return info;
  }

  // Sorts the resolved elements by size. We do this for this inferrer
  // to get the same results for [ListTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<ResolvedAst> sortResolvedAsts() {
    int max = 0;
    Map<int, Setlet<ResolvedAst>> methodSizes = <int, Setlet<ResolvedAst>>{};
    compiler.enqueuer.resolution.processedEntities
        .forEach((AstElement element) {
      ResolvedAst resolvedAst = element.resolvedAst;
      element = element.implementation;
      if (element.impliesType) return;
      assert(invariant(
          element,
          element.isField ||
              element.isFunction ||
              element.isConstructor ||
              element.isGetter ||
              element.isSetter,
          message: 'Unexpected element kind: ${element.kind}'));
      if (element.isAbstract) return;
      // Put the other operators in buckets by length, later to be added in
      // length order.
      int length = 0;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        TreeElementMapping mapping = resolvedAst.elements;
        length = mapping.getSelectorCount();
      }
      max = length > max ? length : max;
      Setlet<ResolvedAst> set =
          methodSizes.putIfAbsent(length, () => new Setlet<ResolvedAst>());
      set.add(resolvedAst);
    });

    List<ResolvedAst> result = <ResolvedAst>[];
    for (int i = 0; i <= max; i++) {
      Setlet<ResolvedAst> set = methodSizes[i];
      if (set != null) result.addAll(set);
    }
    return result;
  }

  void clear() {
    void cleanup(TypeInformation info) => info.cleanup();

    allocatedCalls.forEach(cleanup);
    allocatedCalls.clear();

    defaultTypeOfParameter.clear();

    types.typeInformations.values.forEach(cleanup);

    types.allocatedTypes.forEach(cleanup);
    types.allocatedTypes.clear();

    types.concreteTypes.clear();

    types.allocatedClosures.forEach(cleanup);
    types.allocatedClosures.clear();

    analyzedElements.clear();
    generativeConstructorsExposingThis.clear();

    types.allocatedMaps.values.forEach(cleanup);
    types.allocatedLists.values.forEach(cleanup);
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    MemberTypeInformation info = types.getInferredTypeOf(element);
    return info.callers;
  }

  /**
   * Returns the type of [element] when being called with [selector].
   */
  TypeInformation typeOfElementWithSelector(
      Element element, Selector selector) {
    if (element.name == Identifiers.noSuchMethod_ &&
        selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfElement(element);
    } else if (selector.isGetter) {
      if (element.isFunction) {
        // [functionType] is null if the inferrer did not run.
        return types.functionType == null
            ? types.dynamicType
            : types.functionType;
      } else if (element.isField) {
        return typeOfElement(element);
      } else if (Elements.isUnresolved(element)) {
        return types.dynamicType;
      } else {
        assert(element.isGetter);
        return returnTypeOfElement(element);
      }
    } else if (element.isGetter || element.isField) {
      assert(selector.isCall || selector.isSetter);
      return types.dynamicType;
    } else {
      return returnTypeOfElement(element);
    }
  }

  void recordCapturedLocalRead(Local local) {}

  void recordLocalUpdate(Local local, TypeInformation type) {}
}

class TypeGraphInferrer implements TypesInferrer {
  TypeGraphInferrerEngine inferrer;
  final Compiler compiler;
  final CommonMasks commonMasks;
  TypeGraphInferrer(this.compiler, this.commonMasks);

  String get name => 'Graph inferrer';
  TypeMask get _dynamicType => commonMasks.dynamicType;

  void analyzeMain(Element main) {
    inferrer = new TypeGraphInferrerEngine(compiler, commonMasks, main);
    inferrer.runOverAllElements();
  }

  TypeMask getReturnTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return _dynamicType;
    // Currently, closure calls return dynamic.
    if (element is! FunctionElement) return _dynamicType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeOfElement(Element element) {
    if (compiler.disableTypeInference) return _dynamicType;
    // The inferrer stores the return type for a function, so we have to
    // be careful to not return it here.
    if (element is FunctionElement) return commonMasks.functionType;
    return inferrer.types.getInferredTypeOf(element).type;
  }

  TypeMask getTypeForNewList(Element owner, ast.Node node) {
    if (compiler.disableTypeInference) return _dynamicType;
    return inferrer.types.allocatedLists[node].type;
  }

  bool isFixedArrayCheckedForGrowable(ast.Node node) {
    if (compiler.disableTypeInference) return true;
    ListTypeInformation info = inferrer.types.allocatedLists[node];
    return info.checksGrowable;
  }

  TypeMask getTypeOfSelector(Selector selector, TypeMask mask) {
    if (compiler.disableTypeInference) return _dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall) return _dynamicType;
    if (selector.isSetter || selector.isIndexSet) {
      return _dynamicType;
    }
    if (inferrer.returnsListElementType(selector, mask)) {
      ContainerTypeMask containerTypeMask = mask;
      TypeMask elementType = containerTypeMask.elementType;
      return elementType == null ? _dynamicType : elementType;
    }
    if (inferrer.returnsMapValueType(selector, mask)) {
      MapTypeMask mapTypeMask = mask;
      TypeMask valueType = mapTypeMask.valueType;
      return valueType == null ? _dynamicType : valueType;
    }

    TypeMask result = const TypeMask.nonNullEmpty();
    Iterable<Element> elements =
        compiler.closedWorld.allFunctions.filter(selector, mask);
    for (Element element in elements) {
      TypeMask type =
          inferrer.typeOfElementWithSelector(element, selector).type;
      result = result.union(type, compiler.closedWorld);
    }
    return result;
  }

  Iterable<Element> getCallersOf(Element element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    return inferrer.getCallersOf(element);
  }

  bool isCalledOnce(Element element) {
    if (compiler.disableTypeInference) return false;
    MemberTypeInformation info = inferrer.types.getInferredTypeOf(element);
    return info.isCalledOnce();
  }

  void clear() {
    inferrer.clear();
  }
}
