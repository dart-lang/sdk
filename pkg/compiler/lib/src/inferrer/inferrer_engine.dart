// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../js_backend/annotations.dart';
import '../js_backend/js_backend.dart';
import '../native/behavior.dart' as native;
import '../resolution/tree_elements.dart';
import '../tree/nodes.dart' as ast;
import '../types/constants.dart';
import '../types/types.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../util/util.dart';
import '../world.dart';
import 'closure_tracer.dart';
import 'debug.dart' as debug;
import 'locals_handler.dart';
import 'list_tracer.dart';
import 'map_tracer.dart';
import 'builder.dart';
import 'builder_kernel.dart';
import 'type_graph_dump.dart';
import 'type_graph_inferrer.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

/**
 * An inferencing engine that computes a call graph of
 * [TypeInformation] nodes by visiting the AST of the application, and
 * then does the inferencing on the graph.
 */
class InferrerEngine {
  final Map<ParameterElement, TypeInformation> defaultTypeOfParameter =
      new Map<ParameterElement, TypeInformation>();
  final WorkQueue workQueue = new WorkQueue();
  final FunctionEntity mainElement;
  final Set<MemberElement> analyzedElements = new Set<MemberElement>();

  /// The maximum number of times we allow a node in the graph to
  /// change types. If a node reaches that limit, we give up
  /// inferencing on it and give it the dynamic type.
  final int MAX_CHANGE_COUNT = 6;

  int overallRefineCount = 0;
  int addedInGraph = 0;

  final Compiler compiler;

  /// The [ClosedWorld] on which inference reasoning is based.
  final ClosedWorld closedWorld;

  final ClosedWorldRefiner closedWorldRefiner;
  final TypeSystem types;
  final Map<ast.Node, TypeInformation> concreteTypes =
      new Map<ast.Node, TypeInformation>();

  /// Parallel structure for concreteTypes.
  // TODO(efortuna): Remove concreteTypes and/or parameterize InferrerEngine by
  // ir.Node or ast.Node type. Then remove this in favor of `concreteTypes`.
  final Map<ir.Node, TypeInformation> concreteKernelTypes =
      new Map<ir.Node, TypeInformation>();
  final Set<ConstructorElement> generativeConstructorsExposingThis =
      new Set<ConstructorElement>();

  /// Data computed internally within elements, like the type-mask of a send a
  /// list allocation, or a for-in loop.
  final Map<MemberElement, GlobalTypeInferenceElementData> _memberData =
      new Map<MemberElement, GlobalTypeInferenceElementData>();

  InferrerEngine(this.compiler, ClosedWorld closedWorld,
      this.closedWorldRefiner, this.mainElement)
      : this.types = new TypeSystem(closedWorld),
        this.closedWorld = closedWorld;

  CommonElements get commonElements => closedWorld.commonElements;

  /// Returns `true` if [element] has an `@AssumeDynamic()` annotation.
  bool assumeDynamic(Element element) {
    return element is MemberElement && optimizerHints.assumeDynamic(element);
  }

  /// Returns `true` if [element] has an `@TrustTypeAnnotations()` annotation.
  bool trustTypeAnnotations(Element element) {
    return element is MemberElement &&
        optimizerHints.trustTypeAnnotations(element);
  }

  /**
   * Applies [f] to all elements in the universe that match
   * [selector] and [mask]. If [f] returns false, aborts the iteration.
   */
  void forEachElementMatching(
      Selector selector, TypeMask mask, bool f(Element element)) {
    Iterable<MemberEntity> elements = closedWorld.locateMembers(selector, mask);
    for (MemberElement e in elements) {
      if (!f(e.implementation)) return;
    }
  }

  // TODO(johnniwinther): Make this private again.
  GlobalTypeInferenceElementData dataOfMember(MemberElement element) =>
      _memberData.putIfAbsent(
          element, () => new GlobalTypeInferenceElementData());

  GlobalTypeInferenceElementData lookupDataOfMember(MemberElement element) =>
      _memberData[element];

  /**
   * Update [sideEffects] with the side effects of [callee] being
   * called with [selector].
   */
  void updateSideEffects(
      SideEffects sideEffects, Selector selector, MemberElement callee) {
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
      MethodElement method = callee.declaration;
      sideEffects.add(closedWorldRefiner.getCurrentlyKnownSideEffects(method));
    }
  }

  /**
   * Returns the type for [nativeBehavior]. See documentation on
   * [native.NativeBehavior].
   */
  TypeInformation typeOfNativeBehavior(native.NativeBehavior nativeBehavior) {
    if (nativeBehavior == null) return types.dynamicType;
    List typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return types.dynamicType;
    TypeInformation returnType;
    for (var type in typesReturned) {
      TypeInformation mappedType;
      if (type == native.SpecialType.JsObject) {
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

  void updateSelectorInMember(
      MemberElement owner, Spannable node, Selector selector, TypeMask mask) {
    GlobalTypeInferenceElementData data = dataOfMember(owner);
    ast.Node astNode = node;
    if (astNode.asSendSet() != null) {
      if (selector.isSetter || selector.isIndexSet) {
        data.setTypeMask(node, mask);
      } else if (selector.isGetter || selector.isIndex) {
        data.setGetterTypeMaskInComplexSendSet(node, mask);
      } else {
        assert(selector.isOperator);
        data.setOperatorTypeMaskInComplexSendSet(node, mask);
      }
    } else if (astNode.asSend() != null) {
      data.setTypeMask(node, mask);
    } else {
      assert(astNode.asForIn() != null);
      if (selector == Selectors.iterator) {
        data.setIteratorTypeMask(node, mask);
      } else if (selector == Selectors.current) {
        data.setCurrentTypeMask(node, mask);
      } else {
        assert(selector == Selectors.moveNext);
        data.setMoveNextTypeMask(node, mask);
      }
    }
  }

  bool checkIfExposesThis(ConstructorElement element) {
    element = element.implementation;
    return generativeConstructorsExposingThis.contains(element);
  }

  void recordExposesThis(ConstructorElement element, bool exposesThis) {
    element = element.implementation;
    if (exposesThis) {
      generativeConstructorsExposingThis.add(element);
    }
  }

  JavaScriptBackend get backend => compiler.backend;
  OptimizerHintsForTests get optimizerHints => backend.optimizerHints;
  DiagnosticReporter get reporter => compiler.reporter;
  CommonMasks get commonMasks => closedWorld.commonMasks;

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
    types.allocatedLists.values.forEach((TypeInformation info) {
      analyzeListAndEnqueue(info);
    });

    // Try to infer the key and value types for maps and compute the values'
    // escape information.
    types.allocatedMaps.values.forEach((TypeInformation info) {
      analyzeMapAndEnqueue(info);
    });

    Set<MethodElement> bailedOutOn = new Set<MethodElement>();

    // Trace closures to potentially infer argument types.
    types.allocatedClosures.forEach((dynamic info) {
      void trace(
          Iterable<MethodElement> elements, ClosureTracerVisitor tracer) {
        tracer.run();
        if (!tracer.continueAnalyzing) {
          elements.forEach((MethodElement e) {
            closedWorldRefiner.registerMightBePassedToApply(e);
            if (debug.VERBOSE) print("traced closure $e as ${true} (bail)");
            e.functionSignature.forEachParameter((parameter) {
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
            .forEach((MethodElement e) {
          e.functionSignature.forEachParameter((parameter) {
            var info = types.getInferredTypeOfParameter(parameter);
            info.maybeResume();
            workQueue.add(info);
          });
          if (tracer.tracedType.mightBePassedToFunctionApply) {
            closedWorldRefiner.registerMightBePassedToApply(e);
          }
          if (debug.VERBOSE) {
            print("traced closure $e as "
                "${closedWorldRefiner
                .getCurrentlyKnownMightBePassedToApply(e)}");
          }
        });
      }

      if (info is ClosureTypeInformation) {
        Iterable<MethodElement> elements = [info.closure];
        trace(elements, new ClosureTracerVisitor(elements, info, this));
      } else if (info is CallSiteTypeInformation) {
        if (info is StaticCallSiteTypeInformation &&
            info.selector != null &&
            info.selector.isCall) {
          // This is a constructor call to a class with a call method. So we
          // need to trace the call method here.
          assert(info.calledElement.isGenerativeConstructor);
          ClassElement cls = info.calledElement.enclosingClass;
          MethodElement callMethod = cls.lookupMember(Identifiers.call);
          assert(callMethod != null, failedAt(cls));
          Iterable<MethodElement> elements = [callMethod];
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        } else {
          // We only are interested in functions here, as other targets
          // of this closure call are not a root to trace but an intermediate
          // for some other function.
          Iterable<MethodElement> elements = new List<MethodElement>.from(
              info.callees.where((e) => e.isFunction));
          trace(elements, new ClosureTracerVisitor(elements, info, this));
        }
      } else if (info is MemberTypeInformation) {
        trace([info.member],
            new StaticTearOffClosureTracerVisitor(info.member, info, this));
      } else if (info is ParameterTypeInformation) {
        throw new SpannableAssertionFailure(
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
            'for ${info.originalType.allocationNode} '
            'at ${info.originalType.allocationElement} '
            'after ${info.refineCount}');
      });
      types.allocatedMaps.values.forEach((_info) {
        MapTypeInformation info = _info;
        print('${info.type} '
            'for ${info.originalType.allocationNode} '
            'at ${info.originalType.allocationElement} '
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
          for (MemberElement target in info.targets) {
            if (target is MethodElement) {
              print(
                  '${types.getInferredSignatureOfMethod(target)} for ${target}');
            } else {
              print(
                  '${types.getInferredTypeOfMember(target).type} for ${target}');
            }
          }
        } else if (info is StaticCallSiteTypeInformation) {
          ClassElement cls = info.calledElement.enclosingClass;
          FunctionElement callMethod = cls.lookupMember(Identifiers.call);
          print('${types.getInferredSignatureOfMethod(callMethod)} for ${cls}');
        } else {
          print('${info.type} for some unknown kind of closure');
        }
      });
      analyzedElements.forEach((MemberElement elem) {
        TypeInformation type = types.getInferredTypeOfMember(elem);
        print('${elem} :: ${type} from ${type.assignments} ');
      });
    }
    dump?.afterAnalysis();

    reporter.log('Inferred $overallRefineCount types.');

    processLoopInformation();
  }

  void analyze(ResolvedAst resolvedAst, ArgumentsTypes arguments) {
    MemberElement element = resolvedAst.element.implementation;
    if (analyzedElements.contains(element)) return;
    analyzedElements.add(element);

    dynamic visitor = compiler.options.kernelGlobalInference
        ? new KernelTypeGraphBuilder(element, resolvedAst, compiler, this)
        : new ElementGraphBuilder(element, resolvedAst, compiler, this);
    TypeInformation type;
    reporter.withCurrentElement(element, () {
      // ignore: UNDEFINED_METHOD
      type = visitor.run();
    });
    addedInGraph++;

    if (element.isField) {
      FieldElement fieldElement = element;
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
                  MethodElement function = functionConstant.element;
                  type = types.allocateClosure(node, function);
                } else {
                  // Although we might find a better type, we have to keep
                  // the old type around to ensure that we get a complete view
                  // of the type graph and do not drop any flow edges.
                  TypeMask refinedType = computeTypeMask(closedWorld, value);
                  assert(TypeMask.assertIsNormalized(refinedType, closedWorld));
                  type = new NarrowTypeInformation(type, refinedType);
                  types.allocatedTypes.add(type);
                }
              } else {
                assert(
                    fieldElement.isInstanceMember ||
                        constant.isImplicit ||
                        constant.isPotential,
                    failedAt(
                        fieldElement,
                        "Constant expression without value: "
                        "${constant.toStructuredText()}."));
              }
            }
          }
          recordTypeOfField(element, type);
        } else if (!element.isInstanceMember) {
          recordTypeOfField(element, types.nullType);
        }
      } else if (initializer == null) {
        // Only update types of static fields if there is no
        // assignment. Instance fields are dealt with in the constructor.
        if (Elements.isStaticOrTopLevelField(element)) {
          recordTypeOfNonFinalField(element, type);
        }
      } else {
        recordTypeOfNonFinalField(element, type);
      }
      if (Elements.isStaticOrTopLevelField(element) &&
          resolvedAst.body != null &&
          !element.isConst) {
        dynamic argument = resolvedAst.body;
        // TODO(13429): We could do better here by using the
        // constant handler to figure out if it's a lazy field or not.
        if (argument.asSend() != null ||
            (argument.asNewExpression() != null && !argument.isConst)) {
          recordTypeOfField(element, types.nullType);
        }
      }
    } else {
      recordReturnType(element, type);
    }
  }

  void processLoopInformation() {
    types.allocatedCalls.forEach((dynamic info) {
      if (!info.inLoop) return;
      if (info is StaticCallSiteTypeInformation) {
        MemberElement member = info.calledElement.declaration;
        closedWorldRefiner.addFunctionCalledInLoop(member);
      } else if (info.mask != null && !info.mask.containsAll(closedWorld)) {
        // For instance methods, we only register a selector called in a
        // loop if it is a typed selector, to avoid marking too many
        // methods as being called from within a loop. This cuts down
        // on the code bloat.
        info.targets.forEach((MemberElement element) {
          closedWorldRefiner.addFunctionCalledInLoop(element);
        });
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
          ParameterTypeInformation info =
              types.getInferredTypeOfParameter(parameter);
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
    TypeInformation info = types.getInferredTypeOfParameter(parameter);
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
  TypeInformation getDefaultTypeOfParameter(ParameterElement parameter) {
    return defaultTypeOfParameter.putIfAbsent(parameter, () {
      return new PlaceholderTypeInformation(types.currentMember);
    });
  }

  /**
   * This helper breaks abstractions but is currently required to work around
   * the wrong modeling of default values of optional parameters of
   * synthetic constructors.
   *
   * TODO(johnniwinther): Remove once default values of synthetic parameters
   * are fixed.
   */
  bool hasAlreadyComputedTypeOfParameterDefault(ParameterElement parameter) {
    TypeInformation seen = defaultTypeOfParameter[parameter];
    return (seen != null && seen is! PlaceholderTypeInformation);
  }

  /**
   * Returns the type of [element].
   */
  TypeInformation typeOfParameter(ParameterElement element) {
    return types.getInferredTypeOfParameter(element);
  }

  /**
   * Returns the type of [element].
   */
  TypeInformation typeOfMember(MemberElement element) {
    if (element is MethodElement) return types.functionType;
    return types.getInferredTypeOfMember(element);
  }

  /**
   * Returns the return type of [element].
   */
  TypeInformation returnTypeOfMember(MemberElement element) {
    if (element is! MethodElement) return types.dynamicType;
    return types.getInferredTypeOfMember(element);
  }

  /**
   * Records that [node] sets final field [element] to be of type [type].
   *
   * [nodeHolder] is the element holder of [node].
   */
  void recordTypeOfFinalField(FieldElement element, TypeInformation type) {
    types.getInferredTypeOfMember(element).addAssignment(type);
  }

  /**
   * Records that [node] sets non-final field [element] to be of type
   * [type].
   */
  void recordTypeOfNonFinalField(FieldElement element, TypeInformation type) {
    types.getInferredTypeOfMember(element).addAssignment(type);
  }

  /**
   * Records that [element] is of type [type].
   */
  // TODO(johnniwinther): Merge [recordTypeOfFinalField] and
  // [recordTypeOfNonFinalField] with this?
  void recordTypeOfField(FieldElement element, TypeInformation type) {
    types.getInferredTypeOfMember(element).addAssignment(type);
  }

  /**
   * Records that the return type [element] is of type [type].
   */
  void recordReturnType(MethodElement element, TypeInformation type) {
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

  /**
   * Notifies to the inferrer that [analyzedElement] can have return
   * type [newType]. [currentType] is the type the [ElementGraphBuilder]
   * currently found.
   *
   * Returns the new type for [analyzedElement].
   */
  TypeInformation addReturnTypeForMethod(
      MethodElement element, TypeInformation unused, TypeInformation newType) {
    TypeInformation type = types.getInferredTypeOfMember(element);
    // TODO(ngeoffray): Clean up. We do this check because
    // [SimpleTypesInferrer] deals with two different inferrers.
    if (element.isGenerativeConstructor) return type;
    type.addAssignment(newType);
    return type;
  }

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
  TypeInformation registerCalledMember(
      Spannable node,
      Selector selector,
      TypeMask mask,
      MemberElement caller,
      MemberElement callee,
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
    // Note: we exclude factory constructors because they don't always create an
    // instance of the type. They are static methods that delegate to some other
    // generative constructor to do the actual creation of the object.
    if (selector != null && selector.isCall && callee.isGenerativeConstructor) {
      ClassElement cls = callee.enclosingClass;
      if (cls.callType != null) {
        types.allocatedClosures.add(info);
      }
    }
    info.addToGraph(this);
    types.allocatedCalls.add(info);
    updateSideEffects(sideEffects, selector, callee);
    return info;
  }

  /**
   * Registers that [caller] calls [selector] with [receiverType] as
   * receiver, and [arguments].
   *
   * [sideEffects] will be updated to incorporate the potential
   * callees' side effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  TypeInformation registerCalledSelector(
      ast.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation receiverType,
      MemberElement caller,
      ArgumentsTypes arguments,
      SideEffects sideEffects,
      bool inLoop) {
    if (selector.isClosureCall) {
      return registerCalledClosure(node, selector, mask, receiverType, caller,
          arguments, sideEffects, inLoop);
    }

    closedWorld.locateMembers(selector, mask).forEach((_callee) {
      MemberElement callee = _callee;
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
    types.allocatedCalls.add(info);
    return info;
  }

  /**
   * Registers a call to await with an expression of type [argumentType] as
   * argument.
   */
  TypeInformation registerAwait(ast.Node node, TypeInformation argument) {
    AwaitTypeInformation info =
        new AwaitTypeInformation(types.currentMember, node);
    info.addAssignment(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  /**
   * Registers a call to yield with an expression of type [argumentType] as
   * argument.
   */
  TypeInformation registerYield(ast.Node node, TypeInformation argument) {
    YieldTypeInformation info =
        new YieldTypeInformation(types.currentMember, node);
    info.addAssignment(argument);
    types.allocatedTypes.add(info);
    return info;
  }

  /**
   * Registers that [caller] calls [closure] with [arguments].
   *
   * [sideEffects] will be updated to incorporate the potential
   * callees' side effects.
   *
   * [inLoop] tells whether the call happens in a loop.
   */
  TypeInformation registerCalledClosure(
      ast.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation closure,
      MemberElement caller,
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
    types.allocatedCalls.add(info);
    return info;
  }

  // Sorts the resolved elements by size. We do this for this inferrer
  // to get the same results for [ListTracer] compared to the
  // [SimpleTypesInferrer].
  Iterable<ResolvedAst> sortResolvedAsts() {
    int max = 0;
    Map<int, Setlet<ResolvedAst>> methodSizes = <int, Setlet<ResolvedAst>>{};
    compiler.enqueuer.resolution.processedEntities.forEach((_element) {
      MemberElement element = _element;
      ResolvedAst resolvedAst = element.resolvedAst;
      element = element.implementation;
      if (element.impliesType) return;
      assert(
          element.isField ||
              element.isFunction ||
              element.isConstructor ||
              element.isGetter ||
              element.isSetter,
          failedAt(element, 'Unexpected element kind: ${element.kind}'));
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
  }

  Iterable<Element> getCallersOf(MemberElement element) {
    if (compiler.disableTypeInference) {
      throw new UnsupportedError(
          "Cannot query the type inferrer when type inference is disabled.");
    }
    MemberTypeInformation info = types.getInferredTypeOfMember(element);
    return info.callers;
  }

  /**
   * Returns the type of [element] when being called with [selector].
   */
  TypeInformation typeOfMemberWithSelector(
      MemberElement element, Selector selector) {
    return _typeOfElementWithSelector(element, selector);
  }

  /**
   * Returns the type of [element] when being called with [selector].
   */
  TypeInformation _typeOfElementWithSelector(
      MemberElement element, Selector selector) {
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
      } else if (Elements.isUnresolved(element)) {
        return types.dynamicType;
      } else {
        assert(element.isGetter);
        return returnTypeOfMember(element);
      }
    } else if (element.isGetter || element.isField) {
      assert(selector.isCall || selector.isSetter);
      return types.dynamicType;
    } else {
      return returnTypeOfMember(element);
    }
  }

  /**
   * Records that the captured variable [local] is read.
   */
  void recordCapturedLocalRead(Local local) {}

  /**
   * Records that the variable [local] is being updated.
   */
  void recordLocalUpdate(Local local, TypeInformation type) {}
}
