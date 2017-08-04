// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/names.dart';
import '../compiler.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../resolution/tree_elements.dart';
import '../tree/nodes.dart' as ast;
import '../types/constants.dart';
import '../types/types.dart';
import '../universe/selector.dart';
import '../util/util.dart';
import '../world.dart';
import 'closure_tracer.dart';
import 'debug.dart' as debug;
import 'locals_handler.dart';
import 'builder.dart';
import 'builder_kernel.dart';
import 'inferrer_engine.dart';
import 'type_graph_dump.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

class AstInferrerEngine extends InferrerEngineImpl<ast.Node> {
  AstInferrerEngine(Compiler compiler, ClosedWorld closedWorld,
      ClosedWorldRefiner closedWorldRefiner, FunctionEntity mainElement)
      : super(compiler, closedWorld, closedWorldRefiner, mainElement,
            const TypeSystemStrategyImpl());

  GlobalTypeInferenceElementData<ast.Node> createElementData() =>
      new AstGlobalTypeInferenceElementData();

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
      MemberElement member = resolvedAst.element;
      ast.Node body;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        body = resolvedAst.body;
      }
      types.withMember(member, () => analyze(member, body, null));
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

    Set<FunctionEntity> bailedOutOn = new Set<FunctionEntity>();

    // Trace closures to potentially infer argument types.
    types.allocatedClosures.forEach((dynamic info) {
      void trace(
          Iterable<FunctionEntity> elements, ClosureTracerVisitor tracer) {
        tracer.run();
        if (!tracer.continueAnalyzing) {
          elements.forEach((FunctionEntity _element) {
            MethodElement element = _element;
            MethodElement implementation = element.implementation;
            closedWorldRefiner.registerMightBePassedToApply(element);
            if (debug.VERBOSE) {
              print("traced closure $element as ${true} (bail)");
            }
            implementation.functionSignature
                .forEachParameter((FormalElement _parameter) {
              ParameterElement parameter = _parameter;
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
            .forEach((FunctionEntity _element) {
          MethodElement element = _element;
          MethodElement implementation = element.implementation;
          implementation.functionSignature
              .forEachParameter((FormalElement _parameter) {
            ParameterElement parameter = _parameter;
            ParameterTypeInformation info =
                types.getInferredTypeOfParameter(parameter);
            info.maybeResume();
            workQueue.add(info);
          });
          if (tracer.tracedType.mightBePassedToFunctionApply) {
            closedWorldRefiner.registerMightBePassedToApply(element);
          }
          if (debug.VERBOSE) {
            print("traced closure $element as "
                "${closedWorldRefiner
                .getCurrentlyKnownMightBePassedToApply(element)}");
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
          MethodElement calledElement = info.calledElement;
          assert(calledElement.isGenerativeConstructor);
          ClassElement cls = calledElement.enclosingClass;
          MethodElement callMethod = cls.lookupMember(Identifiers.call);
          if (callMethod == null) {
            callMethod = cls.lookupMember(Identifiers.noSuchMethod_);
          }
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
          for (MemberEntity target in info.targets) {
            if (target is FunctionEntity) {
              print(
                  '${types.getInferredSignatureOfMethod(target)} for ${target}');
            } else {
              print(
                  '${types.getInferredTypeOfMember(target).type} for ${target}');
            }
          }
        } else if (info is StaticCallSiteTypeInformation) {
          ClassElement cls = info.calledElement.enclosingClass;
          MethodElement callMethod = cls.lookupMember(Identifiers.call);
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

  void analyze(MemberEntity element, ast.Node body, ArgumentsTypes arguments) {
    assert(!(element is MemberElement && !element.isDeclaration));
    if (analyzedElements.contains(element)) return;
    analyzedElements.add(element);

    dynamic visitor = compiler.options.kernelGlobalInference
        ? new KernelTypeGraphBuilder(element, compiler, this)
        : new ElementGraphBuilder(element, compiler, this);
    TypeInformation type;
    reporter.withCurrentElement(element, () {
      // ignore: UNDEFINED_METHOD
      type = visitor.run();
    });
    addedInGraph++;

    if (element.isField) {
      FieldElement field = element;
      if (field.isFinal || field.isConst) {
        // If [element] is final and has an initializer, we record
        // the inferred type.
        if (body != null) {
          if (type is! ListTypeInformation && type is! MapTypeInformation) {
            // For non-container types, the constant handler does
            // constant folding that could give more precise results.
            ConstantExpression constant = field.constant;
            if (constant != null) {
              ConstantValue value =
                  compiler.backend.constants.getConstantValue(constant);
              if (value != null) {
                if (value.isFunction) {
                  FunctionConstantValue functionConstant = value;
                  MethodElement function = functionConstant.element;
                  type = types.allocateClosure(function);
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
                    field.isInstanceMember ||
                        constant.isImplicit ||
                        constant.isPotential,
                    failedAt(
                        field,
                        "Constant expression without value: "
                        "${constant.toStructuredText()}."));
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
        dynamic argument = body;
        // TODO(13429): We could do better here by using the
        // constant handler to figure out if it's a lazy field or not.
        if (argument.asSend() != null ||
            (argument.asNewExpression() != null && !argument.isConst)) {
          recordTypeOfField(field, types.nullType);
        }
      }
    } else {
      FunctionEntity method = element;
      recordReturnType(method, type);
    }
  }

  void updateParameterAssignments(TypeInformation caller, MemberEntity callee,
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
      MethodElement method = callee;
      MemberTypeInformation info = types.getInferredTypeOfMember(method);
      if (remove) {
        info.closurizedCount--;
      } else {
        info.closurizedCount++;
        if (Elements.isStaticOrTopLevel(method)) {
          types.allocatedClosures.add(info);
        } else {
          // We add the call-site type information here so that we
          // can benefit from further refinement of the selector.
          types.allocatedClosures.add(caller);
        }
        FunctionElement function = method.implementation;
        FunctionSignature signature = function.functionSignature;
        signature.forEachParameter((FormalElement _parameter) {
          ParameterElement parameter = _parameter;
          ParameterTypeInformation info =
              types.getInferredTypeOfParameter(parameter);
          info.tagAsTearOffClosureParameter(this);
          if (addToQueue) workQueue.add(info);
        });
      }
    } else {
      MethodElement method = callee;
      FunctionElement function = method.implementation;
      FunctionSignature signature = function.functionSignature;
      int parameterIndex = 0;
      bool visitingRequiredParameter = true;
      signature.forEachParameter((FormalElement _parameter) {
        ParameterElement parameter = _parameter;
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
}

class TypeSystemStrategyImpl implements TypeSystemStrategy<ast.Node> {
  const TypeSystemStrategyImpl();

  @override
  MemberTypeInformation createMemberTypeInformation(
      covariant MemberElement member) {
    assert(member.isDeclaration, failedAt(member));
    if (member.isField) {
      FieldElement field = member;
      return new FieldTypeInformation(field, field.type);
    } else if (member.isGetter) {
      GetterElement getter = member;
      return new GetterTypeInformation(getter, getter.type);
    } else if (member.isSetter) {
      SetterElement setter = member;
      return new SetterTypeInformation(setter);
    } else if (member.isFunction) {
      MethodElement method = member;
      return new MethodTypeInformation(method, method.type);
    } else {
      ConstructorElement constructor = member;
      if (constructor.isFactoryConstructor) {
        return new FactoryConstructorTypeInformation(
            constructor, constructor.type);
      } else {
        return new GenerativeConstructorTypeInformation(constructor);
      }
    }
  }

  @override
  ParameterTypeInformation createParameterTypeInformation(
      covariant ParameterElement parameter, TypeSystem<ast.Node> types) {
    assert(parameter.isImplementation, failedAt(parameter));
    FunctionTypedElement function = parameter.functionDeclaration.declaration;
    if (function.isLocal) {
      LocalFunctionElement localFunction = function;
      MethodElement callMethod = localFunction.callMethod;
      return new ParameterTypeInformation.localFunction(
          types.getInferredTypeOfMember(callMethod),
          parameter,
          parameter.type,
          callMethod);
    } else if (function.isInstanceMember) {
      MethodElement method = function;
      return new ParameterTypeInformation.instanceMember(
          types.getInferredTypeOfMember(method),
          parameter,
          parameter.type,
          method,
          new ParameterAssignments());
    } else {
      MethodElement method = function;
      return new ParameterTypeInformation.static(
          types.getInferredTypeOfMember(method),
          parameter,
          parameter.type,
          method,
          // TODO(johnniwinther): Is this still valid now that initializing
          // formals also introduce locals?
          isInitializingFormal: parameter.isInitializingFormal);
    }
  }

  @override
  void forEachParameter(
      covariant MethodElement function, void f(Local parameter)) {
    MethodElement impl = function.implementation;
    FunctionSignature signature = impl.functionSignature;
    signature.forEachParameter((FormalElement _parameter) {
      ParameterElement parameter = _parameter;
      f(parameter);
    });
  }

  @override
  bool checkMapNode(ast.Node node) {
    return node is ast.LiteralMap;
  }

  @override
  bool checkListNode(ast.Node node) {
    return node is ast.LiteralList || node is ast.Send;
  }

  @override
  bool checkLoopPhiNode(ast.Node node) {
    return node is ast.Loop || node is ast.SwitchStatement;
  }

  @override
  bool checkPhiNode(ast.Node node) {
    return true;
  }

  @override
  bool checkClassEntity(covariant ClassElement cls) {
    return cls.isDeclaration;
  }
}
