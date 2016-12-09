// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/text/ast_to_text.dart' show debugNodeToString;

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
import '../dart_types.dart';
import '../elements/elements.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/kernel.dart';
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart';
import '../tree/dartstring.dart';
import '../tree/nodes.dart' show FunctionExpression, Node;
import '../types/masks.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart';
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/side_effects.dart' show SideEffects;
import 'graph_builder.dart';
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

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      AstElement element = work.element.implementation;
      Kernel kernel = backend.kernelTask.kernel;
      KernelSsaBuilder builder = new KernelSsaBuilder(element, work.resolvedAst,
          backend.compiler, work.registry, sourceInformationFactory, kernel);
      HGraph graph = builder.build();

      if (backend.compiler.tracer.isEnabled) {
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
        backend.compiler.tracer.traceCompilation(name);
        backend.compiler.tracer.traceGraph('builder', graph);
      }

      return graph;
    });
  }
}

class KernelSsaBuilder extends ir.Visitor with GraphBuilder {
  ir.Node target;
  final AstElement targetElement;
  final ResolvedAst resolvedAst;
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
      stack.add(graph.addConstantNull(compiler));
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
          value, compiler.coreTypes.boolType,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, backend.boolType);
    add(result);
    return result;
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
            astAdapter.getClass(constructor.enclosingClass),
            compiler.closedWorld),
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
        fieldValues[field] = graph.addConstantNull(compiler);
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
    var foundSuperCall = false;
    for (var initializer in constructor.initializers) {
      if (initializer is ir.SuperInitializer) {
        foundSuperCall = true;
        var superConstructor = initializer.target;
        var arguments = _normalizeAndBuildArguments(
            superConstructor.function, initializer.arguments);
        _buildInlinedSuperInitializers(
            superConstructor, arguments, fieldValues);
      } else if (initializer is ir.FieldInitializer) {
        initializer.value.accept(this);
        fieldValues[initializer.field] = pop();
      }
    }

    // TODO(het): does kernel always set the super initializer at the end?
    // If there was no super-call initializer, then call the default constructor
    // in the superclass.
    if (!foundSuperCall) {
      if (constructor.enclosingClass != astAdapter.objectClass) {
        var superclass = constructor.enclosingClass.superclass;
        var defaultConstructor = superclass.constructors
            .firstWhere((c) => c.name == '', orElse: () => null);
        if (defaultConstructor == null) {
          compiler.reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Could not find default constructor.');
        }
        _buildInlinedSuperInitializers(
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
          builtArguments.add(graph.addConstant(constantValue, compiler));
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
          builtArguments.add(graph.addConstant(constantValue, compiler));
        }
      });
    }

    return builtArguments;
  }

  /// Inlines the given super [constructor]'s initializers by collecting it's
  /// field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _buildInlinedSuperInitializers(ir.Constructor constructor,
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
    push(new HIdentity(
        expression, graph.addConstantNull(compiler), null, backend.boolType));
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
    HInstruction nullValue = graph.addConstantNull(compiler);
    HInstruction errorMessage =
        graph.addConstantString(new DartString.literal(message), compiler);
    HInstruction trap = new HForeignCode(js.js.parseForeignJS("#.#"),
        backend.dynamicType, <HInstruction>[nullValue, errorMessage]);
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
      value = graph.addConstantNull(compiler);
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
        return graph.addConstantBool(true, compiler);
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
    if (astAdapter.isJsIndexableIterator(forInStatement)) {
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
          astAdapter.jsIndexableLength, array, backend.positiveIntType,
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
      push(new HIdentity(length, originalLength, null, backend.boolType));
      _pushStaticInvocation(
          astAdapter.checkConcurrentModificationError,
          [pop(), array],
          astAdapter.checkConcurrentModificationErrorReturnType);
      pop();
    }

    void buildInitializer() {
      forInStatement.iterable.accept(this);
      array = pop();
      isFixed = astAdapter.isFixedLength(array.instructionType);
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, compiler));
      originalLength = buildGetLength();
    }

    HInstruction buildCondition() {
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction length = buildGetLength();
      HInstruction compare = new HLess(index, length, null, backend.boolType);
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
      HInstruction one = graph.addConstantInt(1, compiler);
      HInstruction addInstruction =
          new HAdd(index, one, null, backend.positiveIntType);
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
        backend.dynamicType);

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
        graph.addConstantString(new DartString.literal(message), compiler);
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
    stack.add(graph.addConstantInt(intLiteral.value, compiler));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral doubleLiteral) {
    stack.add(graph.addConstantDouble(doubleLiteral.value, compiler));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral boolLiteral) {
    stack.add(graph.addConstantBool(boolLiteral.value, compiler));
  }

  @override
  void visitStringLiteral(ir.StringLiteral stringLiteral) {
    stack.add(graph.addConstantString(
        new DartString.literal(stringLiteral.value), compiler));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral symbolLiteral) {
    stack.add(graph.addConstant(
        astAdapter.getConstantForSymbol(symbolLiteral), compiler));
    registry?.registerConstSymbol(symbolLiteral.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral nullLiteral) {
    stack.add(graph.addConstantNull(compiler));
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
      listInstruction =
          graph.addConstant(astAdapter.getConstantFor(listLiteral), compiler);
    } else {
      List<HInstruction> elements = <HInstruction>[];
      for (ir.Expression element in listLiteral.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction = new HLiteralList(elements, backend.extendableArrayType);
      add(listInstruction);
      listInstruction =
          setListRuntimeTypeInfoIfNeeded(listInstruction, listLiteral);
    }

    TypeMask type = astAdapter.typeOfListLiteral(targetElement, listLiteral);
    if (!type.containsAll(compiler.closedWorld)) {
      listInstruction.instructionType = type;
    }
    stack.add(listInstruction);
  }

  @override
  void visitMapLiteral(ir.MapLiteral mapLiteral) {
    if (mapLiteral.isConst) {
      stack.add(
          graph.addConstant(astAdapter.getConstantFor(mapLiteral), compiler));
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
          new HLiteralList(constructorArgs, backend.extendableArrayType);
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
    assert(constructor.kind == ir.ProcedureKind.Factory);

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).
    TypeMask mapType = new TypeMask.nonNullSubtype(
        astAdapter.getElement(astAdapter.mapLiteralClass),
        compiler.closedWorld);
    TypeMask returnTypeMask = TypeMaskFactory.inferredReturnTypeForElement(
        astAdapter.getElement(constructor), compiler);
    TypeMask instructionType =
        mapType.intersection(returnTypeMask, compiler.closedWorld);

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
      stack.add(graph.addConstant(constant, compiler));
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
          <HInstruction>[value], backend.stringType);
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
          astAdapter.getConstantFor(staticTarget.initializer), compiler));
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

    _pushDynamicInvocation(propertySet, astAdapter.typeOfSet(propertySet),
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
      HInstruction initialValue = graph.addConstantNull(compiler);
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
    if (initializer == null) return graph.addConstantNull(compiler);
    // TODO(sra): Evaluate constant in ir.Node domain.
    ConstantValue constant =
        astAdapter.getConstantForParameterDefaultValue(initializer);
    if (constant == null) return graph.addConstantNull(compiler);
    return graph.addConstant(constant, compiler);
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
      stack.add(graph.addConstantNull(compiler));
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
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    if (!backend.hasIsolateSupport) {
      // If the isolate library is not used, we just generate code
      // to fetch the static state.
      String name = backend.namer.staticStateHolder;
      push(new HForeignCode(
          js.js.parseForeignJS(name), backend.dynamicType, <HInstruction>[],
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
      _pushStaticInvocation(target, <HInstruction>[], backend.dynamicType);
    }
  }

  void handleForeignJsCallInIsolate(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    if (!backend.hasIsolateSupport) {
      // If the isolate library is not used, we ignore the isolate argument and
      // just invoke the closure.
      push(new HInvokeClosure(new Selector.callClosure(0),
          <HInstruction>[inputs[1]], backend.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      ir.Procedure callInIsolate = astAdapter.callInIsolate;
      if (callInIsolate == null) {
        compiler.reporter.internalError(astAdapter.getNode(invocation),
            'Isolate library and compiler mismatch.');
      }
      _pushStaticInvocation(callInIsolate, inputs, backend.dynamicType);
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
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
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
                backend.dynamicType,
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
    stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
    return;
  }

  void handleForeignJsSetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    String isolateName = backend.namer.staticStateHolder;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeignCode(
        js.js.parseForeignJS("$isolateName = #"), backend.dynamicType, inputs,
        nativeBehavior: native.NativeBehavior.CHANGES_OTHER,
        effects: sideEffects));
  }

  void handleForeignJsGetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 0, 0)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    push(new HForeignCode(js.js.parseForeignJS(backend.namer.staticStateHolder),
        backend.dynamicType, <HInstruction>[],
        nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
  }

  void handleForeignJsGetName(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    ir.Node argument = invocation.arguments.positional.first;
    argument.accept(this);
    HInstruction instruction = pop();

    if (instruction is HConstant) {
      js.Name name =
          astAdapter.getNameForJsGetName(argument, instruction.constant);
      stack.add(graph.addConstantStringFromName(name, compiler));
      return;
    }

    compiler.reporter.reportErrorMessage(
        astAdapter.getNode(argument),
        MessageKind.GENERIC,
        {'text': 'Error: Expected a JsGetName enum value.'});
    stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
  }

  void handleForeignJsEmbeddedGlobal(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
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

    TypeMask ssaType = astAdapter.typeFromNativeBehavior(nativeBehavior);
    push(new HForeignCode(expr, ssaType, const <HInstruction>[],
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsBuiltin(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
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
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
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

    TypeMask ssaType = astAdapter.typeFromNativeBehavior(nativeBehavior);
    push(new HForeignCode(template, ssaType, inputs,
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsGetFlag(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(
          graph.addConstantBool(false, compiler)); // Result expected on stack.
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
    stack.add(graph.addConstantBool(value, compiler));
  }

  void handleJsInterceptorConstant(ir.StaticInvocation invocation) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
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
        HInstruction instruction = graph.addConstant(constant, compiler);
        stack.add(instruction);
        return;
      }
    }

    compiler.reporter.reportErrorMessage(astAdapter.getNode(invocation),
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(compiler));
  }

  void handleForeignJs(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    native.NativeBehavior nativeBehavior =
        astAdapter.getNativeBehavior(invocation);
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
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }

    if (native.HasCapturedPlaceholders.check(nativeBehavior.codeTemplate.ast)) {
      compiler.reporter.reportErrorMessage(
          astAdapter.getNode(invocation), MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    TypeMask ssaType = astAdapter.typeFromNativeBehavior(nativeBehavior);

    SourceInformation sourceInformation = null;
    push(new HForeignCode(nativeBehavior.codeTemplate, ssaType, inputs,
        isStatement: !nativeBehavior.codeTemplate.isExpression,
        effects: nativeBehavior.sideEffects,
        nativeBehavior: nativeBehavior)..sourceInformation = sourceInformation);
  }

  void handleJsStringConcat(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      stack.add(graph.addConstantNull(compiler)); // Result expected on stack.
      return;
    }
    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);
    push(new HStringConcat(inputs[0], inputs[1], backend.stringType));
  }

  void _pushStaticInvocation(
      ir.Node target, List<HInstruction> arguments, TypeMask typeMask) {
    HInvokeStatic instruction = new HInvokeStatic(
        astAdapter.getMember(target), arguments, typeMask,
        targetCanThrow: astAdapter.getCanThrow(target));
    if (currentImplicitInstantiations.isNotEmpty) {
      instruction.instantiatedTypes =
          new List<DartType>.from(currentImplicitInstantiations);
    }
    instruction.sideEffects = astAdapter.getSideEffects(target);

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

    TypeMask type =
        new TypeMask.nonNullExact(closureClassElement, compiler.closedWorld);
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
        astAdapter.typeOfInvocation(invocation),
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
        new HInterceptor(intercepted, backend.nonNullType);
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
        compiler.closedWorld.getSideEffectsOfSelector(selector, null);
    push(instruction);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation invocation) {
    ir.Constructor target = invocation.target;
    // TODO(sra): For JS-interop targets, process arguments differently.
    List<HInstruction> arguments =
        _visitArgumentsForStaticTarget(target.function, invocation.arguments);
    TypeMask typeMask = new TypeMask.nonNullExact(
        astAdapter.getElement(target.enclosingClass), compiler.closedWorld);
    _pushStaticInvocation(target, arguments, typeMask);
  }

  @override
  void visitIsExpression(ir.IsExpression isExpression) {
    isExpression.operand.accept(this);
    HInstruction expression = pop();

    // TODO(sra): Convert the type testing logic here to use ir.DartType.
    DartType type = astAdapter.getDartType(isExpression.type);

    type = localsHandler.substInContext(type).unaliased;

    if (type is MethodTypeVariableType) {
      push(graph.addConstantBool(true, compiler));
      return;
    }

    if (type is MalformedType) {
      ErroneousElement element = type.element;
      generateTypeError(isExpression, element.message);
      push(new HIs.compound(type, expression, pop(), backend.boolType));
      return;
    }

    if (type.isFunctionType) {
      List arguments = <HInstruction>[buildFunctionType(type), expression];
      _pushDynamicInvocation(isExpression, backend.boolType, arguments,
          selector: new Selector.call(
              new PrivateName('_isTest', astAdapter.jsHelperLibrary),
              CallStructure.ONE_ARG));
      push(new HIs.compound(type, expression, pop(), backend.boolType));
      return;
    }

    if (type.isTypeVariable) {
      HInstruction runtimeType =
          typeBuilder.addTypeVariableReference(type, sourceElement);
      _pushStaticInvocation(astAdapter.checkSubtypeOfRuntimeType,
          <HInstruction>[expression, runtimeType], backend.boolType);
      push(new HIs.variable(type, expression, pop(), backend.boolType));
      return;
    }

    // TODO(sra): Type with type parameters.

    if (backend.hasDirectCheckFor(type)) {
      push(new HIs.direct(type, expression, backend.boolType));
      return;
    }

    // The interceptor is not always needed.  It is removed by optimization
    // when the receiver type or tested type permit.
    HInterceptor interceptor = _interceptorFor(expression);
    push(new HIs.raw(type, expression, interceptor, backend.boolType));
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
    push(new HNot(popBoolified(), backend.boolType));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = new KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result);
  }
}
