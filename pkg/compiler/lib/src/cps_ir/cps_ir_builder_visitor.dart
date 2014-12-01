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

  IrBuilderTask(Compiler compiler) : super(compiler);

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
      SourceFile sourceFile = elementSourceFile(element);
      IrBuilderVisitor builder =
          new IrBuilderVisitor(elementsMapping, compiler, sourceFile);
      return builder.buildExecutable(element);
    });
  }

  void buildNodes() {
    measure(() {
      Set<Element> resolved = compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach((AstElement element) {
        ir.ExecutableDefinition definition = buildNode(element);
        if (definition != null) {
          nodes[element] = definition;
        }
      });
    });
  }

  bool canBuild(Element element) {
    if (element is TypedefElement) return false;
    if (element is FunctionElement) {
      // TODO(sigurdm): Support native functions for dart2js.
      assert(invariant(element, !element.isNative));

      // TODO(kmillikin,sigurdm): Support constructors.
      if (element is ConstructorElement) return false;

    } else if (element is! FieldElement) {
      compiler.internalError(element, "Unexpected elementtype $element");
    }
    return compiler.backend.shouldOutput(element);
  }

  bool get inCheckedMode {
    bool result = false;
    assert((result = true));
    return result;
  }

  SourceFile elementSourceFile(Element element) {
    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      if (functionElement.patch != null) element = functionElement.patch;
    }
    return element.compilationUnit.script.file;
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
class IrBuilderVisitor extends ResolvedVisitor<ir.Primitive>
    with IrBuilderMixin<ast.Node> {
  final Compiler compiler;
  final SourceFile sourceFile;

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
  IrBuilderVisitor(TreeElements elements, this.compiler, this.sourceFile)
      : super(elements);

  /**
   * Builds the [ir.ExecutableDefinition] for an executable element. In case the
   * function uses features that cannot be expressed in the IR, this element
   * returns `null`.
   */
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
  /// Returns `null` if [element] has no initializer.
  ir.FieldDefinition buildField(FieldElement element) {
    assert(invariant(element, element.isImplementation));
    ast.VariableDefinitions definitions = element.node;
    ast.Node fieldDefinition =
        definitions.definitions.nodes.first;
    if (definitions.modifiers.isConst) {
      // TODO(sigurdm): Just return const value.
    }
    assert(fieldDefinition != null);
    assert(elements[fieldDefinition] != null);
    DetectClosureVariables closureLocals =
    new DetectClosureVariables(elements);
        closureLocals.visit(fieldDefinition);

    IrBuilder builder = new IrBuilder(compiler.backend.constantSystem,
        element,
        closureLocals.usedFromClosure);
    return withBuilder(builder, () {
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
    ast.FunctionExpression function = element.node;
    assert(function != null);
    assert(elements[function] != null);

    DetectClosureVariables closureLocals = new DetectClosureVariables(elements);
    closureLocals.visit(function);

    return withBuilder(
        new IrBuilder(compiler.backend.constantSystem,
                      element, closureLocals.usedFromClosure),
        () {
      FunctionSignature signature = element.functionSignature;
      signature.orderedForEachParameter((ParameterElement parameterElement) {
        irBuilder.createParameter(parameterElement);
      });

      List<ConstantExpression> defaults = new List<ConstantExpression>();
      signature.orderedOptionalParameters.forEach((ParameterElement element) {
        defaults.add(getConstantForVariable(element));
      });

      visit(function.body);
      return irBuilder.makeFunctionDefinition(defaults);
    });
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
    // TODO(kmillikin,sigurdm): Handle closure variables declared in a for-loop.
    if (node.initializer is ast.VariableDefinitions) {
      ast.VariableDefinitions definitions = node.initializer;
      for (ast.Node definition in definitions.definitions.nodes) {
        Element element = elements[definition];
        if (irBuilder.isClosureVariable(element)) {
          return giveup(definition, 'Closure variable in for loop initializer');
        }
      }
    }

    JumpTarget target = elements.getTargetDefinition(node);
    irBuilder.buildFor(
        buildInitializer: subbuild(node.initializer),
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        buildUpdate: subbuildSequence(node.update),
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
    IrBuilder innerBuilder = new IrBuilder.delimited(irBuilder);
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
      irBuilder.add(new ir.LetCont(joinContinuation, innerBuilder._root));
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
        target: elements.getTargetDefinition(node));
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
        target: elements.getTargetDefinition(node));
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
    Selector closureSelector = elements.getSelector(node);
    if (element == null) {
      ir.Primitive closureTarget = visit(node.selector);
      List<ir.Primitive> args =
          node.arguments.mapToList(visit, growable:false);
      return irBuilder.buildFunctionExpressionInvocation(
          closureTarget, elements.getSelector(node), args);
    } else {
      List<ir.Primitive> args =
          node.arguments.mapToList(visit, growable:false);
      return irBuilder.buildLocalInvocation(
          element, elements.getSelector(node), args);
    }
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
    List<ir.Primitive> arguments = new List<ir.Primitive>();
    for (ast.Node n in node.arguments) {
      arguments.add(visit(n));
    }
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
        result = irBuilder.buildSuperInvocation(selector, arguments);
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
      result = irBuilder.buildStaticGet(element, selector);
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

    // TODO(lry): support default arguments, need support for locals.
    List<ir.Primitive> arguments =
        node.arguments.mapToList(visit, growable:false);
    return irBuilder.buildStaticInvocation(element, selector, arguments);
  }

  ir.Primitive visitSuperSend(ast.Send node) {
    assert(irBuilder.isOpen);
    if (node.isPropertyAccess) {
      return visitGetterSend(node);
    } else {
      Selector selector = elements.getSelector(node);
      List<ir.Primitive> arguments = new List<ir.Primitive>();
      for (ast.Node n in node.arguments) {
        arguments.add(visit(n));
      }
      return irBuilder.buildSuperInvocation(selector, arguments);
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
    } else if ((!node.isSuperCall && Elements.isErroneousElement(element)) ||
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
          irBuilder.buildSuperIndexSet(index, valueToStore);
        } else {
          irBuilder.buildDynamicIndexSet(receiver, index, valueToStore);
        }
      } else {
        if (isSuperCall(node)) {
          irBuilder.buildSuperSet(selector, valueToStore);
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
    List<ir.Definition> arguments =
        node.send.arguments.mapToList(visit, growable:false);
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

  ir.Primitive translateConstant(ast.Node node, [ConstantExpression constant]) {
    assert(irBuilder.isOpen);
    if (constant == null) {
      constant = getConstantForNode(node);
    }
    return irBuilder.buildConstantLiteral(constant);
  }

  ir.FunctionDefinition makeSubFunction(ast.FunctionExpression node) {
    return buildFunction(elements[node]);
  }

  ir.Primitive visitFunctionExpression(ast.FunctionExpression node) {
    return irBuilder.buildFunctionExpression(makeSubFunction(node));
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element = elements[node.function];
    ir.FunctionDefinition inner = makeSubFunction(node.function);
    irBuilder.declareLocalFunction(element, inner);
  }

  static final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

  dynamic giveup(ast.Node node, [String reason]) {
    throw ABORT_IRNODE_BUILDER;
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

/// Classifies local variables and local functions as 'closure variables'.
/// A closure variable is one that is accessed from an inner function nested
/// one or more levels inside the one that declares it.
class DetectClosureVariables extends ast.Visitor {
  final TreeElements elements;
  DetectClosureVariables(this.elements);

  FunctionElement currentFunction;
  Set<Local> usedFromClosure = new Set<Local>();
  Set<FunctionElement> recursiveFunctions = new Set<FunctionElement>();

  bool isClosureVariable(Entity entity) => usedFromClosure.contains(entity);

  void markAsClosureVariable(Local local) {
    usedFromClosure.add(local);
  }

  visit(ast.Node node) => node.accept(this);

  visitNode(ast.Node node) {
    node.visitChildren(this);
  }

  visitSend(ast.Send node) {
    Element element = elements[node];
    if (Elements.isLocal(element) &&
        !element.isConst &&
        element.enclosingElement != currentFunction) {
      LocalElement local = element;
      markAsClosureVariable(local);
    }
    node.visitChildren(this);
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    FunctionElement oldFunction = currentFunction;
    currentFunction = elements[node];
    visit(node.body);
    currentFunction = oldFunction;
  }
}
