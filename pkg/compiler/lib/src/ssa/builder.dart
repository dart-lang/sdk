// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:js_runtime/shared/embedded_names.dart';

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common/names.dart' show Identifiers, Selectors;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../diagnostics/messages.dart' show Message, MessageTemplate;
import '../dump_info.dart' show InfoReporter;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/modelx.dart' show ConstructorBodyElementX;
import '../elements/names.dart';
import '../elements/operators.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/element_strategy.dart' show ElementCodegenWorkItem;
import '../js_backend/runtime_types.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, NativeEmitter;
import '../native/native.dart' as native;
import '../resolution/semantic_visitor.dart';
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse;
import '../util/util.dart';
import '../world.dart' show ClosedWorld;

import 'graph_builder.dart';
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'nodes.dart';
import 'optimize.dart';
import 'ssa.dart';
import 'ssa_branch_builder.dart';
import 'type_builder.dart';
import 'types.dart';

abstract class SsaAstBuilderBase extends SsaBuilderFieldMixin
    implements SsaBuilder {
  final CompilerTask task;
  final JavaScriptBackend backend;

  SsaAstBuilderBase(this.task, this.backend);

  ConstantValue getFieldInitialConstantValue(FieldElement field) {
    ConstantExpression constant = field.constant;
    if (constant != null) {
      ConstantValue initialValue = backend.constants.getConstantValue(constant);
      if (initialValue == null) {
        assert(
            field.isInstanceMember ||
                constant.isImplicit ||
                constant.isPotential,
            failedAt(
                field,
                "Constant expression without value: "
                "${constant.toStructuredText()}."));
      }
      return initialValue;
    }
    return null;
  }
}

class SsaAstBuilder extends SsaAstBuilderBase {
  final CodeEmitterTask emitter;
  final SourceInformationStrategy sourceInformationFactory;

  SsaAstBuilder(CompilerTask task, JavaScriptBackend backend,
      this.sourceInformationFactory)
      : emitter = backend.emitter,
        super(task, backend);

  DiagnosticReporter get reporter => backend.reporter;

  HGraph build(covariant ElementCodegenWorkItem work, ClosedWorld closedWorld) {
    return task.measure(() {
      if (handleConstantField(work.element, work.registry, closedWorld)) {
        // No code is generated for `work.element`.
        return null;
      }
      MemberElement element = work.element.implementation;
      return reporter.withCurrentElement(element, () {
        SsaAstGraphBuilder builder = new SsaAstGraphBuilder(
            work.element.implementation,
            work.resolvedAst,
            work.registry,
            backend,
            closedWorld,
            emitter.nativeEmitter,
            sourceInformationFactory);
        HGraph graph = builder.build();

        // Default arguments are handled elsewhere, but we must ensure
        // that the default values are computed during codegen.
        if (!identical(element.kind, ElementKind.FIELD)) {
          MethodElement function = element;
          FunctionSignature signature = function.functionSignature;
          signature.forEachOptionalParameter((_parameter) {
            ParameterElement parameter = _parameter;
            // This ensures the default value will be computed.
            ConstantValue constant =
                backend.constants.getConstantValue(parameter.constant);
            work.registry.registerConstantUse(new ConstantUse.init(constant));
          });
        }
        if (backend.tracer.isEnabled) {
          String name;
          if (element.isClassMember) {
            String className = element.enclosingClass.name;
            String memberName = element.name;
            name = "$className.$memberName";
            if (element.isGenerativeConstructorBody) {
              name = "$name (body)";
            }
          } else {
            name = "${element.name}";
          }
          backend.tracer.traceCompilation(name);
          backend.tracer.traceGraph('builder', graph);
        }
        return graph;
      });
    });
  }
}

/**
 * This class builds SSA nodes for functions represented in AST.
 */
class SsaAstGraphBuilder extends ast.Visitor
    with
        BaseImplementationOfCompoundsMixin,
        BaseImplementationOfSetIfNullsMixin,
        BaseImplementationOfSuperIndexSetIfNullMixin,
        SemanticSendResolvedMixin,
        NewBulkMixin,
        ErrorBulkMixin,
        GraphBuilder
    implements SemanticSendVisitor {
  /// The element for which this SSA builder is being used.
  final MemberElement target;
  final ClosedWorld closedWorld;

  ResolvedAst resolvedAst;

  /// Used to report information about inlining (which occurs while building the
  /// SSA graph), when dump-info is enabled.
  final InfoReporter infoReporter;

  /// Registry used to enqueue work during codegen, may be null to avoid
  /// enqueing any work.
  // TODO(sigmund,johnniwinther): get rid of registry entirely. We should be
  // able to return the impact as a result after building and avoid enqueing
  // things here. Later the codegen task can decide whether to enqueue
  // something. In the past this didn't matter as much because the SSA graph was
  // used only for codegen, but currently we want to experiment using it for
  // code-analysis too.
  final CodegenRegistry registry;

  /// Results from the global type-inference analysis corresponding to the
  /// current element being visited.
  ///
  /// Invariant: this property is updated together with [resolvedAst].
  GlobalTypeInferenceElementResult elementInferenceResults;

  final JavaScriptBackend backend;

  Compiler get compiler => backend.compiler;

  final ConstantSystem constantSystem;
  final RuntimeTypesSubstitutions rtiSubstitutions;

  SourceInformationBuilder sourceInformationBuilder;

  bool inLazyInitializerExpression = false;

  // TODO(sigmund): make all comments /// instead of /* */
  /* This field is used by the native handler. */
  final NativeEmitter nativeEmitter;

  /**
   * True if we are visiting the expression of a throw statement; we assume this
   * is a slow path.
   */
  bool inExpressionOfThrow = false;

  /**
   * This stack contains declaration elements of the functions being built
   * or inlined by this builder.
   */
  final List<MemberElement> sourceElementStack = <MemberElement>[];

  HInstruction rethrowableException;

  /// Returns `true` if the current element is an `async` function.
  bool get isBuildingAsyncFunction {
    Element element = sourceElement;
    return (element is FunctionElement &&
        element.asyncMarker == AsyncMarker.ASYNC);
  }

  /// Handles the building of loops.
  LoopHandler<ast.Node> loopHandler;

  /// Handles type check building.
  TypeBuilder typeBuilder;

  // TODO(sigmund): make most args optional
  SsaAstGraphBuilder(
      this.target,
      this.resolvedAst,
      this.registry,
      JavaScriptBackend backend,
      this.closedWorld,
      this.nativeEmitter,
      SourceInformationStrategy sourceInformationFactory)
      : this.infoReporter = backend.compiler.dumpInfoTask,
        this.backend = backend,
        this.constantSystem = backend.constantSystem,
        this.rtiSubstitutions = backend.rtiSubstitutions {
    assert(target.isImplementation);
    elementInferenceResults = _resultOf(target);
    assert(elementInferenceResults != null);
    graph.element = target;
    sourceElementStack.add(target);
    sourceInformationBuilder =
        sourceInformationFactory.createBuilderForContext(target);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    localsHandler = new LocalsHandler(
        this,
        target,
        target.memberContext,
        target.contextClass,
        null,
        closedWorld.nativeData,
        closedWorld.interceptorData);
    loopHandler = new SsaLoopHandler(this);
    typeBuilder = new TypeBuilder(this);
  }

  MemberElement get targetElement => target;

  /// Reference to resolved elements in [target]'s AST.
  TreeElements get elements => resolvedAst.elements;

  @override
  SemanticSendVisitor get sendVisitor => this;

  @override
  void visitNode(ast.Node node) {
    internalError(node, "Unhandled node: $node");
  }

  @override
  void apply(ast.Node node, [_]) {
    node.accept(this);
  }

  /// Returns the current source element.
  ///
  /// The returned element is a declaration element.
  // TODO(johnniwinther): Check that all usages of sourceElement agree on
  // implementation/declaration distinction.
  @override
  MemberElement get sourceElement => sourceElementStack.last;

  /// Helper to retrieve global inference results for [element] with special
  /// care for `ConstructorBodyElement`s which don't exist at the time the
  /// global analysis run.
  ///
  /// Note: this helper is used selectively. When we know that we are in a
  /// context were we don't expect to see a constructor body element, we
  /// directly fetch the data from the global inference results.
  GlobalTypeInferenceElementResult _resultOf(MemberElement element) =>
      globalInferenceResults.resultOfMember(
          element is ConstructorBodyElementX ? element.constructor : element);

  /// Build the graph for [target].
  HGraph build() {
    assert(target.isImplementation, failedAt(target));
    HInstruction.idCounter = 0;
    // TODO(sigmund): remove `result` and return graph directly, need to ensure
    // that it can never be null (see result in buildFactory for instance).
    var result;
    if (target.isGenerativeConstructor) {
      result = buildFactory(resolvedAst);
    } else if (target.isGenerativeConstructorBody ||
        target.isFactoryConstructor ||
        target.isFunction ||
        target.isGetter ||
        target.isSetter) {
      result = buildMethod(target);
    } else if (target.isField) {
      if (target.isInstanceMember) {
        assert(options.enableTypeAssertions);
        result = buildCheckedSetter(target);
      } else {
        result = buildLazyInitializer(target);
      }
    } else {
      reporter.internalError(target, 'Unexpected element kind $target.');
    }
    assert(result.isValid());
    return result;
  }

  void addWithPosition(HInstruction instruction, ast.Node node) {
    add(attachPosition(instruction, node));
  }

  /**
   * Returns a complete argument list for a call of [function].
   */
  List<HInstruction> completeSendArgumentsList(
      FunctionElement function,
      Selector selector,
      List<HInstruction> providedArguments,
      ast.Node currentNode) {
    assert(function.isImplementation, failedAt(function));
    assert(providedArguments != null);

    bool isInstanceMember = function.isInstanceMember;
    // For static calls, [providedArguments] is complete, default arguments
    // have been included if necessary, see [makeStaticArgumentList].
    if (!isInstanceMember ||
        currentNode == null || // In erroneous code, currentNode can be null.
        providedArgumentsKnownToBeComplete(currentNode) ||
        function.isGenerativeConstructorBody ||
        selector.isGetter) {
      // For these cases, the provided argument list is known to be complete.
      return providedArguments;
    } else {
      return completeDynamicSendArgumentsList(
          selector, function, providedArguments);
    }
  }

  /**
   * Returns a complete argument list for a dynamic call of [function]. The
   * initial argument list [providedArguments], created by
   * [addDynamicSendArgumentsToList], does not include values for default
   * arguments used in the call. The reason is that the target function (which
   * defines the defaults) is not known.
   *
   * However, inlining can only be performed when the target function can be
   * resolved statically. The defaults can therefore be included at this point.
   *
   * The [providedArguments] list contains first all positional arguments, then
   * the provided named arguments (the named arguments that are defined in the
   * [selector]) in a specific order (see [addDynamicSendArgumentsToList]).
   */
  List<HInstruction> completeDynamicSendArgumentsList(Selector selector,
      MethodElement function, List<HInstruction> providedArguments) {
    assert(selector.applies(function));
    FunctionSignature signature = function.functionSignature;
    List<HInstruction> compiledArguments = new List<HInstruction>(
        signature.parameterCount + 1); // Plus one for receiver.

    compiledArguments[0] = providedArguments[0]; // Receiver.
    int index = 1;
    for (; index <= signature.requiredParameterCount; index++) {
      compiledArguments[index] = providedArguments[index];
    }
    if (!signature.optionalParametersAreNamed) {
      signature.forEachOptionalParameter((element) {
        if (index < providedArguments.length) {
          compiledArguments[index] = providedArguments[index];
        } else {
          compiledArguments[index] =
              handleConstantForOptionalParameter(element);
        }
        index++;
      });
    } else {
      /* Example:
       *   void foo(a, {b, d, c})
       *   foo(0, d = 1, b = 2)
       *
       * providedArguments = [0, 2, 1]
       * selectorArgumentNames = [b, d]
       * signature.orderedOptionalParameters = [b, c, d]
       *
       * For each parameter name in the signature, if the argument name matches
       * we use the next provided argument, otherwise we get the default.
       */
      List<String> selectorArgumentNames =
          selector.callStructure.getOrderedNamedArguments();
      int namedArgumentIndex = 0;
      int firstProvidedNamedArgument = index;
      signature.orderedOptionalParameters.forEach((element) {
        if (namedArgumentIndex < selectorArgumentNames.length &&
            element.name == selectorArgumentNames[namedArgumentIndex]) {
          // The named argument was provided in the function invocation.
          compiledArguments[index] = providedArguments[
              firstProvidedNamedArgument + namedArgumentIndex++];
        } else {
          compiledArguments[index] =
              handleConstantForOptionalParameter(element);
        }
        index++;
      });
    }
    return compiledArguments;
  }

  /**
   * Try to inline [element] within the correct context of the builder. The
   * insertion point is the state of the builder.
   */
  bool tryInlineMethod(MethodElement element, Selector selector, TypeMask mask,
      List<HInstruction> providedArguments, ast.Node currentNode,
      {ResolutionInterfaceType instanceType}) {
    if (nativeData.isJsInteropMember(element) &&
        !element.isFactoryConstructor) {
      // We only inline factory JavaScript interop constructors.
      return false;
    }

    // Ensure that [element] is an implementation element.
    element = element.implementation;

    if (compiler.elementHasCompileTimeError(element)) return false;

    MethodElement function = element;
    MethodElement declaration = function.declaration;
    ResolvedAst functionResolvedAst = function.resolvedAst;
    bool insideLoop = loopDepth > 0 || graph.calledInLoop;

    // Bail out early if the inlining decision is in the cache and we can't
    // inline (no need to check the hard constraints).
    bool cachedCanBeInlined =
        inlineCache.canInline(declaration, insideLoop: insideLoop);
    if (cachedCanBeInlined == false) return false;

    bool meetsHardConstraints() {
      if (options.disableInlining) return false;

      assert(
          selector != null ||
              Elements.isStaticOrTopLevel(function) ||
              function.isGenerativeConstructorBody,
          failedAt(currentNode ?? function,
              "Missing selector for inlining of $function."));
      if (selector != null) {
        if (!selector.applies(function)) return false;
        if (mask != null && !mask.canHit(function, selector, closedWorld)) {
          return false;
        }
      }

      if (nativeData.isJsInteropMember(function)) return false;

      // Don't inline operator== methods if the parameter can be null.
      if (function.name == '==') {
        if (function.enclosingClass != commonElements.objectClass &&
            providedArguments[1].canBeNull()) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (function.isGenerativeConstructor &&
          nativeData.isNativeOrExtendsNative(function.enclosingClass)) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (!function.isGenerativeConstructorBody) {
        if (globalInferenceResults.resultOfMember(function).throwsAlways) {
          isReachable = false;
          return false;
        }
      }

      return true;
    }

    bool doesNotContainCode() {
      // A function with size 1 does not contain any code.
      return InlineWeeder.canBeInlined(functionResolvedAst, 1,
          enableUserAssertions: options.enableUserAssertions);
    }

    bool reductiveHeuristic() {
      // The call is on a path which is executed rarely, so inline only if it
      // does not make the program larger.
      if (isCalledOnce(function)) {
        return InlineWeeder.canBeInlined(functionResolvedAst, null,
            enableUserAssertions: options.enableUserAssertions);
      }
      // TODO(sra): Measure if inlining would 'reduce' the size.  One desirable
      // case we miss by doing nothing is inlining very simple constructors
      // where all fields are initialized with values from the arguments at this
      // call site.  The code is slightly larger (`new Foo(1)` vs `Foo$(1)`) but
      // that usually means the factory constructor is left unused and not
      // emitted.
      // We at least inline bodies that are empty (and thus have a size of 1).
      return doesNotContainCode();
    }

    bool heuristicSayGoodToGo() {
      // Don't inline recursively
      if (inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      if (function.isSynthesized) return true;

      // Don't inline across deferred import to prevent leaking code. The only
      // exception is an empty function (which does not contain code).
      bool hasOnlyNonDeferredImportPaths = deferredLoadTask
          .hasOnlyNonDeferredImportPaths(compiler.currentElement, function);

      if (!hasOnlyNonDeferredImportPaths) {
        return doesNotContainCode();
      }

      // Do not inline code that is rarely executed unless it reduces size.
      if (inExpressionOfThrow || inLazyInitializerExpression) {
        return reductiveHeuristic();
      }

      if (cachedCanBeInlined == true) {
        // We may have forced the inlining of some methods. Therefore check
        // if we can inline this method regardless of size.
        assert(InlineWeeder.canBeInlined(functionResolvedAst, null,
            allowLoops: true,
            enableUserAssertions: options.enableUserAssertions));
        return true;
      }

      int numParameters = function.functionSignature.parameterCount;
      int maxInliningNodes;
      if (insideLoop) {
        maxInliningNodes = InlineWeeder.INLINING_NODES_INSIDE_LOOP +
            InlineWeeder.INLINING_NODES_INSIDE_LOOP_ARG_FACTOR * numParameters;
      } else {
        maxInliningNodes = InlineWeeder.INLINING_NODES_OUTSIDE_LOOP +
            InlineWeeder.INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR * numParameters;
      }

      // If a method is called only once, and all the methods in the
      // inlining stack are called only once as well, we know we will
      // save on output size by inlining this method.
      if (isCalledOnce(function)) {
        maxInliningNodes = null;
      }
      bool canInline = InlineWeeder.canBeInlined(
          functionResolvedAst, maxInliningNodes,
          enableUserAssertions: options.enableUserAssertions);
      if (canInline) {
        inlineCache.markAsInlinable(declaration, insideLoop: insideLoop);
      } else {
        inlineCache.markAsNonInlinable(declaration, insideLoop: insideLoop);
      }
      return canInline;
    }

    void doInlining() {
      registry.registerStaticUse(new StaticUse.inlining(declaration));

      // Add an explicit null check on the receiver before doing the
      // inlining. We use [element] to get the same name in the
      // NoSuchMethodError message as if we had called it.
      if (function.isInstanceMember &&
          !function.isGenerativeConstructorBody &&
          (mask == null || mask.isNullable)) {
        addWithPosition(
            new HFieldGet(null, providedArguments[0], commonMasks.dynamicType,
                isAssignable: false),
            currentNode);
      }
      List<HInstruction> compiledArguments = completeSendArgumentsList(
          function, selector, providedArguments, currentNode);
      enterInlinedMethod(function, functionResolvedAst, compiledArguments,
          instanceType: instanceType);
      inlinedFrom(functionResolvedAst, () {
        if (!isReachable) {
          emitReturn(graph.addConstantNull(closedWorld), null);
        } else {
          doInline(functionResolvedAst);
        }
      });
      leaveInlinedMethod();
    }

    if (meetsHardConstraints() && heuristicSayGoodToGo()) {
      doInlining();
      infoReporter?.reportInlined(function,
          inliningStack.isEmpty ? target : inliningStack.last.function);
      return true;
    }

    return false;
  }

  bool get allInlinedFunctionsCalledOnce {
    return inliningStack.isEmpty || inliningStack.last.allFunctionsCalledOnce;
  }

  bool isFunctionCalledOnce(MethodElement element) {
    // ConstructorBodyElements are not in the type inference graph.
    if (element is ConstructorBodyElement) return false;
    return globalInferenceResults.resultOfMember(element).isCalledOnce;
  }

  bool isCalledOnce(MethodElement element) {
    return allInlinedFunctionsCalledOnce && isFunctionCalledOnce(element);
  }

  inlinedFrom(ResolvedAst resolvedAst, f()) {
    MemberElement element = resolvedAst.element;
    assert(element is FunctionElement || element is VariableElement);
    return reporter.withCurrentElement(element.implementation, () {
      // The [sourceElementStack] contains declaration elements.
      SourceInformationBuilder oldSourceInformationBuilder =
          sourceInformationBuilder;
      sourceInformationBuilder = sourceInformationBuilder.forContext(element);
      sourceElementStack.add(element.declaration);
      var result = f();
      sourceInformationBuilder = oldSourceInformationBuilder;
      sourceElementStack.removeLast();
      return result;
    });
  }

  /**
   * Return null so it is simple to remove the optional parameters completely
   * from interop methods to match JavaScript semantics for omitted arguments.
   */
  HInstruction handleConstantForOptionalParameterJsInterop(Element parameter) =>
      null;

  HInstruction handleConstantForOptionalParameter(ParameterElement parameter) {
    ConstantValue constantValue =
        constants.getConstantValue(parameter.constant);
    assert(constantValue != null,
        failedAt(parameter, 'No constant computed for $parameter'));
    return graph.addConstant(constantValue, closedWorld);
  }

  ClassElement get currentNonClosureClass {
    ClassElement cls = sourceElement.enclosingClass;
    if (cls != null && cls.isClosure) {
      dynamic closureClass = cls;
      // ignore: UNDEFINED_GETTER
      return closureClass.methodElement.enclosingClass;
    } else {
      return cls;
    }
  }

  /// A stack of [ResolutionDartType]s that have been seen during inlining of
  /// factory constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HCreate]s inside the inline code and registered during code generation
  /// for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted) types
  // of the type variables in an environment (like the [LocalsHandler]).
  final List<ResolutionDartType> currentInlinedInstantiations =
      <ResolutionDartType>[];

  final List<AstInliningState> inliningStack = <AstInliningState>[];

  Local returnLocal;
  ResolutionDartType returnType;

  ConstantValue getConstantForNode(ast.Node node) {
    ConstantValue constantValue =
        constants.getConstantValueForNode(node, elements);
    assert(constantValue != null,
        failedAt(node, 'No constant computed for $node'));
    return constantValue;
  }

  HInstruction addConstant(ast.Node node) {
    return graph.addConstant(getConstantForNode(node), closedWorld);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be an implementation element.
   */
  HGraph buildMethod(MethodElement functionElement) {
    assert(functionElement.isImplementation, failedAt(functionElement));
    graph.calledInLoop =
        closedWorld.isCalledInLoop(functionElement.declaration);
    ast.FunctionExpression function = resolvedAst.node;
    assert(function != null);
    assert(elements.getFunctionDefinition(function) != null);
    openFunction(functionElement, function);
    String name = functionElement.name;
    if (nativeData.isJsInteropMember(functionElement)) {
      push(invokeJsInteropFunction(functionElement, parameters.values.toList(),
          sourceInformationBuilder.buildGeneric(function)));
      var value = pop();
      closeAndGotoExit(new HReturn(
          value, sourceInformationBuilder.buildReturn(functionElement.node)));
      return closeFunction();
    }
    assert(!function.modifiers.isExternal, failedAt(functionElement));

    // If [functionElement] is `operator==` we explicitly add a null check at
    // the beginning of the method. This is to avoid having call sites do the
    // null check.
    if (name == '==') {
      if (!backend.operatorEqHandlesNullArgument(functionElement)) {
        handleIf(
            node: function,
            visitCondition: () {
              HParameterValue parameter = parameters.values.first;
              push(new HIdentity(parameter, graph.addConstantNull(closedWorld),
                  null, commonMasks.boolType));
            },
            visitThen: () {
              closeAndGotoExit(new HReturn(
                  graph.addConstantBool(false, closedWorld),
                  sourceInformationBuilder
                      .buildImplicitReturn(functionElement)));
            },
            visitElse: null,
            sourceInformation: sourceInformationBuilder.buildIf(function.body));
      }
    }
    if (const bool.fromEnvironment('unreachable-throw')) {
      var emptyParameters =
          parameters.values.where((p) => p.instructionType.isEmpty);
      if (emptyParameters.length > 0) {
        addComment('${emptyParameters} inferred as [empty]');
        pushInvokeStatic(
            function.body, commonElements.assertUnreachableMethod, []);
        pop();
        return closeFunction();
      }
    }
    function.body.accept(this);
    return closeFunction();
  }

  /// Adds a JavaScript comment to the output. The comment will be omitted in
  /// minified mode.  Each line in [text] is preceded with `//` and indented.
  /// Use sparingly. In order for the comment to be retained it is modeled as
  /// having side effects which will inhibit code motion.
  // TODO(sra): Figure out how to keep comment anchored without effects.
  void addComment(String text) {
    add(new HForeignCode(js.js.statementTemplateYielding(new js.Comment(text)),
        commonMasks.dynamicType, <HInstruction>[],
        isStatement: true));
  }

  HGraph buildCheckedSetter(FieldElement field) {
    ResolvedAst resolvedAst = field.resolvedAst;
    openFunction(field, resolvedAst.node);
    HInstruction thisInstruction = localsHandler.readThis();
    // Use dynamic type because the type computed by the inferrer is
    // narrowed to the type annotation.
    HInstruction parameter =
        new HParameterValue(field, commonMasks.dynamicType);
    // Add the parameter as the last instruction of the entry block.
    // If the method is intercepted, we want the actual receiver
    // to be the first parameter.
    graph.entry.addBefore(graph.entry.last, parameter);
    HInstruction value =
        typeBuilder.potentiallyCheckOrTrustType(parameter, field.type);
    add(new HFieldSet(field, thisInstruction, value));
    return closeFunction();
  }

  HGraph buildLazyInitializer(FieldElement variable) {
    assert(resolvedAst.element == variable,
        failedAt(variable, "Unexpected variable $variable for $resolvedAst."));
    inLazyInitializerExpression = true;
    ast.VariableDefinitions node = resolvedAst.node;
    ast.Node initializer = resolvedAst.body;
    assert(
        initializer != null,
        failedAt(
            variable, "Non-constant variable $variable has no initializer."));
    openFunction(variable, node);
    visit(initializer);
    HInstruction value = pop();
    value = typeBuilder.potentiallyCheckOrTrustType(value, variable.type);
    // In the case of multiple declarations (and some definitions) on the same
    // line, the source pointer needs to point to the right initialized
    // variable. So find the specific initialized variable we are referring to.
    ast.Node sourceInfoNode = initializer;
    for (var definition in node.definitions) {
      if (definition is ast.SendSet &&
          definition.selector.asIdentifier().source == variable.name) {
        sourceInfoNode = definition.assignmentOperator;
        break;
      }
    }

    closeAndGotoExit(new HReturn(
        value, sourceInformationBuilder.buildReturn(sourceInfoNode)));
    return closeFunction();
  }

  /**
   * This method sets up the local state of the builder for inlining [function].
   * The arguments of the function are inserted into the [localsHandler].
   *
   * When inlining a function, [:return:] statements are not emitted as
   * [HReturn] instructions. Instead, the value of a synthetic element is
   * updated in the [localsHandler]. This function creates such an element and
   * stores it in the [returnLocal] field.
   */
  void setupStateForInlining(
      MethodElement function, List<HInstruction> compiledArguments,
      {ResolutionInterfaceType instanceType}) {
    ResolvedAst resolvedAst = function.resolvedAst;
    assert(resolvedAst != null);
    localsHandler = new LocalsHandler(this, function, function.memberContext,
        function.contextClass, instanceType, nativeData, interceptorData);
    localsHandler.scopeInfo = closureDataLookup.getScopeInfo(function);
    returnLocal =
        new SyntheticLocal("result", function, function.memberContext);
    localsHandler.updateLocal(returnLocal, graph.addConstantNull(closedWorld));

    inTryStatement = false; // TODO(lry): why? Document.

    int argumentIndex = 0;
    if (function.isInstanceMember) {
      localsHandler.updateLocal(localsHandler.scopeInfo.thisLocal,
          compiledArguments[argumentIndex++]);
    }

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      HInstruction argument = compiledArguments[argumentIndex++];
      localsHandler.updateLocal(parameter, argument);
    });

    ClassElement enclosing = function.enclosingClass;
    if ((function.isConstructor || function.isGenerativeConstructorBody) &&
        rtiNeed.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((_typeVariable) {
        ResolutionTypeVariableType typeVariable = _typeVariable;
        HInstruction argument = compiledArguments[argumentIndex++];
        localsHandler.updateLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable), argument);
      });
    }
    assert(argumentIndex == compiledArguments.length);

    returnType = signature.type.returnType;
    stack = <HInstruction>[];

    insertTraceCall(function);
    insertCoverageCall(function);
  }

  void restoreState(AstInliningState state) {
    localsHandler = state.oldLocalsHandler;
    returnLocal = state.oldReturnLocal;
    inTryStatement = state.inTryStatement;
    resolvedAst = state.oldResolvedAst;
    elementInferenceResults = state.oldElementInferenceResults;
    returnType = state.oldReturnType;
    assert(stack.isEmpty);
    stack = state.oldStack;
  }

  /**
   * Run this builder on the body of the [function] to be inlined.
   */
  void visitInlinedFunction(ResolvedAst resolvedAst) {
    typeBuilder.potentiallyCheckInlinedParameterTypes(
        resolvedAst.element.implementation);

    if (resolvedAst.element.isGenerativeConstructor) {
      buildFactory(resolvedAst);
    } else {
      ast.FunctionExpression functionNode = resolvedAst.node;
      functionNode.body.accept(this);
    }
  }

  addInlinedInstantiation(ResolutionDartType type) {
    if (type != null) {
      currentInlinedInstantiations.add(type);
    }
  }

  removeInlinedInstantiation(ResolutionDartType type) {
    if (type != null) {
      currentInlinedInstantiations.removeLast();
    }
  }

  bool providedArgumentsKnownToBeComplete(ast.Node currentNode) {
    /* When inlining the iterator methods generated for a [:for-in:] loop, the
     * [currentNode] is the [ForIn] tree. The compiler-generated iterator
     * invocations are known to have fully specified argument lists, no default
     * arguments are used. See invocations of [pushInvokeDynamic] in
     * [visitForIn].
     */
    return currentNode.asForIn() != null;
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructors] must contain only implementation elements.
   */
  void inlineSuperOrRedirect(
      ResolvedAst constructorResolvedAst,
      List<HInstruction> compiledArguments,
      List<ResolvedAst> constructorResolvedAsts,
      Map<Element, HInstruction> fieldValues,
      FunctionElement caller) {
    ConstructorElement callee = constructorResolvedAst.element.implementation;
    reporter.withCurrentElement(callee, () {
      constructorResolvedAsts.add(constructorResolvedAst);
      ClassElement enclosingClass = callee.enclosingClass;
      if (rtiNeed.classNeedsRti(enclosingClass)) {
        // If [enclosingClass] needs RTI, we have to give a value to its
        // type parameters.
        ClassElement currentClass = caller.enclosingClass;
        // For a super constructor call, the type is the supertype of
        // [currentClass]. For a redirecting constructor, the type is
        // the current type. [InterfaceType.asInstanceOf] takes care
        // of both.
        ResolutionInterfaceType type =
            currentClass.thisType.asInstanceOf(enclosingClass);
        type = localsHandler.substInContext(type);
        List<ResolutionDartType> arguments = type.typeArguments;
        List<ResolutionDartType> typeVariables = enclosingClass.typeVariables;
        if (!type.isRaw) {
          assert(arguments.length == typeVariables.length);
          Iterator<ResolutionDartType> variables = typeVariables.iterator;
          type.typeArguments.forEach((ResolutionDartType argument) {
            variables.moveNext();
            ResolutionTypeVariableType typeVariable = variables.current;
            localsHandler.updateLocal(
                localsHandler.getTypeVariableAsLocal(typeVariable),
                typeBuilder.analyzeTypeArgument(argument, sourceElement));
          });
        } else {
          // If the supertype is a raw type, we need to set to null the
          // type variables.
          for (ResolutionTypeVariableType variable in typeVariables) {
            localsHandler.updateLocal(
                localsHandler.getTypeVariableAsLocal(variable),
                graph.addConstantNull(closedWorld));
          }
        }
      }

      // For redirecting constructors, the fields will be initialized later
      // by the effective target.
      if (!callee.isRedirectingGenerative) {
        inlinedFrom(constructorResolvedAst, () {
          buildFieldInitializers(
              callee.enclosingClass.implementation, fieldValues);
        });
      }

      int index = 0;
      FunctionSignature params = callee.functionSignature;
      params.orderedForEachParameter((_parameter) {
        ParameterElement parameter = _parameter;
        HInstruction argument = compiledArguments[index++];
        // Because we are inlining the initializer, we must update
        // what was given as parameter. This will be used in case
        // there is a parameter check expression in the initializer.
        parameters[parameter] = argument;
        localsHandler.updateLocal(parameter, argument);
        // Don't forget to update the field, if the parameter is of the
        // form [:this.x:].
        if (parameter.isInitializingFormal) {
          InitializingFormalElement fieldParameterElement = parameter;
          fieldValues[fieldParameterElement.fieldElement] = argument;
        }
      });

      // Build the initializers in the context of the new constructor.
      ResolvedAst oldResolvedAst = resolvedAst;
      resolvedAst = callee.resolvedAst;
      final oldElementInferenceResults = elementInferenceResults;
      elementInferenceResults = globalInferenceResults.resultOfMember(callee);
      ScopeInfo oldScopeInfo = localsHandler.scopeInfo;
      ScopeInfo newScopeInfo = closureDataLookup.getScopeInfo(callee);
      localsHandler.scopeInfo = newScopeInfo;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        localsHandler.enterScope(
            closureDataLookup.getClosureAnalysisInfo(resolvedAst.node),
            forGenerativeConstructorBody: callee.isGenerativeConstructorBody);
      }
      buildInitializers(callee, constructorResolvedAsts, fieldValues);
      localsHandler.scopeInfo = oldScopeInfo;
      resolvedAst = oldResolvedAst;
      elementInferenceResults = oldElementInferenceResults;
    });
  }

  void buildInitializers(
      ConstructorElement constructor,
      List<ResolvedAst> constructorResolvedAsts,
      Map<Element, HInstruction> fieldValues) {
    assert(
        resolvedAst.element == constructor.declaration,
        failedAt(constructor,
            "Expected ResolvedAst for $constructor, found $resolvedAst"));
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      buildParsedInitializers(
          constructor, constructorResolvedAsts, fieldValues);
    } else {
      buildSynthesizedConstructorInitializers(
          constructor, constructorResolvedAsts, fieldValues);
    }
  }

  void buildSynthesizedConstructorInitializers(
      ConstructorElement constructor,
      List<ResolvedAst> constructorResolvedAsts,
      Map<Element, HInstruction> fieldValues) {
    assert(
        constructor.isSynthesized,
        failedAt(
            constructor, "Unexpected unsynthesized constructor: $constructor"));
    List<HInstruction> arguments = <HInstruction>[];
    HInstruction compileArgument(ParameterElement parameter) {
      return localsHandler.readLocal(parameter);
    }

    ConstructorElement target = constructor.definingConstructor.implementation;
    bool match = !target.isMalformed &&
        Elements.addForwardingElementArgumentsToList<HInstruction>(
            constructor,
            arguments,
            target,
            compileArgument,
            handleConstantForOptionalParameter);
    if (!match) {
      if (compiler.elementHasCompileTimeError(constructor)) {
        return;
      }
      // If this fails, the selector we constructed for the call to a
      // forwarding constructor in a mixin application did not match the
      // constructor (which, for example, may happen when the libraries are
      // not compatible for private names, see issue 20394).
      reporter.internalError(
          constructor, 'forwarding constructor call does not match');
    }
    inlineSuperOrRedirect(target.resolvedAst, arguments,
        constructorResolvedAsts, fieldValues, constructor);
  }

  /**
   * Run through the initializers and inline all field initializers. Recursively
   * inlines super initializers.
   *
   * The constructors of the inlined initializers is added to [constructors]
   * with sub constructors having a lower index than super constructors.
   *
   * Invariant: The [constructor] and elements in [constructors] must all be
   * implementation elements.
   */
  void buildParsedInitializers(
      ConstructorElement constructor,
      List<ResolvedAst> constructorResolvedAsts,
      Map<Element, HInstruction> fieldValues) {
    assert(
        resolvedAst.element == constructor.declaration, failedAt(constructor));
    assert(constructor.isImplementation, failedAt(constructor));
    assert(
        !constructor.isSynthesized,
        failedAt(
            constructor, "Unexpected synthesized constructor: $constructor"));
    ast.FunctionExpression functionNode = resolvedAst.node;

    bool foundSuperOrRedirect = false;
    if (functionNode.initializers != null) {
      Link<ast.Node> initializers = functionNode.initializers.nodes;
      for (Link<ast.Node> link = initializers;
          !link.isEmpty;
          link = link.tail) {
        assert(link.head is ast.Send);
        if (link.head is! ast.SendSet) {
          // A super initializer or constructor redirection.
          foundSuperOrRedirect = true;
          ast.Send call = link.head;
          assert(ast.Initializers.isSuperConstructorCall(call) ||
              ast.Initializers.isConstructorRedirect(call));
          ConstructorElement target = elements[call];
          CallStructure callStructure =
              elements.getSelector(call).callStructure;
          Link<ast.Node> arguments = call.arguments;
          List<HInstruction> compiledArguments;
          inlinedFrom(resolvedAst, () {
            compiledArguments =
                makeStaticArgumentList(callStructure, arguments, target);
          });
          inlineSuperOrRedirect(target.resolvedAst, compiledArguments,
              constructorResolvedAsts, fieldValues, constructor);
        } else {
          // A field initializer.
          ast.SendSet init = link.head;
          Link<ast.Node> arguments = init.arguments;
          assert(!arguments.isEmpty && arguments.tail.isEmpty);
          inlinedFrom(resolvedAst, () {
            visit(arguments.head);
          });
          fieldValues[elements[init]] = pop();
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.enclosingClass;
      ClassElement superClass = enclosingClass.superclass;
      if (!enclosingClass.isObject) {
        assert(superClass != null);
        assert(superClass.isResolved);
        // TODO(johnniwinther): Should we find injected constructors as well?
        FunctionElement target = superClass.lookupDefaultConstructor();
        if (target == null) {
          reporter.internalError(
              superClass, "No default constructor available.");
        }
        List<HInstruction> arguments = Elements.makeArgumentsList<HInstruction>(
            CallStructure.NO_ARGS,
            const Link<ast.Node>(),
            target.implementation,
            null,
            handleConstantForOptionalParameter);
        inlineSuperOrRedirect(target.resolvedAst, arguments,
            constructorResolvedAsts, fieldValues, constructor);
      }
    }
  }

  /**
   * Run through the fields of [cls] and add their potential
   * initializers.
   *
   * Invariant: [classElement] must be an implementation element.
   */
  void buildFieldInitializers(
      ClassElement classElement, Map<Element, HInstruction> fieldValues) {
    assert(classElement.isImplementation, failedAt(classElement));
    classElement.forEachInstanceField(
        (ClassElement enclosingClass, FieldElement member) {
      if (compiler.elementHasCompileTimeError(member)) return;
      reporter.withCurrentElement(member, () {
        ResolvedAst fieldResolvedAst = member.resolvedAst;
        ast.Expression initializer = fieldResolvedAst.body;
        if (initializer == null) {
          // Unassigned fields of native classes are not initialized to
          // prevent overwriting pre-initialized native properties.
          if (!nativeData.isNativeOrExtendsNative(classElement)) {
            fieldValues[member] = graph.addConstantNull(closedWorld);
          }
        } else {
          ast.Node right = initializer;
          ResolvedAst savedResolvedAst = resolvedAst;
          resolvedAst = fieldResolvedAst;
          final oldElementInferenceResults = elementInferenceResults;
          elementInferenceResults =
              globalInferenceResults.resultOfMember(member);
          inlinedFrom(fieldResolvedAst, () => right.accept(this));
          resolvedAst = savedResolvedAst;
          elementInferenceResults = oldElementInferenceResults;
          fieldValues[member] = pop();
        }
      });
    });
  }

  /**
   * Build the factory function corresponding to the constructor
   * [functionElement]:
   *  - Initialize fields with the values of the field initializers of the
   *    current constructor and super constructors or constructors redirected
   *    to, starting from the current constructor.
   *  - Call the constructor bodies, starting from the constructor(s) in the
   *    super class(es).
   */
  HGraph buildFactory(ResolvedAst resolvedAst) {
    ConstructorElement functionElement = resolvedAst.element;
    functionElement = functionElement.implementation;
    ClassElement classElement = functionElement.enclosingClass.implementation;
    bool isNativeUpgradeFactory =
        nativeData.isNativeOrExtendsNative(classElement) &&
            !nativeData.isJsInteropClass(classElement);
    ast.FunctionExpression function;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      function = resolvedAst.node;
    }

    // Note that constructors (like any other static function) do not need
    // to deal with optional arguments. It is the callers job to provide all
    // arguments as if they were positional.

    if (inliningStack.isEmpty) {
      // The initializer list could contain closures.
      openFunction(functionElement, function);
    }

    Map<Element, HInstruction> fieldValues = new Map<Element, HInstruction>();

    // Compile the possible initialization code for local fields and
    // super fields, unless this is a redirecting constructor, in which case
    // the effective target will initialize these.
    if (!functionElement.isRedirectingGenerative) {
      buildFieldInitializers(classElement, fieldValues);
    }

    // Compile field-parameters such as [:this.x:].
    FunctionSignature params = functionElement.functionSignature;
    params.orderedForEachParameter((_parameter) {
      ParameterElement parameter = _parameter;
      if (parameter.isInitializingFormal) {
        // If the [element] is a field-parameter then
        // initialize the field element with its value.
        InitializingFormalElement fieldParameter = parameter;
        HInstruction parameterValue = localsHandler.readLocal(fieldParameter);
        fieldValues[fieldParameter.fieldElement] = parameterValue;
      }
    });

    // Analyze the constructor and all referenced constructors and collect
    // initializers and constructor bodies.
    List<ResolvedAst> constructorResolvedAsts = <ResolvedAst>[resolvedAst];
    buildInitializers(functionElement, constructorResolvedAsts, fieldValues);

    // Call the JavaScript constructor with the fields as argument.
    List<HInstruction> constructorArguments = <HInstruction>[];
    List<FieldEntity> fields = <FieldEntity>[];

    classElement.forEachInstanceField(
        (ClassElement enclosingClass, FieldElement member) {
      HInstruction value = fieldValues[member];
      if (value == null) {
        // Uninitialized native fields are pre-initialized by the native
        // implementation.
        assert(isNativeUpgradeFactory || reporter.hasReportedError,
            failedAt(member));
      } else {
        fields.add(member);
        ResolutionDartType type = localsHandler.substInContext(member.type);
        constructorArguments
            .add(typeBuilder.potentiallyCheckOrTrustType(value, type));
      }
    }, includeSuperAndInjectedMembers: true);

    ResolutionInterfaceType type = classElement.thisType;
    TypeMask ssaType =
        new TypeMask.nonNullExact(classElement.declaration, closedWorld);
    List<DartType> instantiatedTypes;
    addInlinedInstantiation(type);
    if (!currentInlinedInstantiations.isEmpty) {
      instantiatedTypes =
          new List<ResolutionInterfaceType>.from(currentInlinedInstantiations);
    }

    HInstruction newObject;
    if (!isNativeUpgradeFactory) {
      // Create the runtime type information, if needed.
      bool hasRtiInput = false;
      if (rtiNeed.classNeedsRtiField(classElement.declaration)) {
        // Read the values of the type arguments and create a
        // HTypeInfoExpression to set on the newly create object.
        hasRtiInput = true;
        List<HInstruction> typeArguments = <HInstruction>[];
        classElement.typeVariables.forEach((_typeVariable) {
          ResolutionTypeVariableType typeVariable = _typeVariable;
          HInstruction argument = localsHandler
              .readLocal(localsHandler.getTypeVariableAsLocal(typeVariable));
          typeArguments.add(argument);
        });

        HInstruction typeInfo = new HTypeInfoExpression(
            TypeInfoExpressionKind.INSTANCE,
            classElement.thisType,
            typeArguments,
            commonMasks.dynamicType);
        add(typeInfo);
        constructorArguments.add(typeInfo);
      }

      newObject = new HCreate(classElement, constructorArguments, ssaType,
          instantiatedTypes: instantiatedTypes, hasRtiInput: hasRtiInput);
      if (function != null) {
        // TODO(johnniwinther): Provide source information for creation through
        // synthetic constructors.
        newObject.sourceInformation =
            sourceInformationBuilder.buildCreate(function);
      }
      add(newObject);
    } else {
      // Bulk assign to the initialized fields.
      newObject = graph.explicitReceiverParameter;
      // Null guard ensures an error if we are being called from an explicit
      // 'new' of the constructor instead of via an upgrade. It is optimized out
      // if there are field initializers.
      add(new HFieldGet(null, newObject, commonMasks.dynamicType,
          isAssignable: false));
      for (int i = 0; i < fields.length; i++) {
        add(new HFieldSet(fields[i], newObject, constructorArguments[i]));
      }
    }
    removeInlinedInstantiation(type);

    // Generate calls to the constructor bodies.
    HInstruction interceptor = null;
    for (int index = constructorResolvedAsts.length - 1; index >= 0; index--) {
      ResolvedAst constructorResolvedAst = constructorResolvedAsts[index];
      ConstructorElement constructor =
          constructorResolvedAst.element.implementation;
      ConstructorBodyElement body =
          ConstructorBodyElementX.createFromResolvedAst(constructorResolvedAst);
      if (body == null) continue;

      List bodyCallInputs = <HInstruction>[];
      if (isNativeUpgradeFactory) {
        if (interceptor == null) {
          ConstantValue constant = new InterceptorConstantValue(classElement);
          interceptor = graph.addConstant(constant, closedWorld);
        }
        bodyCallInputs.add(interceptor);
      }
      bodyCallInputs.add(newObject);
      ast.Node node = constructorResolvedAst.node;

      FunctionSignature functionSignature = body.functionSignature;
      // Provide the parameters to the generative constructor body.
      functionSignature.orderedForEachParameter((_parameter) {
        ParameterElement parameter = _parameter;
        // If [parameter] is boxed, it will be a field in the box passed as the
        // last parameter. So no need to directly pass it.
        if (!localsHandler.isBoxed(parameter)) {
          bodyCallInputs.add(localsHandler.readLocal(parameter));
        }
      });

      // If there are locals that escape (ie mutated in closures), we
      // pass the box to the constructor.
      // The box must be passed before any type variable.
      ClosureAnalysisInfo scopeData =
          closureDataLookup.getClosureAnalysisInfo(node);
      if (scopeData.requiresContextBox) {
        bodyCallInputs.add(localsHandler.readLocal(scopeData.context));
      }

      // Type variables arguments must come after the box (if there is one).
      ClassElement currentClass = constructor.enclosingClass;
      if (rtiNeed.classNeedsRti(currentClass)) {
        // If [currentClass] needs RTI, we add the type variables as
        // parameters of the generative constructor body.
        currentClass.typeVariables.forEach((_argument) {
          ResolutionTypeVariableType argument = _argument;
          // TODO(johnniwinther): Substitute [argument] with
          // `localsHandler.substInContext(argument)`.
          bodyCallInputs.add(localsHandler
              .readLocal(localsHandler.getTypeVariableAsLocal(argument)));
        });
      }

      if (!isNativeUpgradeFactory && // TODO(13836): Fix inlining.
          tryInlineMethod(body, null, null, bodyCallInputs, function)) {
        pop();
      } else {
        HInvokeConstructorBody invoke = new HInvokeConstructorBody(
            body.declaration, bodyCallInputs, commonMasks.nonNullType);
        invoke.sideEffects = closedWorld.getSideEffectsOfElement(constructor);
        add(invoke);
      }
    }
    if (inliningStack.isEmpty) {
      closeAndGotoExit(new HReturn(newObject,
          sourceInformationBuilder.buildImplicitReturn(functionElement)));
      return closeFunction();
    } else {
      localsHandler.updateLocal(returnLocal, newObject);
      return null;
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be the implementation element.
   */
  void openFunction(MemberElement element, ast.Node node) {
    assert(element.isImplementation, failedAt(element));
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    Map<Local, TypeMask> parameters = <Local, TypeMask>{};
    if (element is MethodElement) {
      element.functionSignature.orderedForEachParameter((_parameter) {
        ParameterElement parameter = _parameter;
        parameters[parameter] = TypeMaskFactory.inferredTypeForParameter(
            parameter, globalInferenceResults);
      });
    }

    localsHandler.startFunction(
        element,
        closureDataLookup.getScopeInfo(element),
        closureDataLookup.getClosureAnalysisInfo(node),
        parameters,
        isGenerativeConstructorBody: element.isGenerativeConstructorBody);
    close(new HGoto()).addSuccessor(block);

    open(block);

    // Add the type parameters of the class as parameters of this method.  This
    // must be done before adding the normal parameters, because their types
    // may contain references to type variables.
    ClassElement cls = element.enclosingClass;
    if ((element.isConstructor || element.isGenerativeConstructorBody) &&
        rtiNeed.classNeedsRti(cls)) {
      cls.typeVariables.forEach((_typeVariable) {
        ResolutionTypeVariableType typeVariable = _typeVariable;
        HParameterValue param =
            addParameter(typeVariable.element, commonMasks.nonNullType);
        localsHandler.directLocals[
            localsHandler.getTypeVariableAsLocal(typeVariable)] = param;
      });
    }

    if (element is MethodElement) {
      MethodElement functionElement = element;
      FunctionSignature signature = functionElement.functionSignature;

      // Put the type checks in the first successor of the entry,
      // because that is where the type guards will also be inserted.
      // This way we ensure that a type guard will dominate the type
      // check.
      signature.orderedForEachParameter((_parameterElement) {
        ParameterElement parameterElement = _parameterElement;
        if (element.isGenerativeConstructorBody) {
          if (closureDataLookup
              .getClosureAnalysisInfo(node)
              .isCaptured(parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction newParameter =
            localsHandler.directLocals[parameterElement];
        if (!element.isConstructor ||
            !(element as ConstructorElement).isRedirectingFactory) {
          // Redirection factories must not check their argument types.
          // Example:
          //
          //     class A {
          //       A(String foo) = A.b;
          //       A(int foo) { print(foo); }
          //     }
          //     main() {
          //       new A(499);    // valid even in checked mode.
          //       new A("foo");  // invalid in checked mode.
          //
          // Only the final target is allowed to check for the argument types.
          newParameter = typeBuilder.potentiallyCheckOrTrustType(
              newParameter, parameterElement.type);
        }
        localsHandler.directLocals[parameterElement] = newParameter;
      });

      returnType = signature.type.returnType;
    } else {
      // Otherwise it is a lazy initializer which does not have parameters.
      assert(element is VariableElement);
    }

    insertTraceCall(element);
    insertCoverageCall(element);
  }

  insertTraceCall(Element element) {
    if (JavaScriptBackend.TRACE_METHOD == 'console') {
      if (element == commonElements.traceHelper) return;
      n(e) => e == null ? '' : e.name;
      String name = "${n(element.library)}:${n(element.enclosingClass)}."
          "${n(element)}";
      HConstant nameConstant = addConstantString(name);
      add(new HInvokeStatic(commonElements.traceHelper,
          <HInstruction>[nameConstant], commonMasks.dynamicType));
    }
  }

  insertCoverageCall(Element element) {
    if (JavaScriptBackend.TRACE_METHOD == 'post') {
      if (element == commonElements.traceHelper) return;
      // TODO(sigmund): create a better uuid for elements.
      HConstant idConstant =
          graph.addConstantInt(element.hashCode, closedWorld);
      HConstant nameConstant = addConstantString(element.name);
      add(new HInvokeStatic(commonElements.traceHelper,
          <HInstruction>[idConstant, nameConstant], commonMasks.dynamicType));
    }
  }

  void assertIsSubtype(ast.Node node, ResolutionDartType subtype,
      ResolutionDartType supertype, String message) {
    HInstruction subtypeInstruction = typeBuilder.analyzeTypeArgument(
        localsHandler.substInContext(subtype), sourceElement);
    HInstruction supertypeInstruction = typeBuilder.analyzeTypeArgument(
        localsHandler.substInContext(supertype), sourceElement);
    HInstruction messageInstruction =
        graph.addConstantString(message, closedWorld);
    MethodElement element = commonElements.assertIsSubtype;
    var inputs = <HInstruction>[
      subtypeInstruction,
      supertypeInstruction,
      messageInstruction
    ];
    HInstruction assertIsSubtype =
        new HInvokeStatic(element, inputs, subtypeInstruction.instructionType);
    registry?.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
    add(assertIsSubtype);
  }

  HGraph closeFunction() {
    // TODO(kasperl): Make this goto an implicit return.
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
    return graph;
  }

  void pushWithPosition(HInstruction instruction, ast.Node node) {
    push(attachPosition(instruction, node));
  }

  /// Pops the most recent instruction from the stack and 'boolifies' it.
  ///
  /// Boolification is checking if the value is '=== true'.
  @override
  HInstruction popBoolified() {
    HInstruction value = pop();
    if (typeBuilder.checkOrTrustTypes) {
      ResolutionInterfaceType boolType = commonElements.boolType;
      return typeBuilder.potentiallyCheckOrTrustType(value, boolType,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, commonMasks.boolType);
    add(result);
    return result;
  }

  HInstruction attachPosition(HInstruction target, ast.Node node) {
    if (node != null) {
      target.sourceInformation = sourceInformationBuilder.buildGeneric(node);
    }
    return target;
  }

  void visit(ast.Node node) {
    if (node != null) node.accept(this);
  }

  /// Visit [node] and pop the resulting [HInstruction].
  HInstruction visitAndPop(ast.Node node) {
    node.accept(this);
    return pop();
  }

  visitAssert(ast.Assert node) {
    if (!options.enableUserAssertions) return;

    if (!node.hasMessage) {
      // Generate:
      //
      //     assertHelper(condition);
      //
      visit(node.condition);
      pushInvokeStatic(node, commonElements.assertHelper, [pop()]);
      pop();
      return;
    }
    // Assert has message. Generate:
    //
    //     if (assertTest(condition)) assertThrow(message);
    //
    void buildCondition() {
      visit(node.condition);
      pushInvokeStatic(node, commonElements.assertTest, [pop()]);
    }

    void fail() {
      visit(node.message);
      pushInvokeStatic(node, commonElements.assertThrow, [pop()]);
      pop();
    }

    handleIf(node: node, visitCondition: buildCondition, visitThen: fail);
  }

  visitBlock(ast.Block node) {
    assert(!isAborted());
    if (!isReachable) return; // This can only happen when inlining.
    for (Link<ast.Node> link = node.statements.nodes;
        !link.isEmpty;
        link = link.tail) {
      visit(link.head);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (!stack.isEmpty) {
          reporter.internalError(node, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (!stack.isEmpty) {
      reporter.internalError(node, 'Non-empty instruction stack.');
    }
  }

  visitClassNode(ast.ClassNode node) {
    reporter.internalError(
        node, 'SsaBuilder.visitClassNode should not be called.');
  }

  visitThrowExpression(ast.Expression expression) {
    bool old = inExpressionOfThrow;
    try {
      inExpressionOfThrow = true;
      visit(expression);
    } finally {
      inExpressionOfThrow = old;
    }
  }

  visitExpressionStatement(ast.ExpressionStatement node) {
    if (!isReachable) return;
    ast.Throw throwExpression = node.expression.asThrow();
    if (throwExpression != null && inliningStack.isEmpty) {
      visitThrowExpression(throwExpression.expression);
      handleInTryStatement();
      closeAndGotoExit(
          new HThrow(pop(), sourceInformationBuilder.buildThrow(node)));
    } else {
      visit(node.expression);
      pop();
    }
  }

  visitFor(ast.For node) {
    assert(isReachable);
    assert(node.body != null);
    void buildInitializer() {
      ast.Node initializer = node.initializer;
      if (initializer == null) return;
      visit(initializer);
      if (initializer.asExpression() != null) {
        pop();
      }
    }

    HInstruction buildCondition() {
      if (node.condition == null) {
        return graph.addConstantBool(true, closedWorld);
      }
      visit(node.condition);
      return popBoolified();
    }

    void buildUpdate() {
      for (ast.Expression expression in node.update) {
        visit(expression);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      visit(node.body);
    }

    loopHandler.handleLoop(
        node,
        closureDataLookup.getClosureRepresentationInfoForLoop(node),
        elements.getTargetDefinition(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody);
  }

  visitWhile(ast.While node) {
    assert(isReachable);
    HInstruction buildCondition() {
      visit(node.condition);
      return popBoolified();
    }

    loopHandler.handleLoop(
        node,
        closureDataLookup.getClosureRepresentationInfoForLoop(node),
        elements.getTargetDefinition(node),
        () {},
        buildCondition,
        () {}, () {
      visit(node.body);
    });
  }

  visitDoWhile(ast.DoWhile node) {
    assert(isReachable);
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    var loopClosureInfo =
        closureDataLookup.getClosureRepresentationInfoForLoop(node);
    localsHandler.startLoop(loopClosureInfo);
    loopDepth++;
    JumpTarget target = elements.getTargetDefinition(node);
    JumpHandler jumpHandler = loopHandler.beginLoopHeader(node, target);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    bool hasContinues = target != null && target.isContinueTarget;
    if (hasContinues) {
      // Add extra block to hang labels on.
      // It doesn't currently work if they are on the same block as the
      // HLoopInfo. The handling of HLabeledBlockInformation will visit a
      // SubGraph that starts at the same block again, so the HLoopInfo is
      // either handled twice, or it's handled after the labeled block info,
      // both of which generate the wrong code.
      // Using a separate block is just a simple workaround.
      bodyEntryBlock = openNewBlock();
    }
    localsHandler.enterLoopBody(loopClosureInfo);
    visit(node.body);

    // If there are no continues we could avoid the creation of the condition
    // block. This could also lead to a block having multiple entries and exits.
    HBasicBlock bodyExitBlock;
    bool isAbortingBody = false;
    if (current != null) {
      bodyExitBlock = close(new HGoto());
    } else {
      isAbortingBody = true;
      bodyExitBlock = lastOpenedBlock;
    }

    SubExpression conditionExpression;
    bool loopIsDegenerate = isAbortingBody && !hasContinues;
    if (!loopIsDegenerate) {
      HBasicBlock conditionBlock = addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler
          .forEachContinue((HContinue instruction, LocalsHandler locals) {
        instruction.block.addSuccessor(conditionBlock);
        continueHandlers.add(locals);
      });

      if (!isAbortingBody) {
        bodyExitBlock.addSuccessor(conditionBlock);
      }

      if (!continueHandlers.isEmpty) {
        if (!isAbortingBody) continueHandlers.add(localsHandler);
        localsHandler =
            savedLocals.mergeMultiple(continueHandlers, conditionBlock);
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        List<LabelDefinition> labels = jumpHandler.labels;
        HSubGraphBlockInformation bodyInfo =
            new HSubGraphBlockInformation(bodyGraph);
        HLabeledBlockInformation info;
        if (!labels.isEmpty) {
          info =
              new HLabeledBlockInformation(bodyInfo, labels, isContinue: true);
        } else {
          info = new HLabeledBlockInformation.implicit(bodyInfo, target,
              isContinue: true);
        }
        bodyEntryBlock.setBlockFlow(info, conditionBlock);
      }
      open(conditionBlock);

      visit(node.condition);
      assert(!isAborted());
      HInstruction conditionInstruction = popBoolified();
      HBasicBlock conditionEndBlock = close(
          new HLoopBranch(conditionInstruction, HLoopBranch.DO_WHILE_LOOP));

      HBasicBlock avoidCriticalEdge = addNewBlock();
      conditionEndBlock.addSuccessor(avoidCriticalEdge);
      open(avoidCriticalEdge);
      close(new HGoto());
      avoidCriticalEdge.addSuccessor(loopEntryBlock); // The back-edge.

      conditionExpression =
          new SubExpression(conditionBlock, conditionEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = addNewBlock();
      open(conditionExitBlock);
      close(new HGoto());
      conditionEndBlock.addSuccessor(conditionExitBlock);

      loopHandler.endLoop(
          loopEntryBlock, conditionExitBlock, jumpHandler, localsHandler);

      loopEntryBlock.postProcessLoopHeader();
      SubGraph bodyGraph = new SubGraph(loopEntryBlock, bodyExitBlock);
      HLoopBlockInformation loopBlockInfo = new HLoopBlockInformation(
          HLoopBlockInformation.DO_WHILE_LOOP,
          null,
          wrapExpressionGraph(conditionExpression),
          wrapStatementGraph(bodyGraph),
          null,
          loopEntryBlock.loopInformation.target,
          loopEntryBlock.loopInformation.labels,
          sourceInformationBuilder.buildLoop(node));
      loopEntryBlock.setBlockFlow(loopBlockInfo, current);
      loopInfo.loopBlockInformation = loopBlockInfo;
    } else {
      // Since the loop has no back edge, we remove the loop information on the
      // header.
      loopEntryBlock.loopInformation = null;

      if (jumpHandler.hasAnyBreak()) {
        // Null branchBlock because the body of the do-while loop always aborts,
        // so we never get to the condition.
        loopHandler.endLoop(loopEntryBlock, null, jumpHandler, localsHandler);

        // Since the body of the loop has a break, we attach a synthesized label
        // to the body.
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        JumpTarget target = elements.getTargetDefinition(node);
        LabelDefinition label =
            target.addLabel(null, 'loop', isBreakTarget: true);
        HLabeledBlockInformation info = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), <LabelDefinition>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
    loopDepth--;
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    LocalFunctionElement methodElement = elements[node];
    ClosureRepresentationInfo closureInfo =
        closureDataLookup.getClosureRepresentationInfo(methodElement);
    ClassEntity closureClassEntity = closureInfo.closureClassEntity;

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureInfo.createdFieldEntities.forEach((Local field) {
      assert(field != null);
      capturedVariables.add(localsHandler.readLocal(field));
    });

    TypeMask type = new TypeMask.nonNullExact(closureClassEntity, closedWorld);
    push(new HCreate(closureClassEntity, capturedVariables, type,
        callMethod: closureInfo.callMethod, localFunction: methodElement)
      ..sourceInformation = sourceInformationBuilder.buildCreate(node));
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    assert(isReachable);
    visit(node.function);
    LocalFunctionElement localFunction =
        elements.getFunctionDefinition(node.function);
    localsHandler.updateLocal(localFunction, pop());
  }

  @override
  void visitThisGet(ast.Identifier node, [_]) {
    stack.add(localsHandler.readThis());
  }

  visitIdentifier(ast.Identifier node) {
    if (node.isThis()) {
      visitThisGet(node);
    } else {
      reporter.internalError(
          node, "SsaFromAstMixin.visitIdentifier on non-this.");
    }
  }

  void handleIf(
      {ast.Node node,
      void visitCondition(),
      void visitThen(),
      void visitElse(),
      SourceInformation sourceInformation}) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    branchBuilder.handleIf(visitCondition, visitThen, visitElse,
        sourceInformation: sourceInformation);
  }

  visitIf(ast.If node) {
    assert(isReachable);
    handleIf(
        node: node,
        visitCondition: () => visit(node.condition),
        visitThen: () => visit(node.thenPart),
        visitElse: node.elsePart != null ? () => visit(node.elsePart) : null,
        sourceInformation: sourceInformationBuilder.buildIf(node));
  }

  @override
  void visitIfNull(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleIfNull(() => visit(left), () => visit(right));
  }

  /// Optimizes logical binary where the left is also a logical binary.
  ///
  /// This method transforms the operator by optimizing the case where [left] is
  /// a logical "and" or logical "or". Then it uses [branchBuilder] to build the
  /// graph for the optimized expression.
  ///
  /// For example, `(x && y) && z` is transformed into `x && (y && z)`:
  ///
  ///     t0 = boolify(x);
  ///     if (t0) {
  ///       t1 = boolify(y);
  ///       if (t1) {
  ///         t2 = boolify(z);
  ///       }
  ///       t3 = phi(t2, false);
  ///     }
  ///     result = phi(t3, false);
  void handleLogicalBinaryWithLeftNode(
      ast.Node left, void visitRight(), SsaBranchBuilder branchBuilder,
      {bool isAnd}) {
    ast.Send send = left.asSend();
    if (send != null && (isAnd ? send.isLogicalAnd : send.isLogicalOr)) {
      ast.Node newLeft = send.receiver;
      Link<ast.Node> link = send.argumentsNode.nodes;
      assert(link.tail.isEmpty);
      ast.Node middle = link.head;
      handleLogicalBinaryWithLeftNode(
          newLeft,
          () => handleLogicalBinaryWithLeftNode(
              middle, visitRight, branchBuilder,
              isAnd: isAnd),
          branchBuilder,
          isAnd: isAnd);
    } else {
      branchBuilder.handleLogicalBinary(() => visit(left), visitRight,
          isAnd: isAnd);
    }
  }

  @override
  void visitLogicalAnd(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    handleLogicalBinaryWithLeftNode(left, () => visit(right), branchBuilder,
        isAnd: true);
  }

  @override
  void visitLogicalOr(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    handleLogicalBinaryWithLeftNode(left, () => visit(right), branchBuilder,
        isAnd: false);
  }

  @override
  void visitNot(ast.Send node, ast.Node expression, _) {
    assert(node.argumentsNode is ast.Prefix);
    visit(expression);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGeneric(node);
    push(new HNot(popBoolified(), commonMasks.boolType)
      ..sourceInformation = sourceInformation);
  }

  @override
  void visitUnary(
      ast.Send node, UnaryOperator operator, ast.Node expression, _) {
    assert(node.argumentsNode is ast.Prefix);
    HInstruction operand = visitAndPop(expression);

    // See if we can constant-fold right away. This avoids rewrites later on.
    if (operand is HConstant) {
      UnaryOperation operation = constantSystem.lookupUnary(operator);
      HConstant constant = operand;
      ConstantValue folded = operation.fold(constant.constant);
      if (folded != null) {
        stack.add(graph.addConstant(folded, closedWorld));
        return;
      }
    }

    pushInvokeDynamic(node, elements.getSelector(node),
        elementInferenceResults.typeOfSend(node), [operand],
        sourceInformation: sourceInformationBuilder.buildGeneric(node));
  }

  @override
  void visitBinary(ast.Send node, ast.Node left, BinaryOperator operator,
      ast.Node right, _) {
    handleBinary(node, left, right);
  }

  @override
  void visitIndex(ast.Send node, ast.Node receiver, ast.Node index, _) {
    generateDynamicSend(node);
  }

  @override
  void visitEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    handleBinary(node, left, right);
  }

  @override
  void visitNotEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    handleBinary(node, left, right);
    pushWithPosition(
        new HNot(popBoolified(), commonMasks.boolType), node.selector);
  }

  void handleBinary(ast.Send node, ast.Node left, ast.Node right) {
    visitBinarySend(
        visitAndPop(left),
        visitAndPop(right),
        elements.getSelector(node),
        elementInferenceResults.typeOfSend(node),
        node,
        sourceInformation:
            sourceInformationBuilder.buildGeneric(node.selector));
  }

  /// TODO(johnniwinther): Merge [visitBinarySend] with [handleBinary] and
  /// remove use of [location] for source information.
  void visitBinarySend(HInstruction left, HInstruction right, Selector selector,
      TypeMask mask, ast.Send send,
      {SourceInformation sourceInformation}) {
    pushInvokeDynamic(send, selector, mask, [left, right],
        sourceInformation: sourceInformation);
  }

  HInstruction generateInstanceSendReceiver(ast.Send send) {
    assert(Elements.isInstanceSend(send, elements));
    if (send.receiver == null) {
      return localsHandler.readThis();
    }
    visit(send.receiver);
    return pop();
  }

  String noSuchMethodTargetSymbolString(Element error, [String prefix]) {
    String result = error.name;
    if (prefix == "set") return "$result=";
    return result;
  }

  /**
   * Returns a set of interceptor classes that contain the given
   * [selector].
   */
  void generateInstanceGetterWithCompiledReceiver(
      ast.Send send, Selector selector, TypeMask mask, HInstruction receiver) {
    assert(Elements.isInstanceSend(send, elements));
    assert(selector.isGetter);
    pushInvokeDynamic(send, selector, mask, [receiver],
        sourceInformation: sourceInformationBuilder.buildGet(send));
  }

  /// Inserts a call to checkDeferredIsLoaded for [prefixElement].
  /// If [prefixElement] is [null] ndo nothing.
  void generateIsDeferredLoadedCheckIfNeeded(
      PrefixElement prefixElement, ast.Node location) {
    if (prefixElement == null) return;
    String loadId =
        deferredLoadTask.getImportDeferName(location, prefixElement);
    HInstruction loadIdConstant = addConstantString(loadId);
    String uri = prefixElement.deferredImport.uri.toString();
    HInstruction uriConstant = addConstantString(uri);
    MethodElement helper = commonElements.checkDeferredIsLoaded;
    pushInvokeStatic(location, helper, [loadIdConstant, uriConstant]);
    pop();
  }

  /// Inserts a call to checkDeferredIsLoaded if the send has a prefix that
  /// resolves to a deferred library.
  void generateIsDeferredLoadedCheckOfSend(ast.Send node) {
    generateIsDeferredLoadedCheckIfNeeded(
        deferredLoadTask.deferredPrefixElement(node, elements), node);
  }

  void handleInvalidStaticGet(ast.Send node, Element element) {
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    generateThrowNoSuchMethod(
        node, noSuchMethodTargetSymbolString(element, 'get'),
        argumentNodes: const Link<ast.Node>(),
        sourceInformation: sourceInformation);
  }

  /// Generate read access of an unresolved static or top level entity.
  void generateStaticUnresolvedGet(ast.Send node, Element element) {
    if (element is ErroneousElement) {
      // An erroneous element indicates an unresolved static getter.
      handleInvalidStaticGet(node, element);
    } else {
      // This happens when [element] has parse errors.
      assert(element == null || element.isMalformed, failedAt(node));
      // TODO(ahe): Do something like the above, that is, emit a runtime
      // error.
      stack.add(graph.addConstantNull(closedWorld));
    }
  }

  /// Read a static or top level [field] of constant value.
  void generateStaticConstGet(ast.Send node, FieldElement field,
      ConstantExpression constant, SourceInformation sourceInformation) {
    ConstantValue value = constants.getConstantValue(constant);
    HConstant instruction;
    // Constants that are referred via a deferred prefix should be referred
    // by reference.
    PrefixElement prefix =
        deferredLoadTask.deferredPrefixElement(node, elements);
    if (prefix != null) {
      instruction = graph.addDeferredConstant(
          value, prefix, sourceInformation, compiler, closedWorld);
    } else {
      instruction = graph.addConstant(value, closedWorld,
          sourceInformation: sourceInformation);
    }
    stack.add(instruction);
    // The inferrer may have found a better type than the constant
    // handler in the case of lists, because the constant handler
    // does not look at elements in the list.
    TypeMask type =
        TypeMaskFactory.inferredTypeForMember(field, globalInferenceResults);
    if (!type.containsAll(closedWorld) && !instruction.isConstantNull()) {
      // TODO(13429): The inferrer should know that an element
      // cannot be null.
      instruction.instructionType = type.nonNullable();
    }
  }

  @override
  void previsitDeferredAccess(ast.Send node, PrefixElement prefix, _) {
    generateIsDeferredLoadedCheckIfNeeded(prefix, node);
  }

  /// Read a static or top level [field].
  void generateStaticFieldGet(ast.Send node, FieldElement field) {
    ConstantExpression constant = field.constant;
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    if (constant != null) {
      if (!field.isAssignable) {
        // A static final or const. Get its constant value and inline it if
        // the value can be compiled eagerly.
        generateStaticConstGet(node, field, constant, sourceInformation);
      } else {
        // TODO(5346): Try to avoid the need for calling [declaration] before
        // creating an [HStatic].
        HInstruction instruction = new HStatic(
            field,
            TypeMaskFactory.inferredTypeForMember(
                field, globalInferenceResults))
          ..sourceInformation = sourceInformation;
        push(instruction);
      }
    } else {
      HInstruction instruction = new HLazyStatic(field,
          TypeMaskFactory.inferredTypeForMember(field, globalInferenceResults))
        ..sourceInformation = sourceInformation;
      push(instruction);
    }
  }

  /// Generate a getter invocation of the static or top level [getter].
  void generateStaticGetterGet(ast.Send node, MethodElement getter) {
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    if (getter.isDeferredLoaderGetter) {
      generateDeferredLoaderGet(node, getter, sourceInformation);
    } else {
      pushInvokeStatic(node, getter, <HInstruction>[],
          sourceInformation: sourceInformation);
    }
  }

  /// Generate a dynamic getter invocation.
  void generateDynamicGet(ast.Send node) {
    HInstruction receiver = generateInstanceSendReceiver(node);
    generateInstanceGetterWithCompiledReceiver(node, elements.getSelector(node),
        elementInferenceResults.typeOfSend(node), receiver);
  }

  /// Generate a closurization of the static or top level [method].
  void generateStaticFunctionGet(ast.Send node, MethodElement method) {
    assert(method.isDeclaration);
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    push(new HStatic(method, commonMasks.nonNullType)
      ..sourceInformation = sourceInformation);
  }

  /// Read a local variable, function or parameter.
  void buildLocalGet(LocalElement local, SourceInformation sourceInformation) {
    stack.add(
        localsHandler.readLocal(local, sourceInformation: sourceInformation));
  }

  void handleLocalGet(ast.Send node, LocalElement local) {
    buildLocalGet(local, sourceInformationBuilder.buildGet(node));
  }

  @override
  void visitDynamicPropertyGet(ast.Send node, ast.Node receiver, Name name, _) {
    generateDynamicGet(node);
  }

  @override
  void visitIfNotNullDynamicPropertyGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    // exp?.x compiled as:
    //   t1 = exp;
    //   result = t1 == null ? t1 : t1.x;
    // This is equivalent to t1 == null ? null : t1.x, but in the current form
    // we will be able to later compress it as:
    //   t1 || t1.x
    HInstruction expression;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(
        () {
          expression = visitAndPop(receiver);
          pushCheckNull(expression);
        },
        () => stack.add(expression),
        () {
          generateInstanceGetterWithCompiledReceiver(
              node,
              elements.getSelector(node),
              elementInferenceResults.typeOfSend(node),
              expression);
        });
  }

  @override
  void visitLocalVariableGet(ast.Send node, LocalVariableElement variable, _) {
    handleLocalGet(node, variable);
  }

  @override
  void visitParameterGet(ast.Send node, ParameterElement parameter, _) {
    handleLocalGet(node, parameter);
  }

  @override
  void visitLocalFunctionGet(ast.Send node, LocalFunctionElement function, _) {
    handleLocalGet(node, function);
  }

  @override
  void visitStaticFieldGet(ast.Send node, FieldElement field, _) {
    generateStaticFieldGet(node, field);
  }

  @override
  void visitStaticFunctionGet(ast.Send node, MethodElement function, _) {
    generateStaticFunctionGet(node, function);
  }

  @override
  void visitStaticGetterGet(ast.Send node, FunctionElement getter, _) {
    generateStaticGetterGet(node, getter);
  }

  @override
  void visitThisPropertyGet(ast.Send node, Name name, _) {
    generateDynamicGet(node);
  }

  @override
  void visitTopLevelFieldGet(ast.Send node, FieldElement field, _) {
    generateStaticFieldGet(node, field);
  }

  @override
  void visitTopLevelFunctionGet(ast.Send node, MethodElement function, _) {
    generateStaticFunctionGet(node, function);
  }

  @override
  void visitTopLevelGetterGet(ast.Send node, FunctionElement getter, _) {
    generateStaticGetterGet(node, getter);
  }

  void generateInstanceSetterWithCompiledReceiver(
      ast.Send send, HInstruction receiver, HInstruction value,
      {Selector selector, TypeMask mask, ast.Node location}) {
    assert(
        send == null || Elements.isInstanceSend(send, elements),
        failedAt(
            send ?? location,
            "Unexpected instance setter"
            "${send != null ? " element: ${elements[send]}" : ""}"));
    if (selector == null) {
      assert(send != null);
      selector = elements.getSelector(send);
      mask ??= elementInferenceResults.typeOfSend(send);
    }
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(selector.isSetter);
    pushInvokeDynamic(location, selector, mask, [receiver, value],
        sourceInformation: sourceInformationBuilder.buildAssignment(location));
    pop();
    stack.add(value);
  }

  void generateNoSuchSetter(
      ast.Node location, Element element, HInstruction value) {
    List<HInstruction> arguments =
        value == null ? const <HInstruction>[] : <HInstruction>[value];
    // An erroneous element indicates an unresolved static setter.
    generateThrowNoSuchMethod(
        location, noSuchMethodTargetSymbolString(element, 'set'),
        argumentValues: arguments);
  }

  void generateNonInstanceSetter(
      ast.SendSet send, Element element, HInstruction value,
      {ast.Node location}) {
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(send == null || !Elements.isInstanceSend(send, elements),
        failedAt(location, "Unexpected non instance setter: $element."));
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isSetter) {
        pushInvokeStatic(location, element, <HInstruction>[value]);
        pop();
      } else {
        FieldElement field = element;
        value = typeBuilder.potentiallyCheckOrTrustType(value, field.type);
        addWithPosition(new HStaticStore(field, value), location);
      }
      stack.add(value);
    } else if (Elements.isError(element)) {
      generateNoSuchSetter(location, element, send == null ? null : value);
    } else if (Elements.isMalformed(element)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(closedWorld));
    } else {
      stack.add(value);
      LocalElement local = element;
      // If the value does not already have a name, give it here.
      if (value.sourceElement == null) {
        value.sourceElement = local;
      }
      HInstruction checkedOrTrusted =
          typeBuilder.potentiallyCheckOrTrustType(value, local.type);
      if (!identical(checkedOrTrusted, value)) {
        pop();
        stack.add(checkedOrTrusted);
      }

      localsHandler.updateLocal(local, checkedOrTrusted,
          sourceInformation:
              sourceInformationBuilder.buildAssignment(location));
    }
  }

  HInstruction invokeInterceptor(HInstruction receiver) {
    HInterceptor interceptor =
        new HInterceptor(receiver, commonMasks.nonNullType);
    add(interceptor);
    return interceptor;
  }

  HLiteralList buildLiteralList(List<HInstruction> inputs) {
    return new HLiteralList(inputs, commonMasks.extendableArrayType);
  }

  @override
  void visitAs(ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    if (type.isMalformed) {
      if (type is MalformedType) {
        ErroneousElement element = type.element;
        generateTypeError(node, element.message);
      } else {
        assert(type is MethodTypeVariableType);
        stack.add(expressionInstruction);
      }
    } else {
      HInstruction converted = typeBuilder.buildTypeConversion(
          expressionInstruction,
          localsHandler.substInContext(type),
          HTypeConversion.CAST_TYPE_CHECK);
      if (converted != expressionInstruction) add(converted);
      stack.add(converted);
    }
  }

  @override
  void visitIs(ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    push(buildIsNode(node, type, expressionInstruction));
  }

  @override
  void visitIsNot(
      ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    HInstruction instruction = buildIsNode(node, type, expressionInstruction);
    add(instruction);
    push(new HNot(instruction, commonMasks.boolType));
  }

  HInstruction buildIsNode(
      ast.Node node, ResolutionDartType type, HInstruction expression) {
    type = localsHandler.substInContext(type).unaliased;
    if (type.isMalformed) {
      String message;
      if (type is MethodTypeVariableType) {
        message = "Method type variables are not reified, "
            "so they cannot be tested with an `is` expression.";
      } else {
        assert(type is MalformedType);
        ErroneousElement element = type.element;
        message = element.message;
      }
      generateTypeError(node, message);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, commonMasks.boolType);
    } else if (type.isFunctionType) {
      HInstruction representation =
          typeBuilder.analyzeTypeArgument(type, sourceElement);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        representation,
      ];
      pushInvokeStatic(node, commonElements.functionTypeTest, inputs,
          typeMask: commonMasks.boolType);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, commonMasks.boolType);
    } else if (type.isTypeVariable) {
      HInstruction runtimeType =
          typeBuilder.addTypeVariableReference(type, sourceElement);
      MethodElement helper = commonElements.checkSubtypeOfRuntimeType;
      List<HInstruction> inputs = <HInstruction>[expression, runtimeType];
      pushInvokeStatic(null, helper, inputs, typeMask: commonMasks.boolType);
      HInstruction call = pop();
      return new HIs.variable(type, expression, call, commonMasks.boolType);
    } else if (RuntimeTypesSubstitutions.hasTypeArguments(type)) {
      ClassElement element = type.element;
      MethodElement helper = commonElements.checkSubtype;
      HInstruction representations =
          typeBuilder.buildTypeArgumentRepresentations(type, sourceElement);
      add(representations);
      js.Name operator = namer.operatorIs(element);
      HInstruction isFieldName = addConstantStringFromName(operator);
      HInstruction asFieldName = closedWorld.hasAnyStrictSubtype(element)
          ? addConstantStringFromName(namer.substitutionName(element))
          : graph.addConstantNull(closedWorld);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        isFieldName,
        representations,
        asFieldName
      ];
      pushInvokeStatic(node, helper, inputs, typeMask: commonMasks.boolType);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, commonMasks.boolType);
    } else {
      if (backend.hasDirectCheckFor(closedWorld.commonElements, type)) {
        return new HIs.direct(type, expression, commonMasks.boolType);
      }
      // The interceptor is not always needed.  It is removed by optimization
      // when the receiver type or tested type permit.
      return new HIs.raw(type, expression, invokeInterceptor(expression),
          commonMasks.boolType);
    }
  }

  void addDynamicSendArgumentsToList(ast.Send node, List<HInstruction> list) {
    CallStructure callStructure = elements.getSelector(node).callStructure;
    if (callStructure.namedArgumentCount == 0) {
      addGenericSendArgumentsToList(node.arguments, list);
    } else {
      // Visit positional arguments and add them to the list.
      Link<ast.Node> arguments = node.arguments;
      int positionalArgumentCount = callStructure.positionalArgumentCount;
      for (int i = 0;
          i < positionalArgumentCount;
          arguments = arguments.tail, i++) {
        visit(arguments.head);
        list.add(pop());
      }

      // Visit named arguments and add them into a temporary map.
      Map<String, HInstruction> instructions = new Map<String, HInstruction>();
      List<String> namedArguments = callStructure.namedArguments;
      int nameIndex = 0;
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        visit(arguments.head);
        instructions[namedArguments[nameIndex++]] = pop();
      }

      // Iterate through the named arguments to add them to the list
      // of instructions, in an order that can be shared with
      // selectors with the same named arguments.
      List<String> orderedNames = callStructure.getOrderedNamedArguments();
      for (String name in orderedNames) {
        list.add(instructions[name]);
      }
    }
  }

  /**
   * Returns a list with the evaluated [arguments] in the normalized order.
   *
   * Precondition: `this.applies(element, world)`.
   * Invariant: [element] must be an implementation element.
   */
  List<HInstruction> makeStaticArgumentList(CallStructure callStructure,
      Link<ast.Node> arguments, MethodElement element) {
    assert(element.isDeclaration, failedAt(element));

    HInstruction compileArgument(ast.Node argument) {
      visit(argument);
      return pop();
    }

    return Elements.makeArgumentsList<HInstruction>(
        callStructure,
        arguments,
        element.implementation,
        compileArgument,
        nativeData.isJsInteropMember(element)
            ? handleConstantForOptionalParameterJsInterop
            : handleConstantForOptionalParameter);
  }

  void addGenericSendArgumentsToList(
      Link<ast.Node> link, List<HInstruction> list) {
    for (; !link.isEmpty; link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  /// Generate a dynamic method, getter or setter invocation.
  void generateDynamicSend(ast.Send node) {
    HInstruction receiver = generateInstanceSendReceiver(node);
    _generateDynamicSend(node, receiver);
  }

  void _generateDynamicSend(ast.Send node, HInstruction receiver) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = elementInferenceResults.typeOfSend(node);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildCall(node, node.selector);

    List<HInstruction> inputs = <HInstruction>[];
    inputs.add(receiver);
    addDynamicSendArgumentsToList(node, inputs);

    pushInvokeDynamic(node, selector, mask, inputs,
        sourceInformation: sourceInformation);
    if (selector.isSetter || selector.isIndexSet) {
      pop();
      stack.add(inputs.last);
    }
  }

  @override
  visitDynamicPropertyInvoke(ast.Send node, ast.Node receiver,
      ast.NodeList arguments, Selector selector, _) {
    generateDynamicSend(node);
  }

  @override
  visitIfNotNullDynamicPropertyInvoke(ast.Send node, ast.Node receiver,
      ast.NodeList arguments, Selector selector, _) {
    /// Desugar `exp?.m()` to `(t1 = exp) == null ? t1 : t1.m()`
    HInstruction receiver;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(() {
      receiver = generateInstanceSendReceiver(node);
      pushCheckNull(receiver);
    }, () => stack.add(receiver), () => _generateDynamicSend(node, receiver));
  }

  @override
  visitThisPropertyInvoke(
      ast.Send node, ast.NodeList arguments, Selector selector, _) {
    generateDynamicSend(node);
  }

  @override
  visitExpressionInvoke(ast.Send node, ast.Node expression,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateCallInvoke(node, visitAndPop(expression),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitThisInvoke(
      ast.Send node, ast.NodeList arguments, CallStructure callStructure, _) {
    generateCallInvoke(node, localsHandler.readThis(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitParameterInvoke(ast.Send node, ParameterElement parameter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateCallInvoke(node, localsHandler.readLocal(parameter),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalVariableInvoke(ast.Send node, LocalVariableElement variable,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateCallInvoke(node, localsHandler.readLocal(variable),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalFunctionInvoke(ast.Send node, LocalFunctionElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateCallInvoke(node, localsHandler.readLocal(function),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalFunctionIncompatibleInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(node, localsHandler.readLocal(function),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  void handleForeignJs(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    // Don't visit the first argument, which is the type, and the second
    // argument, which is the foreign code.
    if (link.isEmpty || link.tail.isEmpty) {
      // We should not get here because the call should be compiled to NSM.
      reporter.internalError(
          node.argumentsNode, 'At least two arguments expected.');
    }
    native.NativeBehavior nativeBehavior = elements.getNativeData(node);
    assert(
        nativeBehavior != null, failedAt(node, "No NativeBehavior for $node"));

    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(link.tail.tail, inputs);

    if (nativeBehavior.codeTemplate.positionalArgumentCount != inputs.length) {
      reporter.reportErrorMessage(node, MessageKind.GENERIC, {
        'text': 'Mismatch between number of placeholders'
            ' and number of arguments.'
      });
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (native.HasCapturedPlaceholders.check(nativeBehavior.codeTemplate.ast)) {
      reporter.reportErrorMessage(node, MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, closedWorld);

    SourceInformation sourceInformation =
        sourceInformationBuilder.buildCall(node, node.argumentsNode);
    if (nativeBehavior.codeTemplate.isExpression) {
      push(new HForeignCode(nativeBehavior.codeTemplate, ssaType, inputs,
          effects: nativeBehavior.sideEffects, nativeBehavior: nativeBehavior)
        ..sourceInformation = sourceInformation);
    } else {
      push(new HForeignCode(nativeBehavior.codeTemplate, ssaType, inputs,
          isStatement: true,
          effects: nativeBehavior.sideEffects,
          nativeBehavior: nativeBehavior)
        ..sourceInformation = sourceInformation);
    }
  }

  void handleJsStringConcat(ast.Send node) {
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(node.arguments, inputs);
    if (inputs.length != 2) {
      reporter.internalError(node.argumentsNode, 'Two arguments expected.');
    }
    push(new HStringConcat(inputs[0], inputs[1], commonMasks.stringType));
  }

  void handleForeignJsCurrentIsolateContext(ast.Send node) {
    if (!node.arguments.isEmpty) {
      reporter.internalError(
          node, 'Too many arguments to JS_CURRENT_ISOLATE_CONTEXT.');
    }

    if (!backendUsage.isIsolateInUse) {
      // If the isolate library is not used, we just generate code
      // to fetch the static state.
      String name = namer.staticStateHolder;
      push(new HForeignCode(
          js.js.parseForeignJS(name), commonMasks.dynamicType, <HInstruction>[],
          nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      MethodElement element = commonElements.currentIsolate;
      if (element == null) {
        reporter.internalError(node, 'Isolate library and compiler mismatch.');
      }
      pushInvokeStatic(null, element, [], typeMask: commonMasks.dynamicType);
    }
  }

  void handleForeignJsGetFlag(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node argument;
    switch (arguments.length) {
      case 0:
        reporter.reportErrorMessage(node, MessageKind.GENERIC,
            {'text': 'Error: Expected one argument to JS_GET_FLAG.'});
        return;
      case 1:
        argument = arguments[0];
        break;
      default:
        for (int i = 1; i < arguments.length; i++) {
          reporter.reportErrorMessage(arguments[i], MessageKind.GENERIC,
              {'text': 'Error: Extra argument to JS_GET_FLAG.'});
        }
        return;
    }
    ast.LiteralString string = argument.asLiteralString();
    if (string == null) {
      reporter.reportErrorMessage(argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a literal string.'});
    }
    String name = string.dartString.slowToString();
    bool value = getFlagValue(name);
    if (value == null) {
      reporter.reportErrorMessage(node, MessageKind.GENERIC,
          {'text': 'Error: Unknown internal flag "$name".'});
    } else {
      stack.add(graph.addConstantBool(value, closedWorld));
    }
  }

  void handleForeignJsGetName(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node argument;
    switch (arguments.length) {
      case 0:
        reporter.reportErrorMessage(node, MessageKind.GENERIC,
            {'text': 'Error: Expected one argument to JS_GET_NAME.'});
        return;
      case 1:
        argument = arguments[0];
        break;
      default:
        for (int i = 1; i < arguments.length; i++) {
          reporter.reportErrorMessage(arguments[i], MessageKind.GENERIC,
              {'text': 'Error: Extra argument to JS_GET_NAME.'});
        }
        return;
    }
    Element element = elements[argument];
    if (element == null ||
        element is! EnumConstantElement ||
        element.enclosingClass != commonElements.jsGetNameEnum) {
      reporter.reportErrorMessage(argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a JsGetName enum value.'});
    }
    EnumConstantElement enumConstant = element;
    int index = enumConstant.index;
    stack.add(addConstantStringFromName(
        namer.getNameForJsGetName(argument, JsGetName.values[index])));
  }

  void handleForeignJsBuiltin(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node argument;
    if (arguments.length < 2) {
      reporter.reportErrorMessage(node, MessageKind.GENERIC,
          {'text': 'Error: Expected at least two arguments to JS_BUILTIN.'});
    }

    Element builtinElement = elements[arguments[1]];
    if (builtinElement == null ||
        (builtinElement is! EnumConstantElement) ||
        builtinElement.enclosingClass != commonElements.jsBuiltinEnum) {
      reporter.reportErrorMessage(argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a JsBuiltin enum value.'});
    }
    EnumConstantElement enumConstant = builtinElement;
    int index = enumConstant.index;

    js.Template template = emitter.builtinTemplateFor(JsBuiltin.values[index]);

    List<HInstruction> compiledArguments = <HInstruction>[];
    for (int i = 2; i < arguments.length; i++) {
      visit(arguments[i]);
      compiledArguments.add(pop());
    }

    native.NativeBehavior nativeBehavior = elements.getNativeData(node);
    assert(
        nativeBehavior != null, failedAt(node, "No NativeBehavior for $node"));

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, closedWorld);

    push(new HForeignCode(template, ssaType, compiledArguments,
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsEmbeddedGlobal(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node globalNameNode;
    switch (arguments.length) {
      case 0:
      case 1:
        reporter.reportErrorMessage(node, MessageKind.GENERIC,
            {'text': 'Error: Expected two arguments to JS_EMBEDDED_GLOBAL.'});
        return;
      case 2:
        // The type has been extracted earlier. We are only interested in the
        // name in this function.
        globalNameNode = arguments[1];
        break;
      default:
        for (int i = 2; i < arguments.length; i++) {
          reporter.reportErrorMessage(arguments[i], MessageKind.GENERIC,
              {'text': 'Error: Extra argument to JS_EMBEDDED_GLOBAL.'});
        }
        return;
    }
    visit(globalNameNode);
    HInstruction globalNameHNode = pop();
    if (!globalNameHNode.isConstantString()) {
      reporter.reportErrorMessage(arguments[1], MessageKind.GENERIC, {
        'text': 'Error: Expected String as second argument '
            'to JS_EMBEDDED_GLOBAL.'
      });
      return;
    }
    HConstant hConstant = globalNameHNode;
    StringConstantValue constant = hConstant.constant;
    String globalName = constant.primitiveValue;
    js.Template expr = js.js.expressionTemplateYielding(
        emitter.generateEmbeddedGlobalAccess(globalName));
    native.NativeBehavior nativeBehavior = elements.getNativeData(node);
    assert(
        nativeBehavior != null, failedAt(node, "No NativeBehavior for $node"));
    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, closedWorld);
    push(new HForeignCode(expr, ssaType, const [],
        nativeBehavior: nativeBehavior));
  }

  void handleJsInterceptorConstant(ast.Send node) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (!node.arguments.isEmpty && node.arguments.tail.isEmpty) {
      ast.Node argument = node.arguments.head;
      visit(argument);
      HInstruction argumentInstruction = pop();
      if (argumentInstruction is HConstant) {
        ConstantValue argumentConstant = argumentInstruction.constant;
        if (argumentConstant is TypeConstantValue &&
            argumentConstant.representedType is ResolutionInterfaceType) {
          ResolutionInterfaceType type = argumentConstant.representedType;
          ConstantValue constant = new InterceptorConstantValue(type.element);
          HInstruction instruction = graph.addConstant(constant, closedWorld);
          stack.add(instruction);
          return;
        }
      }
    }
    reporter.reportErrorMessage(
        node, MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(closedWorld));
  }

  void handleForeignJsCallInIsolate(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    if (!backendUsage.isIsolateInUse) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      push(new HInvokeClosure(new Selector.callClosure(0),
          <HInstruction>[pop()], commonMasks.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      MethodElement element = commonElements.callInIsolate;
      if (element == null) {
        reporter.internalError(node, 'Isolate library and compiler mismatch.');
      }
      List<HInstruction> inputs = <HInstruction>[];
      addGenericSendArgumentsToList(link, inputs);
      pushInvokeStatic(node, element, inputs,
          typeMask: commonMasks.dynamicType);
    }
  }

  FunctionSignature handleForeignRawFunctionRef(ast.Send node, String name) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      reporter.internalError(
          node.argumentsNode, '"$name" requires exactly one argument.');
    }
    ast.Node closure = node.arguments.head;
    Element element = elements[closure];
    if (!Elements.isStaticOrTopLevelFunction(element)) {
      reporter.internalError(
          closure, '"$name" requires a static or top-level method.');
    }
    MethodElement function = element;
    // TODO(johnniwinther): Try to eliminate the need to distinguish declaration
    // and implementation signatures. Currently it is need because the
    // signatures have different elements for parameters.
    FunctionElement implementation = function.implementation;
    FunctionSignature params = implementation.functionSignature;
    if (params.optionalParameterCount != 0) {
      reporter.internalError(
          closure, '"$name" does not handle closure with optional parameters.');
    }

    push(new HForeignCode(
        js.js
            .expressionTemplateYielding(emitter.staticFunctionAccess(function)),
        commonMasks.dynamicType,
        <HInstruction>[],
        nativeBehavior: native.NativeBehavior.PURE,
        foreignFunction: function));
    return params;
  }

  void handleForeignDartClosureToJs(ast.Send node, String name) {
    // TODO(ahe): This implements DART_CLOSURE_TO_JS and should probably take
    // care to wrap the closure in another closure that saves the current
    // isolate.
    handleForeignRawFunctionRef(node, name);
  }

  void handleForeignJsSetStaticState(ast.Send node) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      reporter.internalError(
          node.argumentsNode, 'Exactly one argument required.');
    }
    visit(node.arguments.head);
    String isolateName = namer.staticStateHolder;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeignCode(js.js.parseForeignJS("$isolateName = #"),
        commonMasks.dynamicType, <HInstruction>[pop()],
        nativeBehavior: native.NativeBehavior.CHANGES_OTHER,
        effects: sideEffects));
  }

  void handleForeignJsGetStaticState(ast.Send node) {
    if (!node.arguments.isEmpty) {
      reporter.internalError(node.argumentsNode, 'Too many arguments.');
    }
    push(new HForeignCode(js.js.parseForeignJS(namer.staticStateHolder),
        commonMasks.dynamicType, <HInstruction>[],
        nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
  }

  void handleForeignSend(ast.Send node, FunctionElement element) {
    String name = element.name;
    if (name == JavaScriptBackend.JS) {
      handleForeignJs(node);
    } else if (name == 'JS_CURRENT_ISOLATE_CONTEXT') {
      handleForeignJsCurrentIsolateContext(node);
    } else if (name == 'JS_CALL_IN_ISOLATE') {
      handleForeignJsCallInIsolate(node);
    } else if (name == 'DART_CLOSURE_TO_JS') {
      handleForeignDartClosureToJs(node, 'DART_CLOSURE_TO_JS');
    } else if (name == 'RAW_DART_FUNCTION_REF') {
      handleForeignRawFunctionRef(node, 'RAW_DART_FUNCTION_REF');
    } else if (name == 'JS_SET_STATIC_STATE') {
      handleForeignJsSetStaticState(node);
    } else if (name == 'JS_GET_STATIC_STATE') {
      handleForeignJsGetStaticState(node);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(node);
    } else if (name == JavaScriptBackend.JS_EMBEDDED_GLOBAL) {
      handleForeignJsEmbeddedGlobal(node);
    } else if (name == JavaScriptBackend.JS_BUILTIN) {
      handleForeignJsBuiltin(node);
    } else if (name == 'JS_GET_FLAG') {
      handleForeignJsGetFlag(node);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(closedWorld));
    } else if (name == JavaScriptBackend.JS_INTERCEPTOR_CONSTANT) {
      handleJsInterceptorConstant(node);
    } else if (name == 'JS_STRING_CONCAT') {
      handleJsStringConcat(node);
    } else {
      reporter.internalError(node, "Unknown foreign: ${element}");
    }
  }

  generateDeferredLoaderGet(ast.Send node, FunctionElement deferredLoader,
      SourceInformation sourceInformation) {
    // Until now we only handle these as getters.
    if (!deferredLoader.isDeferredLoaderGetter) {
      failedAt(node);
    }
    FunctionEntity loadFunction = commonElements.loadLibraryWrapper;
    PrefixElement prefixElement = deferredLoader.enclosingElement;
    String loadId = deferredLoadTask.getImportDeferName(node, prefixElement);
    var inputs = [graph.addConstantString(loadId, closedWorld)];
    push(new HInvokeStatic(loadFunction, inputs, commonMasks.nonNullType,
        targetCanThrow: false)
      ..sourceInformation = sourceInformation);
  }

  generateSuperNoSuchMethodSend(
      ast.Send node, Selector selector, List<HInstruction> arguments) {
    String name = selector.name;

    ClassElement cls = currentNonClosureClass;
    MethodElement element = cls.lookupSuperMember(Identifiers.noSuchMethod_);
    if (!Selectors.noSuchMethod_.signatureApplies(element)) {
      ClassElement objectClass = commonElements.objectClass;
      element = objectClass.lookupMember(Identifiers.noSuchMethod_);
    }
    if (backendUsage.isInvokeOnUsed && !element.enclosingClass.isObject) {
      // Register the call as dynamic if [noSuchMethod] on the super
      // class is _not_ the default implementation from [Object], in
      // case the [noSuchMethod] implementation calls
      // [JSInvocationMirror._invokeOn].
      // TODO(johnniwinther): Register this more precisely.
      registry?.registerDynamicUse(new DynamicUse(selector, null));
    }
    String publicName = name;
    if (selector.isSetter) publicName += '=';

    ConstantValue nameConstant = constantSystem.createString(publicName);

    js.Name internalName = namer.invocationName(selector);

    MethodElement createInvocationMirror =
        commonElements.createInvocationMirror;
    var argumentsInstruction = buildLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      ConstantValue argumentNameConstant =
          constantSystem.createString(argumentName);
      argumentNames.add(graph.addConstant(argumentNameConstant, closedWorld));
    }
    var argumentNamesInstruction = buildLiteralList(argumentNames);
    add(argumentNamesInstruction);

    ConstantValue kindConstant =
        constantSystem.createInt(selector.invocationMirrorKind);

    pushInvokeStatic(
        null,
        createInvocationMirror,
        [
          graph.addConstant(nameConstant, closedWorld),
          graph.addConstantStringFromName(internalName, closedWorld),
          graph.addConstant(kindConstant, closedWorld),
          argumentsInstruction,
          argumentNamesInstruction
        ],
        typeMask: commonMasks.dynamicType);

    var inputs = <HInstruction>[pop()];
    push(buildInvokeSuper(Selectors.noSuchMethod_, element, inputs));
  }

  /// Generate a call to a super method or constructor.
  void generateSuperInvoke(ast.Send node, MethodElement method,
      SourceInformation sourceInformation) {
    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [makeStaticArgumentList].
    Selector selector = elements.getSelector(node);
    MethodElement implementation = method.implementation;
    assert(selector.applies(implementation),
        failedAt(node, "$selector does not apply to ${implementation}"));
    List<HInstruction> inputs =
        makeStaticArgumentList(selector.callStructure, node.arguments, method);
    push(buildInvokeSuper(selector, method, inputs, sourceInformation));
  }

  /// Access the value from the super [element].
  void handleSuperGet(ast.Send node, Element element) {
    Selector selector = elements.getSelector(node);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    push(buildInvokeSuper(
        selector, element, const <HInstruction>[], sourceInformation));
  }

  /// Invoke .call on the value retrieved from the super [element].
  void handleSuperCallInvoke(ast.Send node, Element element) {
    Selector selector = elements.getSelector(node);
    HInstruction target = buildInvokeSuper(selector, element,
        const <HInstruction>[], sourceInformationBuilder.buildGet(node));
    add(target);
    generateCallInvoke(node, target,
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  /// Invoke super [method].
  void handleSuperMethodInvoke(ast.Send node, MethodElement method) {
    generateSuperInvoke(
        node, method, sourceInformationBuilder.buildCall(node, node.selector));
  }

  /// Access an unresolved super property.
  void handleUnresolvedSuperInvoke(ast.Send node) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> arguments = <HInstruction>[];
    if (!node.isPropertyAccess) {
      addGenericSendArgumentsToList(node.arguments, arguments);
    }
    generateSuperNoSuchMethodSend(node, selector, arguments);
  }

  @override
  void visitUnresolvedSuperIndex(
      ast.Send node, Element element, ast.Node index, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperUnary(
      ast.Send node, UnaryOperator operator, Element element, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperBinary(ast.Send node, Element element,
      BinaryOperator operator, ast.Node argument, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperGet(ast.Send node, Element element, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperSet(
      ast.Send node, Element element, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperSetterGet(ast.Send node, MethodElement setter, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperInvoke(
      ast.Send node, Element element, ast.Node argument, Selector selector, _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitSuperFieldGet(ast.Send node, FieldElement field, _) {
    handleSuperGet(node, field);
  }

  @override
  void visitSuperGetterGet(ast.Send node, MethodElement method, _) {
    handleSuperGet(node, method);
  }

  @override
  void visitSuperMethodGet(ast.Send node, MethodElement method, _) {
    handleSuperGet(node, method);
  }

  @override
  void visitSuperFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleSuperCallInvoke(node, field);
  }

  @override
  void visitSuperGetterInvoke(ast.Send node, MethodElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleSuperCallInvoke(node, getter);
  }

  @override
  void visitSuperMethodInvoke(ast.Send node, MethodElement method,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperIndex(ast.Send node, MethodElement method, ast.Node index, _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperBinary(ast.Send node, MethodElement method,
      BinaryOperator operator, ast.Node argument, _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperNotEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    handleSuperMethodInvoke(node, method);
    pushWithPosition(
        new HNot(popBoolified(), commonMasks.boolType), node.selector);
  }

  @override
  void visitSuperUnary(
      ast.Send node, UnaryOperator operator, MethodElement method, _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperMethodIncompatibleInvoke(ast.Send node, MethodElement method,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleInvalidSuperInvoke(node, arguments);
  }

  @override
  void visitSuperSetterInvoke(ast.Send node, SetterElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleInvalidSuperInvoke(node, arguments);
  }

  void handleInvalidSuperInvoke(ast.Send node, ast.NodeList arguments) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(arguments.nodes, inputs);
    generateSuperNoSuchMethodSend(node, selector, inputs);
  }

  bool needsSubstitutionForTypeVariableAccess(ClassElement cls) {
    if (closedWorld.isUsedAsMixin(cls)) return true;

    return closedWorld.anyStrictSubclassOf(cls, (ClassEntity subclass) {
      return !rtiSubstitutions.isTrivialSubstitution(subclass, cls);
    });
  }

  HInstruction handleListConstructor(ResolutionInterfaceType type,
      ast.Node currentNode, HInstruction newObject) {
    if (!rtiNeed.classNeedsRti(type.element) || type.treatAsRaw) {
      return newObject;
    }
    List<HInstruction> inputs = <HInstruction>[];
    type = localsHandler.substInContext(type);
    type.typeArguments.forEach((ResolutionDartType argument) {
      inputs.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
    });
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfoWithTypeArguments(type, inputs, newObject);
  }

  HInstruction callSetRuntimeTypeInfo(
      HInstruction typeInfo, HInstruction newObject) {
    // Set the runtime type information on the object.
    MethodElement typeInfoSetterElement = commonElements.setRuntimeTypeInfo;
    pushInvokeStatic(
        null, typeInfoSetterElement, <HInstruction>[newObject, typeInfo],
        typeMask: commonMasks.dynamicType,
        sourceInformation: newObject.sourceInformation);

    // The new object will now be referenced through the
    // `setRuntimeTypeInfo` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(
        stack.last is HInvokeStatic || stack.last == newObject,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE,
            "Unexpected `stack.last`: Found ${stack.last}, "
            "expected ${newObject} or an HInvokeStatic. "
            "State: typeInfo=$typeInfo, stack=$stack."));
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  void handleNewSend(ast.NewExpression node) {
    ast.Send send = node.send;
    generateIsDeferredLoadedCheckOfSend(send);

    ConstructorElement constructor = elements[send];
    bool isFixedList = false;
    bool isFixedListConstructorCall = Elements.isFixedListConstructorCall(
        constructor, send, closedWorld.commonElements);
    bool isGrowableListConstructorCall = Elements.isGrowableListConstructorCall(
        constructor, send, closedWorld.commonElements);

    TypeMask computeType(element) {
      ConstructorElement originalElement = elements[send];
      if (isFixedListConstructorCall ||
          Elements.isFilledListConstructorCall(
              originalElement, send, closedWorld.commonElements)) {
        isFixedList = true;
        TypeMask inferred = _inferredTypeOfNewList(send);
        return inferred.containsAll(closedWorld)
            ? commonMasks.fixedArrayType
            : inferred;
      } else if (isGrowableListConstructorCall) {
        TypeMask inferred = _inferredTypeOfNewList(send);
        return inferred.containsAll(closedWorld)
            ? commonMasks.extendableArrayType
            : inferred;
      } else if (Elements.isConstructorOfTypedArraySubclass(
          originalElement, closedWorld)) {
        isFixedList = true;
        TypeMask inferred = _inferredTypeOfNewList(send);
        ClassElement cls = element.enclosingClass;
        assert(nativeData.isNativeClass(cls));
        return inferred.containsAll(closedWorld)
            ? new TypeMask.nonNullExact(cls, closedWorld)
            : inferred;
      } else if (element.isGenerativeConstructor) {
        ClassElement cls = element.enclosingClass;
        if (cls.isAbstract) {
          // An error will be thrown.
          return new TypeMask.nonNullEmpty();
        } else {
          return new TypeMask.nonNullExact(cls, closedWorld);
        }
      } else {
        return TypeMaskFactory.inferredReturnTypeForElement(
            originalElement, globalInferenceResults);
      }
    }

    CallStructure callStructure = elements.getSelector(send).callStructure;
    ConstructorElement constructorDeclaration = constructor;
    ConstructorElement constructorImplementation = constructor.implementation;
    constructor = constructorImplementation.effectiveTarget;

    final bool isSymbolConstructor =
        closedWorld.commonElements.isSymbolConstructor(constructorDeclaration);
    final bool isJSArrayTypedConstructor = constructorDeclaration ==
        closedWorld.commonElements.jsArrayTypedConstructor;

    if (isSymbolConstructor) {
      constructor = commonElements.symbolValidatedConstructor;
      assert(constructor != null,
          failedAt(send, 'Constructor Symbol.validated is missing'));
      callStructure =
          commonElements.symbolValidatedConstructorSelector.callStructure;
      assert(callStructure != null,
          failedAt(send, 'Constructor Symbol.validated is missing'));
    }

    bool isRedirected = constructorDeclaration.isRedirectingFactory;
    if (!constructorDeclaration.isCyclicRedirection) {
      // Insert a check for every deferred redirection on the path to the
      // final target.
      ConstructorElement target = constructorDeclaration;
      while (target.isRedirectingFactory) {
        if (constructorDeclaration.redirectionDeferredPrefix != null) {
          generateIsDeferredLoadedCheckIfNeeded(
              target.redirectionDeferredPrefix, node);
        }
        target = target.immediateRedirectionTarget;
      }
    }
    ResolutionInterfaceType type = elements.getType(node);
    ResolutionDartType expectedType =
        constructorDeclaration.computeEffectiveTargetType(type);
    expectedType = localsHandler.substInContext(expectedType);

    if (compiler.elementHasCompileTimeError(constructor) ||
        compiler.elementHasCompileTimeError(constructor.enclosingClass)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (checkTypeVariableBounds(node, type)) return;

    // Abstract class instantiation error takes precedence over argument
    // mismatch.
    ClassElement cls = constructor.enclosingClass;
    if (cls.isAbstract && constructor.isGenerativeConstructor) {
      // However, we need to ensure that all arguments are evaluated before we
      // throw the ACIE exception.
      send.arguments.forEach((arg) {
        visit(arg);
        pop();
      });
      generateAbstractClassInstantiationError(send, cls.name);
      return;
    }

    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [makeStaticArgumentList].
    constructorImplementation = constructor.implementation;
    if (constructorImplementation.isMalformed ||
        !callStructure
            .signatureApplies(constructorImplementation.parameterStructure)) {
      generateWrongArgumentCountError(send, constructor, send.arguments);
      return;
    }

    List<HInstruction> inputs = <HInstruction>[];
    if (constructor.isGenerativeConstructor &&
        nativeData.isNativeOrExtendsNative(constructor.enclosingClass) &&
        !nativeData.isJsInteropMember(constructor)) {
      // Native class generative constructors take a pre-constructed object.
      inputs.add(graph.addConstantNull(closedWorld));
    }
    inputs.addAll(makeStaticArgumentList(
        callStructure, send.arguments, constructorImplementation.declaration));

    TypeMask elementType = computeType(constructor);
    if (isFixedListConstructorCall) {
      if (!inputs[0].isNumber(closedWorld)) {
        HTypeConversion conversion = new HTypeConversion(
            null,
            HTypeConversion.ARGUMENT_TYPE_CHECK,
            commonMasks.numType,
            inputs[0]);
        add(conversion);
        inputs[0] = conversion;
      }
      js.Template code = js.js.parseForeignJS('new Array(#)');
      var behavior = new native.NativeBehavior();
      behavior.typesInstantiated.add(expectedType);
      behavior.typesReturned.add(expectedType);
      // The allocation can throw only if the given length is a double or
      // outside the unsigned 32 bit range.
      // TODO(sra): Array allocation should be an instruction so that canThrow
      // can depend on a length type discovered in optimization.
      bool canThrow = true;
      if (inputs[0].isInteger(closedWorld) && inputs[0] is HConstant) {
        dynamic constant = inputs[0];
        int value = constant.constant.primitiveValue;
        if (0 <= value && value < 0x100000000) canThrow = false;
      }
      HForeignCode foreign = new HForeignCode(code, elementType, inputs,
          nativeBehavior: behavior,
          throwBehavior: canThrow
              ? native.NativeThrowBehavior.MAY
              : native.NativeThrowBehavior.NEVER);
      push(foreign);
      if (globalInferenceResults.isFixedArrayCheckedForGrowable(send)) {
        js.Template code = js.js.parseForeignJS(r'#.fixed$length = Array');
        // We set the instruction as [canThrow] to avoid it being dead code.
        // We need a finer grained side effect.
        add(new HForeignCode(code, commonMasks.nullType, [stack.last],
            throwBehavior: native.NativeThrowBehavior.MAY));
      }
    } else if (isGrowableListConstructorCall) {
      push(buildLiteralList(<HInstruction>[]));
      stack.last.instructionType = elementType;
    } else if (constructor.isExternal &&
        constructor.isFromEnvironmentConstructor) {
      generateUnsupportedError(
          node,
          '${cls.name}.${constructor.name} '
          'can only be used as a const constructor');
    } else {
      SourceInformation sourceInformation =
          sourceInformationBuilder.buildNew(send);
      potentiallyAddTypeArguments(inputs, cls, expectedType);
      addInlinedInstantiation(expectedType);
      pushInvokeStatic(node, constructor.declaration, inputs,
          typeMask: elementType,
          instanceType: expectedType,
          sourceInformation: sourceInformation);
      removeInlinedInstantiation(expectedType);
    }
    HInstruction newInstance = stack.last;
    if (isFixedList) {
      // Overwrite the element type, in case the allocation site has
      // been inlined.
      newInstance.instructionType = elementType;
      graph.allocatedFixedLists?.add(newInstance);
    }

    // The List constructor forwards to a Dart static method that does
    // not know about the type argument. Therefore we special case
    // this constructor to have the setRuntimeTypeInfo called where
    // the 'new' is done.
    if (rtiNeed.classNeedsRti(commonElements.listClass) &&
        (isFixedListConstructorCall ||
            isGrowableListConstructorCall ||
            isJSArrayTypedConstructor)) {
      newInstance = handleListConstructor(type, send, pop());
      stack.add(newInstance);
    }

    // Finally, if we called a redirecting factory constructor, check the type.
    if (isRedirected) {
      HInstruction checked =
          typeBuilder.potentiallyCheckOrTrustType(newInstance, type);
      if (checked != newInstance) {
        pop();
        stack.add(checked);
      }
    }
  }

  void potentiallyAddTypeArguments(List<HInstruction> inputs, ClassElement cls,
      ResolutionInterfaceType expectedType,
      {SourceInformation sourceInformation}) {
    if (!rtiNeed.classNeedsRti(cls)) return;
    assert(cls.typeVariables.length == expectedType.typeArguments.length);
    expectedType.typeArguments.forEach((ResolutionDartType argument) {
      inputs.add(typeBuilder.analyzeTypeArgument(argument, sourceElement,
          sourceInformation: sourceInformation));
    });
  }

  /// In checked mode checks the [type] of [node] to be well-bounded. The method
  /// returns [:true:] if an error can be statically determined.
  bool checkTypeVariableBounds(
      ast.NewExpression node, ResolutionInterfaceType type) {
    if (!options.enableTypeAssertions) return false;

    Map<ResolutionDartType, Set<ResolutionDartType>> seenChecksMap =
        new Map<ResolutionDartType, Set<ResolutionDartType>>();
    bool definitelyFails = false;

    void addTypeVariableBoundCheck(
        InterfaceType _instance,
        DartType _typeArgument,
        TypeVariableType _typeVariable,
        DartType _bound) {
      if (definitelyFails) return;
      ResolutionInterfaceType instance = _instance;
      ResolutionDartType typeArgument = _typeArgument;
      ResolutionTypeVariableType typeVariable = _typeVariable;
      ResolutionDartType bound = _bound;

      int subtypeRelation = types.computeSubtypeRelation(typeArgument, bound);
      if (subtypeRelation == DartTypes.IS_SUBTYPE) return;

      String message = "Can't create an instance of malbounded type '$type': "
          "'${typeArgument}' is not a subtype of bound '${bound}' for "
          "type variable '${typeVariable}' of type "
          "${type == instance
              ? "'${type.element.thisType}'"
              : "'${instance.element.thisType}' on the supertype "
                "'${instance}' of '${type}'"
            }.";
      if (subtypeRelation == DartTypes.NOT_SUBTYPE) {
        generateTypeError(node, message);
        definitelyFails = true;
        return;
      } else if (subtypeRelation == DartTypes.MAYBE_SUBTYPE) {
        Set<ResolutionDartType> seenChecks = seenChecksMap.putIfAbsent(
            typeArgument, () => new Set<ResolutionDartType>());
        if (!seenChecks.contains(bound)) {
          seenChecks.add(bound);
          assertIsSubtype(node, typeArgument, bound, message);
        }
      }
    }

    types.checkTypeVariableBounds(type, addTypeVariableBoundCheck);
    if (definitelyFails) {
      return true;
    }
    for (ResolutionInterfaceType supertype in type.element.allSupertypes) {
      ResolutionInterfaceType instance = type.asInstanceOf(supertype.element);
      types.checkTypeVariableBounds(instance, addTypeVariableBoundCheck);
      if (definitelyFails) {
        return true;
      }
    }
    return false;
  }

  visitStaticSend(ast.Send node) {
    internalError(node, "Unexpected visitStaticSend");
  }

  /// Generate an invocation to the static or top level [function].
  void generateStaticFunctionInvoke(
      ast.Send node, MethodElement function, CallStructure callStructure) {
    List<HInstruction> inputs =
        makeStaticArgumentList(callStructure, node.arguments, function);

    pushInvokeStatic(node, function, inputs,
        sourceInformation:
            sourceInformationBuilder.buildCall(node, node.selector));
  }

  /// Generate an invocation to a static or top level function with the wrong
  /// number of arguments.
  void generateStaticFunctionIncompatibleInvoke(
      ast.Send node, Element element) {
    generateWrongArgumentCountError(node, element, node.arguments);
  }

  @override
  void visitStaticFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateStaticFieldGet(node, field);
    generateCallInvoke(node, pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitStaticFunctionInvoke(ast.Send node, MethodElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateStaticFunctionInvoke(node, function, callStructure);
  }

  @override
  void visitStaticFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFunctionIncompatibleInvoke(node, function);
  }

  @override
  void visitStaticGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateStaticGetterGet(node, getter);
    generateCallInvoke(node, pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateStaticFieldGet(node, field);
    generateCallInvoke(node, pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelFunctionInvoke(ast.Send node, MethodElement function,
      ast.NodeList arguments, CallStructure callStructure, _) {
    if (backend.isForeign(closedWorld.commonElements, function)) {
      handleForeignSend(node, function);
    } else {
      generateStaticFunctionInvoke(node, function, callStructure);
    }
  }

  @override
  void visitTopLevelFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFunctionIncompatibleInvoke(node, function);
  }

  @override
  void visitTopLevelGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateStaticGetterGet(node, getter);
    generateCallInvoke(node, pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelSetterGet(ast.Send node, MethodElement setter, _) {
    handleInvalidStaticGet(node, setter);
  }

  @override
  void visitStaticSetterGet(ast.Send node, MethodElement setter, _) {
    handleInvalidStaticGet(node, setter);
  }

  @override
  void visitUnresolvedGet(ast.Send node, Element element, _) {
    generateStaticUnresolvedGet(node, element);
  }

  void handleInvalidStaticInvoke(ast.Send node, Element element) {
    generateThrowNoSuchMethod(node, noSuchMethodTargetSymbolString(element),
        argumentNodes: node.arguments);
  }

  @override
  void visitStaticSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleInvalidStaticInvoke(node, setter);
  }

  @override
  void visitTopLevelSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    handleInvalidStaticInvoke(node, setter);
  }

  @override
  void visitUnresolvedInvoke(ast.Send node, Element element,
      ast.NodeList arguments, Selector selector, _) {
    if (element is ErroneousElement) {
      // An erroneous element indicates that the function could not be
      // resolved (a warning has been issued).
      handleInvalidStaticInvoke(node, element);
    } else {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(closedWorld));
    }
    return;
  }

  HConstant addConstantString(String string) {
    return graph.addConstantString(string, closedWorld);
  }

  HConstant addConstantStringFromName(js.Name name) {
    return graph.addConstantStringFromName(name, closedWorld);
  }

  visitClassTypeLiteralGet(ast.Send node, ConstantExpression constant, _) {
    generateConstantTypeLiteral(node);
  }

  visitClassTypeLiteralInvoke(ast.Send node, ConstantExpression constant,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  visitTypedefTypeLiteralGet(ast.Send node, ConstantExpression constant, _) {
    generateConstantTypeLiteral(node);
  }

  visitTypedefTypeLiteralInvoke(ast.Send node, ConstantExpression constant,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  visitTypeVariableTypeLiteralGet(
      ast.Send node, TypeVariableElement element, _) {
    generateTypeVariableLiteral(node, element.type);
  }

  visitTypeVariableTypeLiteralInvoke(ast.Send node, TypeVariableElement element,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateTypeVariableLiteral(node, element.type);
    generateTypeLiteralCall(node);
  }

  visitDynamicTypeLiteralGet(ast.Send node, ConstantExpression constant, _) {
    generateConstantTypeLiteral(node);
  }

  visitDynamicTypeLiteralInvoke(ast.Send node, ConstantExpression constant,
      ast.NodeList arguments, CallStructure callStructure, _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  /// Generate the constant value for a constant type literal.
  void generateConstantTypeLiteral(ast.Send node) {
    // TODO(karlklose): add type representation
    if (node.isCall) {
      // The node itself is not a constant but we register the selector (the
      // identifier that refers to the class/typedef) as a constant.
      stack.add(addConstant(node.selector));
    } else {
      stack.add(addConstant(node));
    }
  }

  /// Generate the literal for [typeVariable] in the current context.
  void generateTypeVariableLiteral(
      ast.Send node, ResolutionTypeVariableType typeVariable) {
    // GENERIC_METHODS: This provides thin support for method type variables
    // by treating them as malformed when evaluated as a literal. For full
    // support of generic methods this must be revised.
    if (typeVariable is MethodTypeVariableType) {
      generateTypeError(node, "Method type variables are not reified");
    } else {
      ResolutionDartType type = localsHandler.substInContext(typeVariable);
      HInstruction value = typeBuilder.analyzeTypeArgument(type, sourceElement,
          sourceInformation: sourceInformationBuilder.buildGet(node));
      pushInvokeStatic(node, commonElements.runtimeTypeToString, [value],
          typeMask: commonMasks.stringType);
      pushInvokeStatic(node, commonElements.createRuntimeType, [pop()]);
    }
  }

  /// Generate a call to a type literal.
  void generateTypeLiteralCall(ast.Send node) {
    // This send is of the form 'e(...)', where e is resolved to a type
    // reference. We create a regular closure call on the result of the type
    // reference instead of creating a NoSuchMethodError to avoid pulling it
    // in if it is not used (e.g., in a try/catch).
    HInstruction target = pop();
    generateCallInvoke(node, target,
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  /// Generate a '.call' invocation on [target].
  void generateCallInvoke(
      ast.Send node, HInstruction target, SourceInformation sourceInformation) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> inputs = <HInstruction>[target];
    addDynamicSendArgumentsToList(node, inputs);
    push(new HInvokeClosure(
        new Selector.callClosureFrom(selector), inputs, commonMasks.dynamicType)
      ..sourceInformation = sourceInformation);
  }

  visitGetterSend(ast.Send node) {
    internalError(node, "Unexpected visitGetterSend");
  }

  // TODO(antonm): migrate rest of SsaFromAstMixin to internalError.
  internalError(Spannable node, String reason) {
    reporter.internalError(node, reason);
  }

  void generateError(ast.Node node, String message, Element helper) {
    HInstruction errorMessage = addConstantString(message);
    pushInvokeStatic(node, helper, [errorMessage]);
  }

  void generateRuntimeError(ast.Node node, String message) {
    MethodElement helper = commonElements.throwRuntimeError;
    generateError(node, message, helper);
  }

  void generateUnsupportedError(ast.Node node, String message) {
    MethodElement helper = commonElements.throwUnsupportedError;
    generateError(node, message, helper);
  }

  void generateTypeError(ast.Node node, String message) {
    MethodElement helper = commonElements.throwTypeError;
    generateError(node, message, helper);
  }

  void generateAbstractClassInstantiationError(ast.Node node, String message) {
    MethodElement helper = commonElements.throwAbstractClassInstantiationError;
    generateError(node, message, helper);
  }

  void generateThrowNoSuchMethod(ast.Node diagnosticNode, String methodName,
      {Link<ast.Node> argumentNodes,
      List<HInstruction> argumentValues,
      List<String> existingArguments,
      SourceInformation sourceInformation}) {
    MethodElement helper = commonElements.throwNoSuchMethod;
    ConstantValue receiverConstant = constantSystem.createString('');
    HInstruction receiver = graph.addConstant(receiverConstant, closedWorld);
    ConstantValue nameConstant = constantSystem.createString(methodName);
    HInstruction name = graph.addConstant(nameConstant, closedWorld);
    if (argumentValues == null) {
      argumentValues = <HInstruction>[];
      argumentNodes.forEach((argumentNode) {
        visit(argumentNode);
        HInstruction value = pop();
        argumentValues.add(value);
      });
    }
    HInstruction arguments = buildLiteralList(argumentValues);
    add(arguments);
    HInstruction existingNamesList;
    if (existingArguments != null) {
      List<HInstruction> existingNames = <HInstruction>[];
      for (String name in existingArguments) {
        HInstruction nameConstant = graph.addConstantString(name, closedWorld);
        existingNames.add(nameConstant);
      }
      existingNamesList = buildLiteralList(existingNames);
      add(existingNamesList);
    } else {
      existingNamesList = graph.addConstantNull(closedWorld);
    }
    pushInvokeStatic(
        diagnosticNode, helper, [receiver, name, arguments, existingNamesList],
        sourceInformation: sourceInformation);
  }

  /**
   * Generate code to throw a [NoSuchMethodError] exception for calling a
   * method with a wrong number of arguments or mismatching named optional
   * arguments.
   */
  void generateWrongArgumentCountError(ast.Node diagnosticNode,
      FunctionElement function, Link<ast.Node> argumentNodes) {
    List<String> existingArguments = <String>[];
    FunctionSignature signature = function.functionSignature;
    signature.forEachParameter((Element parameter) {
      existingArguments.add(parameter.name);
    });
    generateThrowNoSuchMethod(diagnosticNode, function.name,
        argumentNodes: argumentNodes, existingArguments: existingArguments);
  }

  @override
  void bulkHandleNode(ast.Node node, String message, _) {
    internalError(node, "Unexpected bulk handled node: $node");
  }

  @override
  void bulkHandleNew(ast.NewExpression node, [_]) {
    Element element = elements[node.send];
    if (!Elements.isMalformed(element)) {
      ConstructorElement function = element;
      element = function.effectiveTarget;
    }
    final bool isSymbolConstructor =
        element == commonElements.symbolConstructorTarget;
    if (Elements.isError(element)) {
      ErroneousElement error = element;
      if (error.messageKind == MessageKind.CANNOT_FIND_CONSTRUCTOR ||
          error.messageKind == MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR) {
        generateThrowNoSuchMethod(
            node.send, noSuchMethodTargetSymbolString(error, 'constructor'),
            argumentNodes: node.send.arguments);
      } else {
        MessageTemplate template = MessageTemplate.TEMPLATES[error.messageKind];
        Message message = template.message(error.messageArguments);
        generateRuntimeError(node.send, message.toString());
      }
    } else if (Elements.isMalformed(element)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(closedWorld));
    } else if (node.isConst) {
      stack.add(addConstant(node));
      if (isSymbolConstructor) {
        ConstructedConstantValue symbol = getConstantForNode(node);
        StringConstantValue stringConstant = symbol.fields.values.single;
        String nameString = stringConstant.primitiveValue;
        registry?.registerConstSymbol(nameString);
      }
    } else {
      handleNewSend(node);
    }
  }

  @override
  void errorNonConstantConstructorInvoke(
      ast.NewExpression node,
      Element element,
      ResolutionDartType type,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    bulkHandleNew(node);
  }

  void pushInvokeDynamic(ast.Node node, Selector selector, TypeMask mask,
      List<HInstruction> arguments,
      {SourceInformation sourceInformation}) {
    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(Selector selector, Element element) {
      bool isLength = selector.isGetter && selector.name == "length";
      if (isLength || selector.isIndex) {
        return closedWorld.isSubtypeOf(
            element.enclosingClass, commonElements.jsIndexableClass);
      } else if (selector.isIndexSet) {
        return closedWorld.isSubtypeOf(
            element.enclosingClass, commonElements.jsMutableIndexableClass);
      } else {
        return false;
      }
    }

    bool isOptimizableOperation(Selector selector, Element element) {
      ClassElement cls = element.enclosingClass;
      if (isOptimizableOperationOnIndexable(selector, element)) return true;
      if (!interceptorData.interceptedClasses.contains(cls)) return false;
      if (selector.isOperator) return true;
      if (selector.isSetter) return true;
      if (selector.isIndex) return true;
      if (selector.isIndexSet) return true;
      if (element == commonElements.jsArrayAdd ||
          element == commonElements.jsArrayRemoveLast ||
          element == commonElements.jsStringSplit) {
        return true;
      }
      return false;
    }

    MemberElement element = closedWorld.locateSingleElement(selector, mask);
    if (element != null &&
        !element.isField &&
        !(element.isGetter && selector.isCall) &&
        !(element.isFunction && selector.isGetter) &&
        !isOptimizableOperation(selector, element)) {
      if (tryInlineMethod(element, selector, mask, arguments, node)) {
        return;
      }
    }

    HInstruction receiver = arguments[0];
    List<HInstruction> inputs = <HInstruction>[];
    bool isIntercepted = interceptorData.isInterceptedSelector(selector);
    if (isIntercepted) {
      inputs.add(invokeInterceptor(receiver));
    }
    inputs.addAll(arguments);
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(
        selector, mask, globalInferenceResults);
    if (selector.isGetter) {
      push(new HInvokeDynamicGetter(selector, mask, null, inputs, type)
        ..sourceInformation = sourceInformation);
    } else if (selector.isSetter) {
      push(new HInvokeDynamicSetter(selector, mask, null, inputs, type)
        ..sourceInformation = sourceInformation);
    } else {
      push(new HInvokeDynamicMethod(selector, mask, inputs, type, isIntercepted)
        ..sourceInformation = sourceInformation);
    }
  }

  HForeignCode invokeJsInteropFunction(MethodElement element,
      List<HInstruction> arguments, SourceInformation sourceInformation) {
    assert(nativeData.isJsInteropMember(element));
    nativeEmitter.nativeMethods.add(element);

    if (element.isFactoryConstructor &&
        nativeData.isAnonymousJsInteropClass(element.contextClass)) {
      // Factory constructor that is syntactic sugar for creating a JavaScript
      // object literal.
      ConstructorElement constructor = element;
      FunctionSignature params = constructor.functionSignature;
      int i = 0;
      int positions = 0;
      var filteredArguments = <HInstruction>[];
      var parameterNameMap = new Map<String, js.Expression>();
      params.orderedForEachParameter((_parameter) {
        ParameterElement parameter = _parameter;
        // TODO(jacobr): consider throwing if parameter names do not match
        // names of properties in the class.
        assert(parameter.isNamed);
        HInstruction argument = arguments[i];
        if (argument != null) {
          filteredArguments.add(argument);
          var jsName = nativeData.computeUnescapedJSInteropName(parameter.name);
          parameterNameMap[jsName] = new js.InterpolatedExpression(positions++);
        }
        i++;
      });
      var codeTemplate =
          new js.Template(null, js.objectLiteral(parameterNameMap));

      var nativeBehavior = new native.NativeBehavior()
        ..codeTemplate = codeTemplate;
      if (options.trustJSInteropTypeAnnotations) {
        nativeBehavior.typesReturned.add(constructor.enclosingClass.thisType);
      }
      return new HForeignCode(
          codeTemplate, commonMasks.dynamicType, filteredArguments,
          nativeBehavior: nativeBehavior)
        ..sourceInformation = sourceInformation;
    }
    var target = new HForeignCode(
        js.js.parseForeignJS("${nativeData.getFixedBackendMethodPath(element)}."
            "${nativeData.getFixedBackendName(element)}"),
        commonMasks.dynamicType,
        <HInstruction>[]);
    add(target);
    // Strip off trailing arguments that were not specified.
    // we could assert that the trailing arguments are all null.
    // TODO(jacobr): rewrite named arguments to an object literal matching
    // the factory constructor case.
    arguments = arguments.where((arg) => arg != null).toList();
    var inputs = <HInstruction>[target]..addAll(arguments);

    var nativeBehavior = new native.NativeBehavior()
      ..sideEffects.setAllSideEffects();

    ResolutionDartType type = element.isConstructor
        ? element.enclosingClass.thisType
        : element.type.returnType;
    // Native behavior effects here are similar to native/behavior.dart.
    // The return type is dynamic if we don't trust js-interop type
    // declarations.
    nativeBehavior.typesReturned.add(options.trustJSInteropTypeAnnotations
        ? type
        : const ResolutionDynamicType());

    // The allocation effects include the declared type if it is native (which
    // includes js interop types).
    if (type is ResolutionInterfaceType &&
        nativeData.isNativeClass(type.element)) {
      nativeBehavior.typesInstantiated.add(type);
    }

    // It also includes any other JS interop type if we don't trust the
    // annotation or if is declared too broad.
    if (!options.trustJSInteropTypeAnnotations ||
        type.isObject ||
        type.isDynamic) {
      ClassElement cls = commonElements.jsJavaScriptObjectClass;
      nativeBehavior.typesInstantiated.add(cls.thisType);
    }

    String code;
    if (element.isGetter) {
      code = "#";
    } else if (element.isSetter) {
      code = "# = #";
    } else {
      var args = new List.filled(arguments.length, '#').join(',');
      code = element.isConstructor ? "new #($args)" : "#($args)";
    }
    js.Template codeTemplate = js.js.parseForeignJS(code);
    nativeBehavior.codeTemplate = codeTemplate;

    return new HForeignCode(codeTemplate, commonMasks.dynamicType, inputs,
        nativeBehavior: nativeBehavior)
      ..sourceInformation = sourceInformation;
  }

  void pushInvokeStatic(
      ast.Node location, MethodElement element, List<HInstruction> arguments,
      {TypeMask typeMask,
      ResolutionInterfaceType instanceType,
      SourceInformation sourceInformation}) {
    assert(element.isDeclaration);
    // TODO(johnniwinther): Use [sourceInformation] instead of [location].
    if (tryInlineMethod(element, null, null, arguments, location,
        instanceType: instanceType)) {
      return;
    }

    if (typeMask == null) {
      typeMask = TypeMaskFactory.inferredReturnTypeForElement(
          element, globalInferenceResults);
    }
    bool targetCanThrow = !closedWorld.getCannotThrow(element);
    // TODO(5346): Try to avoid the need for calling [declaration] before
    var instruction;
    if (nativeData.isJsInteropMember(element)) {
      instruction =
          invokeJsInteropFunction(element, arguments, sourceInformation);
    } else {
      // creating an [HInvokeStatic].
      instruction = new HInvokeStatic(element, arguments, typeMask,
          targetCanThrow: targetCanThrow)
        ..sourceInformation = sourceInformation;
      if (currentInlinedInstantiations.isNotEmpty) {
        instruction.instantiatedTypes = new List<ResolutionInterfaceType>.from(
            currentInlinedInstantiations);
      }
      instruction.sideEffects = closedWorld.getSideEffectsOfElement(element);
    }
    if (location == null) {
      push(instruction);
    } else {
      pushWithPosition(instruction, location);
    }
  }

  HInstruction buildInvokeSuper(
      Selector selector, MemberElement element, List<HInstruction> arguments,
      [SourceInformation sourceInformation]) {
    HInstruction receiver = localsHandler.readThis();
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    List<HInstruction> inputs = <HInstruction>[];
    if (interceptorData.isInterceptedSelector(selector) &&
        // Fields don't need an interceptor; consider generating HFieldGet/Set
        // instead.
        element.kind != ElementKind.FIELD) {
      inputs.add(invokeInterceptor(receiver));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);
    TypeMask type;
    if (!element.isGetter && selector.isGetter) {
      type = TypeMaskFactory.inferredTypeForMember(
          element, globalInferenceResults);
    } else if (element.isFunction) {
      type = TypeMaskFactory.inferredReturnTypeForElement(
          element, globalInferenceResults);
    } else {
      type = closedWorld.commonMasks.dynamicType;
    }
    HInstruction instruction = new HInvokeSuper(element, currentNonClosureClass,
        selector, inputs, type, sourceInformation,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        closedWorld.getSideEffectsOfSelector(selector, null);
    return instruction;
  }

  void handleComplexOperatorSend(
      ast.SendSet node, HInstruction receiver, Link<ast.Node> arguments) {
    HInstruction rhs;
    if (node.isPrefix || node.isPostfix) {
      rhs = graph.addConstantInt(1, closedWorld);
    } else {
      visit(arguments.head);
      assert(arguments.tail.isEmpty);
      rhs = pop();
    }
    visitBinarySend(
        receiver,
        rhs,
        elements.getOperatorSelectorInComplexSendSet(node),
        elementInferenceResults.typeOfOperator(node),
        node,
        sourceInformation:
            sourceInformationBuilder.buildGeneric(node.assignmentOperator));
  }

  void handleSuperSendSet(ast.SendSet node) {
    MemberElement element = elements[node];
    List<HInstruction> setterInputs = <HInstruction>[];
    void generateSuperSendSet() {
      Selector setterSelector = elements.getSelector(node);
      if (Elements.isUnresolved(element) || !setterSelector.applies(element)) {
        generateSuperNoSuchMethodSend(node, setterSelector, setterInputs);
        pop();
      } else {
        add(buildInvokeSuper(setterSelector, element, setterInputs));
      }
    }

    if (identical(node.assignmentOperator.source, '=')) {
      addDynamicSendArgumentsToList(node, setterInputs);
      generateSuperSendSet();
      stack.add(setterInputs.last);
    } else {
      Element getter = elements[node.selector];
      List<HInstruction> getterInputs = <HInstruction>[];
      Link<ast.Node> arguments = node.arguments;
      if (node.isIndex) {
        // If node is of the form [:super.foo[0] += 2:], the send has
        // two arguments: the index and the left hand side. We get
        // the index and add it as input of the getter and the
        // setter.
        visit(arguments.head);
        arguments = arguments.tail;
        HInstruction index = pop();
        getterInputs.add(index);
        setterInputs.add(index);
      }
      HInstruction getterInstruction;
      Selector getterSelector =
          elements.getGetterSelectorInComplexSendSet(node);
      if (Elements.isUnresolved(getter)) {
        generateSuperNoSuchMethodSend(node, getterSelector, getterInputs);
        getterInstruction = pop();
      } else {
        getterInstruction =
            buildInvokeSuper(getterSelector, getter, getterInputs);
        add(getterInstruction);
      }

      if (node.isIfNullAssignment) {
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleIfNull(() => stack.add(getterInstruction), () {
          addDynamicSendArgumentsToList(node, setterInputs);
          generateSuperSendSet();
          stack.add(setterInputs.last);
        });
      } else {
        handleComplexOperatorSend(node, getterInstruction, arguments);
        setterInputs.add(pop());
        generateSuperSendSet();
        stack.add(node.isPostfix ? getterInstruction : setterInputs.last);
      }
    }
  }

  @override
  void handleSuperCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterSet(
      ast.SendSet node, FunctionElement getter, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexSet(ast.SendSet node, FunctionElement function,
      ast.Node index, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodSet(
      ast.SendSet node, MethodElement method, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperSetterSet(
      ast.SendSet node, FunctionElement setter, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexSet(ast.SendSet node, ErroneousElement element,
      ast.Node index, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexPrefix(
      ast.Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexPostfix(
      ast.Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterIndexPrefix(ast.SendSet node, Element element,
      MethodElement setter, ast.Node index, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterIndexPostfix(ast.SendSet node, Element element,
      MethodElement setter, ast.Node index, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterIndexPrefix(
      ast.SendSet node,
      MethodElement indexFunction,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterIndexPostfix(
      ast.SendSet node,
      MethodElement indexFunction,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexPrefix(ast.Send node, Element element,
      ast.Node index, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexPostfix(ast.Send node, Element element,
      ast.Node index, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      MethodElement setter,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterCompoundIndexSet(
      ast.SendSet node,
      Element element,
      MethodElement setter,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperCompoundIndexSet(ast.SendSet node, Element element,
      ast.Node index, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldCompound(ast.Send node, FieldElement field,
      AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldCompound(ast.Send node, FieldElement field,
      AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldPrefix(
      ast.Send node, FieldElement field, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperPrefix(
      ast.SendSet node, Element element, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperPostfix(
      ast.SendSet node, Element element, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperCompound(ast.Send node, Element element,
      AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldPostfix(
      ast.Send node, FieldElement field, IncDecOperator operator, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldFieldCompound(ast.Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterSetterCompound(ast.Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodSetterCompound(ast.Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodCompound(ast.Send node, MethodElement method,
      AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterCompound(ast.SendSet node, Element element,
      SetterElement setter, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterCompound(ast.Send node, GetterElement getter,
      Element element, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldSetterCompound(ast.Send node, FieldElement field,
      FunctionElement setter, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterFieldCompound(ast.Send node, FunctionElement getter,
      FieldElement field, AssignmentOperator operator, ast.Node rhs, _) {
    handleSuperSendSet(node);
  }

  @override
  void visitIndexSet(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    generateDynamicSend(node);
  }

  @override
  void visitCompoundIndexSet(ast.SendSet node, ast.Node receiver,
      ast.Node index, AssignmentOperator operator, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  @override
  void visitIndexPrefix(ast.Send node, ast.Node receiver, ast.Node index,
      IncDecOperator operator, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  @override
  void visitIndexPostfix(ast.Send node, ast.Node receiver, ast.Node index,
      IncDecOperator operator, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  void handleIndexSendSet(ast.SendSet node) {
    ast.Operator op = node.assignmentOperator;
    if ("=" == op.source) {
      internalError(node, "Unexpected index set.");
    } else {
      visit(node.receiver);
      HInstruction receiver = pop();
      Link<ast.Node> arguments = node.arguments;
      HInstruction index;
      if (node.isIndex) {
        visit(arguments.head);
        arguments = arguments.tail;
        index = pop();
      }

      pushInvokeDynamic(node, elements.getGetterSelectorInComplexSendSet(node),
          elementInferenceResults.typeOfGetter(node), [receiver, index]);
      HInstruction getterInstruction = pop();
      if (node.isIfNullAssignment) {
        // Compile x[i] ??= e as:
        //   t1 = x[i]
        //   if (t1 == null)
        //      t1 = x[i] = e;
        //   result = t1
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleIfNull(() => stack.add(getterInstruction), () {
          visit(arguments.head);
          HInstruction value = pop();
          pushInvokeDynamic(
              node,
              elements.getSelector(node),
              elementInferenceResults.typeOfSend(node),
              [receiver, index, value]);
          pop();
          stack.add(value);
        });
      } else {
        handleComplexOperatorSend(node, getterInstruction, arguments);
        HInstruction value = pop();
        pushInvokeDynamic(node, elements.getSelector(node),
            elementInferenceResults.typeOfSend(node), [receiver, index, value]);
        pop();
        if (node.isPostfix) {
          stack.add(getterInstruction);
        } else {
          stack.add(value);
        }
      }
    }
  }

  @override
  void visitThisPropertySet(ast.SendSet node, Name name, ast.Node rhs, _) {
    generateInstanceSetterWithCompiledReceiver(
        node, localsHandler.readThis(), visitAndPop(rhs));
  }

  @override
  void visitDynamicPropertySet(
      ast.SendSet node, ast.Node receiver, Name name, ast.Node rhs, _) {
    generateInstanceSetterWithCompiledReceiver(
        node, generateInstanceSendReceiver(node), visitAndPop(rhs));
  }

  @override
  void visitIfNotNullDynamicPropertySet(
      ast.SendSet node, ast.Node receiver, Name name, ast.Node rhs, _) {
    // compile e?.x = e2 to:
    //
    // t1 = e
    // if (t1 == null)
    //   result = t1 // same as result = null
    // else
    //   result = e.x = e2
    HInstruction receiverInstruction;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(
        () {
          receiverInstruction = generateInstanceSendReceiver(node);
          pushCheckNull(receiverInstruction);
        },
        () => stack.add(receiverInstruction),
        () {
          generateInstanceSetterWithCompiledReceiver(
              node, receiverInstruction, visitAndPop(rhs));
        });
  }

  @override
  void visitParameterSet(
      ast.SendSet node, ParameterElement parameter, ast.Node rhs, _) {
    generateNonInstanceSetter(node, parameter, visitAndPop(rhs));
  }

  @override
  void visitFinalParameterSet(
      ast.SendSet node, ParameterElement parameter, ast.Node rhs, _) {
    generateNoSuchSetter(node, parameter, visitAndPop(rhs));
  }

  @override
  void visitLocalVariableSet(
      ast.SendSet node, LocalVariableElement variable, ast.Node rhs, _) {
    generateNonInstanceSetter(node, variable, visitAndPop(rhs));
  }

  @override
  void visitFinalLocalVariableSet(
      ast.SendSet node, LocalVariableElement variable, ast.Node rhs, _) {
    generateNoSuchSetter(node, variable, visitAndPop(rhs));
  }

  @override
  void visitLocalFunctionSet(
      ast.SendSet node, LocalFunctionElement function, ast.Node rhs, _) {
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitTopLevelFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitFinalTopLevelFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitTopLevelGetterSet(
      ast.SendSet node, GetterElement getter, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, getter, visitAndPop(rhs));
  }

  @override
  void visitTopLevelSetterSet(
      ast.SendSet node, SetterElement setter, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, setter, visitAndPop(rhs));
  }

  @override
  void visitTopLevelFunctionSet(
      ast.SendSet node, MethodElement function, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitStaticFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitFinalStaticFieldSet(
      ast.SendSet node, FieldElement field, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitStaticGetterSet(
      ast.SendSet node, GetterElement getter, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, getter, visitAndPop(rhs));
  }

  @override
  void visitStaticSetterSet(
      ast.SendSet node, SetterElement setter, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, setter, visitAndPop(rhs));
  }

  @override
  void visitStaticFunctionSet(
      ast.SendSet node, MethodElement function, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitUnresolvedSet(ast.SendSet node, Element element, ast.Node rhs, _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, element, visitAndPop(rhs));
  }

  @override
  void visitClassTypeLiteralSet(
      ast.SendSet node, TypeConstantExpression constant, ast.Node rhs, _) {
    generateThrowNoSuchMethod(node, constant.name,
        argumentNodes: node.arguments);
  }

  @override
  void visitTypedefTypeLiteralSet(
      ast.SendSet node, TypeConstantExpression constant, ast.Node rhs, _) {
    generateThrowNoSuchMethod(node, constant.name,
        argumentNodes: node.arguments);
  }

  @override
  void visitDynamicTypeLiteralSet(
      ast.SendSet node, TypeConstantExpression constant, ast.Node rhs, _) {
    generateThrowNoSuchMethod(node, constant.name,
        argumentNodes: node.arguments);
  }

  @override
  void visitTypeVariableTypeLiteralSet(
      ast.SendSet node, TypeVariableElement element, ast.Node rhs, _) {
    generateThrowNoSuchMethod(node, element.name,
        argumentNodes: node.arguments);
  }

  void handleCompoundSendSet(ast.SendSet node) {
    Element element = elements[node];
    Element getter = elements[node.selector];

    if (!Elements.isUnresolved(getter) && getter.impliesType) {
      if (node.isIfNullAssignment) {
        // C ??= x is compiled just as C.
        stack.add(addConstant(node.selector));
      } else {
        ast.Identifier selector = node.selector;
        generateThrowNoSuchMethod(node, selector.source,
            argumentNodes: node.arguments);
      }
      return;
    }

    if (Elements.isInstanceSend(node, elements)) {
      void generateAssignment(HInstruction receiver) {
        // desugars `e.x op= e2` to `e.x = e.x op e2`
        generateInstanceGetterWithCompiledReceiver(
            node,
            elements.getGetterSelectorInComplexSendSet(node),
            elementInferenceResults.typeOfGetter(node),
            receiver);
        HInstruction getterInstruction = pop();
        if (node.isIfNullAssignment) {
          SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
          brancher.handleIfNull(() => stack.add(getterInstruction), () {
            visit(node.arguments.head);
            generateInstanceSetterWithCompiledReceiver(node, receiver, pop());
          });
        } else {
          handleComplexOperatorSend(node, getterInstruction, node.arguments);
          HInstruction value = pop();
          generateInstanceSetterWithCompiledReceiver(node, receiver, value);
        }
        if (node.isPostfix) {
          pop();
          stack.add(getterInstruction);
        }
      }

      if (node.isConditional) {
        // generate `e?.x op= e2` as:
        //   t1 = e
        //   t1 == null ? t1 : (t1.x = t1.x op e2);
        HInstruction receiver;
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleConditional(() {
          receiver = generateInstanceSendReceiver(node);
          pushCheckNull(receiver);
        }, () => stack.add(receiver), () => generateAssignment(receiver));
      } else {
        generateAssignment(generateInstanceSendReceiver(node));
      }
      return;
    }

    if (getter.isMalformed) {
      generateStaticUnresolvedGet(node, getter);
    } else if (getter.isField) {
      generateStaticFieldGet(node, getter);
    } else if (getter.isGetter) {
      generateStaticGetterGet(node, getter);
    } else if (getter.isFunction) {
      generateStaticFunctionGet(node, getter);
    } else if (getter.isLocal) {
      handleLocalGet(node, getter);
    } else {
      internalError(node, "Unexpected getter: $getter");
    }
    HInstruction getterInstruction = pop();
    if (node.isIfNullAssignment) {
      SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
      brancher.handleIfNull(() => stack.add(getterInstruction), () {
        visit(node.arguments.head);
        generateNonInstanceSetter(node, element, pop());
      });
    } else {
      handleComplexOperatorSend(node, getterInstruction, node.arguments);
      HInstruction value = pop();
      generateNonInstanceSetter(node, element, value);
    }
    if (node.isPostfix) {
      pop();
      stack.add(getterInstruction);
    }
  }

  @override
  void handleDynamicCompounds(
      ast.Send node, ast.Node receiver, Name name, CompoundRhs rhs, _) {
    handleCompoundSendSet(node);
  }

  @override
  void handleLocalCompounds(
      ast.SendSet node, LocalElement local, CompoundRhs rhs, _,
      {bool isSetterValid}) {
    handleCompoundSendSet(node);
  }

  @override
  void handleStaticCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    handleCompoundSendSet(node);
  }

  @override
  handleDynamicSetIfNulls(
      ast.Send node, ast.Node receiver, Name name, ast.Node rhs, arg) {
    handleCompoundSendSet(node);
  }

  @override
  handleLocalSetIfNulls(ast.SendSet node, LocalElement local, ast.Node rhs, arg,
      {bool isSetterValid}) {
    handleCompoundSendSet(node);
  }

  @override
  handleStaticSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      arg) {
    handleCompoundSendSet(node);
  }

  @override
  handleSuperSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      arg) {
    handleSuperSendSet(node);
  }

  @override
  handleSuperIndexSetIfNull(ast.SendSet node, Element indexFunction,
      Element indexSetFunction, ast.Node index, ast.Node rhs, arg,
      {bool isGetterValid, bool isSetterValid}) {
    handleCompoundSendSet(node);
  }

  @override
  visitIndexSetIfNull(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, arg,
      {bool isGetterValid, bool isSetterValid}) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  @override
  handleTypeLiteralConstantSetIfNulls(
      ast.SendSet node, ConstantExpression constant, ast.Node rhs, arg) {
    // The type variable is never `null`.
    generateConstantTypeLiteral(node);
  }

  @override
  visitTypeVariableTypeLiteralSetIfNull(
      ast.Send node, TypeVariableElement element, ast.Node rhs, arg) {
    // The type variable is never `null`.
    generateTypeVariableLiteral(node, element.type);
  }

  void visitLiteralInt(ast.LiteralInt node) {
    stack.add(graph.addConstantInt(node.value, closedWorld));
  }

  void visitLiteralDouble(ast.LiteralDouble node) {
    stack.add(graph.addConstantDouble(node.value, closedWorld));
  }

  void visitLiteralBool(ast.LiteralBool node) {
    stack.add(graph.addConstantBool(node.value, closedWorld));
  }

  void visitLiteralString(ast.LiteralString node) {
    stack.add(
        graph.addConstantString(node.dartString.slowToString(), closedWorld));
  }

  void visitLiteralSymbol(ast.LiteralSymbol node) {
    stack.add(addConstant(node));
    registry?.registerConstSymbol(node.slowNameString);
  }

  void visitStringJuxtaposition(ast.StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(
          graph.addConstantString(node.dartString.slowToString(), closedWorld));
      return;
    }
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  void visitLiteralNull(ast.LiteralNull node) {
    stack.add(graph.addConstantNull(closedWorld));
  }

  visitNodeList(ast.NodeList node) {
    for (Link<ast.Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      if (isAborted()) {
        reporter.reportHintMessage(
            link.head, MessageKind.GENERIC, {'text': 'dead code'});
      } else {
        visit(link.head);
      }
    }
  }

  void visitParenthesizedExpression(ast.ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitOperator(ast.Operator node) {
    // Operators are intercepted in their surrounding Send nodes.
    reporter.internalError(
        node, 'SsaBuilder.visitOperator should not be called.');
  }

  visitCascade(ast.Cascade node) {
    visit(node.expression);
    // Remove the result and reveal the duplicated receiver on the stack.
    pop();
  }

  visitCascadeReceiver(ast.CascadeReceiver node) {
    visit(node.expression);
    dup();
  }

  visitRethrow(ast.Rethrow node) {
    HInstruction exception = rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(closedWorld);
      reporter.internalError(node, 'rethrowableException should not be null.');
    }
    handleInTryStatement();
    closeAndGotoExit(new HThrow(
        exception, sourceInformationBuilder.buildThrow(node),
        isRethrow: true));
  }

  visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    ConstructorElement targetConstructor =
        elements.getRedirectingTargetConstructor(node).implementation;
    ConstructorElement redirectingConstructor = sourceElement.implementation;
    List<HInstruction> inputs = <HInstruction>[];
    FunctionSignature targetSignature = targetConstructor.functionSignature;
    FunctionSignature redirectingSignature =
        redirectingConstructor.functionSignature;

    List<Element> targetRequireds = targetSignature.requiredParameters;
    List<Element> redirectingRequireds =
        redirectingSignature.requiredParameters;

    List<Element> targetOptionals = targetSignature.orderedOptionalParameters;
    List<Element> redirectingOptionals =
        redirectingSignature.orderedOptionalParameters;

    // TODO(25579): This code can do the wrong thing redirecting constructor and
    // the target do not correspond. It is correct if there is no
    // warning. Ideally the redirecting constructor and the target would be the
    // same function.

    void loadLocal(ParameterElement parameter) {
      inputs.add(localsHandler.readLocal(parameter));
    }

    void loadPosition(int position, ParameterElement optionalParameter) {
      if (position < redirectingRequireds.length) {
        loadLocal(redirectingRequireds[position]);
      } else if (position < redirectingSignature.parameterCount &&
          !redirectingSignature.optionalParametersAreNamed) {
        loadLocal(redirectingOptionals[position - redirectingRequireds.length]);
      } else if (optionalParameter != null) {
        inputs.add(handleConstantForOptionalParameter(optionalParameter));
      } else {
        // Wrong.
        inputs.add(graph.addConstantNull(closedWorld));
      }
    }

    int position = 0;

    for (ParameterElement _ in targetRequireds) {
      loadPosition(position++, null);
    }

    if (targetOptionals.isNotEmpty) {
      if (targetSignature.optionalParametersAreNamed) {
        for (ParameterElement parameter in targetOptionals) {
          ParameterElement redirectingParameter = redirectingOptionals
              .firstWhere((p) => p.name == parameter.name, orElse: () => null);
          if (redirectingParameter == null) {
            inputs.add(handleConstantForOptionalParameter(parameter));
          } else {
            inputs.add(localsHandler.readLocal(redirectingParameter));
          }
        }
      } else {
        for (ParameterElement parameter in targetOptionals) {
          loadPosition(position++, parameter);
        }
      }
    }

    ClassElement targetClass = targetConstructor.enclosingClass;
    if (rtiNeed.classNeedsRti(targetClass)) {
      ClassElement cls = redirectingConstructor.enclosingClass;
      ResolutionDartType targetType =
          redirectingConstructor.computeEffectiveTargetType(cls.thisType);
      targetType = localsHandler.substInContext(targetType);
      if (targetType is ResolutionInterfaceType) {
        targetType.typeArguments.forEach((ResolutionDartType argument) {
          inputs.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
        });
      }
    }
    pushInvokeStatic(node, targetConstructor.declaration, inputs);
    HInstruction value = pop();
    emitReturn(value, node);
  }

  /// Returns true if the [type] is a valid return type for an asynchronous
  /// function.
  ///
  /// Asynchronous functions return a `Future`, and a valid return is thus
  /// either dynamic, Object, or Future.
  ///
  /// We do not accept the internal Future implementation class.
  bool isValidAsyncReturnType(ResolutionDartType type) {
    assert(isBuildingAsyncFunction);
    // TODO(sigurdm): In an internal library a function could be declared:
    //
    // _FutureImpl foo async => 1;
    //
    // This should be valid (because the actual value returned from an async
    // function is a `_FutureImpl`), but currently false is returned in this
    // case.
    return type.isDynamic ||
        type.isObject ||
        (type is ResolutionInterfaceType &&
            type.element == commonElements.futureClass);
  }

  visitReturn(ast.Return node) {
    if (identical(node.beginToken.stringValue, 'native')) {
      native.handleSsaNative(this, node.expression);
      return;
    }
    HInstruction value;
    if (node.expression == null) {
      value = graph.addConstantNull(closedWorld);
    } else {
      visit(node.expression);
      value = pop();
      if (isBuildingAsyncFunction) {
        if (options.enableTypeAssertions &&
            !isValidAsyncReturnType(returnType)) {
          String message = "Async function returned a Future, "
              "was declared to return a $returnType.";
          generateTypeError(node, message);
          pop();
          return;
        }
      } else {
        value = typeBuilder.potentiallyCheckOrTrustType(value, returnType);
      }
    }

    handleInTryStatement();
    emitReturn(value, node);
  }

  visitThrow(ast.Throw node) {
    visitThrowExpression(node.expression);
    if (isReachable) {
      handleInTryStatement();
      push(new HThrowExpression(
          pop(), sourceInformationBuilder.buildThrow(node)));
      isReachable = false;
    }
  }

  visitYield(ast.Yield node) {
    visit(node.expression);
    HInstruction yielded = pop();
    add(new HYield(yielded, node.hasStar));
  }

  visitAwait(ast.Await node) {
    visit(node.expression);
    HInstruction awaited = pop();
    // TODO(herhut): Improve this type.
    push(new HAwait(awaited,
        new TypeMask.subclass(commonElements.objectClass, closedWorld)));
  }

  visitTypeAnnotation(ast.TypeAnnotation node) {
    reporter.internalError(node, 'Visiting type annotation in SSA builder.');
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(isReachable);
    for (Link<ast.Node> link = node.definitions.nodes;
        !link.isEmpty;
        link = link.tail) {
      ast.Node definition = link.head;
      LocalElement local = elements[definition];
      if (definition is ast.Identifier) {
        HInstruction initialValue = graph.addConstantNull(closedWorld);
        localsHandler.updateLocal(local, initialValue);
      } else {
        ast.SendSet node = definition;
        generateNonInstanceSetter(
            node, local, visitAndPop(node.arguments.first));
        pop(); // Discard value.
      }
    }
  }

  HInstruction setRtiIfNeeded(HInstruction object, ast.Node node) {
    ResolutionInterfaceType type =
        localsHandler.substInContext(elements.getType(node));
    if (!rtiNeed.classNeedsRti(type.element) || type.treatAsRaw) {
      return object;
    }
    List<HInstruction> arguments = <HInstruction>[];
    for (ResolutionDartType argument in type.typeArguments) {
      arguments.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
    }
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfoWithTypeArguments(type, arguments, object);
  }

  visitLiteralList(ast.LiteralList node) {
    HInstruction instruction;

    if (node.isConst) {
      instruction = addConstant(node);
    } else {
      List<HInstruction> inputs = <HInstruction>[];
      for (Link<ast.Node> link = node.elements.nodes;
          !link.isEmpty;
          link = link.tail) {
        visit(link.head);
        inputs.add(pop());
      }
      instruction = buildLiteralList(inputs);
      add(instruction);
      instruction = setRtiIfNeeded(instruction, node);
    }

    TypeMask type = _inferredTypeOfListLiteral(node);
    if (!type.containsAll(closedWorld)) {
      instruction.instructionType = type;
    }
    stack.add(instruction);
  }

  _inferredTypeOfNewList(ast.Send node) =>
      _resultOf(sourceElement).typeOfNewList(node) ?? commonMasks.dynamicType;

  _inferredTypeOfListLiteral(ast.LiteralList node) =>
      _resultOf(sourceElement).typeOfListLiteral(node) ??
      commonMasks.dynamicType;

  visitConditional(ast.Conditional node) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(() => visit(node.condition),
        () => visit(node.thenExpression), () => visit(node.elseExpression));
  }

  visitStringInterpolation(ast.StringInterpolation node) {
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  visitStringInterpolationPart(ast.StringInterpolationPart node) {
    // The parts are iterated in visitStringInterpolation.
    reporter.internalError(
        node, 'SsaBuilder.visitStringInterpolation should not be called.');
  }

  visitEmptyStatement(ast.EmptyStatement node) {
    // Do nothing, empty statement.
  }

  visitModifiers(ast.Modifiers node) {
    throw new SpannableAssertionFailure(
        node, 'SsaFromAstMixin.visitModifiers not implemented.');
  }

  visitBreakStatement(ast.BreakStatement node) {
    assert(!isAborted());
    handleInTryStatement();
    JumpTarget target = elements.getTargetOf(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateBreak();
    } else {
      LabelDefinition label = elements.getTargetLabel(node);
      handler.generateBreak(label);
    }
  }

  visitContinueStatement(ast.ContinueStatement node) {
    handleInTryStatement();
    JumpTarget target = elements.getTargetOf(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateContinue();
    } else {
      LabelDefinition label = elements.getTargetLabel(node);
      assert(label != null);
      handler.generateContinue(label);
    }
  }

  /**
   * Creates a [JumpHandler] for a statement. The node must be a jump
   * target. If there are no breaks or continues targeting the statement,
   * a special "null handler" is returned.
   *
   * [isLoopJump] is [:true:] when the jump handler is for a loop. This is used
   * to distinguish the synthesized loop created for a switch statement with
   * continue statements from simple switch statements.
   */
  JumpHandler createJumpHandler(ast.Statement node, JumpTarget jumpTarget,
      {bool isLoopJump}) {
    if (jumpTarget == null || !identical(jumpTarget.statement, node)) {
      // No breaks or continues to this node.
      return new NullJumpHandler(reporter);
    }
    if (isLoopJump && node is ast.SwitchStatement) {
      // Create a special jump handler for loops created for switch statements
      // with continue statements.
      return new AstSwitchCaseJumpHandler(this, jumpTarget, node);
    }
    return new JumpHandler(this, jumpTarget);
  }

  visitAsyncForIn(ast.AsyncForIn node) {
    // The async-for is implemented with a StreamIterator.
    HInstruction streamIterator;

    visit(node.expression);
    HInstruction expression = pop();
    ConstructorElement constructor = commonElements.streamIteratorConstructor;
    pushInvokeStatic(
        node, constructor, [expression, graph.addConstantNull(closedWorld)]);
    streamIterator = pop();

    void buildInitializer() {}

    HInstruction buildCondition() {
      Selector selector = Selectors.moveNext;
      TypeMask mask = elementInferenceResults.typeOfIteratorMoveNext(node);
      pushInvokeDynamic(node, selector, mask, [streamIterator]);
      HInstruction future = pop();
      push(new HAwait(future,
          new TypeMask.subclass(commonElements.objectClass, closedWorld)));
      return popBoolified();
    }

    void buildBody() {
      Selector call = Selectors.current;
      TypeMask callMask = elementInferenceResults.typeOfIteratorCurrent(node);
      pushInvokeDynamic(node, call, callMask, [streamIterator]);

      ast.Node identifier = node.declaredIdentifier;
      Element variable = elements.getForInVariable(node);
      Selector selector = elements.getSelector(identifier);
      HInstruction value = pop();
      if (identifier.asSend() != null &&
          Elements.isInstanceSend(identifier, elements)) {
        TypeMask mask = elementInferenceResults.typeOfSend(identifier);
        HInstruction receiver = generateInstanceSendReceiver(identifier);
        assert(receiver != null);
        generateInstanceSetterWithCompiledReceiver(null, receiver, value,
            selector: selector, mask: mask, location: identifier);
      } else {
        generateNonInstanceSetter(null, variable, value, location: identifier);
      }
      pop(); // Pop the value pushed by the setter call.

      visit(node.body);
    }

    void buildUpdate() {}

    buildProtectedByFinally(() {
      loopHandler.handleLoop(
          node,
          closureDataLookup.getClosureRepresentationInfoForLoop(node),
          elements.getTargetDefinition(node),
          buildInitializer,
          buildCondition,
          buildUpdate,
          buildBody);
    }, () {
      pushInvokeDynamic(node, Selectors.cancel, null, [streamIterator]);
      push(new HAwait(pop(),
          new TypeMask.subclass(commonElements.objectClass, closedWorld)));
      pop();
    });
  }

  visitSyncForIn(ast.SyncForIn node) {
    // The 'get iterator' selector for this node has the inferred receiver type.
    // If the receiver supports JavaScript indexing we generate an indexing loop
    // instead of allocating an iterator object.

    // This scheme recognizes for-in on direct lists.  It does not recognize all
    // uses of ArrayIterator.  They still occur when the receiver is an Iterable
    // with a `get iterator` method that delegates to another Iterable and the
    // method is inlined.  We would require full scalar replacement in that
    // case.

    TypeMask mask = elementInferenceResults.typeOfIterator(node);

    if (mask != null &&
        mask.satisfies(commonElements.jsIndexableClass, closedWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(commonElements.jsStringClass, closedWorld)) {
      return buildSyncForInIndexable(node, mask);
    }
    buildSyncForInIterator(node);
  }

  buildSyncForInIterator(ast.SyncForIn node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <declaredIdentifier> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;

    void buildInitializer() {
      Selector selector = Selectors.iterator;
      TypeMask mask = elementInferenceResults.typeOfIterator(node);
      visit(node.expression);
      HInstruction receiver = pop();
      pushInvokeDynamic(node, selector, mask, [receiver]);
      iterator = pop();
    }

    HInstruction buildCondition() {
      Selector selector = Selectors.moveNext;
      TypeMask mask = elementInferenceResults.typeOfIteratorMoveNext(node);
      pushInvokeDynamic(node, selector, mask, [iterator]);
      return popBoolified();
    }

    void buildBody() {
      Selector call = Selectors.current;
      TypeMask mask = elementInferenceResults.typeOfIteratorCurrent(node);
      pushInvokeDynamic(node, call, mask, [iterator]);
      buildAssignLoopVariable(node, pop());
      visit(node.body);
    }

    loopHandler.handleLoop(
        node,
        closureDataLookup.getClosureRepresentationInfoForLoop(node),
        elements.getTargetDefinition(node),
        buildInitializer,
        buildCondition,
        () {},
        buildBody);
  }

  buildAssignLoopVariable(ast.ForIn node, HInstruction value) {
    ast.Node identifier = node.declaredIdentifier;
    Element variable = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);

    if (identifier.asSend() != null &&
        Elements.isInstanceSend(identifier, elements)) {
      TypeMask mask = elementInferenceResults.typeOfSend(identifier);
      HInstruction receiver = generateInstanceSendReceiver(identifier);
      assert(receiver != null);
      generateInstanceSetterWithCompiledReceiver(null, receiver, value,
          selector: selector, mask: mask, location: identifier);
    } else {
      generateNonInstanceSetter(null, variable, value, location: identifier);
    }
    pop(); // Discard the value pushed by the setter call.
  }

  buildSyncForInIndexable(ast.ForIn node, TypeMask arrayType) {
    // Generate a structure equivalent to:
    //
    //     int end = a.length;
    //     for (int i = 0;
    //          i < a.length;
    //          checkConcurrentModificationError(a.length == end, a), ++i) {
    //       <declaredIdentifier> = a[i];
    //       <body>
    //     }
    ExecutableElement loopVariable = elements.getForInVariable(node);
    SyntheticLocal indexVariable =
        new SyntheticLocal('_i', loopVariable, target);
    TypeMask boolType = commonMasks.boolType;

    // These variables are shared by initializer, condition, body and update.
    HInstruction array; // Set in buildInitializer.
    bool isFixed; // Set in buildInitializer.
    HInstruction originalLength = null; // Set for growable lists.

    HInstruction buildGetLength() {
      HInstruction result = new HGetLength(array, commonMasks.positiveIntType,
          isAssignable: !isFixed);
      add(result);
      return result;
    }

    void buildConcurrentModificationErrorCheck() {
      if (originalLength == null) return;
      // The static call checkConcurrentModificationError() is expanded in
      // codegen to:
      //
      //     array.length == _end || throwConcurrentModificationError(array)
      //
      HInstruction length = buildGetLength();
      push(new HIdentity(length, originalLength, null, boolType));
      pushInvokeStatic(node, commonElements.checkConcurrentModificationError,
          [pop(), array]);
      pop();
    }

    void buildInitializer() {
      visit(node.expression);
      array = pop();
      isFixed = isFixedLength(array.instructionType, closedWorld);
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, closedWorld));
      originalLength = buildGetLength();
    }

    HInstruction buildCondition() {
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction length = buildGetLength();
      HInstruction compare = new HLess(index, length, null, boolType);
      add(compare);
      return compare;
    }

    void buildBody() {
      // If we had mechanically inlined ArrayIterator.moveNext(), it would have
      // inserted the ConcurrentModificationError check as part of the
      // condition.  It is not necessary on the first iteration since there is
      // no code between calls to `get iterator` and `moveNext`, so the test is
      // moved to the loop update.

      // Find a type for the element. Use the element type of the indexer of the
      // array, as this is stronger than the iterator's `get current` type, for
      // example, `get current` includes null.
      // TODO(sra): The element type of a container type mask might be better.
      Selector selector = new Selector.index();
      TypeMask type = TypeMaskFactory.inferredTypeForSelector(
          selector, arrayType, globalInferenceResults);

      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction value = new HIndex(array, index, null, type);
      add(value);

      buildAssignLoopVariable(node, value);
      visit(node.body);
    }

    void buildUpdate() {
      // See buildBody as to why we check here.
      buildConcurrentModificationErrorCheck();

      // TODO(sra): It would be slightly shorter to generate `a[i++]` in the
      // body (and that more closely follows what an inlined iterator would do)
      // but the code is horrible as `i+1` is carried around the loop in an
      // additional variable.
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction one = graph.addConstantInt(1, closedWorld);
      HInstruction addInstruction =
          new HAdd(index, one, null, commonMasks.positiveIntType);
      add(addInstruction);
      localsHandler.updateLocal(indexVariable, addInstruction);
    }

    loopHandler.handleLoop(
        node,
        closureDataLookup.getClosureRepresentationInfoForLoop(node),
        elements.getTargetDefinition(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody);
  }

  visitLabel(ast.Label node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitLabel.');
  }

  visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop ||
        body is ast.SwitchStatement ||
        Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
      return;
    }
    JumpTarget targetElement = elements.getTargetDefinition(body);
    LocalsHandler beforeLocals = new LocalsHandler.from(localsHandler);
    assert(targetElement.isBreakTarget);
    JumpHandler handler = new JumpHandler(this, targetElement);
    // Introduce a new basic block.
    HBasicBlock entryBlock = openNewBlock();
    visit(body);
    SubGraph bodyGraph = new SubGraph(entryBlock, lastOpenedBlock);

    HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(joinBlock);
      breakHandlers.add(locals);
    });
    bool hasBreak = breakHandlers.length > 0;
    if (!isAborted()) {
      goto(current, joinBlock);
      breakHandlers.add(localsHandler);
    }
    open(joinBlock);
    localsHandler = beforeLocals.mergeMultiple(breakHandlers, joinBlock);

    if (hasBreak) {
      // There was at least one reachable break, so the label is needed.
      entryBlock.setBlockFlow(
          new HLabeledBlockInformation(
              new HSubGraphBlockInformation(bodyGraph), handler.labels),
          joinBlock);
    }
    handler.close();
  }

  visitLiteralMap(ast.LiteralMap node) {
    if (node.isConst) {
      stack.add(addConstant(node));
      return;
    }
    List<HInstruction> listInputs = <HInstruction>[];
    for (Link<ast.Node> link = node.entries.nodes;
        !link.isEmpty;
        link = link.tail) {
      visit(link.head);
      listInputs.add(pop());
      listInputs.add(pop());
    }

    ConstructorElement listConstructor;
    List<HInstruction> inputs = <HInstruction>[];

    if (listInputs.isEmpty) {
      listConstructor = commonElements.mapLiteralConstructorEmpty;
    } else {
      listConstructor = commonElements.mapLiteralConstructor;
      HLiteralList keyValuePairs = buildLiteralList(listInputs);
      add(keyValuePairs);
      inputs.add(keyValuePairs);
    }

    assert(listConstructor.isFactoryConstructor);

    ConstructorElement constructorElement = listConstructor;
    listConstructor = constructorElement.effectiveTarget;

    ResolutionInterfaceType type = elements.getType(node);
    ResolutionDartType expectedType =
        constructorElement.computeEffectiveTargetType(type);
    expectedType = localsHandler.substInContext(expectedType);

    ClassElement cls = listConstructor.enclosingClass;

    MethodElement createFunction = listConstructor;
    if (expectedType is ResolutionInterfaceType && rtiNeed.classNeedsRti(cls)) {
      List<HInstruction> typeInputs = <HInstruction>[];
      expectedType.typeArguments.forEach((ResolutionDartType argument) {
        typeInputs
            .add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) => input.isNull())) {
        if (listInputs.isEmpty) {
          createFunction = commonElements.mapLiteralUntypedEmptyMaker;
        } else {
          createFunction = commonElements.mapLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If rti is needed and the map literal has no type parameters,
    // 'constructor' is a static function that forwards the call to the factory
    // constructor without type parameters.
    assert(createFunction is ConstructorElement ||
        createFunction is FunctionElement);

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).
    TypeMask mapType = new TypeMask.nonNullSubtype(
        commonElements.mapLiteralClass, closedWorld);
    TypeMask returnTypeMask = TypeMaskFactory.inferredReturnTypeForElement(
        createFunction, globalInferenceResults);
    TypeMask instructionType =
        mapType.intersection(returnTypeMask, closedWorld);

    addInlinedInstantiation(expectedType);
    pushInvokeStatic(node, createFunction, inputs,
        typeMask: instructionType, instanceType: expectedType);
    removeInlinedInstantiation(expectedType);
  }

  visitLiteralMapEntry(ast.LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(ast.NamedArgument node) {
    visit(node.expression);
  }

  Map<ast.CaseMatch, ConstantValue> buildSwitchCaseConstants(
      ast.SwitchStatement node) {
    Map<ast.CaseMatch, ConstantValue> constants =
        new Map<ast.CaseMatch, ConstantValue>();
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.CaseMatch) {
          ast.CaseMatch match = labelOrCase;
          ConstantValue constant = getConstantForNode(match.expression);
          constants[labelOrCase] = constant;
        }
      }
    }
    return constants;
  }

  visitSwitchStatement(ast.SwitchStatement node) {
    Map<ast.CaseMatch, ConstantValue> constants =
        buildSwitchCaseConstants(node);

    // The switch case indices must match those computed in
    // [SwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<ast.SwitchCase, int> caseIndex = new Map<ast.SwitchCase, int>();
    int switchIndex = 1;
    bool hasDefault = false;
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        ast.Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelDefinition labelElement = elements.getLabelDefinition(label);
          if (labelElement != null && labelElement.isContinueTarget) {
            hasContinue = true;
          }
        }
      }
      if (switchCase.isDefaultCase) {
        hasDefault = true;
      }
      caseIndex[switchCase] = switchIndex;
      switchIndex++;
    }
    if (!hasContinue) {
      // If the switch statement has no switch cases targeted by continue
      // statements we encode the switch statement directly.
      buildSimpleSwitchStatement(node, constants);
    } else {
      buildComplexSwitchStatement(node, constants, caseIndex, hasDefault);
    }
  }

  /**
   * Builds a simple switch statement which does not handle uses of continue
   * statements to labeled switch cases.
   */
  void buildSimpleSwitchStatement(
      ast.SwitchStatement node, Map<ast.CaseMatch, ConstantValue> constants) {
    JumpHandler jumpHandler = createJumpHandler(
        node, elements.getTargetDefinition(node),
        isLoopJump: false);
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }

    Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
      List<ConstantValue> constantList = <ConstantValue>[];
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.CaseMatch) {
          constantList.add(constants[labelOrCase]);
        }
      }
      return constantList;
    }

    bool isDefaultCase(ast.SwitchCase switchCase) {
      return switchCase.isDefaultCase;
    }

    void buildSwitchCase(ast.SwitchCase node) {
      visit(node.statements);
    }

    handleSwitch(node, jumpHandler, buildExpression, node.cases, getConstants,
        isDefaultCase, buildSwitchCase);
    jumpHandler.close();
  }

  /**
   * Builds a switch statement that can handle arbitrary uses of continue
   * statements to labeled switch cases.
   */
  void buildComplexSwitchStatement(
      ast.SwitchStatement node,
      Map<ast.CaseMatch, ConstantValue> constants,
      Map<ast.SwitchCase, int> caseIndex,
      bool hasDefault) {
    // If the switch statement has switch cases targeted by continue
    // statements we create the following encoding:
    //
    //   switch (e) {
    //     l_1: case e0: s_1; break;
    //     l_2: case e1: s_2; continue l_i;
    //     ...
    //     l_n: default: s_n; continue l_j;
    //   }
    //
    // is encoded as
    //
    //   var target;
    //   switch (e) {
    //     case e1: target = 1; break;
    //     case e2: target = 2; break;
    //     ...
    //     default: target = n; break;
    //   }
    //   l: while (true) {
    //    switch (target) {
    //       case 1: s_1; break l;
    //       case 2: s_2; target = i; continue l;
    //       ...
    //       case n: s_n; target = j; continue l;
    //     }
    //   }

    JumpTarget switchTarget = elements.getTargetDefinition(node);
    HInstruction initialValue = graph.addConstantNull(closedWorld);
    localsHandler.updateLocal(switchTarget, initialValue);

    JumpHandler jumpHandler =
        createJumpHandler(node, switchTarget, isLoopJump: false);
    dynamic switchCases = node.cases;
    if (!hasDefault) {
      // Use [:null:] as the marker for a synthetic default clause.
      // The synthetic default is added because otherwise, there would be no
      // good place to give a default value to the local.
      switchCases = node.cases.nodes.toList()..add(null);
    }
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }

    Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
      List<ConstantValue> constantList = <ConstantValue>[];
      if (switchCase != null) {
        for (ast.Node labelOrCase in switchCase.labelsAndCases) {
          if (labelOrCase is ast.CaseMatch) {
            constantList.add(constants[labelOrCase]);
          }
        }
      }
      return constantList;
    }

    bool isDefaultCase(ast.SwitchCase switchCase) {
      return switchCase == null || switchCase.isDefaultCase;
    }

    void buildSwitchCase(ast.SwitchCase switchCase) {
      if (switchCase != null) {
        // Generate 'target = i; break;' for switch case i.
        int index = caseIndex[switchCase];
        HInstruction value = graph.addConstantInt(index, closedWorld);
        localsHandler.updateLocal(switchTarget, value);
      } else {
        // Generate synthetic default case 'target = null; break;'.
        HInstruction value = graph.addConstantNull(closedWorld);
        localsHandler.updateLocal(switchTarget, value);
      }
      jumpTargets[switchTarget].generateBreak();
    }

    handleSwitch(node, jumpHandler, buildExpression, switchCases, getConstants,
        isDefaultCase, buildSwitchCase);
    jumpHandler.close();

    HInstruction buildCondition() => graph.addConstantBool(true, closedWorld);

    void buildSwitch() {
      HInstruction buildExpression() {
        return localsHandler.readLocal(switchTarget);
      }

      Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
        return <ConstantValue>[constantSystem.createInt(caseIndex[switchCase])];
      }

      void buildSwitchCase(ast.SwitchCase switchCase) {
        visit(switchCase.statements);
        if (!isAborted()) {
          // Ensure that we break the loop if the case falls through. (This
          // is only possible for the last case.)
          jumpTargets[switchTarget].generateBreak();
        }
      }

      // Pass a [NullJumpHandler] because the target for the contained break
      // is not the generated switch statement but instead the loop generated
      // in the call to [handleLoop] below.
      handleSwitch(
          node,
          new NullJumpHandler(reporter),
          buildExpression,
          node.cases,
          getConstants,
          (_) => false, // No case is default.
          buildSwitchCase);
    }

    void buildLoop() {
      loopHandler.handleLoop(
          node,
          closureDataLookup.getClosureRepresentationInfoForLoop(node),
          switchTarget,
          () {},
          buildCondition,
          () {},
          buildSwitch);
    }

    if (hasDefault) {
      buildLoop();
    } else {
      // If the switch statement has no default case, surround the loop with
      // a test of the target.
      void buildCondition() {
        js.Template code = js.js.parseForeignJS('#');
        push(new HForeignCode(
            code, commonMasks.boolType, [localsHandler.readLocal(switchTarget)],
            nativeBehavior: native.NativeBehavior.PURE));
      }

      handleIf(
          node: node,
          visitCondition: buildCondition,
          visitThen: buildLoop,
          visitElse: () => {});
    }
  }

  /**
   * Creates a switch statement.
   *
   * [jumpHandler] is the [JumpHandler] for the created switch statement.
   * [buildExpression] creates the switch expression.
   * [switchCases] must be either an [Iterable] of [ast.SwitchCase] nodes or
   *   a [Link] or a [ast.NodeList] of [ast.SwitchCase] nodes.
   * [getConstants] returns the set of constants for a switch case.
   * [isDefaultCase] returns true if the provided switch case should be
   *   considered default for the created switch statement.
   * [buildSwitchCase] creates the statements for the switch case.
   */
  void handleSwitch(
      ast.Node errorNode,
      JumpHandler jumpHandler,
      HInstruction buildExpression(),
      var switchCases,
      Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase),
      bool isDefaultCase(ast.SwitchCase switchCase),
      void buildSwitchCase(ast.SwitchCase switchCase)) {
    HBasicBlock expressionStart = openNewBlock();
    HInstruction expression = buildExpression();
    if (switchCases.isEmpty) {
      return;
    }

    HSwitch switchInstruction = new HSwitch(<HInstruction>[expression]);
    HBasicBlock expressionEnd = close(switchInstruction);
    LocalsHandler savedLocals = localsHandler;

    List<HStatementInformation> statements = <HStatementInformation>[];
    bool hasDefault = false;
    HasNextIterator<ast.Node> caseIterator =
        new HasNextIterator<ast.Node>(switchCases.iterator);
    while (caseIterator.hasNext) {
      ast.SwitchCase switchCase = caseIterator.next();
      HBasicBlock block = graph.addNewBlock();
      for (ConstantValue constant in getConstants(switchCase)) {
        HConstant hConstant = graph.addConstant(constant, closedWorld);
        switchInstruction.inputs.add(hConstant);
        hConstant.usedBy.add(switchInstruction);
        expressionEnd.addSuccessor(block);
      }

      if (isDefaultCase(switchCase)) {
        // An HSwitch has n inputs and n+1 successors, the last being the
        // default case.
        expressionEnd.addSuccessor(block);
        hasDefault = true;
      }
      open(block);
      localsHandler = new LocalsHandler.from(savedLocals);
      buildSwitchCase(switchCase);
      if (!isAborted()) {
        if (caseIterator.hasNext && isReachable) {
          pushInvokeStatic(switchCase, commonElements.fallThroughError, []);
          HInstruction error = pop();
          closeAndGotoExit(new HThrow(error, error.sourceInformation));
        } else if (!isDefaultCase(switchCase)) {
          // If there is no default, we will add one later to avoid
          // the critical edge. So we generate a break statement to make
          // sure the last case does not fall through to the default case.
          jumpHandler.generateBreak();
        }
      }
      statements.add(
          new HSubGraphBlockInformation(new SubGraph(block, lastOpenedBlock)));
    }

    // Add a join-block if necessary.
    // We create [joinBlock] early, and then go through the cases that might
    // want to jump to it. In each case, if we add [joinBlock] as a successor
    // of another block, we also add an element to [caseHandlers] that is used
    // to create the phis in [joinBlock].
    // If we never jump to the join block, [caseHandlers] will stay empty, and
    // the join block is never added to the graph.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseHandlers = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseHandlers.add(locals);
    });
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      assert(false, failedAt(errorNode, 'Continue cannot target a switch.'));
    });
    if (!isAborted()) {
      current.close(new HGoto());
      lastOpenedBlock.addSuccessor(joinBlock);
      caseHandlers.add(localsHandler);
    }
    if (!hasDefault) {
      // Always create a default case, to avoid a critical edge in the
      // graph.
      HBasicBlock defaultCase = addNewBlock();
      expressionEnd.addSuccessor(defaultCase);
      open(defaultCase);
      close(new HGoto());
      defaultCase.addSuccessor(joinBlock);
      caseHandlers.add(savedLocals);
      statements.add(new HSubGraphBlockInformation(
          new SubGraph(defaultCase, defaultCase)));
    }
    assert(caseHandlers.length == joinBlock.predecessors.length);
    if (caseHandlers.length != 0) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseHandlers.length == 1) {
        localsHandler = caseHandlers[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseHandlers, joinBlock);
      }
    } else {
      // The joinblock is not used.
      joinBlock = null;
    }

    HSubExpressionBlockInformation expressionInfo =
        new HSubExpressionBlockInformation(
            new SubExpression(expressionStart, expressionEnd));
    expressionStart.setBlockFlow(
        new HSwitchBlockInformation(
            expressionInfo, statements, jumpHandler.target, jumpHandler.labels),
        joinBlock);

    jumpHandler.close();
  }

  visitSwitchCase(ast.SwitchCase node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitSwitchCase.');
  }

  visitCaseMatch(ast.CaseMatch node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitCaseMatch.');
  }

  /// Calls [buildTry] inside a synthetic try block with [buildFinally] in the
  /// finally block.
  ///
  /// Note that to get the right locals behavior, the code visited by [buildTry]
  /// and [buildFinally] must have been analyzed as if inside a try-statement by
  /// [ClosureTranslator].
  void buildProtectedByFinally(void buildTry(), void buildFinally()) {
    // Save the current locals. The finally block must not reuse the existing
    // locals handler. None of the variables that have been defined in the
    // body-block will be used, but for loops we will add (unnecessary) phis
    // that will reference the body variables. This makes it look as if the
    // variables were used in a non-dominated block.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    HBasicBlock enterBlock = openNewBlock();
    HTry tryInstruction = new HTry();
    close(tryInstruction);
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;

    HBasicBlock startTryBlock;
    HBasicBlock endTryBlock;
    HBasicBlock startFinallyBlock;
    HBasicBlock endFinallyBlock;

    startTryBlock = graph.addNewBlock();
    open(startTryBlock);
    buildTry();
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have two successors: the join block, and
    // the finally block.
    if (!isAborted()) endTryBlock = close(new HExitTry());
    SubGraph bodyGraph = new SubGraph(startTryBlock, lastOpenedBlock);

    SubGraph finallyGraph = null;

    localsHandler = new LocalsHandler.from(savedLocals);
    startFinallyBlock = graph.addNewBlock();
    open(startFinallyBlock);
    buildFinally();
    if (!isAborted()) endFinallyBlock = close(new HGoto());
    tryInstruction.finallyBlock = startFinallyBlock;
    finallyGraph = new SubGraph(startFinallyBlock, lastOpenedBlock);

    HBasicBlock exitBlock = graph.addNewBlock();

    void addExitTrySuccessor(HBasicBlock successor) {
      // Iterate over all blocks created inside this try/catch, and
      // attach successor information to blocks that end with
      // [HExitTry].
      for (int i = startTryBlock.id; i < successor.id; i++) {
        HBasicBlock block = graph.blocks[i];
        var last = block.last;
        if (last is HExitTry) {
          block.addSuccessor(successor);
        }
      }
    }

    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body 2) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    enterBlock.addSuccessor(startFinallyBlock);
    enterBlock.addSuccessor(exitBlock);

    // The body has the finally block as successor.
    if (endTryBlock != null) {
      endTryBlock.addSuccessor(startFinallyBlock);
      endTryBlock.addSuccessor(exitBlock);
    }

    // The finally block has the exit block as successor.
    endFinallyBlock.addSuccessor(exitBlock);

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitly mark this block a predecessor of the catch
    // block and the finally block.
    addExitTrySuccessor(startFinallyBlock);

    // Use the locals handler not altered by the catch and finally
    // blocks.
    // TODO(sigurdm): We can probably do this, because try-variables are boxed.
    // Need to verify.
    localsHandler = savedLocals;
    open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(
            wrapStatementGraph(bodyGraph),
            null, // No catch-variable.
            null, // No catchGraph.
            wrapStatementGraph(finallyGraph)),
        exitBlock);
    inTryStatement = oldInTryStatement;
  }

  visitTryStatement(ast.TryStatement node) {
    // Save the current locals. The catch block and the finally block
    // must not reuse the existing locals handler. None of the variables
    // that have been defined in the body-block will be used, but for
    // loops we will add (unnecessary) phis that will reference the body
    // variables. This makes it look as if the variables were used
    // in a non-dominated block.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    HBasicBlock enterBlock = openNewBlock();
    HTry tryInstruction = new HTry();
    close(tryInstruction);
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;

    HBasicBlock startTryBlock;
    HBasicBlock endTryBlock;
    HBasicBlock startCatchBlock;
    HBasicBlock endCatchBlock;
    HBasicBlock startFinallyBlock;
    HBasicBlock endFinallyBlock;

    startTryBlock = graph.addNewBlock();
    open(startTryBlock);
    visit(node.tryBlock);
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have multiple successors: the join block, and
    // the catch or finally block.
    if (!isAborted()) endTryBlock = close(new HExitTry());
    SubGraph bodyGraph = new SubGraph(startTryBlock, lastOpenedBlock);
    SubGraph catchGraph = null;
    HLocalValue exception = null;

    if (!node.catchBlocks.isEmpty) {
      localsHandler = new LocalsHandler.from(savedLocals);
      startCatchBlock = graph.addNewBlock();
      open(startCatchBlock);
      // Note that the name of this local is irrelevant.
      SyntheticLocal local = localsHandler.createLocal('exception');
      exception = new HLocalValue(local, commonMasks.nonNullType);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeStatic(node, commonElements.exceptionUnwrapper, [exception]);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<ast.Node> link = node.catchBlocks.nodes;

      void pushCondition(ast.CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          ResolutionDartType type = elements.getType(catchBlock.type);
          if (type == null) {
            reporter.internalError(catchBlock.type, 'On with no type.');
          }
          HInstruction condition =
              buildIsNode(catchBlock.type, type, unwrappedException);
          push(condition);
        } else {
          ast.VariableDefinitions declaration = catchBlock.formals.nodes.head;
          HInstruction condition = null;
          if (declaration.type == null) {
            condition = graph.addConstantBool(true, closedWorld);
            stack.add(condition);
          } else {
            // TODO(aprelev@gmail.com): Once old catch syntax is removed
            // "if" condition above and this "else" branch should be deleted as
            // type of declared variable won't matter for the catch
            // condition.
            ResolutionDartType type = elements.getType(declaration.type);
            if (type == null) {
              reporter.internalError(catchBlock, 'Catch with unresolved type.');
            }
            condition = buildIsNode(declaration.type, type, unwrappedException);
            push(condition);
          }
        }
      }

      void visitThen() {
        ast.CatchBlock catchBlock = link.head;
        link = link.tail;
        if (catchBlock.exception != null) {
          LocalVariableElement exceptionVariable =
              elements[catchBlock.exception];
          localsHandler.updateLocal(exceptionVariable, unwrappedException);
        }
        ast.Node trace = catchBlock.trace;
        if (trace != null) {
          pushInvokeStatic(
              trace, commonElements.traceFromException, [exception]);
          HInstruction traceInstruction = pop();
          LocalVariableElement traceVariable = elements[trace];
          localsHandler.updateLocal(traceVariable, traceInstruction);
        }
        visit(catchBlock);
      }

      void visitElse() {
        if (link.isEmpty) {
          closeAndGotoExit(new HThrow(exception, exception.sourceInformation,
              isRethrow: true));
        } else {
          ast.CatchBlock newBlock = link.head;
          handleIf(
              node: node,
              visitCondition: () {
                pushCondition(newBlock);
              },
              visitThen: visitThen,
              visitElse: visitElse);
        }
      }

      ast.CatchBlock firstBlock = link.head;
      handleIf(
          node: node,
          visitCondition: () {
            pushCondition(firstBlock);
          },
          visitThen: visitThen,
          visitElse: visitElse);
      if (!isAborted()) endCatchBlock = close(new HGoto());

      rethrowableException = oldRethrowableException;
      tryInstruction.catchBlock = startCatchBlock;
      catchGraph = new SubGraph(startCatchBlock, lastOpenedBlock);
    }

    SubGraph finallyGraph = null;
    if (node.finallyBlock != null) {
      localsHandler = new LocalsHandler.from(savedLocals);
      startFinallyBlock = graph.addNewBlock();
      open(startFinallyBlock);
      visit(node.finallyBlock);
      if (!isAborted()) endFinallyBlock = close(new HGoto());
      tryInstruction.finallyBlock = startFinallyBlock;
      finallyGraph = new SubGraph(startFinallyBlock, lastOpenedBlock);
    }

    HBasicBlock exitBlock = graph.addNewBlock();

    addOptionalSuccessor(b1, b2) {
      if (b2 != null) b1.addSuccessor(b2);
    }

    addExitTrySuccessor(successor) {
      if (successor == null) return;
      // Iterate over all blocks created inside this try/catch, and
      // attach successor information to blocks that end with
      // [HExitTry].
      for (int i = startTryBlock.id; i < successor.id; i++) {
        HBasicBlock block = graph.blocks[i];
        var last = block.last;
        if (last is HExitTry) {
          block.addSuccessor(successor);
        }
      }
    }

    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body, 2) the catch, 3) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    addOptionalSuccessor(enterBlock, startCatchBlock);
    addOptionalSuccessor(enterBlock, startFinallyBlock);
    enterBlock.addSuccessor(exitBlock);

    // The body has either the catch or the finally block as successor.
    if (endTryBlock != null) {
      assert(startCatchBlock != null || startFinallyBlock != null);
      endTryBlock.addSuccessor(
          startCatchBlock != null ? startCatchBlock : startFinallyBlock);
      endTryBlock.addSuccessor(exitBlock);
    }

    // The catch block has either the finally or the exit block as
    // successor.
    if (endCatchBlock != null) {
      endCatchBlock.addSuccessor(
          startFinallyBlock != null ? startFinallyBlock : exitBlock);
    }

    // The finally block has the exit block as successor.
    if (endFinallyBlock != null) {
      endFinallyBlock.addSuccessor(exitBlock);
    }

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitly mark this block a predecessor of the catch
    // block and the finally block.
    addExitTrySuccessor(startCatchBlock);
    addExitTrySuccessor(startFinallyBlock);

    // Use the locals handler not altered by the catch and finally
    // blocks.
    localsHandler = savedLocals;
    open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(wrapStatementGraph(bodyGraph), exception,
            wrapStatementGraph(catchGraph), wrapStatementGraph(finallyGraph)),
        exitBlock);
    inTryStatement = oldInTryStatement;
  }

  visitCatchBlock(ast.CatchBlock node) {
    visit(node.block);
  }

  visitTypedef(ast.Typedef node) {
    throw new SpannableAssertionFailure(
        node, 'SsaFromAstMixin.visitTypedef not implemented.');
  }

  visitTypeVariable(ast.TypeVariable node) {
    throw new SpannableAssertionFailure(
        node, 'SsaFromAstMixin.visitTypeVariable not implemented.');
  }

  /**
   * This method is invoked before inlining the body of [function] into this
   * [SsaBuilder].
   */
  void enterInlinedMethod(MethodElement function,
      ResolvedAst functionResolvedAst, List<HInstruction> compiledArguments,
      {ResolutionInterfaceType instanceType}) {
    AstInliningState state = new AstInliningState(
        function,
        returnLocal,
        returnType,
        resolvedAst,
        stack,
        localsHandler,
        inTryStatement,
        isCalledOnce(function),
        elementInferenceResults);
    resolvedAst = functionResolvedAst;
    elementInferenceResults = _resultOf(function);
    inliningStack.add(state);

    // Setting up the state of the (AST) builder is performed even when the
    // inlined function is in IR, because the irInliner uses the [returnElement]
    // of the AST builder.
    setupStateForInlining(function, compiledArguments,
        instanceType: instanceType);
  }

  void leaveInlinedMethod() {
    HInstruction result = localsHandler.readLocal(returnLocal);
    AstInliningState state = inliningStack.removeLast();
    restoreState(state);
    stack.add(result);
  }

  void doInline(ResolvedAst resolvedAst) {
    visitInlinedFunction(resolvedAst);
  }

  void emitReturn(HInstruction value, ast.Node node) {
    if (inliningStack.isEmpty) {
      closeAndGotoExit(
          new HReturn(value, sourceInformationBuilder.buildReturn(node)));
    } else {
      localsHandler.updateLocal(returnLocal, value);
    }
  }

  @override
  void handleTypeLiteralConstantCompounds(
      ast.SendSet node, ConstantExpression constant, CompoundRhs rhs, _) {
    handleTypeLiteralCompound(node);
  }

  @override
  void handleTypeVariableTypeLiteralCompounds(
      ast.SendSet node, TypeVariableElement typeVariable, CompoundRhs rhs, _) {
    handleTypeLiteralCompound(node);
  }

  void handleTypeLiteralCompound(ast.SendSet node) {
    generateIsDeferredLoadedCheckOfSend(node);
    ast.Identifier selector = node.selector;
    generateThrowNoSuchMethod(node, selector.source,
        argumentNodes: node.arguments);
  }

  @override
  void visitConstantGet(ast.Send node, ConstantExpression constant, _) {
    visitNode(node);
  }

  @override
  void visitConstantInvoke(ast.Send node, ConstantExpression constant,
      ast.NodeList arguments, CallStructure callStreucture, _) {
    visitNode(node);
  }

  @override
  void errorUndefinedBinaryExpression(
      ast.Send node, ast.Node left, ast.Operator operator, ast.Node right, _) {
    visitNode(node);
  }

  @override
  void errorUndefinedUnaryExpression(
      ast.Send node, ast.Operator operator, ast.Node expression, _) {
    visitNode(node);
  }

  @override
  void bulkHandleError(ast.Node node, ErroneousElement error, _) {
    // TODO(johnniwinther): Use an uncatchable error when supported.
    generateRuntimeError(node, error.message);
  }
}

/**
 * Visitor that handles generation of string literals (LiteralString,
 * StringInterpolation), and otherwise delegates to the given visitor for
 * non-literal subexpressions.
 */
class StringBuilderVisitor extends ast.Visitor {
  final SsaAstGraphBuilder builder;
  final ast.Node diagnosticNode;

  /**
   * The string value generated so far.
   */
  HInstruction result = null;

  StringBuilderVisitor(this.builder, this.diagnosticNode);

  void visit(ast.Node node) {
    node.accept(this);
  }

  visitNode(ast.Node node) {
    builder.reporter.internalError(node, 'Unexpected node.');
  }

  void visitExpression(ast.Node node) {
    node.accept(builder);
    HInstruction expression = builder.pop();

    // We want to use HStringify when:
    //   1. The value is known to be a primitive type, because it might get
    //      constant-folded and codegen has some tricks with JavaScript
    //      conversions.
    //   2. The value can be primitive, because the library stringifier has
    //      fast-path code for most primitives.
    if (expression.canBePrimitive(builder.closedWorld)) {
      append(stringify(node, expression));
      return;
    }

    // If the `toString` method is guaranteed to return a string we can call it
    // directly.
    Selector selector = Selectors.toString_;
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(
        selector, expression.instructionType, builder.globalInferenceResults);
    if (type.containsOnlyString(builder.closedWorld)) {
      builder.pushInvokeDynamic(node, selector, expression.instructionType,
          <HInstruction>[expression]);
      append(builder.pop());
      return;
    }

    append(stringify(node, expression));
  }

  void visitStringInterpolation(ast.StringInterpolation node) {
    node.visitChildren(this);
  }

  void visitStringInterpolationPart(ast.StringInterpolationPart node) {
    visit(node.expression);
    visit(node.string);
  }

  void visitStringJuxtaposition(ast.StringJuxtaposition node) {
    node.visitChildren(this);
  }

  void visitNodeList(ast.NodeList node) {
    node.visitChildren(this);
  }

  void append(HInstruction expression) {
    result = (result == null) ? expression : concat(result, expression);
  }

  HInstruction concat(HInstruction left, HInstruction right) {
    HInstruction instruction =
        new HStringConcat(left, right, builder.commonMasks.stringType);
    builder.add(instruction);
    return instruction;
  }

  HInstruction stringify(ast.Node node, HInstruction expression) {
    HInstruction instruction =
        new HStringify(expression, builder.commonMasks.stringType);
    builder.add(instruction);
    return instruction;
  }
}

/**
 * This class visits the method that is a candidate for inlining and
 * finds whether it is too difficult to inline.
 */
// TODO(karlklose): refactor to make it possible to distinguish between
// implementation restrictions (for example, we *can't* inline multiple returns)
// and heuristics (we *shouldn't* inline large functions).
class InlineWeeder extends ast.Visitor {
  // Invariant: *INSIDE_LOOP* > *OUTSIDE_LOOP*
  static const INLINING_NODES_OUTSIDE_LOOP = 18;
  static const INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR = 3;
  static const INLINING_NODES_INSIDE_LOOP = 42;
  static const INLINING_NODES_INSIDE_LOOP_ARG_FACTOR = 4;

  bool seenReturn = false;
  bool tooDifficult = false;
  int nodeCount = 0;
  final int maxInliningNodes; // `null` for unbounded.
  final bool allowLoops;
  final bool enableUserAssertions;
  final TreeElements elements;

  InlineWeeder._(this.elements, this.maxInliningNodes, this.allowLoops,
      this.enableUserAssertions);

  static bool canBeInlined(ResolvedAst resolvedAst, int maxInliningNodes,
      {bool allowLoops: false, bool enableUserAssertions: null}) {
    assert(enableUserAssertions is bool); // Ensure we passed it.
    if (resolvedAst.elements.containsTryStatement) return false;

    InlineWeeder weeder = new InlineWeeder._(resolvedAst.elements,
        maxInliningNodes, allowLoops, enableUserAssertions);
    ast.FunctionExpression functionExpression = resolvedAst.node;

    weeder.visit(functionExpression.initializers);
    weeder.visit(functionExpression.body);
    weeder.visit(functionExpression.asyncModifier);
    return !weeder.tooDifficult;
  }

  bool registerNode() {
    if (maxInliningNodes == null) return true;
    if (nodeCount++ > maxInliningNodes) {
      tooDifficult = true;
      return false;
    } else {
      return true;
    }
  }

  void visit(ast.Node node) {
    if (node != null) node.accept(this);
  }

  void visitNode(ast.Node node) {
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }

  @override
  void visitAssert(ast.Assert node) {
    if (enableUserAssertions) {
      visitNode(node);
    }
  }

  @override
  void visitAsyncModifier(ast.AsyncModifier node) {
    if (node.isYielding || node.isAsynchronous) {
      tooDifficult = true;
    }
  }

  void visitFunctionExpression(ast.Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitFunctionDeclaration(ast.Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitSend(ast.Send node) {
    // TODO(sra): Investigate following, and possibly count occurrences, since
    // repeated references might cause a temporary to be assigned.
    //
    //     Element element = elements[node];
    //     if (element != null && element.isParameter) {
    //       // Don't count as additional node, since it's likely that passing
    //       // the argument would cost us as much space as we inline.
    //       return;
    //     }
    if (!registerNode()) return;
    node.visitChildren(this);
  }

  visitLoop(ast.Node node) {
    // It's actually not difficult to inline a method with a loop, but
    // our measurements show that it's currently better to not inline a
    // method that contains a loop.
    if (!allowLoops) tooDifficult = true;
  }

  void visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitConditional(ast.Conditional node) {
    // Heuristic: In "parameter ? A : B" there is a high probability that
    // parameter is a constant. Assuming the parameter is constant, we can
    // compute a count that is bounded by the largest arm rather than the sum of
    // both arms.
    visit(node.condition);
    if (tooDifficult) return;
    int commonPrefixCount = nodeCount;

    visit(node.thenExpression);
    if (tooDifficult) return;
    int thenCount = nodeCount - commonPrefixCount;

    nodeCount = commonPrefixCount;
    visit(node.elseExpression);
    if (tooDifficult) return;
    int elseCount = nodeCount - commonPrefixCount;

    nodeCount = commonPrefixCount + thenCount + elseCount;
    if (node.condition.asSend() != null &&
        elements[node.condition]?.isParameter == true) {
      nodeCount =
          commonPrefixCount + (thenCount > elseCount ? thenCount : elseCount);
    }
    // This is last so that [tooDifficult] is always updated.
    if (!registerNode()) return;
  }

  void visitRethrow(ast.Rethrow node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitReturn(ast.Return node) {
    if (!registerNode()) return;
    if (seenReturn || identical(node.beginToken.stringValue, 'native')) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  void visitThrow(ast.Throw node) {
    if (!registerNode()) return;
    // For now, we don't want to handle throw after a return even if
    // it is in an "if".
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }
}

abstract class InliningState {
  /**
   * Invariant: [function] must be an implementation element.
   */
  final FunctionElement function;

  InliningState(this.function) {
    assert(function.isImplementation);
  }
}

class AstInliningState extends InliningState {
  final Local oldReturnLocal;
  final ResolutionDartType oldReturnType;
  final ResolvedAst oldResolvedAst;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;
  final bool allFunctionsCalledOnce;
  final GlobalTypeInferenceElementResult oldElementInferenceResults;

  AstInliningState(
      FunctionElement function,
      this.oldReturnLocal,
      this.oldReturnType,
      this.oldResolvedAst,
      this.oldStack,
      this.oldLocalsHandler,
      this.inTryStatement,
      this.allFunctionsCalledOnce,
      this.oldElementInferenceResults)
      : super(function);
}
