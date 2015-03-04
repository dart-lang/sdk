// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.ir_builder;

/**
 * This task iterates through all resolved elements and builds [ir.Node]s. The
 * nodes are stored in the [nodes] map and accessible through [hasIr] and
 * [getIr].
 *
 * The functionality of the IrNodes is added gradually, therefore elements might
 * have an IR or not, depending on the language features that are used. For
 * elements that do have an IR, the tree [ast.Node]s and the [Token]s are not
 * used in the rest of the compilation. This is ensured by setting the element's
 * cached tree to `null` and also breaking the token stream to crash future
 * attempts to parse.
 *
 * The type inferrer works on either IR nodes or tree nodes. The IR nodes are
 * then translated into the SSA form for optimizations and code generation.
 * Long-term, once the IR supports the full language, the backend can be
 * re-implemented to work directly on the IR.
 */
class IrBuilderTask extends CompilerTask {
  final Map<Element, ir.ExecutableDefinition> nodes =
      <Element, ir.ExecutableDefinition>{};
  final bool generateSourceMap;

  IrBuilderTask(Compiler compiler, {this.generateSourceMap: true})
      : super(compiler);

  String get name => 'IR builder';

  bool hasIr(Element element) => nodes.containsKey(element.implementation);

  ir.ExecutableDefinition getIr(ExecutableElement element) {
    return nodes[element.implementation];
  }

  ir.ExecutableDefinition buildNode(AstElement element) {
    if (!canBuild(element)) return null;

    TreeElements elementsMapping = element.resolvedAst.elements;
    element = element.implementation;
    return compiler.withCurrentElement(element, () {
      SourceInformationBuilder sourceInformationBuilder = generateSourceMap
          ? new PositionSourceInformationBuilder(element)
          : const SourceInformationBuilder();

      IrBuilderVisitor builder =
          compiler.backend is JavaScriptBackend
          ? new JsIrBuilderVisitor(
              elementsMapping, compiler, sourceInformationBuilder)
          : new DartIrBuilderVisitor(
              elementsMapping, compiler, sourceInformationBuilder);
      ir.ExecutableDefinition definition =
            builder.buildExecutable(element);
      if (definition != null) {
        nodes[element] = definition;
      }
      return definition;
    });
  }

  void buildNodes() {
    measure(() {
      Set<Element> resolved = compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach(buildNode);
    });
  }

  bool canBuild(Element element) {
    if (element is TypedefElement) return false;
    if (element is FunctionElement) {
      // TODO(sigurdm): Support native functions for dart2js.
      assert(invariant(element, !element.isNative));

      if (element is ConstructorElement) {
        if (!element.isGenerativeConstructor) {
          // TODO(kmillikin,sigurdm): Support constructors.
          return false;
        }
        if (element.isSynthesized) {
          // Do generate CPS for synthetic constructors.
          return true;
        }
      }
    } else if (element is! FieldElement) {
      compiler.internalError(element, "Unexpected element type $element");
    }
    return compiler.backend.shouldOutput(element);
  }

  bool get inCheckedMode {
    bool result = false;
    assert((result = true));
    return result;
  }

}

class _GetterElements {
  ir.Primitive result;
  ir.Primitive index;
  ir.Primitive receiver;

  _GetterElements({this.result, this.index, this.receiver}) ;
}

/**
 * A tree visitor that builds [IrNodes]. The visit methods add statements using
 * to the [builder] and return the last added statement for trees that represent
 * an expression.
 */
abstract class IrBuilderVisitor extends ResolvedVisitor<ir.Primitive>
    with IrBuilderMixin<ast.Node> {
  final Compiler compiler;
  final SourceInformationBuilder sourceInformationBuilder;

  // In SSA terms, join-point continuation parameters are the phis and the
  // continuation invocation arguments are the corresponding phi inputs.  To
  // support name introduction and renaming for source level variables, we use
  // nested (delimited) visitors for constructing subparts of the IR that will
  // need renaming.  Each source variable is assigned an index.
  //
  // Each nested visitor maintains a list of free variable uses in the body.
  // These are implemented as a list of parameters, each with their own use
  // list of references.  When the delimited subexpression is plugged into the
  // surrounding context, the free occurrences can be captured or become free
  // occurrences in the next outer delimited subexpression.
  //
  // Each nested visitor maintains a list that maps indexes of variables
  // assigned in the delimited subexpression to their reaching definition ---
  // that is, the definition in effect at the hole in 'current'.  These are
  // used to determine if a join-point continuation needs to be passed
  // arguments, and what the arguments are.

  /// Construct a top-level visitor.
  IrBuilderVisitor(TreeElements elements,
                   this.compiler,
                   this.sourceInformationBuilder)
      : super(elements);

  /**
   * Builds the [ir.ExecutableDefinition] for an executable element. In case the
   * function uses features that cannot be expressed in the IR, this element
   * returns `null`.
   */
  ir.ExecutableDefinition buildExecutable(ExecutableElement element);

  ClosureScope getClosureScopeForNode(ast.Node node);
  ClosureEnvironment getClosureEnvironment();

  /// Normalizes the argument list to a static invocation (i.e. where the target
  /// element is known).
  ///
  /// For the JS backend, inserts default arguments and normalizes order of
  /// named arguments.
  ///
  /// For the Dart backend, returns [arguments].
  List<ir.Primitive> normalizeStaticArguments(
      Selector selector,
      FunctionElement target,
      List<ir.Primitive> arguments);

  /// Normalizes the argument list of a dynamic invocation (i.e. where the
  /// target element is unknown).
  ///
  /// For the JS backend, normalizes order of named arguments.
  ///
  /// For the Dart backend, returns [arguments].
  List<ir.Primitive> normalizeDynamicArguments(
      Selector selector,
      List<ir.Primitive> arguments);

  ir.FunctionDefinition _makeFunctionBody(FunctionElement element,
                                          ast.FunctionExpression node) {
    FunctionSignature signature = element.functionSignature;
    List<ParameterElement> parameters = [];
    signature.orderedForEachParameter(parameters.add);

    irBuilder.buildFunctionHeader(parameters,
                                  closureScope: getClosureScopeForNode(node),
                                  env: getClosureEnvironment());

    List<ConstantExpression> defaults = new List<ConstantExpression>();
    signature.orderedOptionalParameters.forEach((ParameterElement element) {
      defaults.add(getConstantForVariable(element));
    });

    List<ir.Initializer> initializers;
    if (element.isSynthesized) {
      assert(element is ConstructorElement);
      return irBuilder.makeConstructorDefinition(const <ConstantExpression>[],
          const <ir.Initializer>[]);
    } else if (element.isGenerativeConstructor) {
      initializers = buildConstructorInitializers(node, element);
      visit(node.body);
      return irBuilder.makeConstructorDefinition(defaults, initializers);
    } else {
      visit(node.body);
      return irBuilder.makeFunctionDefinition(defaults);
    }
  }

  List<ir.Initializer> buildConstructorInitializers(
      ast.FunctionExpression function, ConstructorElement element) {
    List<ir.Initializer> result = <ir.Initializer>[];
    FunctionSignature signature = element.functionSignature;

    void tryAddInitializingFormal(ParameterElement parameterElement) {
      if (parameterElement.isInitializingFormal) {
        InitializingFormalElement initializingFormal = parameterElement;
        withBuilder(irBuilder.makeDelimitedBuilder(), () {
          ir.Primitive value = irBuilder.buildLocalGet(parameterElement);
          result.add(irBuilder.makeFieldInitializer(
              initializingFormal.fieldElement,
              irBuilder.makeRunnableBody(value)));
        });
      }
    }

    // TODO(sigurdm): Preserve initializing formals as initializing formals.
    signature.orderedForEachParameter(tryAddInitializingFormal);

    if (function.initializers == null) return result;
    bool explicitSuperInitializer = false;
    for(ast.Node initializer in function.initializers) {
      if (initializer is ast.SendSet) {
        // Field initializer.
        FieldElement field = elements[initializer];
        withBuilder(irBuilder.makeDelimitedBuilder(), () {
          ir.Primitive value = visit(initializer.arguments.head);
          ir.RunnableBody body = irBuilder.makeRunnableBody(value);
          result.add(irBuilder.makeFieldInitializer(field, body));
        });
      } else if (initializer is ast.Send) {
        // Super or this initializer.
        if (ast.Initializers.isConstructorRedirect(initializer)) {
          giveup(initializer, "constructor redirect (this) initializer");
        }
        ConstructorElement constructor = elements[initializer].implementation;
        Selector selector = elements.getSelector(initializer);
        List<ir.RunnableBody> arguments =
            initializer.arguments.mapToList((ast.Node argument) {
          return withBuilder(irBuilder.makeDelimitedBuilder(), () {
            ir.Primitive value = visit(argument);
            return irBuilder.makeRunnableBody(value);
          });
        });
        result.add(irBuilder.makeSuperInitializer(constructor,
                                                  arguments,
                                                  selector));
        explicitSuperInitializer = true;
      } else {
        compiler.internalError(initializer,
                               "Unexpected initializer type $initializer");
      }

    }
    if (!explicitSuperInitializer) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = element.enclosingClass;
      if (!enclosingClass.isObject) {
        ClassElement superClass = enclosingClass.superclass;
        FunctionElement target = superClass.lookupDefaultConstructor();
        if (target == null) {
          compiler.internalError(superClass,
              "No default constructor available.");
        }
        Selector selector = new Selector.callDefaultConstructor();
        result.add(irBuilder.makeSuperInitializer(target,
                                                  <ir.RunnableBody>[],
                                                  selector));
      }
    }
    return result;
  }

  ir.Primitive visit(ast.Node node) => node.accept(this);

  // ==== Statements ====
  visitBlock(ast.Block node) {
    irBuilder.buildBlock(node.statements.nodes, build);
  }

  ir.Primitive visitBreakStatement(ast.BreakStatement node) {
    if (!irBuilder.buildBreak(elements.getTargetOf(node))) {
      compiler.internalError(node, "'break' target not found");
    }
    return null;
  }

  ir.Primitive visitContinueStatement(ast.ContinueStatement node) {
    if (!irBuilder.buildContinue(elements.getTargetOf(node))) {
      compiler.internalError(node, "'continue' target not found");
    }
    return null;
  }

  // Build(EmptyStatement, C) = C
  ir.Primitive visitEmptyStatement(ast.EmptyStatement node) {
    assert(irBuilder.isOpen);
    return null;
  }

  // Build(ExpressionStatement(e), C) = C'
  //   where (C', _) = Build(e, C)
  ir.Primitive visitExpressionStatement(ast.ExpressionStatement node) {
    assert(irBuilder.isOpen);
    visit(node.expression);
    return null;
  }

  visitFor(ast.For node) {
    List<LocalElement> loopVariables = <LocalElement>[];
    if (node.initializer is ast.VariableDefinitions) {
      ast.VariableDefinitions definitions = node.initializer;
      for (ast.Node node in definitions.definitions.nodes) {
        LocalElement loopVariable = elements[node];
        loopVariables.add(loopVariable);
      }
    }

    JumpTarget target = elements.getTargetDefinition(node);
    irBuilder.buildFor(
        buildInitializer: subbuild(node.initializer),
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        buildUpdate: subbuildSequence(node.update),
        closureScope: getClosureScopeForNode(node),
        loopVariables: loopVariables,
        target: target);
  }

  visitIf(ast.If node) {
    irBuilder.buildIf(
        build(node.condition),
        subbuild(node.thenPart),
        subbuild(node.elsePart));
  }

  ir.Primitive visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop) return visit(body);
    JumpTarget target = elements.getTargetDefinition(body);
    JumpCollector jumps = new JumpCollector(target);
    irBuilder.state.breakCollectors.add(jumps);
    IrBuilder innerBuilder = irBuilder.makeDelimitedBuilder();
    withBuilder(innerBuilder, () {
      visit(body);
    });
    irBuilder.state.breakCollectors.removeLast();
    bool hasBreaks = !jumps.isEmpty;
    ir.Continuation joinContinuation;
    if (hasBreaks) {
      if (innerBuilder.isOpen) {
        jumps.addJump(innerBuilder);
      }

      // All jumps to the break continuation must be in the scope of the
      // continuation's binding.  The continuation is bound just outside the
      // body to satisfy this property without extra analysis.
      // As a consequence, the break continuation needs parameters for all
      // local variables in scope at the exit from the body.
      List<ir.Parameter> parameters =
          new List<ir.Parameter>.generate(irBuilder.environment.length, (i) {
        return new ir.Parameter(irBuilder.environment.index2variable[i]);
      });
      joinContinuation = new ir.Continuation(parameters);
      irBuilder.invokeFullJoin(joinContinuation, jumps, recursive: false);
      irBuilder.add(new ir.LetCont(joinContinuation,
          innerBuilder._root));
      for (int i = 0; i < irBuilder.environment.length; ++i) {
        irBuilder.environment.index2value[i] = parameters[i];
      }
    } else {
      if (innerBuilder._root != null) {
        irBuilder.add(innerBuilder._root);
        irBuilder._current = innerBuilder._current;
        irBuilder.environment = innerBuilder.environment;
      }
    }
    return null;
  }

  visitWhile(ast.While node) {
    irBuilder.buildWhile(
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  visitForIn(ast.ForIn node) {
    // [node.declaredIdentifier] can be either an [ast.VariableDefinitions]
    // (defining a new local variable) or a send designating some existing
    // variable.
    ast.Node identifier = node.declaredIdentifier;
    ast.VariableDefinitions variableDeclaration =
        identifier.asVariableDefinitions();
    Element variableElement = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);

    irBuilder.buildForIn(
        buildExpression: subbuild(node.expression),
        buildVariableDeclaration: subbuild(variableDeclaration),
        variableElement: variableElement,
        variableSelector: selector,
        buildBody: subbuild(node.body),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  ir.Primitive visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(irBuilder.isOpen);
    if (node.modifiers.isConst) {
      for (ast.SendSet definition in node.definitions.nodes) {
        assert(!definition.arguments.isEmpty);
        assert(definition.arguments.tail.isEmpty);
        VariableElement element = elements[definition];
        ConstantExpression value = getConstantForVariable(element);
        irBuilder.declareLocalConstant(element, value);
      }
    } else {
      for (ast.Node definition in node.definitions.nodes) {
        Element element = elements[definition];
        ir.Primitive initialValue;
        // Definitions are either SendSets if there is an initializer, or
        // Identifiers if there is no initializer.
        if (definition is ast.SendSet) {
          assert(!definition.arguments.isEmpty);
          assert(definition.arguments.tail.isEmpty);
          initialValue = visit(definition.arguments.head);
        } else {
          assert(definition is ast.Identifier);
        }
        irBuilder.declareLocalVariable(element, initialValue: initialValue);
      }
    }
    return null;
  }

  // Build(Return(e), C) = C'[InvokeContinuation(return, x)]
  //   where (C', x) = Build(e, C)
  //
  // Return without a subexpression is translated as if it were return null.
  ir.Primitive visitReturn(ast.Return node) {
    assert(irBuilder.isOpen);
    assert(invariant(node, node.beginToken.value != 'native'));
    irBuilder.buildReturn(build(node.expression));
    return null;
  }

  ir.Primitive visitTryStatement(ast.TryStatement node) {
    assert(this.irBuilder.isOpen);
    // Try/catch is not yet implemented in the JS backend.
    if (this.irBuilder.tryStatements == null) {
      return giveup(node, 'try/catch in the JS backend');
    }
    // Multiple catch blocks are not yet implemented.
    if (node.catchBlocks.isEmpty ||
        node.catchBlocks.nodes.tail == null) {
      return giveup(node, 'not exactly one catch block');
    }
    // 'on T' catch blocks are not yet implemented.
    if ((node.catchBlocks.nodes.head as ast.CatchBlock).onKeyword != null) {
      return giveup(node, '"on T" catch block');
    }
    // Finally blocks are not yet implemented.
    if (node.finallyBlock != null) {
      return giveup(node, 'try/finally');
    }

    // Catch handlers are in scope for their body.  The CPS translation of
    // [[try tryBlock catch (e) catchBlock; successor]] is:
    //
    // let cont join(v0, v1, ...) = [[successor]] in
    //   let mutable m0 = x0 in
    //     let mutable m1 = x1 in
    //       ...
    //       let handler catch_(e) =
    //         let prim p0 = GetMutable(m0) in
    //           let prim p1 = GetMutable(m1) in
    //             ...
    //             [[catchBlock]]
    //             join(p0, p1, ...)
    //       in
    //         [[tryBlock]]
    //         let prim p0' = GetMutable(m0) in
    //           let prim p1' = GetMutable(m1) in
    //             ...
    //             join(p0', p1', ...)
    //
    // In other words, both the try and catch block are in the scope of the
    // join-point continuation, and they are both in the scope of a sequence
    // of mutable bindings for the variables assigned in the try.  The join-
    // point continuation is not in the scope of these mutable bindings.
    // The tryBlock is in the scope of a binding for the catch handler.  Each
    // instruction (specifically, each call) in the tryBlock is in the dynamic
    // scope of the handler.  The mutable bindings are dereferenced at the end
    // of the try block and at the beginning of the catch block, so the
    // variables are unboxed in the catch block and at the join point.

    IrBuilder tryCatchBuilder = irBuilder.makeDelimitedBuilder();
    TryStatementInfo tryInfo = tryCatchBuilder.tryStatements[node];
    // Variables that are boxed due to being captured in a closure are boxed
    // for their entire lifetime, and so they do not need to be boxed on
    // entry to any try block.  We check for them here because we can not
    // identify all of them in the same pass where we identify the variables
    // assigned in the try (the may be captured by a closure after the try
    // statement).
    Iterable<LocalVariableElement> boxedOnEntry =
        tryInfo.boxedOnEntry.where((LocalVariableElement variable) {
      return !tryCatchBuilder.mutableCapturedVariables.contains(variable);
    });
    for (LocalVariableElement variable in boxedOnEntry) {
      assert(!tryCatchBuilder.isInMutableVariable(variable));
      ir.Primitive value = tryCatchBuilder.buildLocalGet(variable);
      tryCatchBuilder.makeMutableVariable(variable);
      tryCatchBuilder.declareLocalVariable(variable, initialValue: value);
    }

    IrBuilder catchBuilder = tryCatchBuilder.makeDelimitedBuilder();
    IrBuilder tryBuilder = tryCatchBuilder.makeDelimitedBuilder();
    List<ir.Parameter> joinParameters =
        new List<ir.Parameter>.generate(irBuilder.environment.length, (i) {
      return new ir.Parameter(irBuilder.environment.index2variable[i]);
    });
    ir.Continuation joinContinuation = new ir.Continuation(joinParameters);

    void interceptJumps(JumpCollector collector) {
      collector.enterTry(boxedOnEntry);
    }
    void restoreJumps(JumpCollector collector) {
      collector.leaveTry();
    }
    tryBuilder.state.breakCollectors.forEach(interceptJumps);
    tryBuilder.state.continueCollectors.forEach(interceptJumps);
    withBuilder(tryBuilder, () {
      visit(node.tryBlock);
    });
    tryBuilder.state.breakCollectors.forEach(restoreJumps);
    tryBuilder.state.continueCollectors.forEach(restoreJumps);
    if (tryBuilder.isOpen) {
      for (LocalVariableElement variable in boxedOnEntry) {
        assert(tryBuilder.isInMutableVariable(variable));
        ir.Primitive value = tryBuilder.buildLocalGet(variable);
        tryBuilder.environment.update(variable, value);
      }
      tryBuilder.jumpTo(joinContinuation);
    }

    for (LocalVariableElement variable in boxedOnEntry) {
      assert(catchBuilder.isInMutableVariable(variable));
      ir.Primitive value = catchBuilder.buildLocalGet(variable);
      // Note that we remove the variable from the set of mutable variables
      // here (and not above for the try body).  This is because the set of
      // mutable variables is global for the whole function and not local to
      // a delimited builder.
      catchBuilder.removeMutableVariable(variable);
      catchBuilder.environment.update(variable, value);
    }
    ast.CatchBlock catchClause = node.catchBlocks.nodes.head;
    assert(catchClause.exception != null);
    LocalVariableElement exceptionElement = elements[catchClause.exception];
    ir.Parameter exceptionParameter = new ir.Parameter(exceptionElement);
    catchBuilder.environment.extend(exceptionElement, exceptionParameter);
    ir.Parameter traceParameter;
    if (catchClause.trace != null) {
      LocalVariableElement traceElement = elements[catchClause.trace];
      traceParameter = new ir.Parameter(traceElement);
      catchBuilder.environment.extend(traceElement, traceParameter);
    } else {
      // Use a dummy continuation parameter for the stack trace parameter.
      // This will ensure that all handlers have two parameters and so they
      // can be treated uniformly.
      traceParameter = new ir.Parameter(null);
    }
    withBuilder(catchBuilder, () {
      visit(catchClause.block);
    });
    if (catchBuilder.isOpen) {
      catchBuilder.jumpTo(joinContinuation);
    }
    List<ir.Parameter> catchParameters =
        <ir.Parameter>[exceptionParameter, traceParameter];
    ir.Continuation catchContinuation = new ir.Continuation(catchParameters);
    catchContinuation.body = catchBuilder._root;

    tryCatchBuilder.add(new ir.LetHandler(catchContinuation, tryBuilder._root));
    tryCatchBuilder._current = null;

    irBuilder.add(new ir.LetCont(joinContinuation, tryCatchBuilder._root));
    for (int i = 0; i < irBuilder.environment.length; ++i) {
      irBuilder.environment.index2value[i] = joinParameters[i];
    }
    return null;
  }

  // ==== Expressions ====
  ir.Primitive visitConditional(ast.Conditional node) {
    return irBuilder.buildConditional(
        build(node.condition),
        subbuild(node.thenExpression),
        subbuild(node.elseExpression));
  }

  // For all simple literals:
  // Build(Literal(c), C) = C[let val x = Constant(c) in [], x]
  ir.Primitive visitLiteralBool(ast.LiteralBool node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralDouble(ast.LiteralDouble node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralInt(ast.LiteralInt node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralNull(ast.LiteralNull node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitLiteralString(ast.LiteralString node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ConstantExpression getConstantForNode(ast.Node node) {
    ConstantExpression constant =
        compiler.backend.constantCompilerTask.compileNode(node, elements);
    assert(invariant(node, constant != null,
        message: 'No constant computed for $node'));
    return constant;
  }

  ConstantExpression getConstantForVariable(VariableElement element) {
    ConstantExpression constant =
        compiler.backend.constants.getConstantForVariable(element);
    assert(invariant(element, constant != null,
            message: 'No constant computed for $element'));
    return constant;
  }

  ir.Primitive visitLiteralList(ast.LiteralList node) {
    if (node.isConst) {
      return translateConstant(node);
    }
    List<ir.Primitive> values = node.elements.nodes.mapToList(visit);
    InterfaceType type = elements.getType(node);
    return irBuilder.buildListLiteral(type, values);
  }

  ir.Primitive visitLiteralMap(ast.LiteralMap node) {
    if (node.isConst) {
      return translateConstant(node);
    }
    InterfaceType type = elements.getType(node);
    return irBuilder.buildMapLiteral(
        type,
        node.entries.nodes.map((e) => e.key),
        node.entries.nodes.map((e) => e.value),
        build);
  }

  ir.Primitive visitLiteralSymbol(ast.LiteralSymbol node) {
    assert(irBuilder.isOpen);
    return translateConstant(node);
  }

  ir.Primitive visitIdentifier(ast.Identifier node) {
    // "this" is the only identifier that should be met by the visitor.
    assert(node.isThis());
    return irBuilder.buildThis();
  }

  ir.Primitive visitParenthesizedExpression(
      ast.ParenthesizedExpression node) {
    assert(irBuilder.isOpen);
    return visit(node.expression);
  }

  // Stores the result of visiting a CascadeReceiver, so we can return it from
  // its enclosing Cascade.
  ir.Primitive _currentCascadeReceiver;

  ir.Primitive visitCascadeReceiver(ast.CascadeReceiver node) {
    assert(irBuilder.isOpen);
    return _currentCascadeReceiver = visit(node.expression);
  }

  ir.Primitive visitCascade(ast.Cascade node) {
    assert(irBuilder.isOpen);
    var oldCascadeReceiver = _currentCascadeReceiver;
    // Throw away the result of visiting the expression.
    // Instead we return the result of visiting the CascadeReceiver.
    this.visit(node.expression);
    ir.Primitive receiver = _currentCascadeReceiver;
    _currentCascadeReceiver = oldCascadeReceiver;
    return receiver;
  }

  // ==== Sends ====
  ir.Primitive visitAssert(ast.Send node) {
    assert(irBuilder.isOpen);
    return giveup(node, 'Assert');
  }

  ir.Primitive visitNamedArgument(ast.NamedArgument node) {
    assert(irBuilder.isOpen);
    return visit(node.expression);
  }

  ir.Primitive visitClosureSend(ast.Send node) {
    assert(irBuilder.isOpen);
    Element element = elements[node];
    Selector selector = elements.getSelector(node);
    ir.Primitive receiver = (element == null)
        ? visit(node.selector)
        : irBuilder.buildLocalGet(element);
    List<ir.Primitive> arguments = node.arguments.mapToList(visit);
    arguments = normalizeDynamicArguments(selector, arguments);
    return irBuilder.buildCallInvocation(receiver, selector, arguments);
  }

  /// If [node] is null, returns this.
  /// If [node] is super, returns null (for special handling)
  /// Otherwise visits [node] and returns the result.
  ir.Primitive visitReceiver(ast.Expression node) {
    if (node == null) return irBuilder.buildThis();
    if (node.isSuper()) return null;
    return visit(node);
  }

  /// Returns `true` if [node] is a super call.
  // TODO(johnniwinther): Remove the need for this.
  bool isSuperCall(ast.Send node) {
    return node != null && node.receiver != null && node.receiver.isSuper();
  }

  ir.Primitive visitDynamicSend(ast.Send node) {
    assert(irBuilder.isOpen);
    Selector selector = elements.getSelector(node);
    ir.Primitive receiver = visitReceiver(node.receiver);
    List<ir.Primitive> arguments = node.arguments.mapToList(visit);
    arguments = normalizeDynamicArguments(selector, arguments);
    return irBuilder.buildDynamicInvocation(receiver, selector, arguments);
  }

  _GetterElements translateGetter(ast.Send node, Selector selector) {
    Element element = elements[node];
    ir.Primitive result;
    ir.Primitive receiver;
    ir.Primitive index;

    if (element != null && element.isConst) {
      // Reference to constant local, top-level or static field
      result = translateConstant(node);
    } else if (Elements.isLocal(element)) {
      // Reference to local variable
      result = irBuilder.buildLocalGet(element);
    } else if (element == null ||
               Elements.isInstanceField(element) ||
               Elements.isInstanceMethod(element) ||
               selector.isIndex ||
               // TODO(johnniwinther): clean up semantics of resolution.
               node.isSuperCall) {
      // Dynamic dispatch to a getter. Sometimes resolution will suggest a
      // target element, but in these cases we must still emit a dynamic
      // dispatch. The target element may be an instance method in case we are
      // converting a method to a function object.

      receiver = visitReceiver(node.receiver);
      List<ir.Primitive> arguments = new List<ir.Primitive>();
      if (selector.isIndex) {
        index = visit(node.arguments.head);
        arguments.add(index);
      }

      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.INDEX);
      if (isSuperCall(node)) {
        result = irBuilder.buildSuperInvocation(element, selector, arguments);
      } else {
        result =
            irBuilder.buildDynamicInvocation(receiver, selector, arguments);
      }
    } else if (element.isField || element.isGetter || element.isErroneous ||
               element.isSetter) {
      // TODO(johnniwinther): Change handling of setter selectors.
      // Access to a static field or getter (non-static case handled above).
      // Even if there is only a setter, we compile as if it was a getter,
      // so the vm can fail at runtime.
      assert(selector.kind == SelectorKind.GETTER ||
             selector.kind == SelectorKind.SETTER);
      result = irBuilder.buildStaticGet(element, selector,
          sourceInformation: sourceInformationBuilder.buildGet(node));
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      // Convert a top-level or static function to a function object.
      result = translateConstant(node);
    } else {
      throw "Unexpected SendSet getter: $node, $element";
    }
    return new _GetterElements(
        result: result,index: index, receiver: receiver);
  }

  ir.Primitive visitGetterSend(ast.Send node) {
    assert(irBuilder.isOpen);
    return translateGetter(node, elements.getSelector(node)).result;

  }

  ir.Primitive translateLogicalOperator(ast.Operator op,
                                        ast.Expression left,
                                        ast.Expression right) {
    ir.Primitive leftValue = visit(left);

    ir.Primitive buildRightValue(IrBuilder rightBuilder) {
      return withBuilder(rightBuilder, () => visit(right));
    }

    return irBuilder.buildLogicalOperator(
        leftValue, buildRightValue, isLazyOr: op.source == '||');
  }

  ir.Primitive visitOperatorSend(ast.Send node) {
    assert(irBuilder.isOpen);
    ast.Operator op = node.selector;
    if (isUserDefinableOperator(op.source)) {
      return visitDynamicSend(node);
    }
    if (op.source == '&&' || op.source == '||') {
      assert(node.receiver != null);
      assert(!node.arguments.isEmpty);
      assert(node.arguments.tail.isEmpty);
      return translateLogicalOperator(op, node.receiver, node.arguments.head);
    }
    if (op.source == "!") {
      assert(node.receiver != null);
      assert(node.arguments.isEmpty);
      return irBuilder.buildNegation(visit(node.receiver));
    }
    if (op.source == "!=") {
      assert(node.receiver != null);
      assert(!node.arguments.isEmpty);
      assert(node.arguments.tail.isEmpty);
      return irBuilder.buildNegation(visitDynamicSend(node));
    }
    assert(invariant(node, op.source == "is" || op.source == "as",
           message: "unexpected operator $op"));
    DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
    ir.Primitive receiver = visit(node.receiver);
    return irBuilder.buildTypeOperator(
        receiver, type,
        isTypeTest: op.source == "is",
        isNotCheck: node.isIsNotCheck);
  }

  // Build(StaticSend(f, arguments), C) = C[C'[InvokeStatic(f, xs)]]
  //   where (C', xs) = arguments.fold(Build, C)
  ir.Primitive visitStaticSend(ast.Send node) {
    assert(irBuilder.isOpen);
    Element element = elements[node];
    assert(!element.isConstructor);
    // TODO(lry): support foreign functions.
    if (element.isForeign(compiler.backend)) {
      return giveup(node, 'StaticSend: foreign');
    }

    Selector selector = elements.getSelector(node);

    if (selector.isCall && (element.isGetter || element.isField)) {
      // We are invoking a static field or getter as if it was a method, e.g:
      //
      //     get foo => {..}
      //     main() {  foo(1, 2, 3);  }
      //
      // We invoke the getter of 'foo' and then invoke the 'call' method
      // on the result, using the given arguments.
      Selector getter = new Selector.getterFrom(selector);
      Selector call = new Selector.callClosureFrom(selector);
      ir.Primitive receiver = irBuilder.buildStaticGet(element, getter);
      List<ir.Primitive> arguments = node.arguments.mapToList(visit);
      arguments = normalizeDynamicArguments(selector, arguments);
      return irBuilder.buildCallInvocation(receiver, call, arguments);
    } else if (selector.isGetter) {
      // We are reading a static field or invoking a static getter.
      return irBuilder.buildStaticGet(element, selector);
    } else {
      // We are invoking a static method.
      assert(selector.isCall);
      assert(element is FunctionElement);
      List<ir.Primitive> arguments = node.arguments.mapToList(visit);
      arguments = normalizeStaticArguments(selector, element, arguments);
      return irBuilder.buildStaticInvocation(element, selector, arguments,
          sourceInformation: sourceInformationBuilder.buildCall(node));
    }
  }

  ir.Primitive visitSuperSend(ast.Send node) {
    assert(irBuilder.isOpen);
    Selector selector = elements.getSelector(node);
    Element target = elements[node];

    if (selector.isCall && (target.isGetter || target.isField)) {
      // We are invoking a field or getter as if it was a method, e.g:
      //
      //     class A { get foo => {..} }
      //     class B extends A {
      //         m() {
      //           super.foo(1, 2, 3);  }
      //         }
      //     }
      //
      // We invoke the getter of 'foo' and then invoke the 'call' method on
      // the result, using the given arguments.
      Selector getter = new Selector.getterFrom(selector);
      Selector call = new Selector.callClosureFrom(selector);
      ir.Primitive receiver =
          irBuilder.buildSuperInvocation(target, getter, []);
      List<ir.Primitive> arguments = node.arguments.mapToList(visit);
      arguments = normalizeDynamicArguments(selector, arguments);
      return irBuilder.buildCallInvocation(receiver, call, arguments);
    } else if (selector.isCall) {
      // We are invoking a method.
      assert(target is FunctionElement);
      List<ir.Primitive> arguments = node.arguments.mapToList(visit);
      arguments = normalizeStaticArguments(selector, target, arguments);
      return irBuilder.buildSuperInvocation(target, selector, arguments);
    } else {
      // We are invoking a getter, operator, indexer, etc.
      List<ir.Primitive> arguments = node.argumentsNode == null
          ? <ir.Primitive>[]
          : node.arguments.mapToList(visit);
      return irBuilder.buildSuperInvocation(target, selector, arguments);
    }
  }

  visitTypePrefixSend(ast.Send node) {
    compiler.internalError(node, "visitTypePrefixSend should not be called.");
  }

  ir.Primitive visitTypeLiteralSend(ast.Send node) {
    assert(irBuilder.isOpen);
    // If the user is trying to invoke the type literal or variable,
    // it must be treated as a function call.
    if (node.argumentsNode != null) {
      // TODO(sigurdm): Handle this to match proposed semantics of issue #19725.
      return giveup(node, 'Type literal invoked as function');
    }

    DartType type = elements.getTypeLiteralType(node);
    if (type is TypeVariableType) {
      ir.Primitive prim = new ir.ReifyTypeVar(type.element);
      irBuilder.add(new ir.LetPrim(prim));
      return prim;
    } else {
      return translateConstant(node);
    }
  }

  ir.Primitive visitSendSet(ast.SendSet node) {
    assert(irBuilder.isOpen);
    Element element = elements[node];
    ast.Operator op = node.assignmentOperator;
    // For complex operators, this is the result of getting (before assigning)
    ir.Primitive originalValue;
    // For []+= style operators, this saves the index.
    ir.Primitive index;
    ir.Primitive receiver;
    // This is what gets assigned.
    ir.Primitive valueToStore;
    Selector selector = elements.getSelector(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    Selector getterSelector =
        elements.getGetterSelectorInComplexSendSet(node);
    assert(
        // Indexing send-sets have an argument for the index.
        (selector.isIndexSet ? 1 : 0) +
        // Non-increment send-sets have one more argument.
        (ast.Operator.INCREMENT_OPERATORS.contains(op.source) ? 0 : 1)
            == node.argumentCount());

    ast.Node getAssignArgument() {
      assert(invariant(node, !node.arguments.isEmpty,
                       message: "argument expected"));
      return selector.isIndexSet
          ? node.arguments.tail.head
          : node.arguments.head;
    }

    // Get the value into valueToStore
    if (op.source == "=") {
      if (selector.isIndexSet) {
        receiver = visitReceiver(node.receiver);
        index = visit(node.arguments.head);
      } else if (element == null || Elements.isInstanceField(element)) {
        receiver = visitReceiver(node.receiver);
      }
      valueToStore = visit(getAssignArgument());
    } else {
      // Get the original value into getter
      assert(ast.Operator.COMPLEX_OPERATORS.contains(op.source));

      _GetterElements getterResult = translateGetter(node, getterSelector);
      index = getterResult.index;
      receiver = getterResult.receiver;
      originalValue = getterResult.result;

      // Do the modification of the value in getter.
      ir.Primitive arg;
      if (ast.Operator.INCREMENT_OPERATORS.contains(op.source)) {
        arg = irBuilder.buildIntegerLiteral(1);
      } else {
        arg = visit(getAssignArgument());
      }
      valueToStore = new ir.Parameter(null);
      ir.Continuation k = new ir.Continuation([valueToStore]);
      ir.Expression invoke =
          new ir.InvokeMethod(originalValue, operatorSelector, k, [arg]);
      irBuilder.add(new ir.LetCont(k, invoke));
    }

    if (Elements.isLocal(element)) {
      irBuilder.buildLocalSet(element, valueToStore);
    } else if ((!node.isSuperCall && Elements.isErroneous(element)) ||
                Elements.isStaticOrTopLevel(element)) {
      irBuilder.buildStaticSet(
          element, elements.getSelector(node), valueToStore);
    } else {
      // Setter or index-setter invocation
      Selector selector = elements.getSelector(node);
      assert(selector.kind == SelectorKind.SETTER ||
          selector.kind == SelectorKind.INDEX);
      if (selector.isIndexSet) {
        if (isSuperCall(node)) {
          irBuilder.buildSuperIndexSet(element, index, valueToStore);
        } else {
          irBuilder.buildDynamicIndexSet(receiver, index, valueToStore);
        }
      } else {
        if (isSuperCall(node)) {
          irBuilder.buildSuperSet(element, selector, valueToStore);
        } else {
          irBuilder.buildDynamicSet(receiver, selector, valueToStore);
        }
      }
    }

    if (node.isPostfix) {
      assert(originalValue != null);
      return originalValue;
    } else {
      return valueToStore;
    }
  }

  ir.Primitive visitNewExpression(ast.NewExpression node) {
    if (node.isConst) {
      return translateConstant(node);
    }
    FunctionElement element = elements[node.send];
    Selector selector = elements.getSelector(node.send);
    DartType type = elements.getType(node);
    ast.Node selectorNode = node.send.selector;
    List<ir.Primitive> arguments =
        node.send.arguments.mapToList(visit, growable:false);
    arguments = normalizeStaticArguments(selector, element, arguments);
    return irBuilder.buildConstructorInvocation(
        element, selector, type, arguments);
  }

  ir.Primitive visitStringJuxtaposition(ast.StringJuxtaposition node) {
    assert(irBuilder.isOpen);
    ir.Primitive first = visit(node.first);
    ir.Primitive second = visit(node.second);
    return irBuilder.buildStringConcatenation([first, second]);
  }

  ir.Primitive visitStringInterpolation(ast.StringInterpolation node) {
    assert(irBuilder.isOpen);
    List<ir.Primitive> arguments = [];
    arguments.add(visitLiteralString(node.string));
    var it = node.parts.iterator;
    while (it.moveNext()) {
      ast.StringInterpolationPart part = it.current;
      arguments.add(visit(part.expression));
      arguments.add(visitLiteralString(part.string));
    }
    return irBuilder.buildStringConcatenation(arguments);
  }

  ir.Primitive translateConstant(ast.Node node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildConstantLiteral(getConstantForNode(node));
  }

  ir.ExecutableDefinition nullIfGiveup(ir.ExecutableDefinition action()) {
    try {
      return action();
    } catch(e, tr) {
      if (e == ABORT_IRNODE_BUILDER) {
        return null;
      }
      rethrow;
    }
  }

  void internalError(String reason, {ast.Node node}) {
    giveup(node);
  }
}

final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

dynamic giveup(ast.Node node, [String reason]) {
  throw ABORT_IRNODE_BUILDER;
}

/// Classifies local variables and local functions as captured, if they
/// are accessed from within a nested function.
///
/// This class is specific to the [DartIrBuilder], in that it gives up if it
/// sees a feature that is currently unsupport by that builder. In particular,
/// loop variables captured in a for-loop initializer, condition, or update
/// expression are unsupported.
class DartCapturedVariables extends ast.Visitor {
  final TreeElements elements;
  DartCapturedVariables(this.elements);

  FunctionElement currentFunction;
  bool insideInitializer = false;
  Set<Local> capturedVariables = new Set<Local>();

  Map<ast.TryStatement, TryStatementInfo> tryStatements =
      <ast.TryStatement, TryStatementInfo>{};

  List<TryStatementInfo> tryNestingStack = <TryStatementInfo>[];
  bool get inTryStatement => tryNestingStack.isNotEmpty;

  void markAsCaptured(Local local) {
    capturedVariables.add(local);
  }

  visit(ast.Node node) => node.accept(this);

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  visitFor(ast.For node) {
    if (node.initializer != null) visit(node.initializer);
    if (node.condition != null) visit(node.condition);
    if (node.update != null) visit(node.update);

    // Give up if a variable was captured outside of the loop body.
    if (node.initializer is ast.VariableDefinitions) {
      ast.VariableDefinitions definitions = node.initializer;
      for (ast.Node node in definitions.definitions.nodes) {
        LocalElement loopVariable = elements[node];
        if (capturedVariables.contains(loopVariable)) {
          return giveup(node, 'For-loop variable captured in loop header');
        }
      }
    }

    if (node.body != null) visit(node.body);
  }

  void handleSend(ast.Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element) &&
        !element.isConst &&
        element.enclosingElement != currentFunction) {
      LocalElement local = element;
      markAsCaptured(local);
    }
  }

  visitSend(ast.Send node) {
    handleSend(node);
    node.visitChildren(this);
  }

  visitSendSet(ast.SendSet node) {
    handleSend(node);
    Element element = elements[node];
    if (Elements.isLocal(element)) {
      LocalElement local = element;
      if (insideInitializer) {
        assert(local.isParameter);
        // Initializers in an initializer-list can communicate via parameters.
        // If a parameter is stored in an initializer list we box it.
        // TODO(sigurdm): Fix this.
        // Though these variables do not outlive the activation of the
        // function, they still need to be boxed.  As a simplification, we
        // treat them as if they are captured by a closure (i.e., they do
        // outlive the activation of the function).
        markAsCaptured(local);
      } else if (inTryStatement) {
        assert(local.isParameter || local.isVariable);
        // Search for the position of the try block containing the variable
        // declaration, or -1 if it is declared outside the outermost try.
        int i = tryNestingStack.length - 1;
        while (i >= 0 && !tryNestingStack[i].declared.contains(local)) {
          --i;
        }
        // If there is a next inner try, then the variable should be boxed on
        // entry to it.
        if (i + 1 < tryNestingStack.length) {
          tryNestingStack[i + 1].boxedOnEntry.add(local);
        }
      }
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    FunctionElement oldFunction = currentFunction;
    currentFunction = elements[node];
    if (currentFunction.asyncMarker != AsyncMarker.SYNC) {
      giveup(node, "cannot handle async/sync*/async* functions");
    }
    if (node.initializers != null) {
      insideInitializer = true;
      visit(node.initializers);
      insideInitializer = false;
    }
    visit(node.body);
    currentFunction = oldFunction;
  }

  visitTryStatement(ast.TryStatement node) {
    TryStatementInfo info = new TryStatementInfo();
    tryStatements[node] = info;
    tryNestingStack.add(info);
    visit(node.tryBlock);
    assert(tryNestingStack.last == info);
    tryNestingStack.removeLast();

    visit(node.catchBlocks);
    if (node.finallyBlock != null) visit(node.finallyBlock);
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    if (inTryStatement) {
      for (ast.Node definition in node.definitions.nodes) {
        LocalVariableElement local = elements[definition];
        assert(local != null);
        // In the closure conversion pass we check for isInitializingFormal,
        // but I'm not sure it can arise.
        assert(!local.isInitializingFormal);
        tryNestingStack.last.declared.add(local);
      }
    }
    node.visitChildren(this);
  }
}

/// IR builder specific to the Dart backend, coupled to the [DartIrBuilder].
class DartIrBuilderVisitor extends IrBuilderVisitor {
  /// Promote the type of [irBuilder] to [DartIrBuilder].
  DartIrBuilder get irBuilder => super.irBuilder;

  DartIrBuilderVisitor(TreeElements elements,
                       Compiler compiler,
                       SourceInformationBuilder sourceInformationBuilder)
      : super(elements, compiler, sourceInformationBuilder);

  DartIrBuilder makeIRBuilder(ast.Node node, ExecutableElement element) {
    DartCapturedVariables closures = new DartCapturedVariables(elements);
    if (!element.isSynthesized) {
      closures.visit(node);
    }
    return new DartIrBuilder(compiler.backend.constantSystem,
                             element,
                             closures);
  }

  /// Recursively builds the IR for the given nested function.
  ir.FunctionDefinition makeSubFunction(ast.FunctionExpression node) {
    FunctionElement element = elements[node];
    assert(invariant(element, element.isImplementation));

    IrBuilder builder = irBuilder.makeInnerFunctionBuilder(element);

    return withBuilder(builder, () => _makeFunctionBody(element, node));
  }

  ir.Primitive visitFunctionExpression(ast.FunctionExpression node) {
    return irBuilder.buildFunctionExpression(makeSubFunction(node));
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element = elements[node.function];
    Object inner = makeSubFunction(node.function);
    irBuilder.declareLocalFunction(element, inner);
  }

  ClosureScope getClosureScopeForNode(ast.Node node) => null;
  ClosureEnvironment getClosureEnvironment() => null;

  ir.ExecutableDefinition buildExecutable(ExecutableElement element) {
    return nullIfGiveup(() {
      if (element is FieldElement) {
        return buildField(element);
      } else if (element is FunctionElement) {
        return buildFunction(element);
      } else {
        compiler.internalError(element, "Unexpected element type $element");
      }
    });
  }

  /// Returns a [ir.FieldDefinition] describing the initializer of [element].
  ir.FieldDefinition buildField(FieldElement element) {
    assert(invariant(element, element.isImplementation));
    ast.VariableDefinitions definitions = element.node;
    ast.Node fieldDefinition = definitions.definitions.nodes.first;
    if (definitions.modifiers.isConst) {
      // TODO(sigurdm): Just return const value.
    }
    assert(fieldDefinition != null);
    assert(elements[fieldDefinition] != null);

    IrBuilder builder = makeIRBuilder(fieldDefinition, element);

    return withBuilder(builder, () {
      builder.buildFieldInitializerHeader(
          closureScope: getClosureScopeForNode(fieldDefinition));
      ir.Primitive initializer;
      if (fieldDefinition is ast.SendSet) {
        ast.SendSet sendSet = fieldDefinition;
        initializer = visit(sendSet.arguments.first);
      }
      return builder.makeFieldDefinition(initializer);
    });
  }

  ir.FunctionDefinition buildFunction(FunctionElement element) {
    assert(invariant(element, element.isImplementation));
    ast.FunctionExpression node = element.node;
    if (element.asyncMarker != AsyncMarker.SYNC) {
      giveup(null, 'cannot handle async-await');
    }

    if (!element.isSynthesized) {
      assert(node != null);
      assert(elements[node] != null);
    } else {
      SynthesizedConstructorElementX constructor = element;
      if (!constructor.isDefaultConstructor) {
        giveup(null, 'cannot handle synthetic forwarding constructors');
      }
    }

    IrBuilder builder = makeIRBuilder(node, element);

    return withBuilder(builder, () => _makeFunctionBody(element, node));
  }

  List<ir.Primitive> normalizeStaticArguments(
      Selector selector,
      FunctionElement target,
      List<ir.Primitive> arguments) {
    return arguments;
  }

  List<ir.Primitive> normalizeDynamicArguments(
      Selector selector,
      List<ir.Primitive> arguments) {
    return arguments;
  }
}

/// IR builder specific to the JavaScript backend, coupled to the [JsIrBuilder].
class JsIrBuilderVisitor extends IrBuilderVisitor {
  /// Promote the type of [irBuilder] to [JsIrBuilder].
  JsIrBuilder get irBuilder => super.irBuilder;

  /// Result of closure conversion for the current body of code.
  ///
  /// Will be initialized upon entering the body of a function.
  /// It is computed by the [ClosureTranslator].
  ClosureClassMap closureMap;

  /// During construction of a constructor factory, [fieldValues] maps fields
  /// to the primitive containing their initial value.
  Map<FieldElement, ir.Primitive> fieldValues = <FieldElement, ir.Primitive>{};

  JsIrBuilderVisitor(TreeElements elements,
                     Compiler compiler,
                     SourceInformationBuilder sourceInformationBuilder)
      : super(elements, compiler, sourceInformationBuilder);

  /// Builds the IR for creating an instance of the closure class corresponding
  /// to the given nested function.
  ClosureClassElement makeSubFunction(ast.FunctionExpression node) {
    ClosureClassMap innerMap =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    ClosureClassElement closureClass = innerMap.closureClassElement;
    return closureClass;
  }

  ir.Primitive visitFunctionExpression(ast.FunctionExpression node) {
    return irBuilder.buildFunctionExpression(makeSubFunction(node));
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element = elements[node.function];
    Object inner = makeSubFunction(node.function);
    irBuilder.declareLocalFunction(element, inner);
  }

  Map mapValues(Map map, dynamic fn(dynamic)) {
    Map result = {};
    map.forEach((key, value) {
      result[key] = fn(value);
    });
    return result;
  }

  /// Converts closure.dart's CapturedVariable into a ClosureLocation.
  /// There is a 1:1 corresponce between these; we do this because the
  /// IR builder should not depend on synthetic elements.
  ClosureLocation getLocation(CapturedVariable v) {
    if (v is BoxFieldElement) {
      return new ClosureLocation(v.box, v);
    } else {
      ClosureFieldElement field = v;
      return new ClosureLocation(null, field);
    }
  }

  /// If the current function is a nested function with free variables (or a
  /// captured reference to `this`), returns a [ClosureEnvironment]
  /// indicating how to access these.
  ClosureEnvironment getClosureEnvironment() {
    if (closureMap.closureElement == null) return null;
    return new ClosureEnvironment(
        closureMap.closureElement,
        closureMap.thisLocal,
        mapValues(closureMap.freeVariableMap, getLocation));
  }

  /// If [node] has declarations for variables that should be boxed,
  /// returns a [ClosureScope] naming a box to create, and enumerating the
  /// variables that should be stored in the box.
  ///
  /// Also see [ClosureScope].
  ClosureScope getClosureScopeForNode(ast.Node node) {
    closurelib.ClosureScope scope = closureMap.capturingScopes[node];
    if (scope == null) return null;
    // We translate a ClosureScope from closure.dart into IR builder's variant
    // because the IR builder should not depend on the synthetic elements
    // created in closure.dart.
    return new ClosureScope(scope.boxElement,
                            mapValues(scope.capturedVariables, getLocation),
                            scope.boxedLoopVariables);
  }

  /// Returns the [ClosureScope] for any function, possibly different from the
  /// one currently being built.
  ClosureScope getClosureScopeForFunction(FunctionElement function) {
    ClosureClassMap map =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            function,
            function.node,
            elements);
    closurelib.ClosureScope scope = map.capturingScopes[function.node];
    if (scope == null) return null;
    return new ClosureScope(scope.boxElement,
                            mapValues(scope.capturedVariables, getLocation),
                            scope.boxedLoopVariables);
  }

  ir.ExecutableDefinition buildExecutable(ExecutableElement element) {
    return nullIfGiveup(() {
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
          return buildConstructor(element);

        case ElementKind.GENERATIVE_CONSTRUCTOR_BODY:
          return buildConstructorBody(element);

        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          return buildFunction(element);

        default:
          compiler.internalError(element, "Unexpected element type $element");
      }
    });
  }

  /// Builds the IR for an [expression] taken from a different [context].
  ///
  /// Such expressions need to be compiled with a different [sourceFile] and
  /// [elements] mapping.
  ir.Primitive inlineExpression(AstElement context, ast.Expression expression) {
    JsIrBuilderVisitor visitor = new JsIrBuilderVisitor(
        context.resolvedAst.elements,
        compiler,
        sourceInformationBuilder.forContext(context));
    return visitor.withBuilder(irBuilder, () => visitor.visit(expression));
  }

  /// Builds the IR for a constant taken from a different [context].
  ///
  /// Such constants need to be compiled with a different [sourceFile] and
  /// [elements] mapping.
  ir.Primitive inlineConstant(AstElement context, ast.Expression exp) {
    JsIrBuilderVisitor visitor = new JsIrBuilderVisitor(
        context.resolvedAst.elements,
        compiler,
        sourceInformationBuilder.forContext(context));
    return visitor.withBuilder(irBuilder, () => visitor.translateConstant(exp));
  }

  /// Builds the IR for a given constructor.
  ///
  /// 1. Evaluates all own or inherited field initializers.
  /// 2. Creates the object and assigns its fields.
  /// 3. Calls constructor body and super constructor bodies.
  /// 4. Returns the created object.
  ir.FunctionDefinition buildConstructor(ConstructorElement constructor) {
    constructor = constructor.implementation;
    ClassElement classElement = constructor.enclosingClass.implementation;

    JsIrBuilder builder =
        new JsIrBuilder(compiler.backend.constantSystem, constructor);

    return withBuilder(builder, () {
      // Setup parameters and create a box if anything is captured.
      List<ParameterElement> parameters = [];
      constructor.functionSignature.orderedForEachParameter(parameters.add);
      builder.buildFunctionHeader(parameters,
          closureScope: getClosureScopeForFunction(constructor));

      // -- Step 1: evaluate field initializers ---
      // Evaluate field initializers in constructor and super constructors.
      List<ConstructorElement> constructorList = <ConstructorElement>[];
      evaluateConstructorFieldInitializers(constructor, constructorList);

      // All parameters in all constructors are now bound in the environment.
      // BoxLocals for captured parameters are also in the environment.
      // The initial value of all fields are now bound in [fieldValues].

      // --- Step 2: create the object ---
      // Get the initial field values in the canonical order.
      List<ir.Primitive> instanceArguments = <ir.Primitive>[];
      classElement.forEachInstanceField((ClassElement c, FieldElement field) {
        ir.Primitive value = fieldValues[field];
        if (value != null) {
          instanceArguments.add(fieldValues[field]);
        } else {
          assert(Elements.isNativeOrExtendsNative(c));
          // Native fields are initialized elsewhere.
        }
      }, includeSuperAndInjectedMembers: true);
      ir.Primitive instance =
          new ir.CreateInstance(classElement, instanceArguments);
      irBuilder.add(new ir.LetPrim(instance));

      // --- Step 3: call constructor bodies ---
      for (ConstructorElement target in constructorList) {
        ConstructorBodyElement bodyElement = getConstructorBody(target);
        if (bodyElement == null) continue; // Skip if constructor has no body.
        List<ir.Primitive> bodyArguments = <ir.Primitive>[];
        for (Local param in getConstructorBodyParameters(bodyElement)) {
          bodyArguments.add(irBuilder.environment.lookup(param));
        }
        irBuilder.buildInvokeDirectly(bodyElement, instance, bodyArguments);
      }

      // --- step 4: return the created object ----
      irBuilder.buildReturn(instance);

      return irBuilder.makeFunctionDefinition([]);
    });
  }

  /// Evaluates all field initializers on [constructor] and all constructors
  /// invoked through `this()` or `super()` ("superconstructors").
  ///
  /// The resulting field values will be available in [fieldValues]. The values
  /// are not stored in any fields.
  ///
  /// This procedure assumes that the parameters to [constructor] are available
  /// in the IR builder's environment.
  ///
  /// The parameters to superconstructors are, however, assumed *not* to be in
  /// the environment, but will be put there by this procedure.
  ///
  /// All constructors will be added to [supers], with superconstructors first.
  void evaluateConstructorFieldInitializers(ConstructorElement constructor,
                                            List<ConstructorElement> supers) {
    // Evaluate declaration-site field initializers.
    ClassElement enclosingClass = constructor.enclosingClass.implementation;
    enclosingClass.forEachInstanceField((ClassElement c, FieldElement field) {
      if (field.initializer != null) {
        fieldValues[field] = inlineExpression(field, field.initializer);
      } else {
        if (Elements.isNativeOrExtendsNative(c)) {
          // Native field is initialized elsewhere.
        } else {
          // Fields without an initializer default to null.
          // This value will be overwritten below if an initializer is found.
          fieldValues[field] = irBuilder.buildNullLiteral();
        }
      }
    });
    // Evaluate initializing parameters, e.g. `Foo(this.x)`.
    constructor.functionSignature.orderedForEachParameter(
        (ParameterElement parameter) {
      if (parameter.isInitializingFormal) {
        InitializingFormalElement fieldParameter = parameter;
        fieldValues[fieldParameter.fieldElement] =
            irBuilder.buildLocalGet(parameter);
      }
    });
    // Evaluate constructor initializers, e.g. `Foo() : x = 50`.
    ast.FunctionExpression node = constructor.node;
    bool hasConstructorCall = false; // Has this() or super() initializer?
    if (node != null && node.initializers != null) {
      for(ast.Node initializer in node.initializers) {
        if (initializer is ast.SendSet) {
          // Field initializer.
          FieldElement field = elements[initializer];
          fieldValues[field] =
              inlineExpression(constructor, initializer.arguments.head);
        } else if (initializer is ast.Send) {
          // Super or this initializer.
          ConstructorElement target = elements[initializer].implementation;
          Selector selector = elements.getSelector(initializer);
          List<ir.Primitive> arguments = initializer.arguments.mapToList(visit);
          loadArguments(target, selector, arguments);
          evaluateConstructorFieldInitializers(target, supers);
          hasConstructorCall = true;
        } else {
          compiler.internalError(initializer,
                                 "Unexpected initializer type $initializer");
        }
      }
    }
    // If no super() or this() was found, also call default superconstructor.
    if (!hasConstructorCall && !enclosingClass.isObject) {
      ClassElement superClass = enclosingClass.superclass;
      FunctionElement target = superClass.lookupDefaultConstructor();
      if (target == null) {
        compiler.internalError(superClass, "No default constructor available.");
      }
      evaluateConstructorFieldInitializers(target, supers);
    }
    // Add this constructor after the superconstructors.
    supers.add(constructor);
  }

  /// In preparation of inlining (part of) [target], the [arguments] are moved
  /// into the environment bindings for the corresponding parameters.
  ///
  /// Defaults for optional arguments are evaluated in order to ensure
  /// all parameters are available in the environment.
  void loadArguments(FunctionElement target,
                     Selector selector,
                     List<ir.Primitive> arguments) {
    target = target.implementation;
    FunctionSignature signature = target.functionSignature;

    // Establish a scope in case parameters are captured.
    ClosureScope scope = getClosureScopeForFunction(target);
    irBuilder._enterScope(scope);

    // Load required parameters
    int index = 0;
    signature.forEachRequiredParameter((ParameterElement param) {
      irBuilder.declareLocalVariable(param, initialValue: arguments[index]);
      index++;
    });

    // Load optional parameters, evaluating default values for omitted ones.
    signature.forEachOptionalParameter((ParameterElement param) {
      ir.Primitive value;
      // Load argument if provided.
      if (signature.optionalParametersAreNamed) {
        int nameIndex = selector.namedArguments.indexOf(param.name);
        if (nameIndex != -1) {
          int translatedIndex = selector.positionalArgumentCount + nameIndex;
          value = arguments[translatedIndex];
        }
      } else if (index < arguments.length) {
        value = arguments[index];
      }
      // Load default if argument was not provided.
      if (value == null) {
        if (param.initializer != null) {
          value = inlineExpression(target, param.initializer);
        } else {
          value = irBuilder.buildNullLiteral();
        }
      }
      irBuilder.declareLocalVariable(param, initialValue: value);
      index++;
    });
  }

  /**
   * Returns the constructor body associated with the given constructor or
   * creates a new constructor body, if none can be found.
   *
   * Returns `null` if the constructor does not have a body.
   */
  ConstructorBodyElement getConstructorBody(FunctionElement constructor) {
    // TODO(asgerf): This is largely inherited from the SSA builder.
    // The ConstructorBodyElement has an invalid function signature, but we
    // cannot add a BoxLocal as parameter, because BoxLocal is not an element.
    // Instead of forging ParameterElements to forge a FunctionSignature, we
    // need a way to create backend methods without creating more fake elements.

    assert(constructor.isGenerativeConstructor);
    assert(invariant(constructor, constructor.isImplementation));
    if (constructor.isSynthesized) return null;
    ast.FunctionExpression node = constructor.node;
    // If we know the body doesn't have any code, we don't generate it.
    if (!node.hasBody()) return null;
    if (node.hasEmptyBody()) return null;
    ClassElement classElement = constructor.enclosingClass;
    ConstructorBodyElement bodyElement;
    classElement.forEachBackendMember((Element backendMember) {
      if (backendMember.isGenerativeConstructorBody) {
        ConstructorBodyElement body = backendMember;
        if (body.constructor == constructor) {
          bodyElement = backendMember;
        }
      }
    });
    if (bodyElement == null) {
      bodyElement = new ConstructorBodyElementX(constructor);
      classElement.addBackendMember(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        ConstructorBodyElementX patch = bodyElement;
        ConstructorBodyElementX origin =
            new ConstructorBodyElementX(constructor.origin);
        origin.applyPatch(patch);
        classElement.origin.addBackendMember(bodyElement.origin);
      }
    }
    assert(bodyElement.isGenerativeConstructorBody);
    return bodyElement;
  }

  /// The list of parameters to send from the generative constructor
  /// to the generative constructor body.
  ///
  /// Boxed parameters are not in the list, instead, a [BoxLocal] is passed
  /// containing the boxed parameters.
  ///
  /// For example, given the following constructor,
  ///
  ///     Foo(x, y) : field = (() => ++x) { print(x + y) }
  ///
  /// the argument `x` would be replaced by a [BoxLocal]:
  ///
  ///     Foo_body(box0, y) { print(box0.x + y) }
  ///
  List<Local> getConstructorBodyParameters(ConstructorBodyElement body) {
    List<Local> parameters = <Local>[];
    ClosureScope scope = getClosureScopeForFunction(body.constructor);
    if (scope != null) {
      parameters.add(scope.box);
    }
    body.functionSignature.orderedForEachParameter((ParameterElement param) {
      if (scope != null && scope.capturedVariables.containsKey(param)) {
        // Do not pass this parameter; the box will carry its value.
      } else {
        parameters.add(param);
      }
    });
    return parameters;
  }

  /// Builds the IR for the body of a constructor.
  ///
  /// This function is invoked from one or more "factory" constructors built by
  /// [buildConstructor].
  ir.FunctionDefinition buildConstructorBody(ConstructorBodyElement body) {
    ConstructorElement constructor = body.constructor;
    ast.FunctionExpression node = constructor.node;
    closureMap = compiler.closureToClassMapper.computeClosureToClassMapping(
        constructor,
        node,
        elements);

    JsIrBuilder builder =
        new JsIrBuilder(compiler.backend.constantSystem, body);

    return withBuilder(builder, () {
      irBuilder.buildConstructorBodyHeader(getConstructorBodyParameters(body),
                                           getClosureScopeForNode(node));
      visit(node.body);
      return irBuilder.makeFunctionDefinition([]);
    });
  }

  ir.FunctionDefinition buildFunction(FunctionElement element) {
    assert(invariant(element, element.isImplementation));
    ast.FunctionExpression node = element.node;

    assert(!element.isSynthesized);
    assert(node != null);
    assert(elements[node] != null);

    closureMap = compiler.closureToClassMapper.computeClosureToClassMapping(
        element,
        node,
        elements);
    IrBuilder builder =
        new JsIrBuilder(compiler.backend.constantSystem, element);
    return withBuilder(builder, () => _makeFunctionBody(element, node));
  }

  /// Creates a primitive for the default value of [parameter].
  ir.Primitive translateDefaultValue(ParameterElement parameter) {
    if (parameter.initializer == null) {
      return irBuilder.buildNullLiteral();
    } else {
      return inlineConstant(parameter.executableContext, parameter.initializer);
    }
  }

  /// Inserts default arguments and normalizes order of named arguments.
  List<ir.Primitive> normalizeStaticArguments(
      Selector selector,
      FunctionElement target,
      List<ir.Primitive> arguments) {
    target = target.implementation;
    FunctionSignature signature = target.functionSignature;
    if (!signature.optionalParametersAreNamed &&
        signature.parameterCount == arguments.length) {
      // Optimization: don't copy the argument list for trivial cases.
      return arguments;
    }

    List<ir.Primitive> result = <ir.Primitive>[];
    int i = 0;
    signature.forEachRequiredParameter((ParameterElement element) {
      result.add(arguments[i]);
      ++i;
    });

    if (!signature.optionalParametersAreNamed) {
      signature.forEachOptionalParameter((ParameterElement element) {
        if (i < arguments.length) {
          result.add(arguments[i]);
          ++i;
        } else {
          result.add(translateDefaultValue(element));
        }
      });
    } else {
      int offset = i;
      // Iterate over the optional parameters of the signature, and try to
      // find them in [compiledNamedArguments]. If found, we use the
      // value in the temporary list, otherwise the default value.
      signature.orderedOptionalParameters.forEach((ParameterElement element) {
        int nameIndex = selector.namedArguments.indexOf(element.name);
        if (nameIndex != -1) {
          int translatedIndex = offset + nameIndex;
          result.add(arguments[translatedIndex]);
        } else {
          result.add(translateDefaultValue(element));
        }
      });
    }
    return result;
  }

  /// Normalizes order of named arguments.
  List<ir.Primitive> normalizeDynamicArguments(
      Selector selector,
      List<ir.Primitive> arguments) {
    assert(arguments.length == selector.argumentCount);
    // Optimization: don't copy the argument list for trivial cases.
    if (selector.namedArguments.isEmpty) return arguments;
    List<ir.Primitive> result = <ir.Primitive>[];
    for (int i=0; i < selector.positionalArgumentCount; i++) {
      result.add(arguments[i]);
    }
    for (String argName in selector.getOrderedNamedArguments()) {
      int nameIndex = selector.namedArguments.indexOf(argName);
      int translatedIndex = selector.positionalArgumentCount + nameIndex;
      result.add(arguments[translatedIndex]);
    }
    return result;
  }
}

/// Interface for generating [SourceInformation] for the CPS.
class SourceInformationBuilder {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [element].
  SourceInformationBuilder forContext(AstElement element) => this;

  /// Generate [SourceInformation] for the read access in [node].
  SourceInformation buildGet(ast.Node node) => null;

  /// Generate [SourceInformation] for the invocation in [node].
  SourceInformation buildCall(ast.Node node) => null;
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation].
class PositionSourceInformationBuilder implements SourceInformationBuilder {
  final SourceFile sourceFile;
  final String name;

  PositionSourceInformationBuilder(AstElement element)
      : sourceFile = element.compilationUnit.script.file,
        name = element.name;

  @override
  SourceInformation buildGet(ast.Node node) {
    return new PositionSourceInformation(
        new TokenSourceLocation(sourceFile, node.getBeginToken(), name));
  }

  @override
  SourceInformation buildCall(ast.Node node) {
    return new PositionSourceInformation(
        new TokenSourceLocation(sourceFile, node.getBeginToken(), name));
  }

  @override
  SourceInformationBuilder forContext(AstElement element) {
    return new PositionSourceInformationBuilder(element);
  }
}
