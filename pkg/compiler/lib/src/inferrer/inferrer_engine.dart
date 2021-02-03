// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../../compiler_new.dart';
import '../closure.dart';
import '../common.dart';
import '../common/metrics.dart';
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
import 'set_tracer.dart';
import 'type_graph_dump.dart';
import 'type_graph_inferrer.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';
import 'types.dart';

/// An inferencing engine that computes a call graph of [TypeInformation] nodes
/// by visiting the AST of the application, and then does the inferencing on the
/// graph.
class InferrerEngine {
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

  /// The [JClosedWorld] on which inference reasoning is based.
  final JsClosedWorld closedWorld;

  final TypeSystem types;
  final Map<ir.TreeNode, TypeInformation> concreteTypes = {};
  final InferredDataBuilder inferredDataBuilder;

  final FunctionEntity mainElement;

  final Map<Local, TypeInformation> _defaultTypeOfParameter = {};

  final WorkQueue _workQueue = WorkQueue();

  final _InferrerEngineMetrics metrics = _InferrerEngineMetrics();

  final Set<MemberEntity> _analyzedElements = {};

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int _MAX_CHANGE_COUNT = 6;

  int _overallRefineCount = 0;
  int _addedInGraph = 0;

  final CompilerOptions _options;
  final Progress _progress;
  final DiagnosticReporter _reporter;
  final CompilerOutput _compilerOutput;

  final Set<ConstructorEntity> _generativeConstructorsExposingThis =
      new Set<ConstructorEntity>();

  /// Data computed internally within elements, like the type-mask of a send a
  /// list allocation, or a for-in loop.
  final Map<MemberEntity, GlobalTypeInferenceElementData> _memberData =
      new Map<MemberEntity, GlobalTypeInferenceElementData>();

  ElementEnvironment get _elementEnvironment => closedWorld.elementEnvironment;

  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;
  CommonElements get commonElements => closedWorld.commonElements;

  // TODO(johnniwinther): This should be part of [ClosedWorld] or
  // [ClosureWorldRefiner].
  NoSuchMethodData get noSuchMethodData => closedWorld.noSuchMethodData;

  InferrerEngine(
      this._options,
      this._progress,
      this._reporter,
      this._compilerOutput,
      this.closedWorld,
      this.mainElement,
      this.inferredDataBuilder)
      : this.types = new TypeSystem(
            closedWorld, new KernelTypeSystemStrategy(closedWorld));

  /// Applies [f] to all elements in the universe that match [selector] and
  /// [mask]. If [f] returns false, aborts the iteration.
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
  void _updateSideEffects(SideEffectsBuilder sideEffectsBuilder,
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

  /// Returns the type for [nativeBehavior]. See documentation on
  /// [NativeBehavior].
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
      } else if (type is VoidType) {
        mappedType = types.nullType;
      } else if (type is DynamicType) {
        return types.dynamicType;
      } else if (type is InterfaceType) {
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
    assert(validCallType(callType, node, selector));
    switch (callType) {
      case CallType.access:
        data.setReceiverTypeMask(node, mask);
        break;
      case CallType.indirectAccess:
        // indirect access is not diretly recorded in the result data.
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
    return _generativeConstructorsExposingThis.contains(element);
  }

  void recordExposesThis(ConstructorEntity element, bool exposesThis) {
    if (exposesThis) {
      _generativeConstructorsExposingThis.add(element);
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
    tracer.inputs.forEach(info.elementType.addInput);
    // Enqueue the list for later refinement
    _workQueue.add(info);
    _workQueue.add(info.elementType);
  }

  void analyzeSetAndEnqueue(SetTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    SetTracerVisitor tracer = new SetTracerVisitor(info, this);
    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    info.elementType.inferred = true;

    tracer.inputs.forEach(info.elementType.addInput);
    // Enqueue the set for later refinement.
    _workQueue.add(info);
    _workQueue.add(info.elementType);
  }

  void analyzeMapAndEnqueue(MapTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;
    MapTracerVisitor tracer = new MapTracerVisitor(info, this);

    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    for (int i = 0; i < tracer.keyInputs.length; ++i) {
      TypeInformation newType = info.addEntryInput(
          abstractValueDomain, tracer.keyInputs[i], tracer.valueInputs[i]);
      if (newType != null) _workQueue.add(newType);
    }
    for (TypeInformation map in tracer.mapInputs) {
      _workQueue.addAll(info.addMapInput(abstractValueDomain, map));
    }

    info.markAsInferred();
    _workQueue.add(info.keyType);
    _workQueue.add(info.valueType);
    _workQueue.addAll(info.typeInfoMap.values);
    _workQueue.add(info);
  }

  void runOverAllElements() {
    metrics.time.measure(_runOverAllElements);
  }

  void _runOverAllElements() {
    metrics.analyze.measure(_analyzeAllElements);
    TypeGraphDump dump =
        debug.PRINT_GRAPH ? new TypeGraphDump(_compilerOutput, this) : null;

    dump?.beforeAnalysis();
    _buildWorkQueue();
    metrics.refine1.measure(_refine);

    // Try to infer element types of lists and compute their escape information.
    types.allocatedLists.values.forEach((TypeInformation info) {
      analyzeListAndEnqueue(info);
    });

    // Try to infer element types of sets and compute their escape information.
    types.allocatedSets.values.forEach((TypeInformation info) {
      analyzeSetAndEnqueue(info);
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
                  .giveUp(this, clearInputs: false);
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
            _workQueue.add(info);
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
          FunctionEntity callMethod = _lookupCallMethod(cls);
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
    while (!_workQueue.isEmpty) {
      TypeInformation info = _workQueue.remove();
      if (seenTypes.contains(info)) continue;
      // If the node cannot be reset, we do not need to update its users either.
      if (!info.reset(this)) continue;
      seenTypes.add(info);
      _workQueue.addAll(info.users);
    }

    _workQueue.addAll(seenTypes);
    metrics.refine2.measure(_refine);

    if (debug.PRINT_SUMMARY) {
      types.allocatedLists.values.forEach((_info) {
        ListTypeInformation info = _info;
        print('${info.type} '
            'for ${abstractValueDomain.getAllocationNode(info.originalType)} '
            'at ${abstractValueDomain.getAllocationElement(info.originalType)}'
            'after ${info.refineCount}');
      });
      types.allocatedSets.values.forEach((_info) {
        SetTypeInformation info = _info;
        print('${info.type} '
            'for ${abstractValueDomain.getAllocationNode(info.originalType)} '
            'at ${abstractValueDomain.getAllocationElement(info.originalType)} '
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
          FunctionEntity callMethod = _lookupCallMethod(cls);
          print('${types.getInferredSignatureOfMethod(callMethod)} for ${cls}');
        } else {
          print('${info.type} for some unknown kind of closure');
        }
      });
      _analyzedElements.forEach((MemberEntity elem) {
        TypeInformation type = types.getInferredTypeOfMember(elem);
        print('${elem} :: ${type} from ${type.inputs} ');
      });
    }
    dump?.afterAnalysis();

    metrics.overallRefineCount.add(_overallRefineCount);
    _reporter.log('Inferred $_overallRefineCount types.');

    _processLoopInformation();
  }

  /// Call [analyze] for all live members.
  void _analyzeAllElements() {
    Iterable<MemberEntity> processedMembers = closedWorld.processedMembers
        .where((MemberEntity member) => !member.isAbstract);

    _progress.startPhase();
    processedMembers.forEach((MemberEntity member) {
      _progress.showProgress(
          'Added ', _addedInGraph, ' elements in inferencing graph.');
      // This also forces the creation of the [ElementTypeInformation] to ensure
      // it is in the graph.
      types.withMember(member, () => analyze(member));
    });
    metrics.elementsInGraph.add(_addedInGraph);
    _reporter.log('Added $_addedInGraph elements in inferencing graph.');
    metrics.allTypesCount.add(types.allTypes.length);
  }

  /// Returns the body node for [member].
  ir.Node _computeMemberBody(MemberEntity member) {
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
        ir.LocalFunction node = definition.node;
        return node.function;
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
  FunctionEntity _lookupCallMethod(ClassEntity cls) {
    FunctionEntity function =
        _elementEnvironment.lookupClassMember(cls, Identifiers.call);
    if (function == null || function.isAbstract) {
      function =
          _elementEnvironment.lookupClassMember(cls, Identifiers.noSuchMethod_);
    }
    return function;
  }

  void analyze(MemberEntity element) {
    if (_analyzedElements.contains(element)) return;
    _analyzedElements.add(element);

    ir.Node body = _computeMemberBody(element);

    TypeInformation type;
    _reporter.withCurrentElement(element, () {
      type = _computeMemberTypeInformation(element, body);
    });
    _addedInGraph++;

    if (element.isField) {
      FieldEntity field = element;
      if (!field.isAssignable) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (body != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            ConstantValue value = _getFieldConstant(field);
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
        if (_isFieldInitializerPotentiallyNull(element, body)) {
          recordTypeOfField(field, types.nullType);
        }
      }
    } else {
      FunctionEntity method = element;
      recordReturnType(method, type);
    }
  }

  /// Visits [body] to compute the [TypeInformation] node for [member].
  TypeInformation _computeMemberTypeInformation(
      MemberEntity member, ir.Node body) {
    KernelTypeGraphBuilder visitor = new KernelTypeGraphBuilder(
        _options,
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
  bool _isFieldInitializerPotentiallyNull(
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
  ConstantValue _getFieldConstant(FieldEntity field) {
    return closedWorld.fieldAnalysis.getFieldData(field).initialValue;
  }

  /// Returns `true` if [cls] has a 'call' method.
  bool _hasCallType(ClassEntity cls) {
    return closedWorld.elementMap.types
            .getCallType(closedWorld.elementEnvironment.getThisType(cls)) !=
        null;
  }

  void _processLoopInformation() {
    types.allocatedCalls.forEach((CallSiteTypeInformation info) {
      if (!info.inLoop) return;
      // We can't compute the callees of closures, no new information to add.
      if (info is ClosureCallSiteTypeInformation) {
        return;
      }
      if (info is StaticCallSiteTypeInformation) {
        MemberEntity member = info.calledElement;
        inferredDataBuilder.addFunctionCalledInLoop(member);
      } else if (info is DynamicCallSiteTypeInformation &&
          info.mask != null &&
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

  void _refine() {
    _progress.startPhase();
    while (!_workQueue.isEmpty) {
      _progress.showProgress('Inferred ', _overallRefineCount, ' types.');
      TypeInformation info = _workQueue.remove();
      AbstractValue oldType = info.type;
      AbstractValue newType = info.refine(this);
      // Check that refinement has not accidentally changed the type.
      assert(oldType == info.type);
      if (info.abandonInferencing) info.doNotEnqueue = true;
      if ((info.type = newType) != oldType) {
        _overallRefineCount++;
        info.refineCount++;
        if (info.refineCount > _MAX_CHANGE_COUNT) {
          metrics.exceededMaxChangeCount.add();
          if (debug.ANOMALY_WARN) {
            print("ANOMALY WARNING: max refinement reached for $info");
          }
          info.giveUp(this);
          info.type = info.refine(this);
          info.doNotEnqueue = true;
        }
        _workQueue.addAll(info.users);
        if (info.hasStableType(this)) {
          info.stabilize(this);
        }
      }
    }
  }

  void _buildWorkQueue() {
    _workQueue.addAll(types.orderedTypeInformations);
    _workQueue.addAll(types.allocatedTypes);
    _workQueue.addAll(types.allocatedClosures);
    _workQueue.addAll(types.allocatedCalls);
  }

  /// Update the inputs to parameters in the graph. [remove] tells whether
  /// inputs must be added or removed. If [init] is false, parameters are
  /// added to the work queue.
  void updateParameterInputs(TypeInformation caller, MemberEntity callee,
      ArgumentsTypes arguments, Selector selector,
      {bool remove, bool addToQueue: true}) {
    if (callee.name == Identifiers.noSuchMethod_) return;
    if (callee.isField) {
      if (selector.isSetter) {
        ElementTypeInformation info = types.getInferredTypeOfMember(callee);
        if (remove) {
          info.removeInput(arguments.positional[0]);
        } else {
          info.addInput(arguments.positional[0]);
        }
        if (addToQueue) _workQueue.add(info);
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
          if (addToQueue) _workQueue.add(info);
        });
      }
    } else {
      FunctionEntity method = callee;
      ParameterStructure parameterStructure = method.parameterStructure;
      int parameterIndex = 0;
      types.strategy.forEachParameter(callee, (Local parameter) {
        TypeInformation type;
        if (parameterIndex < parameterStructure.requiredPositionalParameters) {
          type = arguments.positional[parameterIndex];
        } else if (parameterStructure.namedParameters.isNotEmpty) {
          type = arguments.named[parameter.name];
        } else if (parameterIndex < arguments.positional.length) {
          type = arguments.positional[parameterIndex];
        }
        if (type == null) type = getDefaultTypeOfParameter(parameter);
        TypeInformation info = types.getInferredTypeOfParameter(parameter);
        if (remove) {
          info.removeInput(type);
        } else {
          info.addInput(type);
        }
        parameterIndex++;
        if (addToQueue) _workQueue.add(info);
      });
    }
  }

  /// Sets the type of a parameter's default value to [type]. If the global
  /// mapping in `_defaultTypeOfParameter` already contains a type, it must be
  /// a [PlaceholderTypeInformation], which will be replaced. All its uses are
  /// updated.
  void setDefaultTypeOfParameter(Local parameter, TypeInformation type,
      {bool isInstanceMember}) {
    assert(
        type != null, failedAt(parameter, "No default type for $parameter."));
    TypeInformation existing = _defaultTypeOfParameter[parameter];
    _defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOfParameter(parameter);
    if (existing != null && existing is PlaceholderTypeInformation) {
      // Replace references to [existing] to use [type] instead.
      if (isInstanceMember) {
        ParameterInputs inputs = info.inputs;
        inputs.replace(existing, type);
      } else {
        List<TypeInformation> inputs = info.inputs;
        for (int i = 0; i < inputs.length; i++) {
          if (inputs[i] == existing) {
            inputs[i] = type;
          }
        }
      }
      // Also forward all users.
      type.addUsersOf(existing);
    } else {
      assert(existing == null);
    }
  }

  /// Returns the [TypeInformation] node for the default value of a parameter.
  /// If this is queried before it is set by [setDefaultTypeOfParameter], a
  /// [PlaceholderTypeInformation] is returned, which will later be replaced
  /// by the actual node when [setDefaultTypeOfParameter] is called.
  ///
  /// Invariant: After graph construction, no [PlaceholderTypeInformation] nodes
  /// should be present and a default type for each parameter should exist.
  TypeInformation getDefaultTypeOfParameter(Local parameter) {
    return _defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new PlaceholderTypeInformation(
          abstractValueDomain, types.currentMember);
    });
  }

  /// Returns the type of [element].
  TypeInformation typeOfParameter(Local element) {
    return types.getInferredTypeOfParameter(element);
  }

  /// Returns the type of [element].
  TypeInformation typeOfMember(MemberEntity element) {
    if (element is FunctionEntity) return types.functionType;
    return types.getInferredTypeOfMember(element);
  }

  /// Returns the return type of [element].
  TypeInformation returnTypeOfMember(MemberEntity element) {
    if (element is! FunctionEntity) return types.dynamicType;
    return types.getInferredTypeOfMember(element);
  }

  /// Records that [element] is of type [type].
  void recordTypeOfField(FieldEntity element, TypeInformation type) {
    types.getInferredTypeOfMember(element).addInput(type);
  }

  /// Records that the return type [element] is of type [type].
  void recordReturnType(FunctionEntity element, TypeInformation type) {
    TypeInformation info = types.getInferredTypeOfMember(element);
    if (element.name == '==') {
      // Even if x.== doesn't return a bool, 'x == null' evaluates to 'false'.
      info.addInput(types.boolType);
    }
    // TODO(ngeoffray): Clean up. We do these checks because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (type == null) return;
    if (info.inputs.isEmpty) info.addInput(type);
  }

  /// Notifies to the inferrer that [analyzedElement] can have return type
  /// [newType]. [currentType] is the type the inference has currently found.
  ///
  /// Returns the new type for [analyzedElement].
  TypeInformation addReturnTypeForMethod(
      FunctionEntity element, TypeInformation unused, TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOfMember(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element is ConstructorEntity && element.isGenerativeConstructor) {
      return type;
    }
    type.addInput(newType);
    return type;
  }

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
      if (_hasCallType(cls)) {
        types.allocatedClosures.add(info);
      }
    }
    info.addToGraph(this);
    types.allocatedCalls.add(info);
    _updateSideEffects(sideEffectsBuilder, selector, callee);
    return info;
  }

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
      bool isConditional}) {
    if (selector.isClosureCall) {
      return registerCalledClosure(
          node, selector, receiverType, caller, arguments, sideEffectsBuilder,
          inLoop: inLoop);
    }

    if (closedWorld.includesClosureCall(selector, mask)) {
      sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    }

    closedWorld.locateMembers(selector, mask).forEach((callee) {
      _updateSideEffects(sideEffectsBuilder, selector, callee);
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

  /// Registers a call to await with an expression of type [argumentType] as
  /// argument.
  TypeInformation registerAwait(ir.Node node, TypeInformation argument) {
    AwaitTypeInformation info = new AwaitTypeInformation(
        abstractValueDomain, types.currentMember, node);
    info.addInput(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  /// Registers a call to yield with an expression of type [argumentType] as
  /// argument.
  TypeInformation registerYield(ir.Node node, TypeInformation argument) {
    YieldTypeInformation info = new YieldTypeInformation(
        abstractValueDomain, types.currentMember, node);
    info.addInput(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  /// Registers that [caller] calls [closure] with [arguments].
  ///
  /// [sideEffectsBuilder] will be updated to incorporate the potential callees'
  /// side effects.
  ///
  /// [inLoop] tells whether the call happens in a loop.
  TypeInformation registerCalledClosure(
      ir.Node node,
      Selector selector,
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

    _defaultTypeOfParameter.clear();

    types.parameterTypeInformations.values.forEach(cleanup);
    types.memberTypeInformations.values.forEach(cleanup);

    types.allocatedTypes.forEach(cleanup);
    types.allocatedTypes.clear();

    types.concreteTypes.clear();

    types.allocatedClosures.forEach(cleanup);
    types.allocatedClosures.clear();

    _analyzedElements.clear();
    _generativeConstructorsExposingThis.clear();

    types.allocatedMaps.values.forEach(cleanup);
    types.allocatedSets.values.forEach(cleanup);
    types.allocatedLists.values.forEach(cleanup);

    _memberData.clear();
  }

  Iterable<MemberEntity> getCallersOfForTesting(MemberEntity element) {
    MemberTypeInformation info = types.getInferredTypeOfMember(element);
    return info.callersForTesting;
  }

  /// Returns the type of [element] when being called with [selector].
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

  /// Indirect calls share the same dynamic call site information node. This
  /// cache holds that shared dynamic call node for a given selector.
  Map<Selector, DynamicCallSiteTypeInformation> _sharedCalls = {};

  /// For a given selector, return a shared dynamic call site that will be used
  /// to combine the results of multiple dynamic calls in the program via
  /// [IndirectDynamicCallSiteTypeInformation].
  ///
  /// This is used only for scalability reasons: if there are too many targets
  /// and call sites, we may have a quadratic number of edges in the graph, so
  /// we add a level of indirection to merge the information and keep the graph
  /// smaller.
  // TODO(sigmund): start using or delete indirection logic.
  // ignore: unused_element
  DynamicCallSiteTypeInformation _typeOfSharedDynamicCall(
      Selector selector, CallStructure structure) {
    DynamicCallSiteTypeInformation info = _sharedCalls[selector];
    if (info != null) return info;

    TypeInformation receiverType =
        new IndirectParameterTypeInformation(abstractValueDomain, 'receiver');
    List<TypeInformation> positional = [];
    for (int i = 0; i < structure.positionalArgumentCount; i++) {
      positional
          .add(new IndirectParameterTypeInformation(abstractValueDomain, '$i'));
    }
    Map<String, TypeInformation> named = {};
    if (structure.namedArgumentCount > 0) {
      for (var name in structure.namedArguments) {
        named[name] =
            new IndirectParameterTypeInformation(abstractValueDomain, name);
      }
    }

    info = _sharedCalls[selector] = new DynamicCallSiteTypeInformation(
        abstractValueDomain,
        null,
        CallType.indirectAccess,
        null,
        null,
        selector,
        null,
        receiverType,
        ArgumentsTypes(positional, named),
        false,
        false);
    info.addToGraph(this);
    types.allocatedCalls.add(info);
    return info;
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

  /// Returns `true` if inference of parameter types is disabled for [member].
  bool assumeDynamic(MemberEntity member) {
    return closedWorld.annotationsData.hasAssumeDynamic(member);
  }
}

class _InferrerEngineMetrics extends MetricsBase {
  final time = DurationMetric('time');
  final analyze = DurationMetric('time.analyze');
  final refine1 = DurationMetric('time.refine1');
  final refine2 = DurationMetric('time.refine2');
  final elementsInGraph = CountMetric('count.elementsInGraph');
  final allTypesCount = CountMetric('count.allTypes');
  final exceededMaxChangeCount = CountMetric('count.exceededMaxChange');
  final overallRefineCount = CountMetric('count.overallRefines');

  _InferrerEngineMetrics() {
    primary = [time];
    secondary = [
      analyze,
      refine1,
      refine2,
      elementsInGraph,
      allTypesCount,
      exceededMaxChangeCount,
      overallRefineCount
    ];
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
  bool checkSetNode(ir.Node node) => true;

  @override
  bool checkListNode(ir.Node node) => true;

  @override
  bool checkLoopPhiNode(ir.Node node) => true;

  @override
  bool checkPhiNode(ir.Node node) =>
      node == null || node is ir.TryCatch || node is ir.TryFinally;

  @override
  void forEachParameter(FunctionEntity function, void f(Local parameter)) {
    forEachOrderedParameterAsLocal(
        _closedWorld.globalLocalsMap, _closedWorld.elementMap, function,
        (Local parameter, {bool isElided}) {
      f(parameter);
    });
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
    } else if (functionNode.parent is ir.LocalFunction) {
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
          new ParameterInputs());
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

  Map<ir.TreeNode, AbstractValue> _receiverMap;

  Map<ir.ForInStatement, AbstractValue> _iteratorMap;
  Map<ir.ForInStatement, AbstractValue> _currentMap;
  Map<ir.ForInStatement, AbstractValue> _moveNextMap;

  KernelGlobalTypeInferenceElementData();

  KernelGlobalTypeInferenceElementData.internal(this._receiverMap,
      this._iteratorMap, this._currentMap, this._moveNextMap);

  /// Deserializes a [GlobalTypeInferenceElementData] object from [source].
  factory KernelGlobalTypeInferenceElementData.readFromDataSource(
      DataSource source,
      ir.Member context,
      AbstractValueDomain abstractValueDomain) {
    return source.inMemberContext(context, () {
      source.begin(tag);
      Map<ir.TreeNode, AbstractValue> sendMap = source.readTreeNodeMapInContext(
          () => abstractValueDomain.readAbstractValueFromDataSource(source),
          emptyAsNull: true);
      Map<ir.ForInStatement, AbstractValue> iteratorMap =
          source.readTreeNodeMapInContext(
              () => abstractValueDomain.readAbstractValueFromDataSource(source),
              emptyAsNull: true);
      Map<ir.ForInStatement, AbstractValue> currentMap =
          source.readTreeNodeMapInContext(
              () => abstractValueDomain.readAbstractValueFromDataSource(source),
              emptyAsNull: true);
      Map<ir.ForInStatement, AbstractValue> moveNextMap =
          source.readTreeNodeMapInContext(
              () => abstractValueDomain.readAbstractValueFromDataSource(source),
              emptyAsNull: true);
      source.end(tag);
      return new KernelGlobalTypeInferenceElementData.internal(
          sendMap, iteratorMap, currentMap, moveNextMap);
    });
  }

  @override
  void writeToDataSink(DataSink sink, ir.Member context,
      AbstractValueDomain abstractValueDomain) {
    sink.inMemberContext(context, () {
      sink.begin(tag);
      sink.writeTreeNodeMapInContext(
          _receiverMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _iteratorMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _currentMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _moveNextMap,
          (AbstractValue value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.end(tag);
    });
  }

  @override
  GlobalTypeInferenceElementData compress() {
    if (_receiverMap != null) {
      _receiverMap.removeWhere(_mapsToNull);
      if (_receiverMap.isEmpty) {
        _receiverMap = null;
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
    if (_receiverMap == null &&
        _iteratorMap == null &&
        _currentMap == null &&
        _moveNextMap == null) {
      return null;
    }
    return this;
  }

  @override
  AbstractValue typeOfReceiver(ir.TreeNode node) {
    if (_receiverMap == null) return null;
    return _receiverMap[node];
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

  void setReceiverTypeMask(ir.TreeNode node, AbstractValue mask) {
    _receiverMap ??= <ir.TreeNode, AbstractValue>{};
    _receiverMap[node] = mask;
  }
}

bool _mapsToNull(ir.TreeNode node, AbstractValue value) => value == null;
