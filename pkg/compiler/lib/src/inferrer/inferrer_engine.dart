// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../../compiler_new.dart';
import '../closure.dart';
import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../common_elements.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_model/element_map.dart';
import '../js_model/js_world.dart';
import '../js_model/locals.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../world.dart';
import 'abstract_value_domain.dart';
import 'builder_kernel.dart';
import 'closure_tracer.dart';
import 'debug.dart' as debug;
import 'locals_handler.dart';
import 'list_tracer.dart';
import 'map_tracer.dart';
import 'type_graph_dump.dart';
import 'type_graph_inferrer.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';
import 'types.dart';

/// An inferencing engine that computes a call graph of [TypeInformation] nodes
/// by visiting the AST of the application, and then does the inferencing on the
/// graph.
abstract class InferrerEngine {
  /// A set of selector names that [List] implements, that we know return their
  /// element type.
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

  CompilerOptions get options;
  JClosedWorld get closedWorld;
  DiagnosticReporter get reporter;
  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;
  CommonElements get commonElements => closedWorld.commonElements;

  // TODO(johnniwinther): This should be part of [ClosedWorld] or
  // [ClosureWorldRefiner].
  NoSuchMethodData get noSuchMethodData => closedWorld.noSuchMethodData;

  TypeSystem get types;
  Map<ir.Node, TypeInformation> get concreteTypes;
  InferredDataBuilder get inferredDataBuilder;

  FunctionEntity get mainElement;

  void runOverAllElements();

  void analyze(MemberEntity member);
  void analyzeListAndEnqueue(ListTypeInformation info);
  void analyzeMapAndEnqueue(MapTypeInformation info);

  /// Notifies to the inferrer that [analyzedElement] can have return type
  /// [newType]. [currentType] is the type the inference has currently found.
  ///
  /// Returns the new type for [analyzedElement].
  TypeInformation addReturnTypeForMethod(
      FunctionEntity element, TypeInformation unused, TypeInformation newType);

  /// Applies [f] to all elements in the universe that match [selector] and
  /// [mask]. If [f] returns false, aborts the iteration.
  void forEachElementMatching(
      Selector selector, AbstractValue mask, bool f(MemberEntity element));

  /// Returns the [TypeInformation] node for the default value of a parameter.
  /// If this is queried before it is set by [setDefaultTypeOfParameter], a
  /// [PlaceholderTypeInformation] is returned, which will later be replaced
  /// by the actual node when [setDefaultTypeOfParameter] is called.
  ///
  /// Invariant: After graph construction, no [PlaceholderTypeInformation] nodes
  /// should be present and a default type for each parameter should exist.
  TypeInformation getDefaultTypeOfParameter(Local parameter);

  /// This helper breaks abstractions but is currently required to work around
  /// the wrong modeling of default values of optional parameters of
  /// synthetic constructors.
  ///
  /// TODO(johnniwinther): Remove once default values of synthetic parameters
  /// are fixed.
  bool hasAlreadyComputedTypeOfParameterDefault(Local parameter);

  /// Sets the type of a parameter's default value to [type]. If the global
  /// mapping in [defaultTypeOfParameter] already contains a type, it must be
  /// a [PlaceholderTypeInformation], which will be replaced. All its uses are
  /// updated.
  void setDefaultTypeOfParameter(Local parameter, TypeInformation type,
      {bool isInstanceMember});

  Iterable<MemberEntity> getCallersOfForTesting(MemberEntity element);

  // TODO(johnniwinther): Make this private again.
  GlobalTypeInferenceElementData dataOfMember(MemberEntity element);

  bool checkIfExposesThis(ConstructorEntity element);

  void recordExposesThis(ConstructorEntity element, bool exposesThis);

  /// Records that the return type [element] is of type [type].
  void recordReturnType(FunctionEntity element, TypeInformation type);

  /// Records that [element] is of type [type].
  void recordTypeOfField(FieldEntity element, TypeInformation type);

  /// Registers a call to await with an expression of type [argumentType] as
  /// argument.
  TypeInformation registerAwait(ir.Node node, TypeInformation argument);

  /// Registers a call to yield with an expression of type [argumentType] as
  /// argument.
  TypeInformation registerYield(ir.Node node, TypeInformation argument);

  /// Registers that [caller] calls [closure] with [arguments].
  ///
  /// [sideEffectsBuilder] will be updated to incorporate the potential callees'
  /// side effects.
  ///
  /// [inLoop] tells whether the call happens in a loop.
  TypeInformation registerCalledClosure(
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation closure,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop});

  /// Registers that [caller] calls [callee] at location [node], with
  /// [selector], and [arguments]. Note that [selector] is null for forwarding
  /// constructors.
  ///
  /// [sideEffectsBuilder] will be updated to incorporate [callee]'s side
  /// effects.
  ///
  /// [inLoop] tells whether the call happens in a loop.
  TypeInformation registerCalledMember(
      Object node,
      Selector selector,
      AbstractValue mask,
      MemberEntity caller,
      MemberEntity callee,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      bool inLoop);

  /// Registers that [caller] calls [selector] with [receiverType] as receiver,
  /// and [arguments].
  ///
  /// [sideEffectsBuilder] will be updated to incorporate the potential callees'
  /// side effects.
  ///
  /// [inLoop] tells whether the call happens in a loop.
  TypeInformation registerCalledSelector(
      CallType callType,
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation receiverType,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop,
      bool isConditional});

  /// Update the assignments to parameters in the graph. [remove] tells whether
  /// assignments must be added or removed. If [init] is false, parameters are
  /// added to the work queue.
  void updateParameterAssignments(TypeInformation caller, MemberEntity callee,
      ArgumentsTypes arguments, Selector selector, AbstractValue mask,
      {bool remove, bool addToQueue: true});

  void updateSelectorInMember(MemberEntity owner, CallType callType,
      ir.Node node, Selector selector, AbstractValue mask);

  /// Returns the return type of [element].
  TypeInformation returnTypeOfMember(MemberEntity element);

  /// Returns the type of [element] when being called with [selector].
  TypeInformation typeOfMemberWithSelector(
      MemberEntity element, Selector selector);

  /// Returns the type of [element].
  TypeInformation typeOfMember(MemberEntity element);

  /// Returns the type of [element].
  TypeInformation typeOfParameter(Local element);

  /// Returns the type for [nativeBehavior]. See documentation on
  /// [NativeBehavior].
  TypeInformation typeOfNativeBehavior(NativeBehavior nativeBehavior);

  bool returnsListElementType(Selector selector, AbstractValue mask);

  bool returnsMapValueType(Selector selector, AbstractValue mask);

  void close();

  void clear();

  /// Returns true if global optimizations such as type inferencing can apply to
  /// the field [element].
  ///
  /// One category of elements that do not apply is runtime helpers that the
  /// backend calls, but the optimizations don't see those calls.
  bool canFieldBeUsedForGlobalOptimizations(FieldEntity element);

  /// Returns true if global optimizations such as type inferencing can apply to
  /// the parameter [element].
  ///
  /// One category of elements that do not apply is runtime helpers that the
  /// backend calls, but the optimizations don't see those calls.
  bool canFunctionParametersBeUsedForGlobalOptimizations(
      FunctionEntity function);

  /// Returns `true` if inference of parameter types is disabled for [member].
  bool assumeDynamic(MemberEntity member);
}

class InferrerEngineImpl extends InferrerEngine {
  final Map<Local, TypeInformation> defaultTypeOfParameter =
      new Map<Local, TypeInformation>();
  final WorkQueue workQueue = new WorkQueue();
  final FunctionEntity mainElement;
  final Set<MemberEntity> analyzedElements = new Set<MemberEntity>();

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 6;

  int overallRefineCount = 0;
  int addedInGraph = 0;

  final CompilerOptions options;
  final Progress progress;
  final DiagnosticReporter reporter;
  final CompilerOutput _compilerOutput;

  /// The [JClosedWorld] on which inference reasoning is based.
  final JsClosedWorld closedWorld;
  final InferredDataBuilder inferredDataBuilder;

  final TypeSystem types;
  final Map<ir.Node, TypeInformation> concreteTypes =
      new Map<ir.Node, TypeInformation>();

  final Set<ConstructorEntity> generativeConstructorsExposingThis =
      new Set<ConstructorEntity>();

  /// Data computed internally within elements, like the type-mask of a send a
  /// list allocation, or a for-in loop.
  final Map<MemberEntity, GlobalTypeInferenceElementData> _memberData =
      new Map<MemberEntity, GlobalTypeInferenceElementData>();

  final NoSuchMethodRegistry noSuchMethodRegistry;

  InferrerEngineImpl(
      this.options,
      this.progress,
      this.reporter,
      this._compilerOutput,
      this.closedWorld,
      this.noSuchMethodRegistry,
      this.mainElement,
      this.inferredDataBuilder)
      : this.types = new TypeSystem(
            closedWorld, new KernelTypeSystemStrategy(closedWorld));

  ElementEnvironment get _elementEnvironment => closedWorld.elementEnvironment;

  void forEachElementMatching(
      Selector selector, AbstractValue mask, bool f(MemberEntity element)) {
    Iterable<MemberEntity> elements = closedWorld.locateMembers(selector, mask);
    for (MemberEntity e in elements) {
      if (!f(e)) return;
    }
  }

  // TODO(johnniwinther): Make this private again.
  GlobalTypeInferenceElementData dataOfMember(MemberEntity element) =>
      _memberData[element] ??= new KernelGlobalTypeInferenceElementData();

  /// Update [sideEffects] with the side effects of [callee] being
  /// called with [selector].
  void updateSideEffects(SideEffectsBuilder sideEffectsBuilder,
      Selector selector, MemberEntity callee) {
    if (callee.isField) {
      if (callee.isInstanceMember) {
        if (selector.isSetter) {
          sideEffectsBuilder.setChangesInstanceProperty();
        } else if (selector.isGetter) {
          sideEffectsBuilder.setDependsOnInstancePropertyStore();
        } else {
          sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
        }
      } else {
        if (selector.isSetter) {
          sideEffectsBuilder.setChangesStaticProperty();
        } else if (selector.isGetter) {
          sideEffectsBuilder.setDependsOnStaticPropertyStore();
        } else {
          sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
        }
      }
    } else if (callee.isGetter && !selector.isGetter) {
      sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    } else {
      sideEffectsBuilder
          .addInput(inferredDataBuilder.getSideEffectsBuilder(callee));
    }
  }

  TypeInformation typeOfNativeBehavior(NativeBehavior nativeBehavior) {
    if (nativeBehavior == null) return types.dynamicType;
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return types.dynamicType;
    TypeInformation returnType;
    for (var type in typesReturned) {
      TypeInformation mappedType;
      if (type == SpecialType.JsObject) {
        mappedType = types.nonNullExact(commonElements.objectClass);
      } else if (type == commonElements.stringType) {
        mappedType = types.stringType;
      } else if (type == commonElements.intType) {
        mappedType = types.intType;
      } else if (type == commonElements.numType ||
          type == commonElements.doubleType) {
        // Note: the backend double class is specifically for non-integer
        // doubles, and a native behavior returning 'double' does not guarantee
        // a non-integer return type, so we return the number type for those.
        mappedType = types.numType;
      } else if (type == commonElements.boolType) {
        mappedType = types.boolType;
      } else if (type == commonElements.nullType) {
        mappedType = types.nullType;
      } else if (type.isVoid) {
        mappedType = types.nullType;
      } else if (type.isDynamic) {
        return types.dynamicType;
      } else if (type.isInterfaceType) {
        mappedType = types.nonNullSubtype(type.element);
      } else {
        mappedType = types.dynamicType;
      }
      returnType = types.computeLUB(returnType, mappedType);
      if (returnType == types.dynamicType) {
        break;
      }
    }
    return returnType;
  }

  void updateSelectorInMember(MemberEntity owner, CallType callType,
      ir.Node node, Selector selector, AbstractValue mask) {
    KernelGlobalTypeInferenceElementData data = dataOfMember(owner);
    assert(validCallType(callType, node));
    switch (callType) {
      case CallType.access:
        data.setTypeMask(node, mask);
        break;
      case CallType.forIn:
        if (selector == Selectors.iterator) {
          data.setIteratorTypeMask(node, mask);
        } else if (selector == Selectors.current) {
          data.setCurrentTypeMask(node, mask);
        } else {
          assert(selector == Selectors.moveNext);
          data.setMoveNextTypeMask(node, mask);
        }
        break;
    }
  }

  bool checkIfExposesThis(ConstructorEntity element) {
    return generativeConstructorsExposingThis.contains(element);
  }

  void recordExposesThis(ConstructorEntity element, bool exposesThis) {
    if (exposesThis) {
      generativeConstructorsExposingThis.add(element);
    }
  }

  bool returnsListElementType(Selector selector, AbstractValue mask) {
    return mask != null &&
        abstractValueDomain.isContainer(mask) &&
        returnsListElementTypeSet.contains(selector);
  }

  bool returnsMapValueType(Selector selector, AbstractValue mask) {
    return mask != null && abstractValueDomain.isMap(mask) && selector.isIndex;
  }

  void analyzeListAndEnqueue(ListTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    ListTracerVisitor tracer = new ListTracerVisitor(info, this);
    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    info.elementType.inferred = true;
    if (abstractValueDomain.isSpecializationOf(
        info.originalType, abstractValueDomain.fixedListType)) {
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
      TypeInformation newType = info.addEntryAssignment(abstractValueDomain,
          tracer.keyAssignments[i], tracer.valueAssignments[i]);
      if (newType != null) workQueue.add(newType);
    }
    for (TypeInformation map in tracer.mapAssignments) {
      workQueue.addAll(info.addMapAssignment(abstractValueDomain, map));
    }

    info.markAsInferred();
    workQueue.add(info.keyType);
    workQueue.add(info.valueType);
    workQueue.addAll(info.typeInfoMap.values);
    workQueue.add(info);
  }

  void runOverAllElements() {
    analyzeAllElements();
    TypeGraphDump dump =
        debug.PRINT_GRAPH ? new TypeGraphDump(_compilerOutput, this) : null;

    dump?.beforeAnalysis();
    buildWorkQueue();
    refine();

    // Try to infer element types of lists and compute their escape information.
    types.allocatedLists.values.forEach((TypeInformation info) {
      analyzeListAndEnqueue(info);
    });

    // Try to infer the key and value types for maps and compute the values'
    // escape information.
    types.allocatedMaps.values.forEach((TypeInformation info) {
      analyzeMapAndEnqueue(info);
    });

    Set<FunctionEntity> bailedOutOn = new Set<FunctionEntity>();

    // Trace closures to potentially infer argument types.
    types.allocatedClosures.forEach((dynamic info) {
      void trace(
          Iterable<FunctionEntity> elements, ClosureTracerVisitor tracer) {
        tracer.run();
        if (!tracer.continueAnalyzing) {
          elements.forEach((FunctionEntity element) {
            inferredDataBuilder.registerMightBePassedToApply(element);
            if (debug.VERBOSE) {
              print("traced closure $element as ${true} (bail)");
            }
            types.strategy.forEachParameter(element, (Local parameter) {
              types
                  .getInferredTypeOfParameter(parameter)
                  .giveUp(this, clearAssignments: false);
            });
          });
          bailedOutOn.addAll(elements);
          return;
        }
        elements
            .where((e) => !bailedOutOn.contains(e))
            .forEach((FunctionEntity element) {
          types.strategy.forEachParameter(element, (Local parameter) {
            ParameterTypeInformation info =
                types.getInferredTypeOfParameter(parameter);
            info.maybeResume();
            workQueue.add(info);
          });
          if (tracer.tracedType.mightBePassedToFunctionApply) {
            inferredDataBuilder.registerMightBePassedToApply(element);
          }
          if (debug.VERBOSE) {
            print("traced closure $element as "
                "${inferredDataBuilder.getCurrentlyKnownMightBePassedToApply(element)}");
          }
        });
      }

      if (info is ClosureTypeInformation) {
        Iterable<FunctionEntity> elements = [info.closure];
        trace(elements, new ClosureTracerVisitor(elements, info, this));
      } else if (info is CallSiteTypeInformation) {
        if (info is StaticCallSiteTypeInformation &&
            info.selector != null &&
            info.selector.isCall) {
          // This is a constructor call to a class with a call method. So we
          // need to trace the call method here.
          FunctionEntity calledElement = info.calledElement;
          assert(calledElement is ConstructorEntity &&
              calledElement.isGenerativeConstructor);
          ClassEntity cls = calledElement.enclosingClass;
          FunctionEntity callMethod = lookupCallMethod(cls);
          assert(callMethod != null, failedAt(cls));
          Iterable<FunctionEntity> elements = [callMethod];
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        } else {
          // We only are interested in functions here, as other targets
          // of this closure call are not a root to trace but an intermediate
          // for some other function.
          Iterable<FunctionEntity> elements = new List<FunctionEntity>.from(
              info.callees.where((e) => e.isFunction));
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        }
      } else if (info is MemberTypeInformation) {
        trace(<FunctionEntity>[info.member],
            new StaticTearOffClosureTracerVisitor(info.member, info, this));
      } else if (info is ParameterTypeInformation) {
        failedAt(
            NO_LOCATION_SPANNABLE, 'Unexpected closure allocation info $info');
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
      types.allocatedLists.values.forEach((_info) {
        ListTypeInformation info = _info;
        print('${info.type} '
            'for ${abstractValueDomain.getAllocationNode(info.originalType)} '
            'at ${abstractValueDomain.getAllocationElement(info.originalType)}'
            'after ${info.refineCount}');
      });
      types.allocatedMaps.values.forEach((_info) {
        MapTypeInformation info = _info;
        print('${info.type} '
            'for ${abstractValueDomain.getAllocationNode(info.originalType)} '
            'at ${abstractValueDomain.getAllocationElement(info.originalType)}'
            'after ${info.refineCount}');
      });
      types.allocatedClosures.forEach((TypeInformation info) {
        if (info is ElementTypeInformation) {
          print('${info.getInferredSignature(types)} for '
              '${info.debugName}');
        } else if (info is ClosureTypeInformation) {
          print('${info.getInferredSignature(types)} for '
              '${info.debugName}');
        } else if (info is DynamicCallSiteTypeInformation) {
          if (info.hasClosureCallTargets) {
            print('<Closure.call>');
          }
          for (MemberEntity target in info.concreteTargets) {
            if (target is FunctionEntity) {
              print('${types.getInferredSignatureOfMethod(target)} '
                  'for ${target}');
            } else {
              print('${types.getInferredTypeOfMember(target).type} '
                  'for ${target}');
            }
          }
        } else if (info is StaticCallSiteTypeInformation) {
          ClassEntity cls = info.calledElement.enclosingClass;
          FunctionEntity callMethod = lookupCallMethod(cls);
          print('${types.getInferredSignatureOfMethod(callMethod)} for ${cls}');
        } else {
          print('${info.type} for some unknown kind of closure');
        }
      });
      analyzedElements.forEach((MemberEntity elem) {
        TypeInformation type = types.getInferredTypeOfMember(elem);
        print('${elem} :: ${type} from ${type.assignments} ');
      });
    }
    dump?.afterAnalysis();

    reporter.log('Inferred $overallRefineCount types.');

    processLoopInformation();
  }

  /// Call [analyze] for all live members.
  void analyzeAllElements() {
    Iterable<MemberEntity> processedMembers = closedWorld.processedMembers
        .where((MemberEntity member) => !member.isAbstract);

    progress.startPhase();
    processedMembers.forEach((MemberEntity member) {
      progress.showProgress(
          'Added ', addedInGraph, ' elements in inferencing graph.');
      // This also forces the creation of the [ElementTypeInformation] to ensure
      // it is in the graph.
      types.withMember(member, () => analyze(member));
    });
    reporter.log('Added $addedInGraph elements in inferencing graph.');
  }

  /// Returns the body node for [member].
  ir.Node computeMemberBody(MemberEntity member) {
    MemberDefinition definition =
        closedWorld.elementMap.getMemberDefinition(member);
    switch (definition.kind) {
      case MemberKind.regular:
        ir.Member node = definition.node;
        if (node is ir.Field) {
          return getFieldInitializer(closedWorld.elementMap, member);
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.constructor:
        return definition.node;
      case MemberKind.constructorBody:
        ir.Member node = definition.node;
        if (node is ir.Constructor) {
          return node.function;
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.closureCall:
        ir.TreeNode node = definition.node;
        if (node is ir.FunctionDeclaration) {
          return node.function;
        } else if (node is ir.FunctionExpression) {
          return node.function;
        }
        break;
      case MemberKind.closureField:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        break;
    }
    failedAt(member, 'Unexpected member definition: $definition.');
    return null;
  }

  /// Returns the `call` method on [cls] or the `noSuchMethod` if [cls] doesn't
  /// implement `call`.
  FunctionEntity lookupCallMethod(ClassEntity cls) {
    FunctionEntity function =
        _elementEnvironment.lookupClassMember(cls, Identifiers.call);
    if (function == null || function.isAbstract) {
      function =
          _elementEnvironment.lookupClassMember(cls, Identifiers.noSuchMethod_);
    }
    return function;
  }

  void analyze(MemberEntity element) {
    if (analyzedElements.contains(element)) return;
    analyzedElements.add(element);

    ir.Node body = computeMemberBody(element);

    TypeInformation type;
    reporter.withCurrentElement(element, () {
      type = computeMemberTypeInformation(element, body);
    });
    addedInGraph++;

    if (element.isField) {
      FieldEntity field = element;
      if (!field.isAssignable) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (body != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            ConstantValue value = getFieldConstant(field);
            if (value != null) {
              if (value.isFunction) {
                FunctionConstantValue functionConstant = value;
                FunctionEntity function = functionConstant.element;
                type = types.allocateClosure(function);
              } else {
                // Although we might find a better type, we have to keep
                // the old type around to ensure that we get a complete view
                // of the type graph and do not drop any flow edges.
                AbstractValue refinedType =
                    abstractValueDomain.computeAbstractValueForConstant(value);
                type = new NarrowTypeInformation(
                    abstractValueDomain, type, refinedType);
                types.allocatedTypes.add(type);
              }
            }
          }
          recordTypeOfField(field, type);
        } else if (!element.isInstanceMember) {
          recordTypeOfField(field, types.nullType);
        }
      } else if (body == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (element.isStatic || element.isTopLevel) {
          recordTypeOfField(field, type);
        }
      } else {
        recordTypeOfField(field, type);
      }
      if ((element.isStatic || element.isTopLevel) &&
          body != null &&
          !element.isConst) {
        if (isFieldInitializerPotentiallyNull(element, body)) {
          recordTypeOfField(field, types.nullType);
        }
      }
    } else {
      FunctionEntity method = element;
      recordReturnType(method, type);
    }
  }

  /// Visits [body] to compute the [TypeInformation] node for [member].
  TypeInformation computeMemberTypeInformation(
      MemberEntity member, ir.Node body) {
    KernelTypeGraphBuilder visitor = new KernelTypeGraphBuilder(
        options,
        closedWorld,
        this,
        member,
        body,
        closedWorld.globalLocalsMap.getLocalsMap(member),
        closedWorld.elementMap.getStaticTypeProvider(member));
    return visitor.run();
  }

  /// Returns `true` if the [initializer] of the non-const static or top-level
  /// [field] is potentially `null`.
  bool isFieldInitializerPotentiallyNull(
      FieldEntity field, ir.Node initializer) {
    // TODO(13429): We could do better here by using the
    // constant handler to figure out if it's a lazy field or not.
    // TODO(johnniwinther): Implement the ad-hoc check in ast inferrer? This
    // mimicks that ast inferrer which return `true` for [ast.Send] and
    // non-const [ast.NewExpression].
    if (initializer is ir.MethodInvocation ||
        initializer is ir.PropertyGet ||
        initializer is ir.PropertySet ||
        initializer is ir.StaticInvocation ||
        initializer is ir.StaticGet ||
        initializer is ir.StaticSet ||
        initializer is ir.Let ||
        initializer is ir.ConstructorInvocation && !initializer.isConst) {
      return true;
    }
    return false;
  }

  /// Returns the [ConstantValue] for the initial value of [field], or
  /// `null` if the initializer is not a constant value.
  ConstantValue getFieldConstant(FieldEntity field) {
    return closedWorld.elementMap.getFieldConstantValue(field);
  }

  /// Returns `true` if [cls] has a 'call' method.
  bool hasCallType(ClassEntity cls) {
    return closedWorld.elementMap.types
            .getCallType(closedWorld.elementEnvironment.getThisType(cls)) !=
        null;
  }

  void processLoopInformation() {
    types.allocatedCalls.forEach((CallSiteTypeInformation info) {
      if (!info.inLoop) return;
      // We can't compute the callees of closures, no new information to add.
      if (info is ClosureCallSiteTypeInformation) {
        return;
      }
      if (info is StaticCallSiteTypeInformation) {
        MemberEntity member = info.calledElement;
        inferredDataBuilder.addFunctionCalledInLoop(member);
      } else if (info.mask != null &&
          abstractValueDomain.containsAll(info.mask).isDefinitelyFalse) {
        // For instance methods, we only register a selector called in a
        // loop if it is a typed selector, to avoid marking too many
        // methods as being called from within a loop. This cuts down
        // on the code bloat.
        info.callees.forEach((MemberEntity element) {
          inferredDataBuilder.addFunctionCalledInLoop(element);
        });
      }
    });
  }

  void refine() {
    progress.startPhase();
    while (!workQueue.isEmpty) {
      progress.showProgress('Inferred ', overallRefineCount, ' types.');
      TypeInformation info = workQueue.remove();
      AbstractValue oldType = info.type;
      AbstractValue newType = info.refine(this);
      // Check that refinement has not accidentally changed the type.
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
    workQueue.addAll(types.orderedTypeInformations);
    workQueue.addAll(types.allocatedTypes);
    workQueue.addAll(types.allocatedClosures);
    workQueue.addAll(types.allocatedCalls);
  }

  void updateParameterAssignments(TypeInformation caller, MemberEntity callee,
      ArgumentsTypes arguments, Selector selector, AbstractValue mask,
      {bool remove, bool addToQueue: true}) {
    if (callee.name == Identifiers.noSuchMethod_) return;
    if (callee.isField) {
      if (selector.isSetter) {
        ElementTypeInformation info = types.getInferredTypeOfMember(callee);
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
      MemberTypeInformation info = types.getInferredTypeOfMember(callee);
      if (remove) {
        info.closurizedCount--;
      } else {
        info.closurizedCount++;
        if (callee.isStatic || callee.isTopLevel) {
          types.allocatedClosures.add(info);
        } else {
          // We add the call-site type information here so that we
          // can benefit from further refinement of the selector.
          types.allocatedClosures.add(caller);
        }
        types.strategy.forEachParameter(callee, (Local parameter) {
          ParameterTypeInformation info =
              types.getInferredTypeOfParameter(parameter);
          info.tagAsTearOffClosureParameter(this);
          if (addToQueue) workQueue.add(info);
        });
      }
    } else {
      FunctionEntity method = callee;
      ParameterStructure parameterStructure = method.parameterStructure;
      int parameterIndex = 0;
      types.strategy.forEachParameter(callee, (Local parameter) {
        TypeInformation type;
        if (parameterIndex < parameterStructure.requiredParameters) {
          type = arguments.positional[parameterIndex];
        } else if (parameterStructure.namedParameters.isNotEmpty) {
          type = arguments.named[parameter.name];
        } else if (parameterIndex < arguments.positional.length) {
          type = arguments.positional[parameterIndex];
        }
        if (type == null) type = getDefaultTypeOfParameter(parameter);
        TypeInformation info = types.getInferredTypeOfParameter(parameter);
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

  void setDefaultTypeOfParameter(Local parameter, TypeInformation type,
      {bool isInstanceMember}) {
    assert(
        type != null, failedAt(parameter, "No default type for $parameter."));
    TypeInformation existing = defaultTypeOfParameter[parameter];
    defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOfParameter(parameter);
    if (existing != null && existing is PlaceholderTypeInformation) {
      // Replace references to [existing] to use [type] instead.
      if (isInstanceMember) {
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

  TypeInformation getDefaultTypeOfParameter(Local parameter) {
    return defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new PlaceholderTypeInformation(
          abstractValueDomain, types.currentMember);
    });
  }

  bool hasAlreadyComputedTypeOfParameterDefault(Local parameter) {
    TypeInformation seen = defaultTypeOfParameter[parameter];
    return (seen != null && seen is! PlaceholderTypeInformation);
  }

  TypeInformation typeOfParameter(Local element) {
    return types.getInferredTypeOfParameter(element);
  }

  TypeInformation typeOfMember(MemberEntity element) {
    if (element is FunctionEntity) return types.functionType;
    return types.getInferredTypeOfMember(element);
  }

  TypeInformation returnTypeOfMember(MemberEntity element) {
    if (element is! FunctionEntity) return types.dynamicType;
    return types.getInferredTypeOfMember(element);
  }

  void recordTypeOfField(FieldEntity element, TypeInformation type) {
    types.getInferredTypeOfMember(element).addAssignment(type);
  }

  void recordReturnType(FunctionEntity element, TypeInformation type) {
    TypeInformation info = types.getInferredTypeOfMember(element);
    if (element.name == '==') {
      // Even if x.== doesn't return a bool, 'x == null' evaluates to 'false'.
      info.addAssignment(types.boolType);
    }
    // TODO(ngeoffray): Clean up. We do these checks because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (type == null) return;
    if (info.assignments.isEmpty) info.addAssignment(type);
  }

  TypeInformation addReturnTypeForMethod(
      FunctionEntity element, TypeInformation unused, TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOfMember(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element is ConstructorEntity && element.isGenerativeConstructor) {
      return type;
    }
    type.addAssignment(newType);
    return type;
  }

  TypeInformation registerCalledMember(
      Object node,
      Selector selector,
      AbstractValue mask,
      MemberEntity caller,
      MemberEntity callee,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      bool inLoop) {
    CallSiteTypeInformation info = new StaticCallSiteTypeInformation(
        abstractValueDomain,
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
    // Note: we exclude factory constructors because they don't always create an
    // instance of the type. They are static methods that delegate to some other
    // generative constructor to do the actual creation of the object.
    if (selector != null &&
        selector.isCall &&
        callee is ConstructorEntity &&
        callee.isGenerativeConstructor) {
      ClassEntity cls = callee.enclosingClass;
      if (hasCallType(cls)) {
        types.allocatedClosures.add(info);
      }
    }
    info.addToGraph(this);
    types.allocatedCalls.add(info);
    updateSideEffects(sideEffectsBuilder, selector, callee);
    return info;
  }

  TypeInformation registerCalledSelector(
      CallType callType,
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation receiverType,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop,
      bool isConditional}) {
    if (selector.isClosureCall) {
      return registerCalledClosure(node, selector, mask, receiverType, caller,
          arguments, sideEffectsBuilder,
          inLoop: inLoop);
    }

    if (closedWorld.includesClosureCall(selector, mask)) {
      sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    }
    closedWorld.locateMembers(selector, mask).forEach((callee) {
      updateSideEffects(sideEffectsBuilder, selector, callee);
    });

    CallSiteTypeInformation info = new DynamicCallSiteTypeInformation(
        abstractValueDomain,
        types.currentMember,
        callType,
        node,
        caller,
        selector,
        mask,
        receiverType,
        arguments,
        inLoop,
        isConditional);

    info.addToGraph(this);
    types.allocatedCalls.add(info);
    return info;
  }

  TypeInformation registerAwait(ir.Node node, TypeInformation argument) {
    AwaitTypeInformation info = new AwaitTypeInformation(
        abstractValueDomain, types.currentMember, node);
    info.addAssignment(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  TypeInformation registerYield(ir.Node node, TypeInformation argument) {
    YieldTypeInformation info = new YieldTypeInformation(
        abstractValueDomain, types.currentMember, node);
    info.addAssignment(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  TypeInformation registerCalledClosure(
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation closure,
      MemberEntity caller,
      ArgumentsTypes arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {bool inLoop}) {
    sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    CallSiteTypeInformation info = new ClosureCallSiteTypeInformation(
        abstractValueDomain,
        types.currentMember,
        node,
        caller,
        selector,
        mask,
        closure,
        arguments,
        inLoop);
    info.addToGraph(this);
    types.allocatedCalls.add(info);
    return info;
  }

  void close() {
    for (MemberTypeInformation typeInformation
        in types.memberTypeInformations.values) {
      typeInformation.computeIsCalledOnce();
    }
  }

  void clear() {
    if (retainDataForTesting) return;

    void cleanup(TypeInformation info) {
      info.cleanup();
    }

    types.allocatedCalls.forEach(cleanup);
    types.allocatedCalls.clear();

    defaultTypeOfParameter.clear();

    types.parameterTypeInformations.values.forEach(cleanup);
    types.memberTypeInformations.values.forEach(cleanup);

    types.allocatedTypes.forEach(cleanup);
    types.allocatedTypes.clear();

    types.concreteTypes.clear();

    types.allocatedClosures.forEach(cleanup);
    types.allocatedClosures.clear();

    analyzedElements.clear();
    generativeConstructorsExposingThis.clear();

    types.allocatedMaps.values.forEach(cleanup);
    types.allocatedLists.values.forEach(cleanup);

    _memberData.clear();
  }

  Iterable<MemberEntity> getCallersOfForTesting(MemberEntity element) {
    MemberTypeInformation info = types.getInferredTypeOfMember(element);
    return info.callersForTesting;
  }

  TypeInformation typeOfMemberWithSelector(
      MemberEntity element, Selector selector) {
    if (element.name == Identifiers.noSuchMethod_ &&
        selector.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfMember(element);
    } else if (selector.isGetter) {
      if (element.isFunction) {
        // [functionType] is null if the inferrer did not run.
        return types.functionType == null
            ? types.dynamicType
            : types.functionType;
      } else if (element.isField) {
        return typeOfMember(element);
      } else if (element.isGetter) {
        return returnTypeOfMember(element);
      } else {
        assert(false, failedAt(element, "Unexpected member $element"));
        return types.dynamicType;
      }
    } else if (element.isGetter || element.isField) {
      assert(selector.isCall || selector.isSetter);
      return types.dynamicType;
    } else {
      return returnTypeOfMember(element);
    }
  }

  /// Returns true if global optimizations such as type inferencing can apply to
  /// the field [element].
  ///
  /// One category of elements that do not apply is runtime helpers that the
  /// backend calls, but the optimizations don't see those calls.
  bool canFieldBeUsedForGlobalOptimizations(FieldEntity element) {
    if (closedWorld.backendUsage.isFieldUsedByBackend(element)) {
      return false;
    }
    if ((element.isTopLevel || element.isStatic) && !element.isAssignable) {
      return true;
    }
    return true;
  }

  /// Returns true if global optimizations such as type inferencing can apply to
  /// the parameter [element].
  ///
  /// One category of elements that do not apply is runtime helpers that the
  /// backend calls, but the optimizations don't see those calls.
  bool canFunctionParametersBeUsedForGlobalOptimizations(
      FunctionEntity function) {
    return !closedWorld.backendUsage.isFunctionUsedByBackend(function);
  }

  @override
  bool assumeDynamic(MemberEntity member) {
    return closedWorld.annotationsData.assumeDynamicMembers.contains(member);
  }
}

class KernelTypeSystemStrategy implements TypeSystemStrategy {
  final JsClosedWorld _closedWorld;

  KernelTypeSystemStrategy(this._closedWorld);

  JElementEnvironment get _elementEnvironment =>
      _closedWorld.elementEnvironment;

  @override
  bool checkClassEntity(ClassEntity cls) => true;

  @override
  bool checkMapNode(ir.Node node) => true;

  @override
  bool checkListNode(ir.Node node) => true;

  @override
  bool checkLoopPhiNode(ir.Node node) => true;

  @override
  bool checkPhiNode(ir.Node node) =>
      node == null || node is ir.TryCatch || node is ir.TryFinally;

  @override
  void forEachParameter(FunctionEntity function, void f(Local parameter)) {
    forEachOrderedParameter(
        _closedWorld.globalLocalsMap, _closedWorld.elementMap, function, f);
  }

  @override
  ParameterTypeInformation createParameterTypeInformation(
      AbstractValueDomain abstractValueDomain,
      covariant JLocal parameter,
      TypeSystem types) {
    MemberEntity context = parameter.memberContext;
    KernelToLocalsMap localsMap =
        _closedWorld.globalLocalsMap.getLocalsMap(context);
    ir.FunctionNode functionNode =
        localsMap.getFunctionNodeForParameter(parameter);
    DartType type = localsMap.getLocalType(_closedWorld.elementMap, parameter);
    MemberEntity member;
    bool isClosure = false;
    if (functionNode.parent is ir.Member) {
      member = _closedWorld.elementMap.getMember(functionNode.parent);
    } else if (functionNode.parent is ir.FunctionExpression ||
        functionNode.parent is ir.FunctionDeclaration) {
      ClosureRepresentationInfo info =
          _closedWorld.closureDataLookup.getClosureInfo(functionNode.parent);
      member = info.callMethod;
      isClosure = true;
    }
    MemberTypeInformation memberTypeInformation =
        types.getInferredTypeOfMember(member);
    if (isClosure) {
      return new ParameterTypeInformation.localFunction(
          abstractValueDomain, memberTypeInformation, parameter, type, member);
    } else if (member.isInstanceMember) {
      return new ParameterTypeInformation.instanceMember(
          abstractValueDomain,
          memberTypeInformation,
          parameter,
          type,
          member,
          new ParameterAssignments());
    } else {
      return new ParameterTypeInformation.static(
          abstractValueDomain, memberTypeInformation, parameter, type, member);
    }
  }

  @override
  MemberTypeInformation createMemberTypeInformation(
      AbstractValueDomain abstractValueDomain, MemberEntity member) {
    if (member.isField) {
      FieldEntity field = member;
      DartType type = _elementEnvironment.getFieldType(field);
      return new FieldTypeInformation(abstractValueDomain, field, type);
    } else if (member.isGetter) {
      FunctionEntity getter = member;
      DartType type = _elementEnvironment.getFunctionType(getter);
      return new GetterTypeInformation(abstractValueDomain, getter, type);
    } else if (member.isSetter) {
      FunctionEntity setter = member;
      return new SetterTypeInformation(abstractValueDomain, setter);
    } else if (member.isFunction) {
      FunctionEntity method = member;
      DartType type = _elementEnvironment.getFunctionType(method);
      return new MethodTypeInformation(abstractValueDomain, method, type);
    } else {
      ConstructorEntity constructor = member;
      if (constructor.isFactoryConstructor) {
        DartType type = _elementEnvironment.getFunctionType(constructor);
        return new FactoryConstructorTypeInformation(
            abstractValueDomain, constructor, type);
      } else {
        return new GenerativeConstructorTypeInformation(
            abstractValueDomain, constructor);
      }
    }
  }
}

class KernelGlobalTypeInferenceElementData
    implements GlobalTypeInferenceElementData {
  /// Tag used for identifying serialized [GlobalTypeInferenceElementData]
  /// objects in a debugging data stream.
  static const String tag = 'global-type-inference-element-data';

  // TODO(johnniwinther): Rename this together with [typeOfSend].
  Map<ir.TreeNode, AbstractValue> _sendMap;

  Map<ir.ForInStatement, AbstractValue> _iteratorMap;
  Map<ir.ForInStatement, AbstractValue> _currentMap;
  Map<ir.ForInStatement, AbstractValue> _moveNextMap;

  KernelGlobalTypeInferenceElementData();

  KernelGlobalTypeInferenceElementData.internal(
      this._sendMap, this._iteratorMap, this._currentMap, this._moveNextMap);

  /// Deserializes a [GlobalTypeInferenceElementData] object from [source].
  factory KernelGlobalTypeInferenceElementData.readFromDataSource(
      DataSource source, AbstractValueDomain abstractValueDomain) {
    source.begin(tag);
    Map<ir.TreeNode, AbstractValue> sendMap = source.readTreeNodeMap(
        () => abstractValueDomain.readAbstractValueFromDataSource(source),
        emptyAsNull: true);
    Map<ir.ForInStatement, AbstractValue> iteratorMap = source.readTreeNodeMap(
        () => abstractValueDomain.readAbstractValueFromDataSource(source),
        emptyAsNull: true);
    Map<ir.ForInStatement, AbstractValue> currentMap = source.readTreeNodeMap(
        () => abstractValueDomain.readAbstractValueFromDataSource(source),
        emptyAsNull: true);
    Map<ir.ForInStatement, AbstractValue> moveNextMap = source.readTreeNodeMap(
        () => abstractValueDomain.readAbstractValueFromDataSource(source),
        emptyAsNull: true);
    source.end(tag);
    return new KernelGlobalTypeInferenceElementData.internal(
        sendMap, iteratorMap, currentMap, moveNextMap);
  }

  /// Serializes this [GlobalTypeInferenceElementData] to [sink].
  void writeToDataSink(DataSink sink, AbstractValueDomain abstractValueDomain) {
    sink.begin(tag);
    sink.writeTreeNodeMap(
        _sendMap,
        (AbstractValue value) =>
            abstractValueDomain.writeAbstractValueToDataSink(sink, value),
        allowNull: true);
    sink.writeTreeNodeMap(
        _iteratorMap,
        (AbstractValue value) =>
            abstractValueDomain.writeAbstractValueToDataSink(sink, value),
        allowNull: true);
    sink.writeTreeNodeMap(
        _currentMap,
        (AbstractValue value) =>
            abstractValueDomain.writeAbstractValueToDataSink(sink, value),
        allowNull: true);
    sink.writeTreeNodeMap(
        _moveNextMap,
        (AbstractValue value) =>
            abstractValueDomain.writeAbstractValueToDataSink(sink, value),
        allowNull: true);
    sink.end(tag);
  }

  @override
  GlobalTypeInferenceElementData compress() {
    if (_sendMap != null) {
      _sendMap.removeWhere(_mapsToNull);
      if (_sendMap.isEmpty) {
        _sendMap = null;
      }
    }
    if (_iteratorMap != null) {
      _iteratorMap.removeWhere(_mapsToNull);
      if (_iteratorMap.isEmpty) {
        _iteratorMap = null;
      }
    }
    if (_currentMap != null) {
      _currentMap.removeWhere(_mapsToNull);
      if (_currentMap.isEmpty) {
        _currentMap = null;
      }
    }
    if (_moveNextMap != null) {
      _moveNextMap.removeWhere(_mapsToNull);
      if (_moveNextMap.isEmpty) {
        _moveNextMap = null;
      }
    }
    if (_sendMap == null &&
        _iteratorMap == null &&
        _currentMap == null &&
        _moveNextMap == null) {
      return null;
    }
    return this;
  }

  @override
  AbstractValue typeOfSend(ir.TreeNode node) {
    if (_sendMap == null) return null;
    return _sendMap[node];
  }

  void setCurrentTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _currentMap ??= <ir.ForInStatement, AbstractValue>{};
    _currentMap[node] = mask;
  }

  void setMoveNextTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _moveNextMap ??= <ir.ForInStatement, AbstractValue>{};
    _moveNextMap[node] = mask;
  }

  void setIteratorTypeMask(ir.ForInStatement node, AbstractValue mask) {
    _iteratorMap ??= <ir.ForInStatement, AbstractValue>{};
    _iteratorMap[node] = mask;
  }

  @override
  AbstractValue typeOfIteratorCurrent(covariant ir.ForInStatement node) {
    if (_currentMap == null) return null;
    return _currentMap[node];
  }

  @override
  AbstractValue typeOfIteratorMoveNext(covariant ir.ForInStatement node) {
    if (_moveNextMap == null) return null;
    return _moveNextMap[node];
  }

  @override
  AbstractValue typeOfIterator(covariant ir.ForInStatement node) {
    if (_iteratorMap == null) return null;
    return _iteratorMap[node];
  }

  void setTypeMask(ir.TreeNode node, AbstractValue mask) {
    _sendMap ??= <ir.TreeNode, AbstractValue>{};
    _sendMap[node] = mask;
  }

  @override
  AbstractValue typeOfGetter(ir.TreeNode node) {
    if (_sendMap == null) return null;
    return _sendMap[node];
  }
}

bool _mapsToNull(ir.TreeNode node, AbstractValue value) => value == null;
