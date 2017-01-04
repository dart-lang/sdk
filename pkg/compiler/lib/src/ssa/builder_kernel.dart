// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/names.dart';
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart';
import '../constants/values.dart'
    show
        ConstantValue,
        InterceptorConstantValue,
        StringConstantValue,
        TypeConstantValue;
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart';
import '../tree/dartstring.dart';
import '../tree/nodes.dart' show Node, BreakStatement;
import '../types/masks.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart';
import '../universe/side_effects.dart' show SideEffects;
import '../universe/use.dart' show StaticUse;
import '../world.dart';
import 'graph_builder.dart';
import 'jump_handler.dart';
import 'kernel_ast_adapter.dart';
import 'kernel_string_builder.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'nodes.dart';
import 'ssa_branch_builder.dart';
import 'type_builder.dart';
import 'types.dart' show TypeMaskFactory;

class SsaKernelBuilderTask extends CompilerTask {
  final JavaScriptBackend backend;
  final SourceInformationStrategy sourceInformationFactory;

  String get name => 'SSA kernel builder';

  SsaKernelBuilderTask(JavaScriptBackend backend, this.sourceInformationFactory)
      : backend = backend,
        super(backend.compiler.measurer);

  HGraph build(CodegenWorkItem work, ClosedWorld closedWorld) {
    return measure(() {
      AstElement element = work.element.implementation;
      Kernel kernel = backend.kernelTask.kernel;
      KernelSsaBuilder builder = new KernelSsaBuilder(
          element,
          work.resolvedAst,
          backend.compiler,
          closedWorld,
          work.registry,
          sourceInformationFactory,
          kernel);
      HGraph graph = builder.build();

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
  }
}

class KernelSsaBuilder extends ir.Visitor with GraphBuilder {
  ir.Node target;
  final AstElement targetElement;
  final ResolvedAst resolvedAst;
  final ClosedWorld closedWorld;
  final CodegenRegistry registry;

  /// Helper accessor for all kernel function-like targets (Procedure,
  /// FunctionExpression, FunctionDeclaration) of the inner FunctionNode itself.
  /// If the current target is not a function-like target, _targetFunction will
  /// be null.
  ir.FunctionNode _targetFunction;

  /// A stack of [DartType]s that have been seen during inlining of factory
  /// constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HCreate]s inside the inline code and registered during code generation
  /// for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted) types
  // of the type variables in an environment (like the [LocalsHandler]).
  final List<DartType> currentImplicitInstantiations = <DartType>[];

  HInstruction rethrowableException;

  @override
  JavaScriptBackend get backend => compiler.backend;

  @override
  TreeElements get elements => resolvedAst.elements;

  SourceInformationBuilder sourceInformationBuilder;
  KernelAstAdapter astAdapter;
  LoopHandler<ir.Node> loopHandler;
  TypeBuilder typeBuilder;

  final Map<ir.VariableDeclaration, HInstruction> letBindings =
      <ir.VariableDeclaration, HInstruction>{};

  /// True if we are visiting the expression of a throw statement; we assume
  /// this is a slow path.
  bool _inExpressionOfThrow = false;

  KernelSsaBuilder(
      this.targetElement,
      this.resolvedAst,
      Compiler compiler,
      this.closedWorld,
      this.registry,
      SourceInformationStrategy sourceInformationFactory,
      Kernel kernel) {
    this.compiler = compiler;
    this.loopHandler = new KernelLoopHandler(this);
    typeBuilder = new TypeBuilder(this);
    graph.element = targetElement;
    // TODO(het): Should sourceInformationBuilder be in GraphBuilder?
    this.sourceInformationBuilder =
        sourceInformationFactory.createBuilderForContext(resolvedAst);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler = new LocalsHandler(this, targetElement, null, compiler);
    this.astAdapter = new KernelAstAdapter(kernel, compiler.backend,
        resolvedAst, kernel.nodeToAst, kernel.nodeToElement);
    Element originTarget = targetElement;
    if (originTarget.isPatch) {
      originTarget = originTarget.origin;
    }
    if (originTarget is FunctionElement) {
      target = kernel.functions[originTarget];
      // Closures require a lookup one level deeper in the closure class mapper.
      if (target == null) {
        ClosureClassMap classMap = compiler.closureToClassMapper
            .getClosureToClassMapping(originTarget.resolvedAst);
        if (classMap.closureElement != null) {
          target = kernel.localFunctions[classMap.closureElement];
        }
      }
    } else if (originTarget is FieldElement) {
      target = kernel.fields[originTarget];
    }
  }

  HGraph build() {
    // TODO(het): no reason to do this here...
    HInstruction.idCounter = 0;
    if (target is ir.Procedure) {
      _targetFunction = (target as ir.Procedure).function;
      buildFunctionNode(_targetFunction);
    } else if (target is ir.Field) {
      buildField(target);
    } else if (target is ir.Constructor) {
      buildConstructor(target);
    } else if (target is ir.FunctionExpression) {
      _targetFunction = (target as ir.FunctionExpression).function;
      buildFunctionNode(_targetFunction);
    } else if (target is ir.FunctionDeclaration) {
      _targetFunction = (target as ir.FunctionDeclaration).function;
      buildFunctionNode(_targetFunction);
    } else {
      throw 'No case implemented to handle $target';
    }
    assert(graph.isValid());
    return graph;
  }

  void buildField(ir.Field field) {
    openFunction();
    if (field.initializer != null) {
      field.initializer.accept(this);
      HInstruction fieldValue = pop();
      HInstruction checkInstruction = typeBuilder.potentiallyCheckOrTrustType(
          fieldValue, astAdapter.getDartType(field.type));
      stack.add(checkInstruction);
    } else {
      stack.add(graph.addConstantNull(closedWorld));
    }
    HInstruction value = pop();
    closeAndGotoExit(new HReturn(value, null));
    closeFunction();
  }

  /// Pops the most recent instruction from the stack and 'boolifies' it.
  ///
  /// Boolification is checking if the value is '=== true'.
  @override
  HInstruction popBoolified() {
    HInstruction value = pop();
    if (typeBuilder.checkOrTrustTypes) {
      return typeBuilder.potentiallyCheckOrTrustType(
          value, compiler.commonElements.boolType,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, commonMasks.boolType);
    add(result);
    return result;
  }

  void _addClassTypeVariablesIfNeeded(ir.Member constructor) {
    var enclosing = constructor.enclosingClass;
    if (backend.classNeedsRti(astAdapter.getElement(enclosing))) {
      ClassElement clsElement =
          astAdapter.getElement(constructor).enclosingElement;
      enclosing.typeParameters.forEach((ir.TypeParameter typeParameter) {
        var typeParamElement = astAdapter.getElement(typeParameter);
        HParameterValue param =
            addParameter(typeParamElement, commonMasks.nonNullType);
        // This is a little bit wacky (and n^2) until we make the localsHandler
        // take Kernel DartTypes instead of just the AST DartTypes.
        var typeVariableType = clsElement.typeVariables
            .firstWhere((TypeVariableType i) => i.name == typeParameter.name);
        localsHandler.directLocals[
            localsHandler.getTypeVariableAsLocal(typeVariableType)] = param;
      });
    }
  }

  /// Builds generative constructors.
  ///
  /// Generative constructors are built in two stages.
  ///
  /// First, the field values for every instance field for every class in the
  /// class hierarchy are collected. Then, create a function body that sets
  /// all of the instance fields to the collected values and call the
  /// constructor bodies for all constructors in the hierarchy.
  void buildConstructor(ir.Constructor constructor) {
    openFunction();
    _addClassTypeVariablesIfNeeded(constructor);

    // Collect field values for the current class.
    // TODO(het): Does kernel always put field initializers in the constructor
    //            initializer list? If so then this is unnecessary...
    Map<ir.Field, HInstruction> fieldValues =
        _collectFieldValues(constructor.enclosingClass);

    _buildInitializers(constructor, fieldValues);

    final constructorArguments = <HInstruction>[];
    astAdapter.getClass(constructor.enclosingClass).forEachInstanceField(
        (ClassElement enclosingClass, FieldElement member) {
      var value = fieldValues[astAdapter.getFieldFromElement(member)];
      constructorArguments.add(value);
    }, includeSuperAndInjectedMembers: true);

    // TODO(het): If the class needs runtime type information, add it as a
    // constructor argument.
    HInstruction create = new HCreate(
        astAdapter.getClass(constructor.enclosingClass),
        constructorArguments,
        new TypeMask.nonNullExact(
            astAdapter.getClass(constructor.enclosingClass), closedWorld),
        instantiatedTypes: <DartType>[
          astAdapter.getClass(constructor.enclosingClass).thisType
        ],
        hasRtiInput: false);

    add(create);

    // Generate calls to the constructor bodies.

    closeAndGotoExit(new HReturn(create, null));
    closeFunction();
  }

  /// Maps the fields of a class to their SSA values.
  Map<ir.Field, HInstruction> _collectFieldValues(ir.Class clazz) {
    final fieldValues = <ir.Field, HInstruction>{};

    for (var field in clazz.fields) {
      if (field.initializer == null) {
        fieldValues[field] = graph.addConstantNull(closedWorld);
      } else {
        field.initializer.accept(this);
        fieldValues[field] = pop();
      }
    }

    return fieldValues;
  }

  /// Collects field initializers all the way up the inheritance chain.
  void _buildInitializers(
      ir.Constructor constructor, Map<ir.Field, HInstruction> fieldValues) {
    var foundSuperOrRedirectCall = false;
    for (var initializer in constructor.initializers) {
      if (initializer is ir.SuperInitializer ||
          initializer is ir.RedirectingInitializer) {
        foundSuperOrRedirectCall = true;
        var superOrRedirectConstructor = initializer.target;
        var arguments = _normalizeAndBuildArguments(
            superOrRedirectConstructor.function, initializer.arguments);
        _buildInlinedInitializers(
            superOrRedirectConstructor, arguments, fieldValues);
      } else if (initializer is ir.FieldInitializer) {
        initializer.value.accept(this);
        fieldValues[initializer.field] = pop();
      }
    }

    // Kernel always set the super initializer at the end, so if there was no
    // super-call initializer, then the default constructor is called in the
    // superclass.
    if (!foundSuperOrRedirectCall) {
      if (constructor.enclosingClass != astAdapter.objectClass) {
        var superclass = constructor.enclosingClass.superclass;
        var defaultConstructor = superclass.constructors
            .firstWhere((c) => c.name.name == '', orElse: () => null);
        if (defaultConstructor == null) {
          compiler.reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Could not find default constructor.');
        }
        _buildInlinedInitializers(
            defaultConstructor, <HInstruction>[], fieldValues);
      }
    }
  }

  List<HInstruction> _normalizeAndBuildArguments(
      ir.FunctionNode function, ir.Arguments arguments) {
    var signature = astAdapter.getFunctionSignature(function);
    var builtArguments = <HInstruction>[];
    var positionalIndex = 0;
    signature.forEachRequiredParameter((_) {
      arguments.positional[positionalIndex++].accept(this);
      builtArguments.add(pop());
    });
    if (!signature.optionalParametersAreNamed) {
      signature.forEachOptionalParameter((ParameterElement element) {
        if (positionalIndex < arguments.positional.length) {
          arguments.positional[positionalIndex++].accept(this);
          builtArguments.add(pop());
        } else {
          var constantValue =
              backend.constants.getConstantValue(element.constant);
          assert(invariant(element, constantValue != null,
              message: 'No constant computed for $element'));
          builtArguments.add(graph.addConstant(constantValue, closedWorld));
        }
      });
    } else {
      signature.orderedOptionalParameters.forEach((ParameterElement element) {
        var correspondingNamed = arguments.named.firstWhere(
            (named) => named.name == element.name,
            orElse: () => null);
        if (correspondingNamed != null) {
          correspondingNamed.value.accept(this);
          builtArguments.add(pop());
        } else {
          var constantValue =
              backend.constants.getConstantValue(element.constant);
          assert(invariant(element, constantValue != null,
              message: 'No constant computed for $element'));
          builtArguments.add(graph.addConstant(constantValue, closedWorld));
        }
      });
    }

    return builtArguments;
  }

  /// Inlines the given super [constructor]'s initializers by collecting it's
  /// field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _buildInlinedInitializers(ir.Constructor constructor,
      List<HInstruction> arguments, Map<ir.Field, HInstruction> fieldValues) {
    // TODO(het): Handle RTI if class needs it
    fieldValues.addAll(_collectFieldValues(constructor.enclosingClass));

    var signature = astAdapter.getFunctionSignature(constructor.function);
    var index = 0;
    signature.orderedForEachParameter((ParameterElement parameter) {
      HInstruction argument = arguments[index++];
      // Because we are inlining the initializer, we must update
      // what was given as parameter. This will be used in case
      // there is a parameter check expression in the initializer.
      parameters[parameter] = argument;
      localsHandler.updateLocal(parameter, argument);
    });

    // TODO(het): set the locals handler state as if we were inlining the
    // constructor.
    _buildInitializers(constructor, fieldValues);
  }

  HTypeConversion buildFunctionTypeConversion(
      HInstruction original, DartType type, int kind) {
    HInstruction reifiedType = buildFunctionType(type);
    return new HTypeConversion.viaMethodOnType(
        type, kind, original.instructionType, reifiedType, original);
  }

  /// Builds a SSA graph for FunctionNodes, found in FunctionExpressions and
  /// Procedures.
  void buildFunctionNode(ir.FunctionNode functionNode) {
    openFunction();
    if (functionNode.parent is ir.Procedure &&
        (functionNode.parent as ir.Procedure).kind ==
            ir.ProcedureKind.Factory) {
      _addClassTypeVariablesIfNeeded(functionNode.parent);
    }
    functionNode.body.accept(this);
    closeFunction();
  }

  void addImplicitInstantiation(DartType type) {
    if (type != null) {
      currentImplicitInstantiations.add(type);
    }
  }

  void removeImplicitInstantiation(DartType type) {
    if (type != null) {
      currentImplicitInstantiations.removeLast();
    }
  }

  void openFunction() {
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    Node function;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      function = resolvedAst.node;
    }
    localsHandler.startFunction(targetElement, function);
    close(new HGoto()).addSuccessor(block);

    open(block);
  }

  void closeFunction() {
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
  }

  /// Pushes a boolean checking [expression] against null.
  pushCheckNull(HInstruction expression) {
    push(new HIdentity(expression, graph.addConstantNull(closedWorld), null,
        commonMasks.boolType));
  }

  @override
  void defaultExpression(ir.Expression expression) {
    // TODO(het): This is only to get tests working.
    _trap('Unhandled ir.${expression.runtimeType}  $expression');
  }

  @override
  void defaultStatement(ir.Statement statement) {
    _trap('Unhandled ir.${statement.runtimeType}  $statement');
    pop();
  }

  void _trap(String message) {
    HInstruction nullValue = graph.addConstantNull(closedWorld);
    HInstruction errorMessage =
        graph.addConstantString(new DartString.literal(message), closedWorld);
    HInstruction trap = new HForeignCode(js.js.parseForeignJS("#.#"),
        commonMasks.dynamicType, <HInstruction>[nullValue, errorMessage]);
    trap.sideEffects
      ..setAllSideEffects()
      ..setDependsOnSomething();
    push(trap);
  }

  /// Returns the current source element.
  ///
  /// The returned element is a declaration element.
  // TODO(efortuna): Update this when we implement inlining.
  @override
  Element get sourceElement => astAdapter.getElement(target);

  @override
  void visitBlock(ir.Block block) {
    assert(!isAborted());
    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (stack.isNotEmpty) {
          compiler.reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (stack.isNotEmpty) {
      compiler.reporter
          .internalError(NO_LOCATION_SPANNABLE, 'Non-empty instruction stack');
    }
  }

  @override
  void visitEmptyStatement(ir.EmptyStatement statement) {
    // Empty statement adds no instructions to current block.
  }

  @override
  void visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    if (!isReachable) return;
    ir.Expression expression = exprStatement.expression;
    if (expression is ir.Throw) {
      // TODO(sra): Prevent generating a statement when inlining.
      _visitThrowExpression(expression.expression);
      closeAndGotoExit(new HThrow(pop(), null));
    } else {
      expression.accept(this);
      pop();
    }
  }

  @override
  void visitReturnStatement(ir.ReturnStatement returnStatement) {
    HInstruction value;
    if (returnStatement.expression == null) {
      value = graph.addConstantNull(closedWorld);
    } else {
      assert(_targetFunction != null && _targetFunction is ir.FunctionNode);
      returnStatement.expression.accept(this);
      value = typeBuilder.potentiallyCheckOrTrustType(
          pop(), astAdapter.getFunctionReturnType(_targetFunction));
    }
    // TODO(het): Add source information
    // TODO(het): Set a return value instead of closing the function when we
    // support inlining.
    closeAndGotoExit(new HReturn(value, null));
  }

  @override
  void visitForStatement(ir.ForStatement forStatement) {
    assert(isReachable);
    assert(forStatement.body != null);
    void buildInitializer() {
      for (ir.VariableDeclaration declaration in forStatement.variables) {
        declaration.accept(this);
      }
    }

    HInstruction buildCondition() {
      if (forStatement.condition == null) {
        return graph.addConstantBool(true, closedWorld);
      }
      forStatement.condition.accept(this);
      return popBoolified();
    }

    void buildUpdate() {
      for (ir.Expression expression in forStatement.updates) {
        expression.accept(this);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      forStatement.body.accept(this);
    }

    loopHandler.handleLoop(
        forStatement, buildInitializer, buildCondition, buildUpdate, buildBody);
  }

  @override
  void visitForInStatement(ir.ForInStatement forInStatement) {
    if (forInStatement.isAsync) {
      compiler.reporter.internalError(astAdapter.getNode(forInStatement),
          "Cannot compile async for-in using kernel.");
    }
    // If the expression being iterated over is a JS indexable type, we can
    // generate an optimized version of for-in that uses indexing.
    if (astAdapter.isJsIndexableIterator(forInStatement, closedWorld)) {
      _buildForInIndexable(forInStatement);
    } else {
      _buildForInIterator(forInStatement);
    }
  }

  /// Builds the graph for a for-in node with an indexable expression.
  ///
  /// In this case we build:
  ///
  ///    int end = a.length;
  ///    for (int i = 0;
  ///         i < a.length;
  ///         checkConcurrentModificationError(a.length == end, a), ++i) {
  ///      <declaredIdentifier> = a[i];
  ///      <body>
  ///    }
  _buildForInIndexable(ir.ForInStatement forInStatement) {
    SyntheticLocal indexVariable = new SyntheticLocal('_i', targetElement);

    // These variables are shared by initializer, condition, body and update.
    HInstruction array; // Set in buildInitializer.
    bool isFixed; // Set in buildInitializer.
    HInstruction originalLength = null; // Set for growable lists.

    HInstruction buildGetLength() {
      HFieldGet result = new HFieldGet(
          astAdapter.jsIndexableLength, array, commonMasks.positiveIntType,
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
      push(new HIdentity(length, originalLength, null, commonMasks.boolType));
      _pushStaticInvocation(
          astAdapter.checkConcurrentModificationError,
          [pop(), array],
          astAdapter.checkConcurrentModificationErrorReturnType);
      pop();
    }

    void buildInitializer() {
      forInStatement.iterable.accept(this);
      array = pop();
      isFixed = astAdapter.isFixedLength(array.instructionType, closedWorld);
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, closedWorld));
      originalLength = buildGetLength();
    }

    HInstruction buildCondition() {
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction length = buildGetLength();
      HInstruction compare =
          new HLess(index, length, null, commonMasks.boolType);
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
      TypeMask type = astAdapter.inferredIndexType(forInStatement);

      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction value = new HIndex(array, index, null, type);
      add(value);

      localsHandler.updateLocal(
          astAdapter.getLocal(forInStatement.variable), value);

      forInStatement.body.accept(this);
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

    loopHandler.handleLoop(forInStatement, buildInitializer, buildCondition,
        buildUpdate, buildBody);
  }

  _buildForInIterator(ir.ForInStatement forInStatement) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <declaredIdentifier> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;

    void buildInitializer() {
      TypeMask mask = astAdapter.typeOfIterator(forInStatement);
      forInStatement.iterable.accept(this);
      HInstruction receiver = pop();
      _pushDynamicInvocation(forInStatement, mask, <HInstruction>[receiver],
          selector: Selectors.iterator);
      iterator = pop();
    }

    HInstruction buildCondition() {
      TypeMask mask = astAdapter.typeOfIteratorMoveNext(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, <HInstruction>[iterator],
          selector: Selectors.moveNext);
      return popBoolified();
    }

    void buildBody() {
      TypeMask mask = astAdapter.typeOfIteratorCurrent(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, [iterator],
          selector: Selectors.current);
      localsHandler.updateLocal(
          astAdapter.getLocal(forInStatement.variable), pop());
      forInStatement.body.accept(this);
    }

    loopHandler.handleLoop(
        forInStatement, buildInitializer, buildCondition, () {}, buildBody);
  }

  HInstruction callSetRuntimeTypeInfo(
      HInstruction typeInfo, HInstruction newObject) {
    // Set the runtime type information on the object.
    ir.Procedure typeInfoSetterFn = astAdapter.setRuntimeTypeInfo;
    // TODO(efortuna): Insert source information in this static invocation.
    _pushStaticInvocation(typeInfoSetterFn, <HInstruction>[newObject, typeInfo],
        commonMasks.dynamicType);

    // The new object will now be referenced through the
    // `setRuntimeTypeInfo` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(invariant(CURRENT_ELEMENT_SPANNABLE,
        stack.last is HInvokeStatic || stack.last == newObject,
        message: "Unexpected `stack.last`: Found ${stack.last}, "
            "expected ${newObject} or an HInvokeStatic. "
            "State: typeInfo=$typeInfo, stack=$stack."));
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  @override
  void visitWhileStatement(ir.WhileStatement whileStatement) {
    assert(isReachable);
    HInstruction buildCondition() {
      whileStatement.condition.accept(this);
      return popBoolified();
    }

    loopHandler.handleLoop(whileStatement, () {}, buildCondition, () {}, () {
      whileStatement.body.accept(this);
    });
  }

  @override
  visitDoStatement(ir.DoStatement doStatement) {
    // TODO(efortuna): I think this can be rewritten using
    // LoopHandler.handleLoop with some tricks about when the "update" happens.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    localsHandler.startLoop(astAdapter.getNode(doStatement));
    JumpHandler jumpHandler = loopHandler.beginLoopHeader(doStatement);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    JumpTarget target =
        elements.getTargetDefinition(astAdapter.getNode(doStatement));
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
    localsHandler.enterLoopBody(astAdapter.getNode(doStatement));
    doStatement.body.accept(this);

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

      doStatement.condition.accept(this);
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
          sourceInformationBuilder.buildLoop(astAdapter.getNode(doStatement)));
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
        JumpTarget target =
            elements.getTargetDefinition(astAdapter.getNode(doStatement));
        LabelDefinition label = target.addLabel(null, 'loop');
        label.setBreakTarget();
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
  }

  @override
  void visitIfStatement(ir.IfStatement ifStatement) {
    handleIf(
        visitCondition: () => ifStatement.condition.accept(this),
        visitThen: () => ifStatement.then.accept(this),
        visitElse: () => ifStatement.otherwise?.accept(this));
  }

  @override
  void visitAsExpression(ir.AsExpression asExpression) {
    asExpression.operand.accept(this);
    HInstruction expressionInstruction = pop();
    DartType type = astAdapter.getDartType(asExpression.type);
    if (type.isMalformed) {
      if (type is MalformedType) {
        ErroneousElement element = type.element;
        generateTypeError(asExpression, element.message);
      } else {
        assert(type is MethodTypeVariableType);
        stack.add(expressionInstruction);
      }
    } else {
      HInstruction converted = typeBuilder.buildTypeConversion(
          expressionInstruction,
          localsHandler.substInContext(type),
          HTypeConversion.CAST_TYPE_CHECK);
      if (converted != expressionInstruction) {
        add(converted);
      }
      stack.add(converted);
    }
  }

  void generateError(ir.Node node, String message, TypeMask typeMask) {
    HInstruction errorMessage =
        graph.addConstantString(new DartString.literal(message), closedWorld);
    _pushStaticInvocation(node, [errorMessage], typeMask);
  }

  void generateTypeError(ir.Node node, String message) {
    generateError(node, message, astAdapter.throwTypeErrorType);
  }

  @override
  void visitAssertStatement(ir.AssertStatement assertStatement) {
    if (!compiler.options.enableUserAssertions) return;
    if (assertStatement.message == null) {
      assertStatement.condition.accept(this);
      _pushStaticInvocation(astAdapter.assertHelper, <HInstruction>[pop()],
          astAdapter.assertHelperReturnType);
      pop();
      return;
    }

    // if (assertTest(condition)) assertThrow(message);
    void buildCondition() {
      assertStatement.condition.accept(this);
      _pushStaticInvocation(astAdapter.assertTest, <HInstruction>[pop()],
          astAdapter.assertTestReturnType);
    }

    void fail() {
      assertStatement.message.accept(this);
      _pushStaticInvocation(astAdapter.assertThrow, <HInstruction>[pop()],
          astAdapter.assertThrowReturnType);
      pop();
    }

    handleIf(visitCondition: buildCondition, visitThen: fail);
  }

  @override
  void visitBreakStatement(ir.BreakStatement breakStatement) {
    assert(!isAborted());
    JumpTarget target = astAdapter.getJumpTarget(breakStatement.target);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    handler.generateBreak(handler.labels.first);
  }

  @override
  void visitLabeledStatement(ir.LabeledStatement labeledStatement) {
    JumpTarget target = astAdapter.getJumpTarget(labeledStatement);
    JumpHandler handler = new JumpHandler(this, target);

    ir.Statement body = labeledStatement.body;
    if (body is ir.WhileStatement ||
        body is ir.DoStatement ||
        body is ir.ForStatement ||
        body is ir.ForInStatement) {
      // loops handle breaks on their own
      body.accept(this);
      return;
    }
    LocalsHandler beforeLocals = new LocalsHandler.from(localsHandler);

    HBasicBlock newBlock = openNewBlock();
    body.accept(this);
    SubGraph bodyGraph = new SubGraph(newBlock, lastOpenedBlock);

    HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(joinBlock);
      breakHandlers.add(locals);
    });

    if (!isAborted()) {
      goto(current, joinBlock);
      breakHandlers.add(localsHandler);
    }

    open(joinBlock);
    localsHandler = beforeLocals.mergeMultiple(breakHandlers, joinBlock);

    // There was at least one reachable break, so the label is needed.
    newBlock.setBlockFlow(
        new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), handler.labels),
        joinBlock);
    handler.close();
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression conditional) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, compiler);
    brancher.handleConditional(
        () => conditional.condition.accept(this),
        () => conditional.then.accept(this),
        () => conditional.otherwise.accept(this));
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression logicalExpression) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, compiler);
    brancher.handleLogicalBinary(() => logicalExpression.left.accept(this),
        () => logicalExpression.right.accept(this),
        isAnd: logicalExpression.operator == '&&');
  }

  @override
  void visitIntLiteral(ir.IntLiteral intLiteral) {
    stack.add(graph.addConstantInt(intLiteral.value, closedWorld));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral doubleLiteral) {
    stack.add(graph.addConstantDouble(doubleLiteral.value, closedWorld));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral boolLiteral) {
    stack.add(graph.addConstantBool(boolLiteral.value, closedWorld));
  }

  @override
  void visitStringLiteral(ir.StringLiteral stringLiteral) {
    stack.add(graph.addConstantString(
        new DartString.literal(stringLiteral.value), closedWorld));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral symbolLiteral) {
    stack.add(graph.addConstant(
        astAdapter.getConstantForSymbol(symbolLiteral), closedWorld));
    registry?.registerConstSymbol(symbolLiteral.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral nullLiteral) {
    stack.add(graph.addConstantNull(closedWorld));
  }

  /// Set the runtime type information if necessary.
  HInstruction setListRuntimeTypeInfoIfNeeded(
      HInstruction object, ir.ListLiteral listLiteral) {
    InterfaceType type = localsHandler
        .substInContext(astAdapter.getDartTypeOfListLiteral(listLiteral));
    if (!backend.classNeedsRti(type.element) || type.treatAsRaw) {
      return object;
    }
    List<HInstruction> arguments = <HInstruction>[];
    for (DartType argument in type.typeArguments) {
      arguments.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
    }
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfoWithTypeArguments(type, arguments, object);
  }

  @override
  void visitListLiteral(ir.ListLiteral listLiteral) {
    HInstruction listInstruction;
    if (listLiteral.isConst) {
      listInstruction = graph.addConstant(
          astAdapter.getConstantFor(listLiteral), closedWorld);
    } else {
      List<HInstruction> elements = <HInstruction>[];
      for (ir.Expression element in listLiteral.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction =
          new HLiteralList(elements, commonMasks.extendableArrayType);
      add(listInstruction);
      listInstruction =
          setListRuntimeTypeInfoIfNeeded(listInstruction, listLiteral);
    }

    TypeMask type =
        astAdapter.typeOfListLiteral(targetElement, listLiteral, closedWorld);
    if (!type.containsAll(closedWorld)) {
      listInstruction.instructionType = type;
    }
    stack.add(listInstruction);
  }

  @override
  void visitMapLiteral(ir.MapLiteral mapLiteral) {
    if (mapLiteral.isConst) {
      stack.add(graph.addConstant(
          astAdapter.getConstantFor(mapLiteral), closedWorld));
      return;
    }

    // The map literal constructors take the key-value pairs as a List
    List<HInstruction> constructorArgs = <HInstruction>[];
    for (ir.MapEntry mapEntry in mapLiteral.entries) {
      mapEntry.accept(this);
      constructorArgs.add(pop());
      constructorArgs.add(pop());
    }

    // The constructor is a procedure because it's a factory.
    ir.Procedure constructor;
    List<HInstruction> inputs = <HInstruction>[];
    if (constructorArgs.isEmpty) {
      constructor = astAdapter.mapLiteralConstructorEmpty;
    } else {
      constructor = astAdapter.mapLiteralConstructor;
      HLiteralList argList =
          new HLiteralList(constructorArgs, commonMasks.extendableArrayType);
      add(argList);
      inputs.add(argList);
    }

    assert(constructor.kind == ir.ProcedureKind.Factory);

    InterfaceType type = localsHandler
        .substInContext(astAdapter.getDartTypeOfMapLiteral(mapLiteral));

    ir.Class cls = constructor.enclosingClass;

    if (backend.classNeedsRti(astAdapter.getElement(cls))) {
      List<HInstruction> typeInputs = <HInstruction>[];
      type.typeArguments.forEach((DartType argument) {
        typeInputs
            .add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) => input.isNull())) {
        if (constructorArgs.isEmpty) {
          constructor = astAdapter.mapLiteralUntypedEmptyMaker;
        } else {
          constructor = astAdapter.mapLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If runtime type information is needed and the map literal has no type
    // parameters, 'constructor' is a static function that forwards the call to
    // the factory constructor without type parameters.
    assert(constructor.kind == ir.ProcedureKind.Method ||
        constructor.kind == ir.ProcedureKind.Factory);

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).
    TypeMask mapType = new TypeMask.nonNullSubtype(
        astAdapter.getElement(astAdapter.mapLiteralClass), closedWorld);
    TypeMask returnTypeMask = TypeMaskFactory.inferredReturnTypeForElement(
        astAdapter.getElement(constructor), globalInferenceResults);
    TypeMask instructionType =
        mapType.intersection(returnTypeMask, closedWorld);

    addImplicitInstantiation(type);
    _pushStaticInvocation(constructor, inputs, instructionType);
    removeImplicitInstantiation(type);
  }

  @override
  void visitMapEntry(ir.MapEntry mapEntry) {
    // Visit value before the key because each will push an expression to the
    // stack, so when we pop them off, the key is popped first, then the value.
    mapEntry.value.accept(this);
    mapEntry.key.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral typeLiteral) {
    ir.DartType type = typeLiteral.type;
    if (type is ir.InterfaceType) {
      ConstantValue constant = astAdapter.getConstantForType(type);
      stack.add(graph.addConstant(constant, closedWorld));
      return;
    }
    if (type is ir.TypeParameterType) {
      // TODO(sra): Convert the type logic here to use ir.DartType.
      DartType dartType = astAdapter.getDartType(type);
      dartType = localsHandler.substInContext(dartType);
      HInstruction value = typeBuilder.analyzeTypeArgument(
          dartType, sourceElement,
          sourceInformation: null);
      _pushStaticInvocation(astAdapter.runtimeTypeToString,
          <HInstruction>[value], commonMasks.stringType);
      _pushStaticInvocation(astAdapter.createRuntimeType, <HInstruction>[pop()],
          astAdapter.createRuntimeTypeReturnType);
      return;
    }
    // TODO(27394): 'dynamic' and function types observed. Where are they from?
    defaultExpression(typeLiteral);
    return;
  }

  @override
  void visitStaticGet(ir.StaticGet staticGet) {
    ir.Member staticTarget = staticGet.target;
    if (staticTarget is ir.Procedure &&
        staticTarget.kind == ir.ProcedureKind.Getter) {
      // Invoke the getter
      _pushStaticInvocation(staticTarget, const <HInstruction>[],
          astAdapter.returnTypeOf(staticTarget));
    } else if (staticTarget is ir.Field && staticTarget.isConst) {
      assert(staticTarget.initializer != null);
      stack.add(graph.addConstant(
          astAdapter.getConstantFor(staticTarget.initializer), closedWorld));
    } else {
      if (_isLazyStatic(staticTarget)) {
        push(new HLazyStatic(astAdapter.getField(staticTarget),
            astAdapter.inferredTypeOf(staticTarget)));
      } else {
        push(new HStatic(astAdapter.getMember(staticTarget),
            astAdapter.inferredTypeOf(staticTarget)));
      }
    }
  }

  bool _isLazyStatic(ir.Member target) {
    return astAdapter.isLazyStatic(target);
  }

  @override
  void visitStaticSet(ir.StaticSet staticSet) {
    staticSet.value.accept(this);
    HInstruction value = pop();

    var staticTarget = staticSet.target;
    if (staticTarget is ir.Procedure) {
      // Invoke the setter
      _pushStaticInvocation(staticTarget, <HInstruction>[value],
          astAdapter.returnTypeOf(staticTarget));
      pop();
    } else {
      add(new HStaticStore(
          astAdapter.getMember(staticTarget),
          typeBuilder.potentiallyCheckOrTrustType(
              value, astAdapter.getDartType(staticTarget.setterType))));
    }
    stack.add(value);
  }

  @override
  void visitPropertyGet(ir.PropertyGet propertyGet) {
    propertyGet.receiver.accept(this);
    HInstruction receiver = pop();

    _pushDynamicInvocation(propertyGet, astAdapter.typeOfGet(propertyGet),
        <HInstruction>[receiver]);
  }

  @override
  void visitVariableGet(ir.VariableGet variableGet) {
    ir.VariableDeclaration variable = variableGet.variable;
    HInstruction letBinding = letBindings[variable];
    if (letBinding != null) {
      stack.add(letBinding);
      return;
    }

    Local local = astAdapter.getLocal(variableGet.variable);
    stack.add(localsHandler.readLocal(local));
  }

  @override
  void visitPropertySet(ir.PropertySet propertySet) {
    propertySet.receiver.accept(this);
    HInstruction receiver = pop();
    propertySet.value.accept(this);
    HInstruction value = pop();

    _pushDynamicInvocation(
        propertySet,
        astAdapter.typeOfSet(propertySet, closedWorld),
        <HInstruction>[receiver, value]);

    pop();
    stack.add(value);
  }

  @override
  void visitVariableSet(ir.VariableSet variableSet) {
    variableSet.value.accept(this);
    HInstruction value = pop();
    _visitLocalSetter(variableSet.variable, value);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration declaration) {
    Local local = astAdapter.getLocal(declaration);
    if (declaration.initializer == null) {
      HInstruction initialValue = graph.addConstantNull(closedWorld);
      localsHandler.updateLocal(local, initialValue);
    } else {
      declaration.initializer.accept(this);
      HInstruction initialValue = pop();

      _visitLocalSetter(declaration, initialValue);

      // Ignore value
      pop();
    }
  }

  void _visitLocalSetter(ir.VariableDeclaration variable, HInstruction value) {
    LocalElement local = astAdapter.getElement(variable);

    // Give the value a name if it doesn't have one already.
    if (value.sourceElement == null) {
      value.sourceElement = local;
    }

    stack.add(value);
    localsHandler.updateLocal(
        local,
        typeBuilder.potentiallyCheckOrTrustType(
            value, astAdapter.getDartType(variable.type)));
  }

  @override
  void visitLet(ir.Let let) {
    ir.VariableDeclaration variable = let.variable;
    variable.initializer.accept(this);
    HInstruction initializedValue = pop();
    // TODO(sra): Apply inferred type information.
    letBindings[variable] = initializedValue;
    let.body.accept(this);
  }

  /// Extracts the list of instructions for the positional subset of arguments.
  List<HInstruction> _visitPositionalArguments(ir.Arguments arguments) {
    List<HInstruction> result = <HInstruction>[];
    for (ir.Expression argument in arguments.positional) {
      argument.accept(this);
      result.add(pop());
    }
    return result;
  }

  /// Builds the list of instructions for the expressions in the arguments to a
  /// dynamic target (member function).  Dynamic targets use stubs to add
  /// defaulted arguments, so (unlike static targets) we do not add the default
  /// values.
  List<HInstruction> _visitArgumentsForDynamicTarget(
      Selector selector, ir.Arguments arguments) {
    List<HInstruction> values = _visitPositionalArguments(arguments);

    if (arguments.named.isEmpty) return values;

    var namedValues = <String, HInstruction>{};
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
      namedValues[argument.name] = pop();
    }
    for (String name in selector.callStructure.getOrderedNamedArguments()) {
      values.add(namedValues[name]);
    }

    return values;
  }

  /// Build argument list in canonical order for a static [target], including
  /// filling in the defaulted argument value.
  List<HInstruction> _visitArgumentsForStaticTarget(
      ir.FunctionNode target, ir.Arguments arguments) {
    // Visit arguments in source order, then re-order and fill in defaults.
    var values = _visitPositionalArguments(arguments);

    while (values.length < target.positionalParameters.length) {
      ir.VariableDeclaration parameter =
          target.positionalParameters[values.length];
      values.add(_defaultValueForParameter(parameter));
    }

    if (arguments.named.isEmpty) return values;

    var namedValues = <String, HInstruction>{};
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
      namedValues[argument.name] = pop();
    }

    // Visit named arguments in parameter-position order, selecting provided or
    // default value.
    // TODO(sra): Ensure the stored order is canonical so we don't have to
    // sort. The old builder uses CallStructure.makeArgumentList which depends
    // on the old element model.
    var namedParameters = target.namedParameters.toList()
      ..sort((ir.VariableDeclaration a, ir.VariableDeclaration b) =>
          a.name.compareTo(b.name));
    for (ir.VariableDeclaration parameter in namedParameters) {
      HInstruction value = namedValues[parameter.name];
      if (value == null) {
        values.add(_defaultValueForParameter(parameter));
      } else {
        values.add(value);
        namedValues.remove(parameter.name);
      }
    }
    assert(namedValues.isEmpty);

    return values;
  }

  HInstruction _defaultValueForParameter(ir.VariableDeclaration parameter) {
    ir.Expression initializer = parameter.initializer;
    if (initializer == null) return graph.addConstantNull(closedWorld);
    // TODO(sra): Evaluate constant in ir.Node domain.
    ConstantValue constant =
        astAdapter.getConstantForParameterDefaultValue(initializer);
    if (constant == null) return graph.addConstantNull(closedWorld);
    return graph.addConstant(constant, closedWorld);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation invocation) {
    ir.Procedure target = invocation.target;
    if (astAdapter.isInForeignLibrary(target)) {
      handleInvokeStaticForeign(invocation, target);
      return;
    }
    TypeMask typeMask = astAdapter.returnTypeOf(target);

    // TODO(sra): For JS interop external functions, use a different function to
    // build arguments.
    List<HInstruction> arguments =
        _visitArgumentsForStaticTarget(target.function, invocation.arguments);

    _pushStaticInvocation(target, arguments, typeMask);
  }

  void handleInvokeStaticForeign(
      ir.StaticInvocation invocation, ir.Procedure target) {
    String name = target.name.name;
    if (name == 'JS') {
      handleForeignJs(invocation);
    } else if (name == 'JS_CURRENT_ISOLATE_CONTEXT') {
      handleForeignJsCurrentIsolateContext(invocation);
    } else if (name == 'JS_CALL_IN_ISOLATE') {
      handleForeignJsCallInIsolate(invocation);
    } else if (name == 'DART_CLOSURE_TO_JS') {
      handleForeignDartClosureToJs(invocation, 'DART_CLOSURE_TO_JS');
    } else if (name == 'RAW_DART_FUNCTION_REF') {
      handleForeignRawFunctionRef(invocation, 'RAW_DART_FUNCTION_REF');
    } else if (name == 'JS_SET_STATIC_STATE') {
      handleForeignJsSetStaticState(invocation);
    } else if (name == 'JS_GET_STATIC_STATE') {
      handleForeignJsGetStaticState(invocation);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(invocation);
    } else if (name == 'JS_EMBEDDED_GLOBAL') {
      handleForeignJsEmbeddedGlobal(invocation);
    } else if (name == 'JS_BUILTIN') {
      handleForeignJsBuiltin(invocation);
    } else if (name == 'JS_GET_FLAG') {
      handleForeignJsGetFlag(invocation);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(closedWorld));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      handleJsInterceptorConstant(invocation);
    } else if (name == 'JS_STRING_CONCAT') {
      handleJsStringConcat(invocation);
    } else {
      compiler.reporter.internalError(
          astAdapter.getNode(invocation), "Unknown foreign: ${name}");
    }
  }

  bool _unexpectedForeignArguments(
      ir.StaticInvocation invocation, int minPositional,
      [int maxPositional]) {
    String pluralizeArguments(int count) {
      if (count == 0) return 'no arguments';
      if (count == 1) return 'one argument';
      if (count == 2) return 'two arguments';
      return '$count arguments';
    }

    String name() => invocation.target.name.name;

    ir.Arguments arguments = invocation.arguments;
    bool bad = false;
    if (arguments.types.isNotEmpty) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' does not take type arguments."});
      bad = true;
    }
    if (arguments.positional.length < minPositional) {
      String phrase = pluralizeArguments(minPositional);
      if (maxPositional != minPositional) phrase = 'at least $phrase';
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too few arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (maxPositional != null && arguments.positional.length > maxPositional) {
      String phrase = pluralizeArguments(maxPositional);
      if (maxPositional != minPositional) phrase = 'at most $phrase';
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too many arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (arguments.named.isNotEmpty) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' does not take named arguments."});
      bad = true;
    }
    return bad;
  }

  /// Returns the value of the string argument. The argument must evaluate to a
  /// constant.  If there is an error, the error is reported and `null` is
  /// returned.
  String _foreignConstantStringArgument(
      ir.StaticInvocation invocation, int position, String methodName,
      [String adjective = '']) {
    ir.Expression argument = invocation.arguments.positional[position];
    argument.accept(this);
    HInstruction instruction = pop();

    if (!instruction.isConstantString()) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(argument), MessageKind.GENERIC, {
        'text': "Error: Expected String constant as ${adjective}argument "
            "to '$methodName'."
      });
      return null;
    }

    HConstant hConstant = instruction;
    StringConstantValue stringConstant = hConstant.constant;
    return stringConstant.primitiveValue.slowToString();
  }

  void handleForeignJsCurrentIsolateContext(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 0, 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (!backend.hasIsolateSupport) {
      // If the isolate library is not used, we just generate code
      // to fetch the static state.
      String name = backend.namer.staticStateHolder;
      push(new HForeignCode(
          js.js.parseForeignJS(name), commonMasks.dynamicType, <HInstruction>[],
          nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
    } else {
      // Call a helper method from the isolate library. The isolate library uses
      // its own isolate structure that encapsulates the isolate structure used
      // for binding to methods.
      ir.Procedure target = astAdapter.currentIsolate;
      if (target == null) {
        compiler.reporter.internalError(astAdapter.getNode(invocation),
            'Isolate library and compiler mismatch.');
      }
      _pushStaticInvocation(target, <HInstruction>[], commonMasks.dynamicType);
    }
  }

  void handleForeignJsCallInIsolate(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    if (!backend.hasIsolateSupport) {
      // If the isolate library is not used, we ignore the isolate argument and
      // just invoke the closure.
      push(new HInvokeClosure(new Selector.callClosure(0),
          <HInstruction>[inputs[1]], commonMasks.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      ir.Procedure callInIsolate = astAdapter.callInIsolate;
      if (callInIsolate == null) {
        compiler.reporter.internalError(astAdapter.getNode(invocation),
            'Isolate library and compiler mismatch.');
      }
      _pushStaticInvocation(callInIsolate, inputs, commonMasks.dynamicType);
    }
  }

  void handleForeignDartClosureToJs(
      ir.StaticInvocation invocation, String name) {
    // TODO(sra): Do we need to wrap the closure in something that saves the
    // current isolate?
    handleForeignRawFunctionRef(invocation, name);
  }

  void handleForeignRawFunctionRef(
      ir.StaticInvocation invocation, String name) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Expression closure = invocation.arguments.positional.single;
    String problem = 'requires a static method or top-level method';
    if (closure is ir.StaticGet) {
      ir.Member staticTarget = closure.target;
      if (staticTarget is ir.Procedure) {
        if (staticTarget.kind == ir.ProcedureKind.Method) {
          ir.FunctionNode function = staticTarget.function;
          if (function != null &&
              function.requiredParameterCount ==
                  function.positionalParameters.length &&
              function.namedParameters.isEmpty) {
            registry?.registerStaticUse(
                new StaticUse.foreignUse(astAdapter.getMember(staticTarget)));
            push(new HForeignCode(
                js.js.expressionTemplateYielding(backend.emitter
                    .staticFunctionAccess(astAdapter.getMember(staticTarget))),
                commonMasks.dynamicType,
                <HInstruction>[],
                nativeBehavior: native.NativeBehavior.PURE));
            return;
          }
          problem = 'does not handle a closure with optional parameters';
        }
      }
    }

    compiler.reporter.reportErrorMessage(astAdapter.getNode(invocation),
        MessageKind.GENERIC, {'text': "'$name' $problem."});
    stack.add(graph.addConstantNull(closedWorld)); // Result expected on stack.
    return;
  }

  void handleForeignJsSetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    String isolateName = backend.namer.staticStateHolder;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeignCode(js.js.parseForeignJS("$isolateName = #"),
        commonMasks.dynamicType, inputs,
        nativeBehavior: native.NativeBehavior.CHANGES_OTHER,
        effects: sideEffects));
  }

  void handleForeignJsGetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 0, 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    push(new HForeignCode(js.js.parseForeignJS(backend.namer.staticStateHolder),
        commonMasks.dynamicType, <HInstruction>[],
        nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
  }

  void handleForeignJsGetName(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Node argument = invocation.arguments.positional.first;
    argument.accept(this);
    HInstruction instruction = pop();

    if (instruction is HConstant) {
      js.Name name =
          astAdapter.getNameForJsGetName(argument, instruction.constant);
      stack.add(graph.addConstantStringFromName(name, closedWorld));
      return;
    }

    compiler.reporter.reportErrorMessage(
        astAdapter.getNode(argument),
        MessageKind.GENERIC,
        {'text': 'Error: Expected a JsGetName enum value.'});
    // Result expected on stack.
    stack.add(graph.addConstantNull(closedWorld));
  }

  void handleForeignJsEmbeddedGlobal(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    String globalName = _foreignConstantStringArgument(
        invocation, 1, 'JS_EMBEDDED_GLOBAL', 'second ');
    js.Template expr = js.js.expressionTemplateYielding(
        backend.emitter.generateEmbeddedGlobalAccess(globalName));

    native.NativeBehavior nativeBehavior =
        astAdapter.getNativeBehavior(invocation);
    assert(invariant(astAdapter.getNode(invocation), nativeBehavior != null,
        message: "No NativeBehavior for $invocation"));

    TypeMask ssaType =
        astAdapter.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(new HForeignCode(expr, ssaType, const <HInstruction>[],
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsBuiltin(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<ir.Expression> arguments = invocation.arguments.positional;
    ir.Expression nameArgument = arguments[1];

    nameArgument.accept(this);
    HInstruction instruction = pop();

    js.Template template;
    if (instruction is HConstant) {
      template = astAdapter.getJsBuiltinTemplate(instruction.constant);
    }
    if (template == null) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(nameArgument),
          MessageKind.GENERIC,
          {'text': 'Error: Expected a JsBuiltin enum value.'});
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = <HInstruction>[];
    for (ir.Expression argument in arguments.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    native.NativeBehavior nativeBehavior =
        astAdapter.getNativeBehavior(invocation);
    assert(invariant(astAdapter.getNode(invocation), nativeBehavior != null,
        message: "No NativeBehavior for $invocation"));

    TypeMask ssaType =
        astAdapter.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(new HForeignCode(template, ssaType, inputs,
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsGetFlag(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantBool(false, closedWorld));
      return;
    }
    String name = _foreignConstantStringArgument(invocation, 0, 'JS_GET_FLAG');
    bool value = false;
    switch (name) {
      case 'MUST_RETAIN_METADATA':
        value = backend.mustRetainMetadata;
        break;
      case 'USE_CONTENT_SECURITY_POLICY':
        value = compiler.options.useContentSecurityPolicy;
        break;
      default:
        compiler.reporter.reportErrorMessage(
            astAdapter.getNode(invocation),
            MessageKind.GENERIC,
            {'text': 'Error: Unknown internal flag "$name".'});
    }
    stack.add(graph.addConstantBool(value, closedWorld));
  }

  void handleJsInterceptorConstant(ir.StaticInvocation invocation) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    ir.Expression argument = invocation.arguments.positional.single;
    argument.accept(this);
    HInstruction argumentInstruction = pop();
    if (argumentInstruction is HConstant) {
      ConstantValue argumentConstant = argumentInstruction.constant;
      if (argumentConstant is TypeConstantValue) {
        // TODO(sra): Check that type is a subclass of [Interceptor].
        ConstantValue constant =
            new InterceptorConstantValue(argumentConstant.representedType);
        HInstruction instruction = graph.addConstant(constant, closedWorld);
        stack.add(instruction);
        return;
      }
    }

    compiler.reporter.reportErrorMessage(astAdapter.getNode(invocation),
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(closedWorld));
  }

  void handleForeignJs(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    native.NativeBehavior nativeBehavior =
        astAdapter.getNativeBehaviorForJsCall(invocation);
    assert(invariant(astAdapter.getNode(invocation), nativeBehavior != null,
        message: "No NativeBehavior for $invocation"));

    List<HInstruction> inputs = <HInstruction>[];
    for (ir.Expression argument in invocation.arguments.positional.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    if (nativeBehavior.codeTemplate.positionalArgumentCount != inputs.length) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation), MessageKind.GENERIC, {
        'text': 'Mismatch between number of placeholders'
            ' and number of arguments.'
      });
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (native.HasCapturedPlaceholders.check(nativeBehavior.codeTemplate.ast)) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation), MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    TypeMask ssaType =
        astAdapter.typeFromNativeBehavior(nativeBehavior, closedWorld);

    SourceInformation sourceInformation = null;
    push(new HForeignCode(nativeBehavior.codeTemplate, ssaType, inputs,
        isStatement: !nativeBehavior.codeTemplate.isExpression,
        effects: nativeBehavior.sideEffects,
        nativeBehavior: nativeBehavior)..sourceInformation = sourceInformation);
  }

  void handleJsStringConcat(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);
    push(new HStringConcat(inputs[0], inputs[1], commonMasks.stringType));
  }

  void _pushStaticInvocation(
      ir.Node target, List<HInstruction> arguments, TypeMask typeMask) {
    HInvokeStatic instruction = new HInvokeStatic(
        astAdapter.getMember(target), arguments, typeMask,
        targetCanThrow: astAdapter.getCanThrow(target, closedWorld));
    if (currentImplicitInstantiations.isNotEmpty) {
      instruction.instantiatedTypes =
          new List<DartType>.from(currentImplicitInstantiations);
    }
    instruction.sideEffects = astAdapter.getSideEffects(target, closedWorld);

    push(instruction);
  }

  void _pushDynamicInvocation(
      ir.Node node, TypeMask mask, List<HInstruction> arguments,
      {Selector selector}) {
    HInstruction receiver = arguments.first;
    List<HInstruction> inputs = <HInstruction>[];

    selector ??= astAdapter.getSelector(node);
    bool isIntercepted = astAdapter.isInterceptedSelector(selector);

    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    TypeMask type = astAdapter.selectorTypeOf(selector, mask);
    if (selector.isGetter) {
      push(new HInvokeDynamicGetter(selector, mask, null, inputs, type));
    } else if (selector.isSetter) {
      push(new HInvokeDynamicSetter(selector, mask, null, inputs, type));
    } else {
      push(new HInvokeDynamicMethod(
          selector, mask, inputs, type, isIntercepted));
    }
  }

  @override
  visitFunctionNode(ir.FunctionNode node) {
    LocalFunctionElement methodElement = astAdapter.getElement(node);
    ClosureClassMap nestedClosureData = compiler.closureToClassMapper
        .getClosureToClassMapping(methodElement.resolvedAst);
    assert(nestedClosureData != null);
    assert(nestedClosureData.closureClassElement != null);
    ClosureClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    // TODO(ahe): This should be registered in codegen, not here.
    // TODO(johnniwinther): Is [registerStaticUse] equivalent to
    // [addToWorkList]?
    registry?.registerStaticUse(new StaticUse.foreignUse(callElement));

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureClassElement.closureFields.forEach((ClosureFieldElement field) {
      Local capturedLocal =
          nestedClosureData.getLocalVariableForClosureField(field);
      assert(capturedLocal != null);
      capturedVariables.add(localsHandler.readLocal(capturedLocal));
    });

    TypeMask type = new TypeMask.nonNullExact(closureClassElement, closedWorld);
    // TODO(efortuna): Add source information here.
    push(new HCreate(closureClassElement, capturedVariables, type));

    registry?.registerInstantiatedClosure(methodElement);
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration declaration) {
    assert(isReachable);
    declaration.function.accept(this);
    LocalFunctionElement localFunction =
        astAdapter.getElement(declaration.function);
    localsHandler.updateLocal(localFunction, pop());
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression funcExpression) {
    funcExpression.function.accept(this);
  }

  // TODO(het): Decide when to inline
  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    // Handle `x == null` specially. When these come from null-aware operators,
    // there is no mapping in the astAdapter.
    if (_handleEqualsNull(invocation)) return;
    invocation.receiver.accept(this);
    HInstruction receiver = pop();
    Selector selector = astAdapter.getSelector(invocation);
    _pushDynamicInvocation(
        invocation,
        astAdapter.typeOfInvocation(invocation, closedWorld),
        <HInstruction>[receiver]
          ..addAll(
              _visitArgumentsForDynamicTarget(selector, invocation.arguments)));
  }

  bool _handleEqualsNull(ir.MethodInvocation invocation) {
    if (invocation.name.name == '==') {
      ir.Arguments arguments = invocation.arguments;
      if (arguments.types.isEmpty &&
          arguments.positional.length == 1 &&
          arguments.named.isEmpty) {
        bool finish(ir.Expression comparand) {
          comparand.accept(this);
          pushCheckNull(pop());
          return true;
        }

        ir.Expression receiver = invocation.receiver;
        ir.Expression argument = arguments.positional.first;
        if (argument is ir.NullLiteral) return finish(receiver);
        if (receiver is ir.NullLiteral) return finish(argument);
      }
    }
    return false;
  }

  HInterceptor _interceptorFor(HInstruction intercepted) {
    HInterceptor interceptor =
        new HInterceptor(intercepted, commonMasks.nonNullType);
    add(interceptor);
    return interceptor;
  }

  static ir.Class _containingClass(ir.TreeNode node) {
    while (node != null) {
      if (node is ir.Class) return node;
      node = node.parent;
    }
    return null;
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation invocation) {
    Selector selector = astAdapter.getSelector(invocation);
    List<HInstruction> arguments = _visitArgumentsForStaticTarget(
        invocation.interfaceTarget.function, invocation.arguments);
    HInstruction receiver = localsHandler.readThis();
    ir.Class surroundingClass = _containingClass(invocation);

    List<HInstruction> inputs = <HInstruction>[];
    if (astAdapter.isIntercepted(invocation)) {
      inputs.add(_interceptorFor(receiver));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);

    HInstruction instruction = new HInvokeSuper(
        astAdapter.getMethod(invocation.interfaceTarget),
        astAdapter.getClass(surroundingClass),
        selector,
        inputs,
        astAdapter.returnTypeOf(invocation.interfaceTarget),
        null,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        closedWorld.getSideEffectsOfSelector(selector, null);
    push(instruction);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation invocation) {
    ir.Constructor target = invocation.target;
    // TODO(sra): For JS-interop targets, process arguments differently.
    List<HInstruction> arguments =
        _visitArgumentsForStaticTarget(target.function, invocation.arguments);
    TypeMask typeMask = new TypeMask.nonNullExact(
        astAdapter.getElement(target.enclosingClass), closedWorld);
    _pushStaticInvocation(target, arguments, typeMask);
  }

  @override
  void visitIsExpression(ir.IsExpression isExpression) {
    isExpression.operand.accept(this);
    HInstruction expression = pop();
    push(buildIsNode(isExpression, isExpression.type, expression));
  }

  HInstruction buildIsNode(
      ir.Node node, ir.DartType type, HInstruction expression) {
    // Note: The call to "unalias" this type like in the original SSA builder is
    // unnecessary in kernel because Kernel has no notion of typedef.
    // TODO(efortuna): Add test for this.
    DartType typeValue =
        localsHandler.substInContext(astAdapter.getDartType(type));
    if (type is ir.InvalidType) {
      generateTypeError(node, (typeValue.element as ErroneousElement).message);
      return new HIs.compound(
          typeValue, expression, pop(), commonMasks.boolType);
    }

    if (type is ir.FunctionType) {
      List arguments = [buildFunctionType(typeValue), expression];
      _pushDynamicInvocation(node, null, arguments,
          selector: new Selector.call(
              new PrivateName('_isTest', backend.helpers.jsHelperLibrary),
              CallStructure.ONE_ARG));
      return new HIs.compound(
          typeValue, expression, pop(), commonMasks.boolType);
    }

    if (type is ir.TypeParameterType) {
      HInstruction runtimeType =
          typeBuilder.addTypeVariableReference(typeValue, sourceElement);
      _pushStaticInvocation(astAdapter.checkSubtypeOfRuntimeType,
          <HInstruction>[expression, runtimeType], commonMasks.boolType);
      return new HIs.variable(
          typeValue, expression, pop(), commonMasks.boolType);
    }

    if (_isInterfaceWithNoDynamicTypes(type)) {
      HInstruction representations = typeBuilder
          .buildTypeArgumentRepresentations(typeValue, sourceElement);
      add(representations);
      ClassElement element = typeValue.element;
      js.Name operator = backend.namer.operatorIs(element);
      HInstruction isFieldName =
          graph.addConstantStringFromName(operator, closedWorld);
      HInstruction asFieldName = closedWorld.hasAnyStrictSubtype(element)
          ? graph.addConstantStringFromName(
              backend.namer.substitutionName(element), closedWorld)
          : graph.addConstantNull(closedWorld);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        isFieldName,
        representations,
        asFieldName
      ];
      _pushStaticInvocation(
          astAdapter.checkSubtype, inputs, commonMasks.boolType);
      return new HIs.compound(
          typeValue, expression, pop(), commonMasks.boolType);
    }

    if (backend.hasDirectCheckFor(typeValue)) {
      return new HIs.direct(typeValue, expression, commonMasks.boolType);
    }
    // The interceptor is not always needed.  It is removed by optimization
    // when the receiver type or tested type permit.
    return new HIs.raw(typeValue, expression, _interceptorFor(expression),
        commonMasks.boolType);
  }

  bool _isInterfaceWithNoDynamicTypes(ir.DartType type) {
    bool isMethodTypeVariableType(ir.DartType typeArgType) {
      return (typeArgType is ir.TypeParameterType &&
          typeArgType.parameter.parent is ir.FunctionNode);
    }

    return type is ir.InterfaceType &&
        (type as ir.InterfaceType).typeArguments.any(
            (ir.DartType typeArgType) =>
                typeArgType is! ir.DynamicType &&
                typeArgType is! ir.InvalidType &&
                !isMethodTypeVariableType(type));
  }

  @override
  void visitThrow(ir.Throw throwNode) {
    _visitThrowExpression(throwNode.expression);
    if (isReachable) {
      push(new HThrowExpression(pop(), null));
      isReachable = false;
    }
  }

  void _visitThrowExpression(ir.Expression expression) {
    bool old = _inExpressionOfThrow;
    try {
      _inExpressionOfThrow = true;
      expression.accept(this);
    } finally {
      _inExpressionOfThrow = old;
    }
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    stack.add(localsHandler.readThis());
  }

  @override
  void visitNot(ir.Not not) {
    not.operand.accept(this);
    push(new HNot(popBoolified(), commonMasks.boolType));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = new KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result);
  }

  @override
  void visitTryCatch(ir.TryCatch tryCatch) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(this);
    tryCatch.body.accept(this);
    tryBuilder
      ..closeTryBody()
      ..buildCatch(tryCatch)
      ..cleanUp();
  }

  /// `try { ... } catch { ... } finally { ... }` statements are a little funny
  /// because a try can have one or both of {catch|finally}. The way this is
  /// encoded in kernel AST are two separate classes with no common superclass
  /// aside from Statement. If a statement has both `catch` and `finally`
  /// clauses then it is encoded in kernel as so that the TryCatch is the body
  /// statement of the TryFinally. To produce more efficient code rather than
  /// nested try statements, the visitors avoid one potential level of
  /// recursion.
  @override
  void visitTryFinally(ir.TryFinally tryFinally) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(this);

    // We do these shenanigans to produce better looking code that doesn't
    // have nested try statements.
    if (tryFinally.body is ir.TryCatch) {
      ir.TryCatch tryCatch = tryFinally.body;
      tryCatch.body.accept(this);
      tryBuilder
        ..closeTryBody()
        ..buildCatch(tryCatch);
    } else {
      tryFinally.body.accept(this);
      tryBuilder.closeTryBody();
    }

    tryBuilder
      ..buildFinallyBlock(tryFinally)
      ..cleanUp();
  }
}

/// Class in charge of building try, catch and/or finally blocks. This handles
/// the instructions that need to be output and the dominator calculation of
/// this sequence of code.
class TryCatchFinallyBuilder {
  HBasicBlock enterBlock;
  HBasicBlock startTryBlock;
  HBasicBlock endTryBlock;
  HBasicBlock startCatchBlock;
  HBasicBlock endCatchBlock;
  HBasicBlock startFinallyBlock;
  HBasicBlock endFinallyBlock;
  HBasicBlock exitBlock;
  HTry tryInstruction;
  HLocalValue exception;
  KernelSsaBuilder kernelBuilder;

  SubGraph bodyGraph;
  SubGraph catchGraph;
  SubGraph finallyGraph;

  // The original set of locals that were defined before this try block.
  // The catch block and the finally block must not reuse the existing locals
  // handler. None of the variables that have been defined in the body-block
  // will be used, but for loops we will add (unnecessary) phis that will
  // reference the body variables. This makes it look as if the variables were
  // used in a non-dominated block.
  LocalsHandler originalSavedLocals;

  TryCatchFinallyBuilder(this.kernelBuilder) {
    tryInstruction = new HTry();
    originalSavedLocals = new LocalsHandler.from(kernelBuilder.localsHandler);
    enterBlock = kernelBuilder.openNewBlock();
    kernelBuilder.close(tryInstruction);

    startTryBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startTryBlock);
  }

  void _addExitTrySuccessor(successor) {
    if (successor == null) return;
    // Iterate over all blocks created inside this try/catch, and
    // attach successor information to blocks that end with
    // [HExitTry].
    for (int i = startTryBlock.id; i < successor.id; i++) {
      HBasicBlock block = kernelBuilder.graph.blocks[i];
      var last = block.last;
      if (last is HExitTry) {
        block.addSuccessor(successor);
      }
    }
  }

  void _addOptionalSuccessor(block1, block2) {
    if (block2 != null) block1.addSuccessor(block2);
  }

  /// Helper function to set up basic block successors for try-catch-finally
  /// sequences.
  void _setBlockSuccessors() {
    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body, 2) the catch, 3) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    _addOptionalSuccessor(enterBlock, startCatchBlock);
    _addOptionalSuccessor(enterBlock, startFinallyBlock);
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
    endCatchBlock?.addSuccessor(
        startFinallyBlock != null ? startFinallyBlock : exitBlock);

    // The finally block has the exit block as successor.
    endFinallyBlock?.addSuccessor(exitBlock);

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitely mark this block a predecessor of the catch
    // block and the finally block.
    _addExitTrySuccessor(startCatchBlock);
    _addExitTrySuccessor(startFinallyBlock);
  }

  /// Build the finally{} clause of a try/{catch}/finally statement. Note this
  /// does not examine the body of the try clause, only the finally portion.
  void buildFinallyBlock(ir.TryFinally tryFinally) {
    kernelBuilder.localsHandler = new LocalsHandler.from(originalSavedLocals);
    startFinallyBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startFinallyBlock);
    tryFinally.finalizer.accept(kernelBuilder);
    if (!kernelBuilder.isAborted()) {
      endFinallyBlock = kernelBuilder.close(new HGoto());
    }
    tryInstruction.finallyBlock = startFinallyBlock;
    finallyGraph =
        new SubGraph(startFinallyBlock, kernelBuilder.lastOpenedBlock);
  }

  void closeTryBody() {
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have multiple successors: the join block, and
    // the catch or finally block.
    if (!kernelBuilder.isAborted()) {
      endTryBlock = kernelBuilder.close(new HExitTry());
    }
    bodyGraph = new SubGraph(startTryBlock, kernelBuilder.lastOpenedBlock);
  }

  void buildCatch(ir.TryCatch tryCatch) {
    kernelBuilder.localsHandler = new LocalsHandler.from(originalSavedLocals);
    startCatchBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startCatchBlock);
    // Note that the name of this local is irrelevant.
    SyntheticLocal local = new SyntheticLocal(
        'exception', kernelBuilder.localsHandler.executableContext);
    exception = new HLocalValue(local, kernelBuilder.commonMasks.nonNullType);
    kernelBuilder.add(exception);
    HInstruction oldRethrowableException = kernelBuilder.rethrowableException;
    kernelBuilder.rethrowableException = exception;

    kernelBuilder._pushStaticInvocation(
        kernelBuilder.astAdapter.exceptionUnwrapper,
        [exception],
        kernelBuilder.astAdapter.exceptionUnwrapperType);
    HInvokeStatic unwrappedException = kernelBuilder.pop();
    tryInstruction.exception = exception;
    int catchesIndex = 0;

    void pushCondition(ir.Catch catchBlock) {
      if (catchBlock.guard is! ir.DynamicType) {
        HInstruction condition = kernelBuilder.buildIsNode(
            catchBlock.exception, catchBlock.guard, unwrappedException);
        kernelBuilder.push(condition);
      } else {
        kernelBuilder.stack.add(kernelBuilder.graph
            .addConstantBool(true, kernelBuilder.closedWorld));
      }
    }

    void visitThen() {
      ir.Catch catchBlock = tryCatch.catches[catchesIndex];
      catchesIndex++;
      if (catchBlock.exception != null) {
        LocalVariableElement exceptionVariable =
            kernelBuilder.astAdapter.getElement(catchBlock.exception);
        kernelBuilder.localsHandler
            .updateLocal(exceptionVariable, unwrappedException);
      }
      if (catchBlock.stackTrace != null) {
        kernelBuilder._pushStaticInvocation(
            kernelBuilder.astAdapter.traceFromException,
            [exception],
            kernelBuilder.astAdapter.traceFromExceptionType);
        HInstruction traceInstruction = kernelBuilder.pop();
        LocalVariableElement traceVariable =
            kernelBuilder.astAdapter.getElement(catchBlock.stackTrace);
        kernelBuilder.localsHandler
            .updateLocal(traceVariable, traceInstruction);
      }
      catchBlock.body.accept(kernelBuilder);
    }

    void visitElse() {
      if (catchesIndex >= tryCatch.catches.length) {
        kernelBuilder.closeAndGotoExit(new HThrow(
            exception, exception.sourceInformation,
            isRethrow: true));
      } else {
        // TODO(efortuna): Make SsaBranchBuilder handle kernel elements, and
        // pass tryCatch in here as the "diagnosticNode".
        kernelBuilder.handleIf(
            visitCondition: () {
              pushCondition(tryCatch.catches[catchesIndex]);
            },
            visitThen: visitThen,
            visitElse: visitElse);
      }
    }

    ir.Catch firstBlock = tryCatch.catches[catchesIndex];
    // TODO(efortuna): Make SsaBranchBuilder handle kernel elements, and then
    // pass tryCatch in here as the "diagnosticNode".
    kernelBuilder.handleIf(
        visitCondition: () {
          pushCondition(firstBlock);
        },
        visitThen: visitThen,
        visitElse: visitElse);
    if (!kernelBuilder.isAborted()) {
      endCatchBlock = kernelBuilder.close(new HGoto());
    }

    kernelBuilder.rethrowableException = oldRethrowableException;
    tryInstruction.catchBlock = startCatchBlock;
    catchGraph = new SubGraph(startCatchBlock, kernelBuilder.lastOpenedBlock);
  }

  void cleanUp() {
    exitBlock = kernelBuilder.graph.addNewBlock();
    _setBlockSuccessors();

    // Use the locals handler not altered by the catch and finally
    // blocks.
    kernelBuilder.localsHandler = originalSavedLocals;
    kernelBuilder.open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(
            kernelBuilder.wrapStatementGraph(bodyGraph),
            exception,
            kernelBuilder.wrapStatementGraph(catchGraph),
            kernelBuilder.wrapStatementGraph(finallyGraph)),
        exitBlock);
  }
}
