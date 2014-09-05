// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_graph_inferrer;

import 'dart:collection' show Queue, IterableBase;
import '../dart_types.dart' show DartType, InterfaceType, TypeKind;
import '../elements/elements.dart';
import '../tree/tree.dart' as ast show DartString, Node;
import '../cps_ir/cps_ir_nodes.dart' as cps_ir show Node;
import '../types/types.dart'
  show TypeMask, ContainerTypeMask, MapTypeMask, DictionaryTypeMask,
       ValueTypeMask, TypesInferrer;
import '../universe/universe.dart' show Selector, TypedSelector, SideEffects;
import '../dart2jslib.dart'
    show ClassWorld,
         Compiler,
         Constant,
         FunctionConstant,
         invariant,
         TreeElementMapping;
import 'inferrer_visitor.dart' show TypeSystem, ArgumentsTypes;
import '../native_handler.dart' as native;
import '../util/util.dart' show Spannable, Setlet, ImmutableEmptySet;
import 'simple_types_inferrer.dart';

part 'type_graph_nodes.dart';
part 'closure_tracer.dart';
part 'list_tracer.dart';
part 'node_tracer.dart';
part 'map_tracer.dart';

bool _VERBOSE = false;
bool _PRINT_SUMMARY = false;
final _ANOMALY_WARN = false;

class TypeInformationSystem extends TypeSystem<TypeInformation> {
  final Compiler compiler;
  final ClassWorld classWorld;

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

  TypeInformationSystem(Compiler compiler)
      : this.compiler = compiler,
        this.classWorld = compiler.world {
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

  TypeInformation uint32TypeCache;
  TypeInformation get uint32Type {
    if (uint32TypeCache != null) return uint32TypeCache;
    return uint32TypeCache = getConcreteTypeFor(compiler.typesTask.uint32Type);
  }

  TypeInformation uint31TypeCache;
  TypeInformation get uint31Type {
    if (uint31TypeCache != null) return uint31TypeCache;
    return uint31TypeCache = getConcreteTypeFor(compiler.typesTask.uint31Type);
  }

  TypeInformation positiveIntTypeCache;
  TypeInformation get positiveIntType {
    if (positiveIntTypeCache != null) return positiveIntTypeCache;
    return positiveIntTypeCache =
        getConcreteTypeFor(compiler.typesTask.positiveIntType);
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

  TypeInformation stringLiteralType(ast.DartString value) {
    return new StringLiteralTypeInformation(
        value, compiler.typesTask.stringType);
  }

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
        firstType.type.union(secondType.type, classWorld));
  }

  bool selectorNeedsUpdate(TypeInformation info, Selector selector)
  {
    return info.type != selector.mask;
  }

  TypeInformation refineReceiver(Selector selector, TypeInformation receiver) {
    if (receiver.type.isExact) return receiver;
    TypeMask otherType = compiler.world.allFunctions.receiverType(selector);
    // If this is refining to nullable subtype of `Object` just return
    // the receiver. We know the narrowing is useless.
    if (otherType.isNullable && otherType.containsAll(classWorld)) {
      return receiver;
    }
    assert(TypeMask.isNormalized(otherType, classWorld));
    TypeInformation newType = new NarrowTypeInformation(receiver, otherType);
    allocatedTypes.add(newType);
    return newType;
  }

  TypeInformation narrowType(TypeInformation type,
                             DartType annotation,
                             {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return nullType;
    if (annotation.element == classWorld.objectClass && isNullable) return type;
    TypeMask otherType;
    if (annotation.isTypedef || annotation.isFunctionType) {
      otherType = functionType.type;
    } else if (annotation.isTypeVariable) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      assert(annotation.isInterfaceType);
      otherType = annotation.element == classWorld.objectClass
          ? dynamicType.type.nonNullable()
          : new TypeMask.nonNullSubtype(annotation.element, classWorld);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type.type.isExact) {
      return type;
    } else {
      assert(TypeMask.isNormalized(otherType, classWorld));
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
        new TypeMask.nonNullSubtype(type.declaration, classWorld));
  }

  TypeInformation nonNullSubclass(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullSubclass(type.declaration, classWorld));
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

  TypeInformation allocateList(TypeInformation type,
                               ast.Node node,
                               Element enclosing,
                               [TypeInformation elementType, int length]) {
    bool isTypedArray = (compiler.typedDataClass != null) &&
        type.type.satisfies(compiler.typedDataClass, classWorld);
    bool isConst = (type.type == compiler.typesTask.constListType);
    bool isFixed = (type.type == compiler.typesTask.fixedListType) ||
                   isConst ||
                   isTypedArray;
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
    return allocatedLists[node] =
        new ListTypeInformation(mask, element, length);
  }

  TypeInformation allocateClosure(ast.Node node, Element element) {
    TypeInformation result = new ClosureTypeInformation(node, element);
    allocatedClosures.add(result);
    return result;
  }

  TypeInformation allocateMap(ConcreteTypeInformation type,
                              ast.Node node,
                              Element element,
                              [List<TypeInformation> keyTypes,
                               List<TypeInformation> valueTypes]) {
    assert(keyTypes.length == valueTypes.length);
    bool isFixed = (type.type == compiler.typesTask.constMapType);

    TypeMask keyType, valueType;
    if (isFixed) {
      keyType = keyTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, classWorld));
      valueType = valueTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, classWorld));
    } else {
      keyType = valueType = dynamicType.type;
    }
    MapTypeMask mask = new MapTypeMask(type.type,
                                       node,
                                       element,
                                       keyType,
                                       valueType);

    TypeInformation keyTypeInfo = new KeyInMapTypeInformation(null);
    TypeInformation valueTypeInfo = new ValueInMapTypeInformation(null);
    allocatedTypes.add(keyTypeInfo);
    allocatedTypes.add(valueTypeInfo);

    MapTypeInformation map =
        new MapTypeInformation(mask, keyTypeInfo, valueTypeInfo);

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

  Selector newTypedSelector(TypeInformation info, Selector selector) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete
        ? new TypedSelector(info.type, selector, classWorld)
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

  PhiElementTypeInformation allocatePhi(ast.Node node,
                                        Local variable,
                                        inputType) {
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation &&
        inputType.branchNode == node) {
      return inputType;
    }
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(node, true, variable);
    allocatedTypes.add(result);
    result.addAssignment(inputType);
    return result;
  }

  TypeInformation simplifyPhi(ast.Node node,
                              Local variable,
                              PhiElementTypeInformation phiType) {
    if (phiType.assignments.length == 1) return phiType.assignments.first;
    return phiType;
  }

  PhiElementTypeInformation addPhiInput(Local variable,
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
      newType = newType.union(mask, classWorld);
    }
    return newType.containsAll(classWorld) ? dynamicType.type : newType;
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
  final Set<Element> analyzedElements = new Set<Element>();

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 6;

  int overallRefineCount = 0;
  int addedInGraph = 0;

  TypeGraphInferrerEngine(Compiler compiler, this.mainElement)
        : super(compiler, new TypeInformationSystem(compiler));

  /**
   * A set of selector names that [List] implements, that we know return
   * their element type.
   */
  final Set<Selector> _returnsListElementTypeSet = new Set<Selector>.from(
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

  bool returnsListElementType(Selector selector) {
    return (selector.mask != null) &&
           selector.mask.isContainer &&
           _returnsListElementTypeSet.contains(selector.asUntyped);
  }

  bool returnsMapValueType(Selector selector) {
    return (selector.mask != null) &&
           selector.mask.isMap &&
           selector.isIndex;
  }

  void analyzeListAndEnqueue(ListTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    ListTracerVisitor tracer = new ListTracerVisitor(info, this);
    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    info.elementType.inferred = true;
    TypeMask fixedListType = compiler.typesTask.fixedListType;
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
    if (compiler.verbose) {
      compiler.progress.reset();
    }
    sortResolvedElements().forEach((Element element) {
      if (compiler.shouldPrintProgress) {
        compiler.log('Added $addedInGraph elements in inferencing graph.');
        compiler.progress.reset();
      }
      // Force the creation of the [ElementTypeInformation] to ensure it is
      // in the graph.
      types.getInferredTypeOf(element);
      analyze(element, null);
    });
    compiler.log('Added $addedInGraph elements in inferencing graph.');

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

    // Trace closures to potentially infer argument types.
    types.allocatedClosures.forEach((info) {
      void trace(Iterable<FunctionElement> elements,
                 ClosureTracerVisitor tracer) {
        tracer.run();
        if (!tracer.continueAnalyzing) {
          elements.forEach((FunctionElement e) {
            compiler.world.registerMightBePassedToApply(e);
            if (_VERBOSE) print("traced closure $e as ${true} (bail)");
          });
          return;
        }
        elements.forEach((FunctionElement e) {
          e.functionSignature.forEachParameter((parameter) {
            workQueue.add(types.getInferredTypeOf(parameter));
          });
          if (tracer.tracedType.mightBePassedToFunctionApply) {
            compiler.world.registerMightBePassedToApply(e);
          };
          if (_VERBOSE) {
            print("traced closure $e as "
                "${compiler.world.getMightBePassedToApply(e)}");
          }
        });
      }
      if (info is ClosureTypeInformation) {
        Iterable<FunctionElement> elements = [info.element];
        trace(elements, new ClosureTracerVisitor(elements, info, this));
      } else if (info is CallSiteTypeInformation) {
        // We only are interested in functions here, as other targets
        // of this closure call are not a root to trace but an intermediate
        // for some other function.
        Iterable<FunctionElement> elements = info.callees
            .where((e) => e.isFunction);
        trace(elements, new ClosureTracerVisitor(elements, info, this));
      } else {
        assert(info is ElementTypeInformation);
        trace([info.element],
            new StaticTearOffClosureTracerVisitor(info.element, info, this));
      }
    });

    // Reset all nodes that use lists/maps that have been inferred, as well
    // as nodes that use elements fetched from these lists/maps. The
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

    if (_PRINT_SUMMARY) {
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
        } else {
          print('${info.type} for some unknown kind of closure');
        }
      });
      analyzedElements.forEach((Element elem) {
        TypeInformation type = types.getInferredTypeOf(elem);
        print('${elem} :: ${type} from ${type.assignments} ');
      });
    }

    compiler.log('Inferred $overallRefineCount types.');

    processLoopInformation();
  }

  void analyze(Element element, ArgumentsTypes arguments) {
    element = element.implementation;
    if (analyzedElements.contains(element)) return;
    analyzedElements.add(element);

    SimpleTypeInferrerVisitor visitor =
        new SimpleTypeInferrerVisitor(element, compiler, this);
    TypeInformation type;
    compiler.withCurrentElement(element, () {
      type = visitor.run();
    });
    addedInGraph++;

    if (element.isField) {
      VariableElement fieldElement = element;
      ast.Node node = fieldElement.node;
      if (element.isFinal || element.isConst) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (fieldElement.initializer != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            Constant value = compiler.backend.constants
                .getConstantForVariable(element);
            if (value != null) {
              if (value.isFunction) {
                FunctionConstant functionConstant = value;
                type = types.allocateClosure(node, functionConstant.element);
              } else {
                // Although we might find a better type, we have to keep
                // the old type around to ensure that we get a complete view
                // of the type graph and do not drop any flow edges.
                TypeMask refinedType = value.computeMask(compiler);
                assert(TypeMask.isNormalized(refinedType, classWorld));
                type = new NarrowTypeInformation(type, refinedType);
                types.allocatedTypes.add(type);
              }
            }
          }
          recordType(element, type);
        } else if (!element.isInstanceMember) {
          recordType(element, types.nullType);
        }
      } else if (fieldElement.initializer == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (Elements.isStaticOrTopLevelField(element)) {
          recordTypeOfNonFinalField(node, element, type);
        }
      } else {
        recordTypeOfNonFinalField(node, element, type);
      }
      if (Elements.isStaticOrTopLevelField(element) &&
          fieldElement.initializer != null &&
          !element.isConst) {
        var argument = fieldElement.initializer;
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
        compiler.world.addFunctionCalledInLoop(info.calledElement);
      } else if (info.selector.mask != null &&
                 !info.selector.mask.containsAll(compiler.world)) {
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
      if (compiler.shouldPrintProgress) {
        compiler.log('Inferred $overallRefineCount types.');
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
          if (_ANOMALY_WARN) {
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
  void updateParameterAssignments(TypeInformation caller,
                                  Element callee,
                                  ArgumentsTypes arguments,
                                  Selector selector,
                                  {bool remove, bool addToQueue: true}) {
    if (callee.name == Compiler.NO_SUCH_METHOD) return;
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
            parameter == signature.firstOptionalParameter) {
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
  void setDefaultTypeOfParameter(ParameterElement parameter,
                                 TypeInformation type) {
    assert(parameter.functionDeclaration.isImplementation);
    TypeInformation existing = defaultTypeOfParameter[parameter];
    defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOf(parameter);
    if (existing != null && existing is PlaceholderTypeInformation) {
      // Replace references to [existing] to use [type] instead.
      if (parameter.functionDeclaration.isInstanceMember) {
        ParameterAssignments assignments = info.assignments;
        assignments.replace(existing, type);
        type.addUser(info);
      } else {
        List<TypeInformation> assignments = info.assignments;
        for (int i = 0; i < assignments.length; i++) {
          if (assignments[i] == existing) {
            assignments[i] = type;
            type.addUser(info);
          }
        }
      }
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
      return new PlaceholderTypeInformation();
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

  TypeInformation addReturnTypeFor(Element element,
                                   TypeInformation unused,
                                   TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOf(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element.isGenerativeConstructor) return type;
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

  TypeInformation registerCalledSelector(ast.Node node,
                                         Selector selector,
                                         TypeInformation receiverType,
                                         Element caller,
                                         ArgumentsTypes arguments,
                                         SideEffects sideEffects,
                                         bool inLoop) {
    if (selector.isClosureCall) {
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

  TypeInformation registerCalledClosure(ast.Node node,
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
  // to get the same results for [ListTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<Element> sortResolvedElements() {
    int max = 0;
    Map<int, Setlet<Element>> methodSizes = new Map<int, Setlet<Element>>();
    compiler.enqueuer.resolution.resolvedElements.forEach((AstElement element) {
        // TODO(ngeoffray): Not sure why the resolver would put a null
        // mapping.
        if (!compiler.enqueuer.resolution.hasBeenResolved(element)) return;
        TreeElementMapping mapping = element.resolvedAst.elements;
        element = element.implementation;
        if (element.impliesType) return;
        assert(invariant(element,
            element.isField ||
            element.isFunction ||
            element.isGenerativeConstructor ||
            element.isGetter ||
            element.isSetter,
            message: 'Unexpected element kind: ${element.kind}'));
        if (element.isAbstract) return;
        // Put the other operators in buckets by length, later to be added in
        // length order.
        int length = mapping.getSelectorCount();
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
    types.allocatedClosures.clear();
    analyzedElements.clear();
    generativeConstructorsExposingThis.clear();
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
  TypeInformation typeOfElementWithSelector(Element element,
                                            Selector selector) {
    if (element.name == Compiler.NO_SUCH_METHOD &&
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

  TypeMask getTypeOfNode(Element owner, ast.Node node) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    return inferrer.types.allocatedLists[node].type;
  }

  bool isFixedArrayCheckedForGrowable(ast.Node node) {
    if (compiler.disableTypeInference) return true;
    ListTypeInformation info = inferrer.types.allocatedLists[node];
    return info.checksGrowable;
  }

  TypeMask getTypeOfSelector(Selector selector) {
    if (compiler.disableTypeInference) return compiler.typesTask.dynamicType;
    // Bailout for closure calls. We're not tracking types of
    // closures.
    if (selector.isClosureCall) return compiler.typesTask.dynamicType;
    if (selector.isSetter || selector.isIndexSet) {
      return compiler.typesTask.dynamicType;
    }
    if (inferrer.returnsListElementType(selector)) {
      ContainerTypeMask mask = selector.mask;
      TypeMask elementType = mask.elementType;
      return elementType == null ? compiler.typesTask.dynamicType : elementType;
    }
    if (inferrer.returnsMapValueType(selector)) {
      MapTypeMask mask = selector.mask;
      TypeMask valueType = mask.valueType;
      return valueType == null ? compiler.typesTask.dynamicType
                               : valueType;
    }

    TypeMask result = const TypeMask.nonNullEmpty();
    Iterable<Element> elements = compiler.world.allFunctions.filter(selector);
    for (Element element in elements) {
      TypeMask type =
          inferrer.typeOfElementWithSelector(element, selector).type;
      result = result.union(type, compiler.world);
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
