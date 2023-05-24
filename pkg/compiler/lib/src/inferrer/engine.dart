// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../../compiler_api.dart' as api;
import '../closure.dart';
import '../common.dart';
import '../common/elements.dart';
import '../common/metrics.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_model/element_map.dart';
import '../js_model/elements.dart';
import '../js_model/js_world.dart';
import '../js_model/locals.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../universe/member_hierarchy.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import 'abstract_value_domain.dart';
import 'builder.dart';
import 'closure_tracer.dart';
import 'debug.dart' as debug;
import 'locals_handler.dart';
import 'list_tracer.dart';
import 'map_tracer.dart';
import 'record_tracer.dart';
import 'set_tracer.dart';
import 'type_graph_dump.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';
import 'types.dart';
import 'work_queue.dart';

/// An inferencing engine that computes a call graph of [TypeInformation] nodes
/// by visiting the AST of the application, and then does the inferencing on the
/// graph.
class InferrerEngine {
  /// A set of selector names that [List] implements, that we know return their
  /// element type.
  final Set<Selector> returnsListElementTypeSet = Set<Selector>.from(<Selector>[
    Selector.getter(const PublicName('first')),
    Selector.getter(const PublicName('last')),
    Selector.getter(const PublicName('single')),
    Selector.call(const PublicName('singleWhere'), CallStructure.ONE_ARG),
    Selector.call(const PublicName('elementAt'), CallStructure.ONE_ARG),
    Selector.index(),
    Selector.call(const PublicName('removeAt'), CallStructure.ONE_ARG),
    Selector.call(const PublicName('removeLast'), CallStructure.NO_ARGS)
  ]);

  /// The [JClosedWorld] on which inference reasoning is based.
  final JClosedWorld closedWorld;

  final TypeSystem types;
  final Map<ir.TreeNode, TypeInformation> concreteTypes = {};
  final GlobalLocalsMap globalLocalsMap;
  final InferredDataBuilder inferredDataBuilder;

  final FunctionEntity mainElement;

  final Map<Local, TypeInformation> _defaultTypeOfParameter = {};

  final WorkQueue _workQueue = WorkQueue();

  late final _InferrerEngineMetrics metrics =
      _InferrerEngineMetrics(closedWorld.abstractValueDomain.metrics);

  final Set<MemberEntity> _analyzedElements = {};

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  /// TODO(natebiggs): This value is needed right now because some types
  /// do not converge. See https://github.com/dart-lang/sdk/issues/50626
  ///
  /// Note: Due to the encoding to track refine count for a given node this
  /// value must be less than 2^(64-N) where N is the number of values in the
  /// TypeInformation flags enum.
  static const int _MAX_CHANGE_COUNT = 12;

  int _overallRefineCount = 0;
  int _addedInGraph = 0;

  final CompilerOptions _options;
  final Progress _progress;
  final DiagnosticReporter _reporter;
  final api.CompilerOutput _compilerOutput;

  final Set<ConstructorEntity> _generativeConstructorsExposingThis =
      Set<ConstructorEntity>();

  /// Data computed internally within elements, like the type-mask of a send a
  /// list allocation, or a for-in loop.
  final Map<MemberEntity, KernelGlobalTypeInferenceElementData> _memberData =
      Map<MemberEntity, KernelGlobalTypeInferenceElementData>();

  ElementEnvironment get _elementEnvironment => closedWorld.elementEnvironment;

  AbstractValueDomain get abstractValueDomain =>
      closedWorld.abstractValueDomain;
  CommonElements get commonElements => closedWorld.commonElements;

  // TODO(johnniwinther): This should be part of [ClosedWorld] or
  // [ClosureWorldRefiner].
  NoSuchMethodData get noSuchMethodData => closedWorld.noSuchMethodData;

  final MemberHierarchyBuilder memberHierarchyBuilder;
  Set<MemberEntity>? _initializedVirtualMembers = {};

  InferrerEngine(
      this._options,
      this._progress,
      this._reporter,
      this._compilerOutput,
      this.closedWorld,
      this.mainElement,
      this.globalLocalsMap,
      this.inferredDataBuilder)
      : this.types = TypeSystem(closedWorld,
            KernelTypeSystemStrategy(closedWorld, globalLocalsMap)),
        memberHierarchyBuilder = MemberHierarchyBuilder(closedWorld),
        // Ensure `_MAX_CHANGE_COUNT` conforms to TypeInformation flag encoding.
        assert(_MAX_CHANGE_COUNT.bitLength <
            64 - TypeInformation.NUM_TYPE_INFO_FLAGS);

  /// Applies [f] to all elements in the universe that match [selector] and
  /// [mask]. If [f] returns false, aborts the iteration.
  void forEachElementMatching(
      Selector selector, AbstractValue? mask, bool f(MemberEntity element)) {
    final targets = memberHierarchyBuilder.rootsForCall(mask, selector);
    for (final target in targets) {
      memberHierarchyBuilder.forEachTargetMember(
          target, (member) => member.isAbstract || f(member));
    }
  }

  // TODO(johnniwinther): Make this private again.
  KernelGlobalTypeInferenceElementData dataOfMember(MemberEntity element) =>
      _memberData[element] ??= KernelGlobalTypeInferenceElementData();

  /// Update [sideEffects] with the side effects of [callee] being
  /// called with [selector].
  void _updateSideEffects(SideEffectsBuilder sideEffectsBuilder,
      Selector? selector, MemberEntity callee) {
    if (callee is FieldEntity) {
      if (callee.isInstanceMember) {
        if (selector!.isSetter) {
          sideEffectsBuilder.setChangesInstanceProperty();
        } else if (selector.isGetter) {
          sideEffectsBuilder.setDependsOnInstancePropertyStore();
        } else {
          sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
        }
      } else {
        if (selector!.isSetter) {
          sideEffectsBuilder.setChangesStaticProperty();
        } else if (selector.isGetter) {
          sideEffectsBuilder.setDependsOnStaticPropertyStore();
        } else {
          sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
        }
      }
    } else if (callee.isGetter && !selector!.isGetter) {
      sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    } else {
      sideEffectsBuilder.addInput(
          inferredDataBuilder.getSideEffectsBuilder(callee as FunctionEntity));
    }
  }

  /// Returns the type for [nativeBehavior]. See documentation on
  /// [NativeBehavior].
  TypeInformation typeOfNativeBehavior(NativeBehavior? nativeBehavior) {
    if (nativeBehavior == null) return types.dynamicType;
    List<Object> typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return types.dynamicType;
    TypeInformation? returnType;
    for (var type in typesReturned) {
      TypeInformation? mappedType;
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
    return returnType!;
  }

  void updateSelectorInMember(MemberEntity owner, CallType callType,
      ir.TreeNode node, Selector? selector, AbstractValue? mask) {
    final data = dataOfMember(owner);
    assert(validCallType(callType, node));
    switch (callType) {
      case CallType.access:
        data.setReceiverTypeMask(node, mask);
        break;
      case CallType.forIn:
        if (selector == Selectors.iterator) {
          data.setIteratorTypeMask(node as ir.ForInStatement, mask);
        } else if (selector == Selectors.current) {
          data.setCurrentTypeMask(node as ir.ForInStatement, mask);
        } else {
          assert(selector == Selectors.moveNext);
          data.setMoveNextTypeMask(node as ir.ForInStatement, mask);
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
    return abstractValueDomain.isContainer(mask) &&
        returnsListElementTypeSet.contains(selector);
  }

  bool returnsMapValueType(Selector selector, AbstractValue mask) {
    return abstractValueDomain.isMap(mask) && selector.isIndex;
  }

  void analyzeListAndEnqueue(ListTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    ListTracerVisitor tracer = ListTracerVisitor(info, this);
    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    info.elementType.inferred = true;
    tracer.inputs.forEach(info.elementType.addInput);
    // Enqueue the list for later refinement
    _workQueue.add(info);
    _workQueue.add(info.elementType);
  }

  void analyzeSetAndEnqueue(SetTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;

    SetTracerVisitor tracer = SetTracerVisitor(info, this);
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
    MapTracerVisitor tracer = MapTracerVisitor(info, this);

    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    for (int i = 0; i < tracer.keyInputs.length; ++i) {
      final newType = info.addEntryInput(
          abstractValueDomain, tracer.keyInputs[i], tracer.valueInputs[i]);
      if (newType != null) _workQueue.add(newType);
    }
    for (final map in tracer.mapInputs) {
      _workQueue.addAll(info.addMapInput(abstractValueDomain, map));
    }

    info.markAsInferred();
    _workQueue.add(info.keyType);
    _workQueue.add(info.valueType);
    _workQueue.addAll(info.typeInfoMap.values);
    _workQueue.add(info);
  }

  void analyzeRecordAndEnqueue(RecordTypeInformation info) {
    if (info.analyzed) return;
    info.analyzed = true;
    RecordTracerVisitor tracer = RecordTracerVisitor(info, this);

    bool succeeded = tracer.run();
    if (!succeeded) return;

    info.bailedOut = false;
    _workQueue.add(info);
  }

  void runOverAllElements() {
    metrics.time.measure(_runOverAllElements);
  }

  void _runOverAllElements() {
    _initMemberHierarchy();

    metrics.analyze.measure(_analyzeAllElements);
    final dump =
        debug.PRINT_GRAPH ? TypeGraphDump(_compilerOutput, this) : null;

    dump?.beforeAnalysis();
    _buildWorkQueue();
    metrics.refine1.measure(_refine);

    // Process the refined targets of calls labeling closureized members. We do
    // not need to mark targets as called in this pass because we don't use this
    // information in global inference.
    _processCalledTargets(shouldMarkCalled: false);

    metrics.trace.measure(() {
      // Try to infer element types of lists and compute their escape information.
      types.allocatedLists.values.forEach((ListTypeInformation info) {
        analyzeListAndEnqueue(info);
      });

      // Try to infer element types of sets and compute their escape information.
      types.allocatedSets.values.forEach((SetTypeInformation info) {
        analyzeSetAndEnqueue(info);
      });

      // Try to infer the key and value types for maps and compute the values'
      // escape information.
      types.allocatedMaps.values.forEach((MapTypeInformation info) {
        analyzeMapAndEnqueue(info);
      });

      Set<FunctionEntity> bailedOutOn = Set<FunctionEntity>();

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
          trace(elements, ClosureTracerVisitor(elements, info, this));
        } else if (info is CallSiteTypeInformation) {
          final selector = info.selector;
          List<FunctionEntity> elements;
          if (info is StaticCallSiteTypeInformation) {
            if (selector != null && selector.isCall) {
              // This is a constructor call to a class with a call method. So we
              // need to trace the call method here.
              final calledElement = info.calledElement;
              assert(calledElement is ConstructorEntity &&
                  calledElement.isGenerativeConstructor);
              final cls = calledElement.enclosingClass!;
              final callMethod = _lookupCallMethod(cls)!;
              elements = [callMethod];
            } else {
              elements = [info.calledElement as FunctionEntity];
            }
          } else if (info is DynamicCallSiteTypeInformation) {
            // We only are interested in functions here, as other targets
            // of this closure call are not a root to trace but an intermediate
            // for some other function.
            elements = [];
            bool processTarget(MemberEntity entity) {
              if (entity.isFunction && !entity.isAbstract) {
                elements.add(entity as FunctionEntity);
              }
              return true;
            }

            info.forEachConcreteTarget(memberHierarchyBuilder, processTarget);
          } else {
            elements = const [];
          }
          trace(elements, ClosureTracerVisitor(elements, info, this));
        } else if (info is MemberTypeInformation) {
          final member = info.member as FunctionEntity;
          trace(
              [member], StaticTearOffClosureTracerVisitor(member, info, this));
        } else if (info is ParameterTypeInformation) {
          failedAt(NO_LOCATION_SPANNABLE,
              'Unexpected closure allocation info $info');
        }
      });
    });

    dump?.beforeTracing();

    // Reset all nodes that use lists/maps that have been inferred, as well
    // as nodes that use elements fetched from these lists/maps. The
    // workset for a new run of the analysis will be these nodes.
    Set<TypeInformation> seenTypes = Set<TypeInformation>();
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

    // Process the refined targets of calls labeling closureized members and
    // marking targeted members as called.
    _processCalledTargets(shouldMarkCalled: true);

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
          info.forEachConcreteTarget(memberHierarchyBuilder, (member) {
            if (member is FunctionEntity) {
              print('${types.getInferredSignatureOfMethod(member)} '
                  'for ${member}');
            } else {
              print('${types.getInferredTypeOfMember(member).type} '
                  'for ${member}');
            }
            return true;
          });
        } else if (info is StaticCallSiteTypeInformation) {
          final cls = info.calledElement.enclosingClass!;
          final callMethod = _lookupCallMethod(cls)!;
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
    _progress.startPhase();
    final toProcess = {
      ...closedWorld.processedMembers,
      ...closedWorld.liveAbstractInstanceMembers
    };
    toProcess.forEach((MemberEntity member) {
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

  void _initMemberHierarchy() {
    metrics.memberHierarchy
        .measure(() => memberHierarchyBuilder.init(_initializeOverrideEdges));
    // Once the hierarchy is set up we will not need to initialize new
    // virtual members and can clear the initialization cache.
    _initializedVirtualMembers = null;
  }

  /// Returns the body node for [member].
  ir.Node? _computeMemberBody(MemberEntity member) {
    MemberDefinition definition =
        closedWorld.elementMap.getMemberDefinition(member);
    switch (definition.kind) {
      case MemberKind.regular:
        final node = definition.node;
        if (node is ir.Field) {
          return getFieldInitializer(
              closedWorld.elementMap, member as FieldEntity);
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.constructor:
        return definition.node;
      case MemberKind.constructorBody:
        final node = definition.node;
        if (node is ir.Constructor) {
          return node.function;
        } else if (node is ir.Procedure) {
          return node.function;
        }
        break;
      case MemberKind.closureCall:
        final node = definition.node as ir.LocalFunction;
        return node.function;
      case MemberKind.closureField:
      case MemberKind.signature:
      case MemberKind.generatorBody:
      case MemberKind.recordGetter:
        break;
    }
    failedAt(member, 'Unexpected member definition: $definition.');
  }

  /// Returns the `call` method on [cls] or the `noSuchMethod` if [cls] doesn't
  /// implement `call`.
  FunctionEntity? _lookupCallMethod(ClassEntity cls) {
    var function = _elementEnvironment.lookupClassMember(cls, Names.call)
        as FunctionEntity?;
    if (function == null || function.isAbstract) {
      function = _elementEnvironment.lookupClassMember(cls, Names.noSuchMethod_)
          as FunctionEntity?;
    }
    return function;
  }

  void analyze(MemberEntity element) {
    if (_analyzedElements.contains(element)) return;
    _analyzedElements.add(element);

    final body = _computeMemberBody(element);

    TypeInformation? type;
    _reporter.withCurrentElement(element, () {
      type = _computeMemberTypeInformation(element, body);
    });
    _addedInGraph++;

    if (element is FieldEntity) {
      final field = element;
      if (!field.isAssignable) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (body != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            final value = _getFieldConstant(field as JField);
            if (value != null) {
              if (value is FunctionConstantValue) {
                type = types.allocateClosure(value.element);
              } else {
                // Although we might find a better type, we have to keep
                // the old type around to ensure that we get a complete view
                // of the type graph and do not drop any flow edges.
                AbstractValue refinedType =
                    abstractValueDomain.computeAbstractValueForConstant(value);
                type = NarrowTypeInformation(
                    abstractValueDomain, type!, refinedType);
                types.allocatedTypes.add(type!);
              }
            }
          }
          recordTypeOfField(field, type!);
        } else if (!element.isInstanceMember) {
          recordTypeOfField(field, types.nullType);
        }
      } else if (body == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (element.isStatic || element.isTopLevel) {
          recordTypeOfField(field, type!);
        }
      } else {
        recordTypeOfField(field, type!);
      }
      if ((element.isStatic || element.isTopLevel) &&
          body != null &&
          !element.isConst) {
        if (_isFieldInitializerPotentiallyNull(element, body)) {
          recordTypeOfField(field, types.nullType);
        }
      }
    } else {
      final method = element as FunctionEntity;
      // Abstract methods don't have a body so they won't have a return type.
      if (!method.isAbstract) recordReturnType(method, type!);
    }
  }

  /// Visits [body] to compute the [TypeInformation] node for [member].
  TypeInformation _computeMemberTypeInformation(
      MemberEntity member, ir.Node? body) {
    KernelTypeGraphBuilder visitor = KernelTypeGraphBuilder(
        _options,
        closedWorld,
        this,
        member,
        body,
        globalLocalsMap.getLocalsMap(member),
        closedWorld.elementMap.getStaticTypeProvider(member),
        memberHierarchyBuilder);
    return visitor.run();
  }

  /// Returns `true` if the [initializer] of the non-const static or top-level
  /// [field] is potentially `null`.
  bool _isFieldInitializerPotentiallyNull(
      FieldEntity field, ir.Node initializer) {
    // TODO(13429): We could do better here by using the
    // constant handler to figure out if it's a lazy field or not.
    // TODO(johnniwinther): Implement the ad-hoc check in ast inferrer? This
    // mimics that ast inferrer which return `true` for [ast.Send] and
    // non-const [ast.NewExpression].
    if (initializer is ir.InstanceInvocation ||
        initializer is ir.InstanceGetterInvocation ||
        initializer is ir.DynamicInvocation ||
        initializer is ir.FunctionInvocation ||
        initializer is ir.LocalFunctionInvocation ||
        initializer is ir.EqualsNull ||
        initializer is ir.EqualsCall ||
        initializer is ir.InstanceGet ||
        initializer is ir.DynamicGet ||
        initializer is ir.InstanceTearOff ||
        initializer is ir.FunctionTearOff ||
        initializer is ir.InstanceSet ||
        initializer is ir.DynamicSet ||
        initializer is ir.StaticInvocation ||
        initializer is ir.StaticGet ||
        initializer is ir.StaticTearOff ||
        initializer is ir.StaticSet ||
        initializer is ir.Let ||
        initializer is ir.ConstructorInvocation && !initializer.isConst) {
      return true;
    }
    return false;
  }

  /// Returns the [ConstantValue] for the initial value of [field], or
  /// `null` if the initializer is not a constant value.
  ConstantValue? _getFieldConstant(JField field) {
    return closedWorld.fieldAnalysis.getFieldData(field).initialValue;
  }

  /// Returns `true` if [cls] has a 'call' method.
  bool _hasCallType(ClassEntity cls) {
    return closedWorld.dartTypes
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
          abstractValueDomain.containsAll(info.mask!).isDefinitelyFalse) {
        // For instance methods, we only register a selector called in a
        // loop if it is a typed selector, to avoid marking too many
        // methods as being called from within a loop. This cuts down
        // on the code bloat.
        info.forEachConcreteTarget(memberHierarchyBuilder,
            (MemberEntity element) {
          inferredDataBuilder.addFunctionCalledInLoop(element);
          return true;
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
      final validRefine =
          abstractValueDomain.isValidRefinement(oldType, newType);
      if (validRefine && (info.type = newType) != oldType) {
        _overallRefineCount++;
        info.incrementRefineCount();
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
  /// inputs must be added or removed. If [addToQueue] is `true`, parameters are
  /// added to the work queue. Returns `true` if the call requires [callee] to
  /// be closurized. If [virtualCall] is `true` inputs are added and removed
  /// from the virtual types for [callee].
  bool updateParameterInputs(TypeInformation callSiteType, MemberEntity callee,
      ArgumentsTypes? arguments, Selector? selector,
      {required bool remove,
      required bool addToQueue,
      bool virtualCall = false}) {
    if (callee.name == Identifiers.noSuchMethod_) return false;
    if (callee is FieldEntity) {
      if (selector!.isSetter) {
        ElementTypeInformation info =
            types.getInferredTypeOfMember(callee, virtual: virtualCall);
        if (remove) {
          info.removeInput(arguments!.positional[0]);
        } else {
          info.addInput(arguments!.positional[0]);
        }
        if (addToQueue) _workQueue.add(info);
      }
    } else if (callee.isGetter) {
      return false;
    } else if (selector != null && selector.isGetter) {
      // We are tearing a function off and thus create a closure.
      assert(callee.isFunction);
      final memberInfo =
          types.getInferredTypeOfMember(callee, virtual: virtualCall);
      _markForClosurization(memberInfo, callSiteType,
          remove: remove, addToQueue: addToQueue, isVirtualCall: virtualCall);
      return true;
    } else {
      final method = callee as FunctionEntity;
      ParameterStructure parameterStructure = method.parameterStructure;
      int parameterIndex = 0;
      final localArguments = arguments!;
      types.strategy.forEachParameter(callee, (Local parameter) {
        TypeInformation? type;
        if (parameterIndex < parameterStructure.requiredPositionalParameters) {
          type = localArguments.positional[parameterIndex];
        } else if (parameterStructure.namedParameters.isNotEmpty) {
          type = localArguments.named[parameter.name];
        } else if (parameterIndex < localArguments.positional.length) {
          type = localArguments.positional[parameterIndex];
        }
        if (type == null) type = getDefaultTypeOfParameter(parameter);
        TypeInformation info =
            types.getInferredTypeOfParameter(parameter, isVirtual: virtualCall);
        if (remove) {
          info.removeInput(type);
        } else {
          info.addInput(type);
        }
        parameterIndex++;
        if (addToQueue) _workQueue.add(info);
      });
    }
    return false;
  }

  /// Adds edges between the virtual type information for [parent] and
  /// [override] based on the type of each member. If the virtual type
  /// information for either does not exist yet, create it and initialize
  /// it by adding edges to the concrete type information for that member.
  /// Passed to [MemberHierarchyBuilder.init] to be called as it discovers
  /// overrides.
  ///
  /// Possible override configurations (parent/override):
  /// - field/getter
  /// - field/setter
  /// - field/field
  /// - getter/getter
  /// - getter/field
  /// - setter/setter
  /// - setter/field
  /// - method/method
  void _initializeOverrideEdges(MemberEntity parent, MemberEntity override) {
    // Skip adding edges for Object.noSuchMethod since it cannot virtually
    // dispatch to other implementations of NSM. However, user-defined NSM
    // methods do need to handle virtual dispatch.
    if (parent == commonElements.objectNoSuchMethod) return;
    final parentType = _getAndSetupVirtualMember(parent);
    final overrideType = _getAndSetupVirtualMember(override);

    _addOverrideTypeInputs(parent, override, parentType, overrideType);
  }

  void _setupVirtualCall(
      MemberTypeInformation virtualCallType, MemberEntity member) {
    if (member is FieldEntity || member.isGetter) {
      final realMember = types.getInferredTypeOfMember(member);
      virtualCallType.addInput(realMember);
      if (member.isAssignable) {
        realMember.addInput(virtualCallType);
      }
    } else {
      assert(member.isSetter || member.isFunction);
      types.strategy.forEachParameter(member as FunctionEntity,
          (Local parameter) {
        final virtualParamInfo =
            types.getInferredTypeOfParameter(parameter, isVirtual: true);
        final realParamInfo = types.getInferredTypeOfParameter(parameter);
        realParamInfo.addInput(virtualParamInfo);
        assert(virtualParamInfo.users.first == realParamInfo);
      });
      if (member.isFunction) {
        virtualCallType.addInput(types.getInferredTypeOfMember(member));
      }
    }
  }

  void _addOverrideParameterEdges(MemberEntity parent, MemberEntity override) {
    final method = parent as FunctionEntity;
    ParameterStructure parameterStructure = method.parameterStructure;
    int parameterIndex = 0;
    // Collect the parent parameter type infos.
    final List<TypeInformation> positional = [];
    final Map<String, TypeInformation> named = {};
    types.strategy.forEachParameter(parent, (Local parameter) {
      TypeInformation type =
          types.getInferredTypeOfParameter(parameter, isVirtual: true);
      if (parameterIndex < parameterStructure.requiredPositionalParameters) {
        positional.add(type);
      } else if (parameterStructure.namedParameters.isNotEmpty) {
        named[parameter.name!] = type;
      } else if (parameterIndex < parameterStructure.positionalParameters) {
        positional.add(type);
      }
      parameterIndex++;
    });
    parameterIndex = 0;

    // Add the parent parameter type infos as inputs to the override's
    // parameters.
    types.strategy.forEachParameter(override as FunctionEntity,
        (Local parameter) {
      TypeInformation? parentParamInfo;
      if (parameterIndex < parameterStructure.requiredPositionalParameters) {
        parentParamInfo = positional[parameterIndex];
      } else if (parameterStructure.namedParameters.isNotEmpty) {
        parentParamInfo = named[parameter.name];
      } else if (parameterIndex < positional.length) {
        parentParamInfo = positional[parameterIndex];
      }
      // If the override includes parameters that the parent doesn't
      // (optional parameters) then use the override's default type as any
      // default value will be used within the body of the override.
      parentParamInfo ??= getDefaultTypeOfParameter(parameter);
      TypeInformation overrideParamInfo =
          types.getInferredTypeOfParameter(parameter, isVirtual: true);
      overrideParamInfo.addInput(parentParamInfo);
      parameterIndex++;
    });
  }

  MemberTypeInformation _getAndSetupVirtualMember(MemberEntity member) {
    final memberType = types.getInferredTypeOfMember(member, virtual: true);
    if (_initializedVirtualMembers!.add(member)) {
      _setupVirtualCall(memberType, member);
    }
    return memberType;
  }

  void _addOverrideTypeInputs(MemberEntity parent, MemberEntity override,
      MemberTypeInformation parentType, MemberTypeInformation overrideType) {
    if (parent is FieldEntity) {
      if (override.isGetter) {
        parentType.addInput(overrideType);
      } else if (override.isSetter) {
        types.strategy.forEachParameter(override as FunctionEntity,
            (Local parameter) {
          final paramInfo =
              types.getInferredTypeOfParameter(parameter, isVirtual: true);
          paramInfo.addInput(parentType);
        });
      } else {
        assert(override is FieldEntity);
        parentType.addInput(overrideType);
        if (parent.isAssignable) {
          // Parent has an implicit setter so the types of set values need to
          // flow into the override.
          overrideType.addInput(parentType);
        }
      }
    } else if (parent.isGetter) {
      assert(override.isGetter || override is FieldEntity);
      parentType.addInput(overrideType);
    } else if (parent.isSetter) {
      if (override.isSetter) {
        _addOverrideParameterEdges(parent, override);
      } else {
        assert(override is FieldEntity);
        types.strategy.forEachParameter(parent as FunctionEntity,
            (Local parameter) {
          final paramInfo =
              types.getInferredTypeOfParameter(parameter, isVirtual: true);
          overrideType.addInput(paramInfo);
        });
      }
    } else {
      assert(parent.isFunction && override.isFunction);
      parentType.addInput(overrideType);
      _addOverrideParameterEdges(parent, override);
    }
  }

  void _markForClosurization(
      MemberTypeInformation memberInfo, TypeInformation callSiteType,
      {required bool remove,
      required bool addToQueue,
      required bool isVirtualCall}) {
    final member = memberInfo.member;
    if (remove) {
      memberInfo.closurizedCount--;
    } else {
      memberInfo.closurizedCount++;
      if (member.isStatic || member.isTopLevel) {
        types.allocatedClosures.add(memberInfo);
      } else {
        // We add the call-site type information here so that we
        // can benefit from further refinement of the selector.
        types.allocatedClosures.add(callSiteType);
      }
      types.strategy.forEachParameter(member as FunctionEntity,
          (Local parameter) {
        ParameterTypeInformation info = types
            .getInferredTypeOfParameter(parameter, isVirtual: isVirtualCall);
        info.tagAsTearOffClosureParameter(this);
        if (addToQueue) _workQueue.add(info);
      });
    }
  }

  /// Iterate through reachable members for the given target. Label relevant
  /// members as needing closurization if necessary. If [shouldMarkCalled] then
  /// also mark reachable members as called.
  void _processDynamicTarget(
      DynamicCallTarget target, DynamicCallSiteTypeInformation callSiteType,
      {required bool shouldMarkCalled}) {
    final virtualType =
        types.getInferredTypeOfMember(target.member, virtual: true);
    final needsClosurization = virtualType.closurizedCount > 0;

    // There is nothing to do so no need to iterate over target members.
    if (!needsClosurization && !shouldMarkCalled) return;

    bool handleTarget(MemberEntity member) {
      if (!member.isAbstract) {
        MemberTypeInformation info = types.getInferredTypeOfMember(member);
        if (shouldMarkCalled) info.markCalled();

        if (needsClosurization) {
          _markForClosurization(info, callSiteType,
              remove: false,
              addToQueue: false,
              isVirtualCall: target.isVirtual);
        }
      }
      return true;
    }

    memberHierarchyBuilder.forEachTargetMember(target, handleTarget);
  }

  /// Update call information for targets of calls.
  ///
  /// Marks targets of dynamic calls that need closuraization. If [shouldMarkCalled]
  /// is true any members targeted by a dynamic or static call is also marked
  /// as being called.
  void _processCalledTargets({required bool shouldMarkCalled}) {
    for (final call in types.allocatedCalls) {
      if (call is DynamicCallSiteTypeInformation) {
        for (final target in call.targets) {
          _processDynamicTarget(target, call,
              shouldMarkCalled: shouldMarkCalled);
        }
      } else if (shouldMarkCalled && call is StaticCallSiteTypeInformation) {
        types.getInferredTypeOfMember(call.calledElement).markCalled();
      }
    }
  }

  /// Sets the type of a parameter's default value to [type]. If the global
  /// mapping in `_defaultTypeOfParameter` already contains a type, it must be
  /// a [PlaceholderTypeInformation], which will be replaced. All its uses are
  /// updated.
  void setDefaultTypeOfParameter(Local parameter, TypeInformation type) {
    final existing = _defaultTypeOfParameter[parameter];
    _defaultTypeOfParameter[parameter] = type;
    TypeInformation info = types.getInferredTypeOfParameter(parameter);
    if (existing != null && existing is PlaceholderTypeInformation) {
      TypeInformation virtualInfo =
          types.getInferredTypeOfParameter(parameter, isVirtual: true);
      // Replace references to [existing] to use [type] instead.
      info.inputs.replace(existing, type);
      virtualInfo.inputs.replace(existing, type);
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
      return PlaceholderTypeInformation(
          abstractValueDomain, types.currentMember);
    });
  }

  /// Returns the type of [element].
  TypeInformation typeOfParameter(Local element) {
    return types.getInferredTypeOfParameter(element);
  }

  MemberTypeInformation _inferredTypeOfMember(MemberEntity element,
      {required bool isVirtual}) {
    return types.getInferredTypeOfMember(element, virtual: isVirtual);
  }

  MemberTypeInformation inferredTypeOfTarget(DynamicCallTarget target) {
    return _inferredTypeOfMember(target.member, isVirtual: target.isVirtual);
  }

  /// Returns the type of [element].
  TypeInformation typeOfMember(MemberEntity element, {bool isVirtual = false}) {
    if (element is FunctionEntity) return types.functionType;
    return _inferredTypeOfMember(element, isVirtual: isVirtual);
  }

  /// Returns the return type of [element].
  TypeInformation returnTypeOfMember(MemberEntity element,
      {bool isVirtual = false}) {
    if (element is! FunctionEntity) return types.dynamicType;
    return _inferredTypeOfMember(element, isVirtual: isVirtual);
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

    if (info.inputs.isEmpty) info.addInput(type);
  }

  /// Notifies to the inferrer that [analyzedElement] can have return type
  /// [newType]. [currentType] is the type the inference has currently found.
  ///
  /// Returns the new type for [analyzedElement].
  TypeInformation addReturnTypeForMethod(
      FunctionEntity element, TypeInformation newType) {
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
      ir.Node node,
      Selector? selector,
      MemberEntity caller,
      MemberEntity callee,
      ArgumentsTypes? arguments,
      SideEffectsBuilder sideEffectsBuilder,
      bool inLoop) {
    CallSiteTypeInformation info = StaticCallSiteTypeInformation(
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
      AbstractValue? mask,
      TypeInformation receiverType,
      MemberEntity caller,
      ArgumentsTypes? arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {required bool inLoop,
      required bool isConditional}) {
    if (selector.isClosureCall) {
      return registerCalledClosure(
          node, selector, receiverType, caller, arguments, sideEffectsBuilder,
          inLoop: inLoop);
    }

    if (closedWorld.includesClosureCall(selector, mask)) {
      sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    }

    forEachElementMatching(selector, mask, (element) {
      _updateSideEffects(sideEffectsBuilder, selector, element);
      return true;
    });

    CallSiteTypeInformation info = DynamicCallSiteTypeInformation(
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
    AwaitTypeInformation info =
        AwaitTypeInformation(abstractValueDomain, types.currentMember, node);
    info.addInput(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  /// Registers a call to yield with an expression of type [argumentType] as
  /// argument.
  TypeInformation registerYield(ir.Node node, TypeInformation argument) {
    YieldTypeInformation info =
        YieldTypeInformation(abstractValueDomain, types.currentMember, node);
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
      ArgumentsTypes? arguments,
      SideEffectsBuilder sideEffectsBuilder,
      {required bool inLoop}) {
    sideEffectsBuilder.setAllSideEffectsAndDependsOnSomething();
    CallSiteTypeInformation info = ClosureCallSiteTypeInformation(
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

  Map<MemberEntity, Set<MemberEntity>>? _cachedCallersOfForTesting;

  Iterable<MemberEntity>? getCallersOfForTesting(MemberEntity element) {
    if (_cachedCallersOfForTesting == null) {
      final callers = _cachedCallersOfForTesting = {};
      for (final callSite in types.allocatedCalls) {
        if (callSite is StaticCallSiteTypeInformation) {
          (callers[callSite.calledElement] ??= {}).add(callSite.caller);
        } else if (callSite is DynamicCallSiteTypeInformation) {
          callSite.forEachConcreteTarget(memberHierarchyBuilder, (member) {
            (callers[member] ??= {}).add(callSite.caller);
            return true;
          });
        }
      }
    }
    return _cachedCallersOfForTesting![element];
  }

  /// Returns the type of [element] when being called with [selector].
  TypeInformation typeOfMemberWithSelector(
      MemberEntity element, Selector? selector,
      {required bool isVirtual}) {
    if (element.name == Identifiers.noSuchMethod_ &&
        selector!.name != element.name) {
      // An invocation can resolve to a [noSuchMethod], in which case
      // we get the return type of [noSuchMethod].
      return returnTypeOfMember(element);
    } else if (selector!.isGetter) {
      if (element.isFunction) {
        return types.functionType;
      } else if (element is FieldEntity) {
        return typeOfMember(element, isVirtual: isVirtual);
      } else if (element.isGetter) {
        return returnTypeOfMember(element, isVirtual: isVirtual);
      } else {
        assert(false, failedAt(element, "Unexpected member $element"));
        return types.dynamicType;
      }
    } else if (element.isGetter || element is FieldEntity) {
      assert(selector.isCall || selector.isSetter);
      return types.dynamicType;
    } else {
      return returnTypeOfMember(element, isVirtual: isVirtual);
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

  /// Returns `true` if inference of parameter types is disabled for [member].
  bool assumeDynamic(MemberEntity member) {
    return closedWorld.annotationsData.hasAssumeDynamic(member);
  }
}

class _InferrerEngineMetrics extends MetricsBase {
  final time = DurationMetric('time');
  final analyze = DurationMetric('time.analyze');
  final memberHierarchy = DurationMetric('time.memberHierarchy');
  final refine1 = DurationMetric('time.refine1');
  final trace = DurationMetric('time.trace');
  final refine2 = DurationMetric('time.refine2');
  final elementsInGraph = CountMetric('count.elementsInGraph');
  final allTypesCount = CountMetric('count.allTypes');
  final exceededMaxChangeCount = CountMetric('count.exceededMaxChange');
  final overallRefineCount = CountMetric('count.overallRefines');

  _InferrerEngineMetrics(Metrics subMetrics) {
    primary = [time, ...subMetrics.primary];
    secondary = [
      analyze,
      memberHierarchy,
      refine1,
      trace,
      refine2,
      elementsInGraph,
      allTypesCount,
      exceededMaxChangeCount,
      overallRefineCount,
      ...subMetrics.secondary,
    ];
  }
}

class KernelTypeSystemStrategy implements TypeSystemStrategy {
  final JClosedWorld _closedWorld;
  final GlobalLocalsMap _globalLocalsMap;

  KernelTypeSystemStrategy(this._closedWorld, this._globalLocalsMap);

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
  bool checkPhiNode(ir.Node? node) =>
      node == null || node is ir.TryCatch || node is ir.TryFinally;

  @override
  void forEachParameter(FunctionEntity function, void f(Local parameter)) {
    forEachOrderedParameterAsLocal(
        _globalLocalsMap, _closedWorld.elementMap, function, (Local parameter,
            {required bool isElided}) {
      f(parameter);
    });
  }

  @override
  ParameterTypeInformation createParameterTypeInformation(
      AbstractValueDomain abstractValueDomain,
      covariant JLocal parameter,
      TypeSystem types,
      {required bool isVirtual}) {
    MemberEntity context = parameter.memberContext;
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(context);
    ir.FunctionNode functionNode =
        localsMap.getFunctionNodeForParameter(parameter);
    DartType type = localsMap.getLocalType(_closedWorld.elementMap, parameter);
    late final MemberEntity member;
    bool isClosure = false;
    final parent = functionNode.parent;
    if (parent is ir.Member) {
      member = _closedWorld.elementMap.getMember(parent);
    } else if (parent is ir.LocalFunction) {
      ClosureRepresentationInfo info =
          _closedWorld.closureDataLookup.getClosureInfo(parent);
      member = info.callMethod!;
      isClosure = true;
    }
    MemberTypeInformation memberTypeInformation =
        types.getInferredTypeOfMember(member);
    if (isClosure) {
      return ParameterTypeInformation.localFunction(abstractValueDomain,
          memberTypeInformation, parameter, type, member as FunctionEntity);
    } else if (member.isInstanceMember) {
      return ParameterTypeInformation.instanceMember(
          abstractValueDomain,
          memberTypeInformation,
          parameter,
          type,
          member as FunctionEntity,
          ParameterInputs.instanceMember(),
          isVirtual: isVirtual);
    } else {
      return ParameterTypeInformation.static(abstractValueDomain,
          memberTypeInformation, parameter, type, member as FunctionEntity);
    }
  }

  @override
  MemberTypeInformation createMemberTypeInformation(
      AbstractValueDomain abstractValueDomain, MemberEntity member) {
    if (member is FieldEntity) {
      final field = member;
      DartType type = _elementEnvironment.getFieldType(field);
      return FieldTypeInformation(abstractValueDomain, field, type);
    } else if (member.isGetter) {
      final getter = member as FunctionEntity;
      DartType type = _elementEnvironment.getFunctionType(getter);
      return GetterTypeInformation(
          abstractValueDomain, getter, type as FunctionType);
    } else if (member.isSetter) {
      final setter = member as FunctionEntity;
      return SetterTypeInformation(abstractValueDomain, setter);
    } else if (member.isFunction) {
      final method = member as FunctionEntity;
      DartType type = _elementEnvironment.getFunctionType(method);
      return MethodTypeInformation(
          abstractValueDomain, method, type as FunctionType);
    } else {
      final constructor = member as ConstructorEntity;
      if (constructor.isFactoryConstructor) {
        DartType type = _elementEnvironment.getFunctionType(constructor);
        return FactoryConstructorTypeInformation(
            abstractValueDomain, constructor, type as FunctionType);
      } else {
        return GenerativeConstructorTypeInformation(
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

  // TODO(natebiggs): Can we remove nulls from these maps.
  Map<ir.TreeNode, AbstractValue?>? _receiverMap;

  Map<ir.ForInStatement, AbstractValue?>? _iteratorMap;
  Map<ir.ForInStatement, AbstractValue?>? _currentMap;
  Map<ir.ForInStatement, AbstractValue?>? _moveNextMap;

  KernelGlobalTypeInferenceElementData();

  KernelGlobalTypeInferenceElementData.internal(this._receiverMap,
      this._iteratorMap, this._currentMap, this._moveNextMap);

  /// Deserializes a [GlobalTypeInferenceElementData] object from [source].
  factory KernelGlobalTypeInferenceElementData.readFromDataSource(
      DataSourceReader source,
      ir.Member? context,
      AbstractValueDomain abstractValueDomain) {
    return source.inMemberContext(context, () {
      source.begin(tag);
      Map<ir.TreeNode, AbstractValue>? sendMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? iteratorMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? currentMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      Map<ir.ForInStatement, AbstractValue>? moveNextMap =
          source.readTreeNodeMapInContextOrNull(() =>
              abstractValueDomain.readAbstractValueFromDataSource(source));
      source.end(tag);
      return KernelGlobalTypeInferenceElementData.internal(
          sendMap, iteratorMap, currentMap, moveNextMap);
    });
  }

  @override
  void writeToDataSink(DataSinkWriter sink, ir.Member? context,
      AbstractValueDomain abstractValueDomain) {
    sink.inMemberContext(context, () {
      sink.begin(tag);
      sink.writeTreeNodeMapInContext(
          _receiverMap,
          (AbstractValue? value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _iteratorMap,
          (AbstractValue? value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _currentMap,
          (AbstractValue? value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.writeTreeNodeMapInContext(
          _moveNextMap,
          (AbstractValue? value) =>
              abstractValueDomain.writeAbstractValueToDataSink(sink, value),
          allowNull: true);
      sink.end(tag);
    });
  }

  @override
  GlobalTypeInferenceElementData? compress() {
    final receiverMap = _receiverMap;
    if (receiverMap != null) {
      receiverMap.removeWhere(_mapsToNull);
      if (receiverMap.isEmpty) {
        _receiverMap = null;
      }
    }
    final iteratorMap = _iteratorMap;
    if (iteratorMap != null) {
      iteratorMap.removeWhere(_mapsToNull);
      if (iteratorMap.isEmpty) {
        _iteratorMap = null;
      }
    }
    final currentMap = _currentMap;
    if (currentMap != null) {
      currentMap.removeWhere(_mapsToNull);
      if (currentMap.isEmpty) {
        _currentMap = null;
      }
    }
    final moveNextMap = _moveNextMap;
    if (moveNextMap != null) {
      moveNextMap.removeWhere(_mapsToNull);
      if (moveNextMap.isEmpty) {
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
  AbstractValue? typeOfReceiver(ir.TreeNode node) {
    if (_receiverMap == null) return null;
    return _receiverMap![node];
  }

  void setCurrentTypeMask(ir.ForInStatement node, AbstractValue? mask) {
    final currentMap = _currentMap ??= <ir.ForInStatement, AbstractValue?>{};
    currentMap[node] = mask;
  }

  void setMoveNextTypeMask(ir.ForInStatement node, AbstractValue? mask) {
    final moveNextMap = _moveNextMap ??= <ir.ForInStatement, AbstractValue?>{};
    moveNextMap[node] = mask;
  }

  void setIteratorTypeMask(ir.ForInStatement node, AbstractValue? mask) {
    final iteratorMap = _iteratorMap ??= <ir.ForInStatement, AbstractValue?>{};
    iteratorMap[node] = mask;
  }

  @override
  AbstractValue? typeOfIteratorCurrent(covariant ir.ForInStatement node) {
    if (_currentMap == null) return null;
    return _currentMap![node];
  }

  @override
  AbstractValue? typeOfIteratorMoveNext(covariant ir.ForInStatement node) {
    if (_moveNextMap == null) return null;
    return _moveNextMap![node];
  }

  @override
  AbstractValue? typeOfIterator(covariant ir.ForInStatement node) {
    if (_iteratorMap == null) return null;
    return _iteratorMap![node];
  }

  void setReceiverTypeMask(ir.TreeNode node, AbstractValue? mask) {
    final receiverMap = _receiverMap ??= <ir.TreeNode, AbstractValue?>{};
    receiverMap[node] = mask;
  }
}

bool _mapsToNull(ir.TreeNode node, AbstractValue? value) => value == null;
