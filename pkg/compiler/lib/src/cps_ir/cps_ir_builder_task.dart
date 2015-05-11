// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_builder_task;

import '../closure.dart' as closurelib;
import '../closure.dart' hide ClosureScope;
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../dart2jslib.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart' show SynthesizedConstructorElementX,
    ConstructorBodyElementX, FunctionSignatureX;
import '../io/source_information.dart';
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../resolution/semantic_visitor.dart';
import '../resolution/operators.dart' as op;
import '../scanner/scannerlib.dart' show Token, isUserDefinableOperator;
import '../tree/tree.dart' as ast;
import '../universe/universe.dart' show SelectorKind, CallStructure;
import 'cps_ir_nodes.dart' as ir;
import 'cps_ir_builder.dart';

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
  final Map<Element, ir.RootNode> nodes = <Element, ir.RootNode>{};
  final SourceInformationFactory sourceInformationFactory;

  String bailoutMessage = null;

  IrBuilderTask(Compiler compiler, this.sourceInformationFactory)
      : super(compiler);

  String get name => 'IR builder';

  bool hasIr(Element element) => nodes.containsKey(element.implementation);

  ir.RootNode getIr(ExecutableElement element) {
    return nodes[element.implementation];
  }

  ir.RootNode buildNode(AstElement element) {
    return measure(() => _buildNode(element));
  }

  ir.RootNode _buildNode(AstElement element) {
    bailoutMessage = null;
    if (!canBuild(element)) {
      bailoutMessage = 'unsupported element ${element.name}:${element.kind}';
      return null;
    }

    TreeElements elementsMapping = element.resolvedAst.elements;
    element = element.implementation;
    return compiler.withCurrentElement(element, () {
      SourceInformationBuilder sourceInformationBuilder =
          sourceInformationFactory.forContext(element);

      IrBuilderVisitor builder =
          compiler.backend is JavaScriptBackend
          ? new JsIrBuilderVisitor(
              elementsMapping, compiler, sourceInformationBuilder)
          : new DartIrBuilderVisitor(
              elementsMapping, compiler, sourceInformationBuilder);
      ir.RootNode irNode = builder.buildExecutable(element);
      if (irNode == null) {
        bailoutMessage = builder.bailoutMessage;
      } else {
        nodes[element] = irNode;
      }
      return irNode;
    });
  }

  void buildNodes() {
    measure(() {
      Set<Element> resolved = compiler.enqueuer.resolution.resolvedElements;
      resolved.forEach(buildNode);
    });
  }

  bool canBuild(Element element) {
    // If using JavaScript backend, don't try to bail out early.
    if (compiler.backend is JavaScriptBackend) return true;

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

/**
 * A tree visitor that builds [IrNodes]. The visit methods add statements using
 * to the [builder] and return the last added statement for trees that represent
 * an expression.
 */
// TODO(johnniwinther): Implement [SemanticDeclVisitor].
abstract class IrBuilderVisitor extends ast.Visitor<ir.Primitive>
    with IrBuilderMixin<ast.Node>,
         SemanticSendResolvedMixin<ir.Primitive, dynamic>,
         SendResolverMixin,
         BaseImplementationOfStaticsMixin<ir.Primitive, dynamic>,
         BaseImplementationOfLocalsMixin<ir.Primitive, dynamic>,
         BaseImplementationOfDynamicsMixin<ir.Primitive, dynamic>,
         BaseImplementationOfConstantsMixin<ir.Primitive, dynamic>,
         BaseImplementationOfSuperIncDecsMixin<ir.Primitive, dynamic>,
         BaseImplementationOfNewMixin<ir.Primitive, dynamic>
    implements SemanticSendVisitor<ir.Primitive, dynamic> {
  final TreeElements elements;
  final Compiler compiler;
  final SourceInformationBuilder sourceInformationBuilder;

  /// A map from try statements in the source to analysis information about
  /// them.
  ///
  /// The analysis information includes the set of variables that must be
  /// copied into [ir.MutableVariable]s on entry to the try and copied out on
  /// exit.
  Map<ast.TryStatement, TryStatementInfo> tryStatements = null;

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
  IrBuilderVisitor(this.elements,
                   this.compiler,
                   this.sourceInformationBuilder);

  String bailoutMessage = null;

  @override
  ir.Primitive apply(ast.Node node, _) => node.accept(this);

  @override
  SemanticSendVisitor get sendVisitor => this;

  /**
   * Builds the [ir.RootNode] for an executable element. In case the
   * function uses features that cannot be expressed in the IR, this element
   * returns `null`.
   */
  ir.RootNode buildExecutable(ExecutableElement element);

  ClosureClassMap get closureClassMap;
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
      CallStructure callStructure,
      FunctionElement target,
      List<ir.Primitive> arguments);

  /// Normalizes the argument list of a dynamic invocation (i.e. where the
  /// target element is unknown).
  ///
  /// For the JS backend, normalizes order of named arguments.
  ///
  /// For the Dart backend, returns [arguments].
  List<ir.Primitive> normalizeDynamicArguments(
      CallStructure callStructure,
      List<ir.Primitive> arguments);

  /// Creates a [TypedSelector] variant of [newSelector] using the type of
  /// [oldSelector], if available.
  ///
  /// This is needed to preserve inferred receiver types when creating new
  /// selectors.
  Selector useSelectorType(Selector newSelector, Selector oldSelector) {
    // TODO(asgerf,johnniwinther): This works but it is brittle.
    //     We should decouple selectors from inferred receiver type masks.
    // TODO(asgerf): Use this whenever we create a selector for a dynamic call.
    if (oldSelector is TypedSelector) {
      return new TypedSelector(oldSelector.mask, newSelector, compiler.world);
    } else {
      return newSelector;
    }
  }

  /// Like [useSelectorType], except the original typed selector is obtained
  /// from the [node].
  Selector useSelectorTypeOfNode(Selector newSelector, ast.Send node) {
    return useSelectorType(newSelector, elements.getSelector(node));
  }

  ir.RootNode _makeFunctionBody(FunctionElement element,
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
      if (element.isExternal) {
        return irBuilder.makeAbstractConstructorDefinition(defaults);
      } else {
        initializers = buildConstructorInitializers(node, element);
        visit(node.body);
        return irBuilder.makeConstructorDefinition(defaults, initializers);
      }
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
        withBuilder(irBuilder.makeInitializerBuilder(), () {
          ir.Primitive value =
              irBuilder.buildLocalVariableGet(parameterElement);
          result.add(irBuilder.makeFieldInitializer(
              initializingFormal.fieldElement,
              irBuilder.makeBody(value)));
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
        withBuilder(irBuilder.makeInitializerBuilder(), () {
          ir.Primitive value = visit(initializer.arguments.head);
          ir.Body body = irBuilder.makeBody(value);
          result.add(irBuilder.makeFieldInitializer(field, body));
        });
      } else if (initializer is ast.Send) {
        // Super or this initializer.
        if (ast.Initializers.isConstructorRedirect(initializer)) {
          giveup(initializer, "constructor redirect (this) initializer");
        }
        ConstructorElement constructor = elements[initializer].implementation;
        Selector selector = elements.getSelector(initializer);
        List<ir.Body> arguments =
            initializer.arguments.mapToList((ast.Node argument) {
          return withBuilder(irBuilder.makeInitializerBuilder(), () {
            ir.Primitive value = visit(argument);
            return irBuilder.makeBody(value);
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
                                                  <ir.Body>[],
                                                  selector));
      }
    }
    return result;
  }

  ir.Primitive visit(ast.Node node) => node.accept(this);

  // ## Statements ##
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
    if (node.expression is ast.Throw) {
      // Throw expressions that occur as statements are translated differently
      // from ones that occur as subexpressions.  This is achieved by peeking
      // at statement-level expressions here.
      irBuilder.buildThrow(visit(node.expression));
    } else {
      visit(node.expression);
    }
    return null;
  }

  ir.Primitive visitRethrow(ast.Rethrow node) {
    assert(irBuilder.isOpen);
    irBuilder.buildRethrow();
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

  visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop) {
      visit(body);
    } else {
      JumpTarget target = elements.getTargetDefinition(body);
      irBuilder.buildLabeledStatement(
          buildBody: subbuild(body),
          target: target);
    }
  }

  visitDoWhile(ast.DoWhile node) {
    irBuilder.buildDoWhile(
        buildBody: subbuild(node.body),
        buildCondition: subbuild(node.condition),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  visitWhile(ast.While node) {
    irBuilder.buildWhile(
        buildCondition: subbuild(node.condition),
        buildBody: subbuild(node.body),
        target: elements.getTargetDefinition(node),
        closureScope: getClosureScopeForNode(node));
  }

  visitAsyncForIn(ast.AsyncForIn node) {
    // await for is not yet implemented.
    return giveup(node, 'await for');
  }

  visitSyncForIn(ast.SyncForIn node) {
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

  visitTryStatement(ast.TryStatement node) {
    // Finally blocks are not yet implemented.
    if (node.finallyBlock != null) {
      return giveup(node, 'try/finally');
    }

    List<CatchClauseInfo> catchClauseInfos = <CatchClauseInfo>[];
    for (ast.CatchBlock catchClause in node.catchBlocks.nodes) {
      assert(catchClause.exception != null);
      LocalVariableElement exceptionVariable = elements[catchClause.exception];
      LocalVariableElement stackTraceVariable;
      if (catchClause.trace != null) {
        stackTraceVariable = elements[catchClause.trace];
      }
      DartType type;
      if (catchClause.onKeyword != null) {
        type = elements.getType(catchClause.type);
      }
      catchClauseInfos.add(new CatchClauseInfo(
          type: type,
          exceptionVariable: exceptionVariable,
          stackTraceVariable: stackTraceVariable,
          buildCatchBlock: subbuild(catchClause.block)));
    }

    irBuilder.buildTry(
        tryStatementInfo: tryStatements[node],
        buildTryBlock: subbuild(node.tryBlock),
        catchClauseInfos: catchClauseInfos,
        closureClassMap: closureClassMap);
  }

  // ## Expressions ##
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
    return irBuilder.buildBooleanConstant(node.value);
  }

  ir.Primitive visitLiteralDouble(ast.LiteralDouble node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildDoubleConstant(node.value);
  }

  ir.Primitive visitLiteralInt(ast.LiteralInt node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildIntegerConstant(node.value);
  }

  ir.Primitive visitLiteralNull(ast.LiteralNull node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildNullConstant();
  }

  ir.Primitive visitLiteralString(ast.LiteralString node) {
    assert(irBuilder.isOpen);
    return irBuilder.buildDartStringConstant(node.dartString);
  }

  ConstantExpression getConstantForNode(ast.Node node) {
    ConstantExpression constant =
        compiler.backend.constants.getConstantForNode(node, elements);
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
    visit(node.expression);
    ir.Primitive receiver = _currentCascadeReceiver;
    _currentCascadeReceiver = oldCascadeReceiver;
    return receiver;
  }

  // ## Sends ##
  @override
  ir.Primitive visitAssert(ast.Send node, ast.Node condition, _) {
    assert(irBuilder.isOpen);
    if (compiler.enableUserAssertions) {
      return giveup(node, 'assert in checked mode not implemented');
    } else {
      // The call to assert and its argument expression must be ignored
      // in production mode.
      // Assertions can only occur in expression statements, so no value needs
      // to be returned.
      return null;
    }
  }

  ir.Primitive visitNamedArgument(ast.NamedArgument node) {
    assert(irBuilder.isOpen);
    return visit(node.expression);
  }

  @override
  ir.Primitive visitExpressionInvoke(ast.Send node,
                                     ast.Node expression,
                                     ast.NodeList arguments,
                                     Selector selector, _) {
    ir.Primitive receiver = visit(expression);
    List<ir.Primitive> arguments = node.arguments.mapToList(visit);
    arguments = normalizeDynamicArguments(selector.callStructure, arguments);
    return irBuilder.buildCallInvocation(
        receiver, selector.callStructure, arguments);
  }

  /// Returns `true` if [node] is a super call.
  // TODO(johnniwinther): Remove the need for this.
  bool isSuperCall(ast.Send node) {
    return node != null && node.receiver != null && node.receiver.isSuper();
  }

  @override
  ir.Primitive handleConstantGet(
      ast.Node node,
      ConstantExpression constant, _) {
    return irBuilder.buildConstant(constant);
  }

  /// If [node] is null, returns this.
  /// Otherwise visits [node] and returns the result.
  ir.Primitive translateReceiver(ast.Expression node) {
    return node != null ? visit(node) : irBuilder.buildThis();
  }

  @override
  ir.Primitive handleDynamicGet(
      ast.Send node,
      ast.Node receiver,
      Selector selector,
      _) {
    return irBuilder.buildDynamicGet(
        translateReceiver(receiver),
        selector);
  }

  @override
  ir.Primitive visitDynamicTypeLiteralGet(
      ast.Send node,
      ConstantExpression constant,
      _) {
    return irBuilder.buildConstant(constant);
  }

  @override
  ir.Primitive visitLocalVariableGet(
      ast.Send node,
      LocalVariableElement element,
      _) {
    return element.isConst
        ? irBuilder.buildConstant(getConstantForVariable(element))
        : irBuilder.buildLocalVariableGet(element);
  }

  @override
  ir.Primitive handleLocalGet(
      ast.Send node,
      LocalElement element,
      _) {
    return irBuilder.buildLocalVariableGet(element);
  }

  @override
  ir.Primitive visitLocalFunctionGet(
      ast.Send node,
      LocalFunctionElement function,
      _) {
    return irBuilder.buildLocalFunctionGet(function);
  }

  @override
  ir.Primitive handleStaticFieldGet(ast.Send node, FieldElement field, _) {
    return field.isConst
        ? irBuilder.buildConstant(getConstantForVariable(field))
        : irBuilder.buildStaticFieldGet(field,
              sourceInformation: sourceInformationBuilder.buildGet(node));
  }

  @override
  ir.Primitive handleStaticFunctionGet(
      ast.Send node,
      MethodElement function,
      _) {
    // TODO(karlklose): support foreign functions.
    if (function.isForeign(compiler.backend)) {
      return giveup(node, 'handleStaticFunctionGet: foreign: $function');
    }
    return giveup(node, 'handleStaticFunctionGet: $function');
  }

  @override
  ir.Primitive handleStaticGetterGet(
      ast.Send node,
      FunctionElement getter,
      _) {
    return irBuilder.buildStaticGetterGet(getter);
  }

  @override
  ir.Primitive visitSuperFieldGet(
      ast.Send node,
      FieldElement field,
      _) {
    return irBuilder.buildSuperFieldGet(field);
  }

  @override
  ir.Primitive visitSuperGetterGet(
      ast.Send node,
      FunctionElement getter,
      _) {
    return irBuilder.buildSuperGetterGet(getter);
  }

  @override
  ir.Primitive visitSuperMethodGet(
      ast.Send node,
      MethodElement method,
      _) {
    return irBuilder.buildSuperMethodGet(method);
  }

  @override
  ir.Primitive visitUnresolvedSuperGet(
      ast.Send node,
      Element element, _) {
    return buildInstanceNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive visitThisGet(ast.Identifier node, _) {
    if (irBuilder.state.thisParameter == null) {
      // TODO(asgerf,johnniwinther): Should be in a visitInvalidThis method.
      // 'this' in static context. Just translate to null.
      assert(compiler.compilationFailed);
      return irBuilder.buildNullConstant();
    }
    return irBuilder.buildThis();
  }

  ir.Primitive translateTypeVariableTypeLiteral(TypeVariableElement element) {
    return irBuilder.buildReifyTypeVariable(element.type);
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralGet(ast.Send node,
                                               TypeVariableElement element, _) {
    return translateTypeVariableTypeLiteral(element);
  }

  ir.Primitive translateLogicalOperator(ast.Expression left,
                                        ast.Expression right,
                                        {bool isLazyOr}) {
    ir.Primitive leftValue = visit(left);

    ir.Primitive buildRightValue(IrBuilder rightBuilder) {
      return withBuilder(rightBuilder, () => visit(right));
    }

    return irBuilder.buildLogicalOperator(
        leftValue, buildRightValue, isLazyOr: isLazyOr);
  }

  @override
  ir.Primitive visitLogicalAnd(
      ast.Send node, ast.Node left, ast.Node right, _) {
    return translateLogicalOperator(left, right, isLazyOr: false);
  }

  @override
  ir.Primitive visitLogicalOr(
      ast.Send node, ast.Node left, ast.Node right, _) {
    return translateLogicalOperator(left, right, isLazyOr: true);
  }

  @override
  ir.Primitive visitAs(
      ast.Send node,
      ast.Node expression,
      DartType type,
      _) {
    ir.Primitive receiver = visit(expression);
    return irBuilder.buildTypeOperator(receiver, type, isTypeTest: false);
  }

  @override
  ir.Primitive visitIs(
      ast.Send node,
      ast.Node expression,
      DartType type,
      _) {
    ir.Primitive receiver = visit(expression);
    return irBuilder.buildTypeOperator(
        receiver, type,
        isTypeTest: true,
        isNotCheck: false);
  }

  @override
  ir.Primitive visitIsNot(ast.Send node,
                          ast.Node expression, DartType type, _) {
    ir.Primitive receiver = visit(expression);
    return irBuilder.buildTypeOperator(
        receiver, type,
        isTypeTest: true,
        isNotCheck: true);
  }

  ir.Primitive translateBinary(ast.Node left,
                               op.BinaryOperator operator,
                               ast.Node right) {
    Selector selector = new Selector.binaryOperator(operator.selectorName);
    ir.Primitive receiver = visit(left);
    List<ir.Primitive> arguments = <ir.Primitive>[visit(right)];
    arguments = normalizeDynamicArguments(selector.callStructure, arguments);
    return irBuilder.buildDynamicInvocation(receiver, selector, arguments);
  }

  @override
  ir.Primitive visitBinary(ast.Send node,
                           ast.Node left,
                           op.BinaryOperator operator,
                           ast.Node right, _) {
    return translateBinary(left, operator, right);
  }

  @override
  ir.Primitive visitIndex(ast.Send node,
                          ast.Node receiver,
                          ast.Node index, _) {
    Selector selector = new Selector.index();
    ir.Primitive target = visit(receiver);
    List<ir.Primitive> arguments = <ir.Primitive>[visit(index)];
    arguments = normalizeDynamicArguments(selector.callStructure, arguments);
    return irBuilder.buildDynamicInvocation(target, selector, arguments);
  }

  ir.Primitive translateSuperBinary(FunctionElement function,
                                    op.BinaryOperator operator,
                                    ast.Node argument) {
    CallStructure callStructure = CallStructure.ONE_ARG;
    List<ir.Primitive> arguments = <ir.Primitive>[visit(argument)];
    arguments = normalizeDynamicArguments(callStructure, arguments);
    return irBuilder.buildSuperMethodInvocation(
        function, callStructure, arguments);
  }

  @override
  ir.Primitive visitSuperBinary(
      ast.Send node,
      FunctionElement function,
      op.BinaryOperator operator,
      ast.Node argument,
      _) {
    return translateSuperBinary(function, operator, argument);
  }

  @override
  ir.Primitive visitSuperIndex(
      ast.Send node,
      FunctionElement function,
      ast.Node index,
      _) {
    return irBuilder.buildSuperIndex(function, visit(index));
  }

  @override
  ir.Primitive visitEquals(
      ast.Send node,
      ast.Node left,
      ast.Node right,
      _) {
    return translateBinary(left, op.BinaryOperator.EQ, right);
  }

  @override
  ir.Primitive visitSuperEquals(
      ast.Send node,
      FunctionElement function,
      ast.Node argument,
      _) {
    return translateSuperBinary(function, op.BinaryOperator.EQ, argument);
  }

  @override
  ir.Primitive visitNot(
      ast.Send node,
      ast.Node expression,
      _) {
    return irBuilder.buildNegation(visit(expression));
  }

  @override
  ir.Primitive visitNotEquals(
      ast.Send node,
      ast.Node left,
      ast.Node right,
      _) {
    return irBuilder.buildNegation(
        translateBinary(left, op.BinaryOperator.NOT_EQ, right));
  }

  @override
  ir.Primitive visitSuperNotEquals(
      ast.Send node,
      FunctionElement function,
      ast.Node argument,
      _) {
    return irBuilder.buildNegation(
        translateSuperBinary(function, op.BinaryOperator.NOT_EQ, argument));
  }

  @override
  ir.Primitive visitUnary(ast.Send node,
                          op.UnaryOperator operator, ast.Node expression, _) {
    // TODO(johnniwinther): Clean up the creation of selectors.
    Selector selector = new Selector(
        SelectorKind.OPERATOR,
        new PublicName(operator.selectorName),
        CallStructure.NO_ARGS);
    ir.Primitive receiver = translateReceiver(expression);
    return irBuilder.buildDynamicInvocation(receiver, selector, const []);
  }

  @override
  ir.Primitive visitSuperUnary(
      ast.Send node,
      op.UnaryOperator operator,
      FunctionElement function,
      _) {
    return irBuilder.buildSuperMethodInvocation(
        function, CallStructure.NO_ARGS, const []);
  }

  // TODO(johnniwinther): Handle this in the [IrBuilder] to ensure the correct
  // semantic correlation between arguments and invocation.
  List<ir.Primitive> translateDynamicArguments(ast.NodeList nodeList,
                                               CallStructure callStructure) {
    List<ir.Primitive> arguments = nodeList.nodes.mapToList(visit);
    return normalizeDynamicArguments(callStructure, arguments);
  }

  // TODO(johnniwinther): Handle this in the [IrBuilder] to ensure the correct
  // semantic correlation between arguments and invocation.
  List<ir.Primitive> translateStaticArguments(ast.NodeList nodeList,
                                              Element element,
                                              CallStructure callStructure) {
    List<ir.Primitive> arguments = nodeList.nodes.mapToList(visit);
    return normalizeStaticArguments(callStructure, element, arguments);
  }

  ir.Primitive translateCallInvoke(ir.Primitive target,
                                   ast.NodeList arguments,
                                   CallStructure callStructure) {

    return irBuilder.buildCallInvocation(target, callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive handleConstantInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Primitive target = irBuilder.buildConstant(constant);
    return translateCallInvoke(target, arguments, callStructure);
  }

  @override
  ir.Primitive handleDynamicInvoke(
      ast.Send node,
      ast.Node receiver,
      ast.NodeList arguments,
      Selector selector,
      _) {
    return irBuilder.buildDynamicInvocation(
        translateReceiver(receiver), selector,
        translateDynamicArguments(arguments, selector.callStructure));
  }

  ir.Primitive handleLocalInvoke(
      ast.Send node,
      LocalElement element,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return irBuilder.buildLocalVariableInvocation(element, callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitLocalFunctionInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return irBuilder.buildLocalFunctionInvocation(function, callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive handleStaticFieldInvoke(
      ast.Send node,
      FieldElement field,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Primitive target = irBuilder.buildStaticFieldGet(field);
    return irBuilder.buildCallInvocation(target,
        callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive handleStaticFunctionInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    // TODO(karlklose): support foreign functions.
    if (function.isForeign(compiler.backend)) {
      return giveup(node, 'handleStaticFunctionInvoke: foreign: $function');
    }
    return irBuilder.buildStaticFunctionInvocation(function, callStructure,
        translateStaticArguments(arguments, function, callStructure),
        sourceInformation: sourceInformationBuilder.buildCall(node));
  }

  @override
  ir.Primitive handleStaticFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    return buildStaticNoSuchMethod(
        elements.getSelector(node),
        arguments.nodes.mapToList(visit));
  }

  @override
  ir.Primitive handleStaticGetterInvoke(
      ast.Send node,
      FunctionElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    if (getter.isForeign(compiler.backend)) {
      return giveup(node, 'handleStaticGetterInvoke: foreign: $getter');
    }
    ir.Primitive target = irBuilder.buildStaticGetterGet(getter);
    return irBuilder.buildCallInvocation(target,
        callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitSuperFieldInvoke(
      ast.Send node,
      FieldElement field,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Primitive target = irBuilder.buildSuperFieldGet(field);
    return irBuilder.buildCallInvocation(target,
        callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitSuperGetterInvoke(
      ast.Send node,
      FunctionElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Primitive target = irBuilder.buildSuperGetterGet(getter);
    return irBuilder.buildCallInvocation(target,
        callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitSuperMethodInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return irBuilder.buildSuperMethodInvocation(method, callStructure,
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitSuperMethodIncompatibleInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    return buildInstanceNoSuchMethod(
        elements.getSelector(node),
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive visitUnresolvedSuperInvoke(
      ast.Send node,
      Element element,
      ast.NodeList arguments,
      Selector selector, _) {
    return buildInstanceNoSuchMethod(
        elements.getSelector(node),
        translateDynamicArguments(arguments, selector.callStructure));
  }

  @override
  ir.Primitive visitThisInvoke(
      ast.Send node,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return translateCallInvoke(irBuilder.buildThis(), arguments, callStructure);
  }

  @override
  ir.Primitive visitTypeVariableTypeLiteralInvoke(
      ast.Send node,
      TypeVariableElement element,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return translateCallInvoke(
        translateTypeVariableTypeLiteral(element),
        arguments,
        callStructure);
  }

  @override
  ir.Primitive visitIndexSet(
       ast.SendSet node,
       ast.Node receiver,
       ast.Node index,
       ast.Node rhs,
       _) {
    return irBuilder.buildDynamicIndexSet(
        visit(receiver), visit(index), visit(rhs));
  }

  @override
  ir.Primitive visitSuperIndexSet(
      ast.SendSet node,
      FunctionElement function,
      ast.Node index,
      ast.Node rhs,
      _) {
    return irBuilder.buildSuperIndexSet(function, visit(index), visit(rhs));
  }

  @override
  ir.Primitive visitCompoundIndexSet(
      ast.SendSet node,
      ast.Node receiver,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    ir.Primitive target = visit(receiver);
    ir.Primitive indexValue = visit(index);
    return translateCompound(
        getValue: () {
          Selector selector = new Selector.index();
          List<ir.Primitive> arguments = <ir.Primitive>[indexValue];
          arguments =
              normalizeDynamicArguments(selector.callStructure, arguments);
          return irBuilder.buildDynamicInvocation(target, selector, arguments);
        },
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildDynamicIndexSet(target, indexValue, result);
        });
  }

  @override
  ir.Primitive visitSuperCompoundIndexSet(
      ast.SendSet node,
      FunctionElement getter,
      FunctionElement setter,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    ir.Primitive indexValue = visit(index);
    return translateCompound(
        getValue: () {
          return irBuilder.buildSuperIndex(getter, indexValue);
        },
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperIndexSet(setter, indexValue, result);
        });
  }

  ir.Primitive translatePrefixPostfix(
      {ir.Primitive getValue(),
       op.IncDecOperator operator,
       void setValue(ir.Primitive value),
       bool isPrefix}) {
    ir.Primitive value = getValue();
    Selector operatorSelector =
        new Selector.binaryOperator(operator.selectorName);
    List<ir.Primitive> arguments =
        <ir.Primitive>[irBuilder.buildIntegerConstant(1)];
    arguments = normalizeDynamicArguments(
        operatorSelector.callStructure, arguments);
    ir.Primitive result =
        irBuilder.buildDynamicInvocation(value, operatorSelector, arguments);
    setValue(result);
    return isPrefix ? result : value;
  }

  ir.Primitive translateCompound(
      {ir.Primitive getValue(),
       op.AssignmentOperator operator,
       ast.Node rhs,
       void setValue(ir.Primitive value)}) {
    ir.Primitive value = getValue();
    Selector operatorSelector =
        new Selector.binaryOperator(operator.selectorName);
    List<ir.Primitive> arguments = <ir.Primitive>[visit(rhs)];
    arguments = normalizeDynamicArguments(
        operatorSelector.callStructure, arguments);
    ir.Primitive result =
        irBuilder.buildDynamicInvocation(value, operatorSelector, arguments);
    setValue(result);
    return result;
  }

  @override
  ir.Primitive handleDynamicCompound(
      ast.Send node,
      ast.Node receiver,
      op.AssignmentOperator operator,
      ast.Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      _) {
    ir.Primitive target = translateReceiver(receiver);
    return translateCompound(
        getValue: () => irBuilder.buildDynamicGet(target, getterSelector),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildDynamicSet(target, setterSelector, result);
        });
  }

  @override
  ir.Primitive handleDynamicPostfixPrefix(
      ast.Send node,
      ast.Node receiver,
      op.IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      arg,
      {bool isPrefix}) {
    ir.Primitive target = translateReceiver(receiver);
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildDynamicGet(target, getterSelector),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildDynamicSet(target, setterSelector, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleDynamicSet(
      ast.SendSet node,
      ast.Node receiver,
      Selector selector,
      ast.Node rhs,
      _) {
    return irBuilder.buildDynamicSet(
        translateReceiver(receiver),
        selector,
        visit(rhs));
  }

  @override
  ir.Primitive handleLocalCompound(
      ast.Send node,
      LocalElement element,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildLocalVariableGet(element),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildLocalVariableSet(element, result);
        });
  }

  @override
  ir.Primitive handleLocalPostfixPrefix(
      ast.Send node,
      LocalElement element,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildLocalVariableGet(element),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildLocalVariableSet(element, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleLocalSet(
      ast.SendSet node,
      LocalElement element,
      ast.Node rhs,
      _) {
    return irBuilder.buildLocalVariableSet(element, visit(rhs));
  }

  @override
  ir.Primitive handleStaticFieldCompound(
      ast.Send node,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildStaticFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticFieldSet(field, result);
        });
  }

  @override
  ir.Primitive handleStaticFieldPostfixPrefix(
      ast.Send node,
      FieldElement field,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildStaticFieldGet(field),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticFieldSet(field, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleStaticFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    return irBuilder.buildStaticFieldSet(field, visit(rhs));
  }

  @override
  ir.Primitive visitSuperFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    return irBuilder.buildSuperFieldSet(field, visit(rhs));
  }

  @override
  ir.Primitive visitSuperSetterSet(
      ast.SendSet node,
      FunctionElement setter,
      ast.Node rhs,
      _) {
    return irBuilder.buildSuperSetterSet(setter, visit(rhs));
  }

  @override
  ir.Primitive handleStaticGetterSetterCompound(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildStaticGetterGet(getter),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticSetterSet(setter, result);
        });
  }

  @override
  ir.Primitive handleSuperFieldFieldPostfixPrefix(
      ast.Send node,
      FieldElement readField,
      FieldElement writtenField,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperFieldGet(readField),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(writtenField, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleSuperFieldSetterPostfixPrefix(
      ast.Send node,
      FieldElement field,
      FunctionElement setter,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperFieldGet(field),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleSuperGetterFieldPostfixPrefix(
      ast.Send node,
      FunctionElement getter,
      FieldElement field,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperGetterGet(getter),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(field, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleSuperGetterSetterPostfixPrefix(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperGetterGet(getter),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleSuperMethodSetterPostfixPrefix(
      ast.Send node,
      FunctionElement method,
      FunctionElement setter,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperMethodGet(method),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleStaticGetterSetterPostfixPrefix(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildStaticGetterGet(getter),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticSetterSet(setter, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleStaticMethodSetterCompound(
      ast.Send node,
      FunctionElement method,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildStaticFunctionGet(method),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticSetterSet(setter, result);
        });
  }

  @override
  ir.Primitive handleStaticMethodSetterPostfixPrefix(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildStaticFunctionGet(getter),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildStaticSetterSet(setter, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleDynamicIndexPostfixPrefix(
      ast.Send node,
      ast.Node receiver,
      ast.Node index,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    ir.Primitive target = visit(receiver);
    ir.Primitive indexValue = visit(index);
    return translatePrefixPostfix(
        getValue: () {
          Selector selector = new Selector.index();
          List<ir.Primitive> arguments = <ir.Primitive>[indexValue];
          arguments =
              normalizeDynamicArguments(selector.callStructure, arguments);
          return irBuilder.buildDynamicInvocation(target, selector, arguments);
        },
        operator: operator,
        setValue: (ir.Primitive result) {
          Selector selector = new Selector.indexSet();
          List<ir.Primitive> arguments = <ir.Primitive>[indexValue, result];
          arguments =
              normalizeDynamicArguments(selector.callStructure, arguments);
          irBuilder.buildDynamicInvocation(target, selector, arguments);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleSuperIndexPostfixPrefix(
      ast.Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      ast.Node index,
      op.IncDecOperator operator,
      arg,
      {bool isPrefix}) {
    ir.Primitive indexValue = visit(index);
    return translatePrefixPostfix(
        getValue: () {
          return irBuilder.buildSuperIndex(indexFunction, indexValue);
        },
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperIndexSet(indexSetFunction, indexValue, result);
        },
        isPrefix: isPrefix);
  }

  @override
  ir.Primitive handleStaticSetterSet(
      ast.SendSet node,
      FunctionElement setter,
      ast.Node rhs,
      _) {
    return irBuilder.buildStaticSetterSet(setter, visit(rhs));
  }

  @override
  ir.Primitive visitSuperFieldCompound(
      ast.Send node,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildSuperFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(field, result);
        });
  }

  @override
  ir.Primitive visitSuperFieldFieldPostfix(
      ast.Send node,
      FieldElement readField,
      FieldElement writtenField,
      op.IncDecOperator operator,
      _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperFieldGet(readField),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(writtenField, result);
        },
        isPrefix: false);
  }

  @override
  ir.Primitive visitSuperFieldFieldPrefix(
      ast.Send node,
      FieldElement readField,
      FieldElement writtenField,
      op.IncDecOperator operator,
      _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildSuperFieldGet(readField),
        operator: operator,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(writtenField, result);
        },
        isPrefix: true);
  }

  @override
  ir.Primitive visitSuperFieldSetterCompound(
      ast.Send node,
      FieldElement field,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildSuperFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        });
  }

  @override
  ir.Primitive visitSuperGetterFieldCompound(
      ast.Send node,
      FunctionElement getter,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildSuperGetterGet(getter),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperFieldSet(field, result);
        });
  }

  @override
  ir.Primitive visitSuperGetterSetterCompound(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildSuperGetterGet(getter),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        });
  }

  @override
  ir.Primitive visitSuperMethodSetterCompound(
      ast.Send node,
      FunctionElement method,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return translateCompound(
        getValue: () => irBuilder.buildSuperMethodGet(method),
        operator: operator,
        rhs: rhs,
        setValue: (ir.Primitive result) {
          irBuilder.buildSuperSetterSet(setter, result);
        });
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
    return irBuilder.buildConstant(getConstantForNode(node));
  }

  ir.Primitive visitThrow(ast.Throw node) {
    assert(irBuilder.isOpen);
    // This function is not called for throw expressions occurring as
    // statements.
    return irBuilder.buildNonTailThrow(visit(node.expression));
  }

  ir.Primitive buildStaticNoSuchMethod(
      Selector selector,
      List<ir.Primitive> arguments);

  ir.Primitive buildInstanceNoSuchMethod(
      Selector selector,
      List<ir.Primitive> arguments);

  ir.Primitive buildRuntimeError(String message);

  ir.Primitive buildAbstractClassInstantiationError(ClassElement element);

  @override
  ir.Primitive errorInvalidAssert(
      ast.Send node,
      ast.NodeList arguments, _) {
    if (compiler.enableUserAssertions) {
      return giveup(node, 'Assert');
    } else {
      return irBuilder.buildNullConstant();
    }
  }

  @override
  ir.Primitive errorUnresolvedCompound(
      ast.Send node,
      Element element,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    // TODO(asgerf): What is unresolved? The getter and/or the setter?
    //               If it was the setter, we must evaluate the right-hand side.
    return buildStaticNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive visitUnresolvedClassConstructorInvoke(
      ast.NewExpression node,
      Element element,
      DartType type,
      ast.NodeList arguments,
      Selector selector, _) {
    // If the class is missing it's a runtime error.
    return buildRuntimeError("Unresolved class: '${element.name}'");
  }

  @override
  ir.Primitive visitUnresolvedConstructorInvoke(
      ast.NewExpression node,
      Element constructor,
      DartType type,
      ast.NodeList arguments,
      Selector selector, _) {
    // If the class is there but the constructor is missing, it's an NSM error.
    return buildStaticNoSuchMethod(selector,
        translateDynamicArguments(arguments, selector.callStructure));
  }

  @override
  ir.Primitive errorNonConstantConstructorInvoke(
      ast.NewExpression node,
      Element element,
      InterfaceType type,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    assert(compiler.compilationFailed);
    return irBuilder.buildNullConstant();
  }

  @override
  ir.Primitive visitUnresolvedGet(
      ast.Send node,
      Element element, _) {
    return buildStaticNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive visitUnresolvedInvoke(
      ast.Send node,
      Element element,
      ast.NodeList arguments,
      Selector selector, _) {
    return buildStaticNoSuchMethod(elements.getSelector(node),
        arguments.nodes.mapToList(visit));
  }

  @override
  ir.Primitive errorUnresolvedPostfix(
      ast.Send node,
      Element element,
      op.IncDecOperator operator, _) {
    // TODO(asgerf): Which ones are missing? The getter and/or the setter?
    return buildStaticNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive errorUnresolvedPrefix(
      ast.Send node,
      Element element,
      op.IncDecOperator operator, _) {
    // TODO(asgerf): Which ones are missing? The getter and/or the setter?
    return buildStaticNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive visitUnresolvedRedirectingFactoryConstructorInvoke(
       ast.NewExpression node,
       ConstructorElement constructor,
       InterfaceType type,
       ast.NodeList arguments,
       CallStructure callStructure, _) {
    String nameString = Elements.reconstructConstructorName(constructor);
    Name name = new Name(nameString, constructor.library);
    return buildStaticNoSuchMethod(
        new Selector(SelectorKind.CALL, name, callStructure),
        translateDynamicArguments(arguments, callStructure));
  }

  @override
  ir.Primitive errorUnresolvedSet(
      ast.Send node,
      Element element,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(elements.getSelector(node), [visit(rhs)]);
  }

  @override
  ir.Primitive errorUnresolvedSuperCompoundIndexSet(
      ast.SendSet node,
      Element element,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    // Assume the index getter is missing.
    Selector selector = useSelectorTypeOfNode(new Selector.index(), node);
    return buildInstanceNoSuchMethod(selector, [visit(index)]);
  }

  @override
  ir.Primitive visitUnresolvedSuperIndex(
      ast.Send node,
      Element function,
      ast.Node index, _) {
    // Assume the index getter is missing.
    Selector selector = useSelectorTypeOfNode(new Selector.index(), node);
    return buildInstanceNoSuchMethod(selector, [visit(index)]);
  }

  @override
  ir.Primitive errorUnresolvedSuperIndexPostfix(
      ast.Send node,
      Element function,
      ast.Node index,
      op.IncDecOperator operator, _) {
    // Assume the index getter is missing.
    Selector selector = useSelectorTypeOfNode(new Selector.index(), node);
    return buildInstanceNoSuchMethod(selector, [visit(index)]);
  }

  @override
  ir.Primitive errorUnresolvedSuperIndexPrefix(
      ast.Send node,
      Element function,
      ast.Node index,
      op.IncDecOperator operator, _) {
    // Assume the index getter is missing.
    Selector selector = useSelectorTypeOfNode(new Selector.index(), node);
    return buildInstanceNoSuchMethod(selector, [visit(index)]);
  }

  @override
  ir.Primitive errorUnresolvedSuperIndexSet(
      ast.SendSet node,
      Element element,
      ast.Node index,
      ast.Node rhs, _) {
    Selector selector = useSelectorTypeOfNode(new Selector.index(), node);
    return buildInstanceNoSuchMethod(
        selector,
        [visit(index), visit(rhs)]);
  }

  @override
  ir.Primitive visitUnresolvedSuperBinary(
      ast.Send node,
      Element element,
      op.BinaryOperator operator,
      ast.Node argument, _) {
    return buildInstanceNoSuchMethod(
        elements.getSelector(node),
        [visit(argument)]);
  }

  @override
  ir.Primitive visitUnresolvedSuperUnary(
      ast.Send node,
      op.UnaryOperator operator,
      Element element, _) {
    return buildInstanceNoSuchMethod(elements.getSelector(node), []);
  }

  @override
  ir.Primitive errorUndefinedBinaryExpression(
      ast.Send node,
      ast.Node left,
      ast.Operator operator,
      ast.Node right, _) {
    assert(compiler.compilationFailed);
    return irBuilder.buildNullConstant();
  }

  @override
  ir.Primitive errorUndefinedUnaryExpression(
      ast.Send node,
      ast.Operator operator,
      ast.Node expression, _) {
    assert(compiler.compilationFailed);
    return irBuilder.buildNullConstant();
  }

  @override
  ir.Primitive errorTopLevelFunctionSet(
      ast.Send node,
      MethodElement function,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(function.name, function.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorTopLevelSetterGet(
      ast.Send node,
      FunctionElement setter, _) {
    return buildStaticNoSuchMethod(
        new Selector.getter(setter.name, setter.library), []);
  }

  @override
  ir.Primitive errorTopLevelGetterSet(
      ast.SendSet node,
      FunctionElement getter,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(getter.name, getter.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorTopLevelSetterInvoke(
      ast.Send node,
      FunctionElement setter,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    return buildStaticNoSuchMethod(
        new Selector.getter(setter.name, setter.library), []);
  }

  @override
  ir.Primitive errorClassTypeLiteralSet(
      ast.SendSet node,
      TypeConstantExpression constant,
      ast.Node rhs, _) {
    InterfaceType type = constant.type;
    ClassElement element = type.element;
    return buildStaticNoSuchMethod(
        new Selector.setter(element.name, element.library), [visit(rhs)]);
  }

  @override
  ir.Primitive errorTypedefTypeLiteralSet(
      ast.SendSet node,
      TypeConstantExpression constant,
      ast.Node rhs, _) {
    TypedefType type = constant.type;
    TypedefElement element = type.element;
    return buildStaticNoSuchMethod(
        new Selector.setter(element.name, element.library), [visit(rhs)]);
  }

  @override
  ir.Primitive errorTypeVariableTypeLiteralSet(
      ast.SendSet node,
      TypeVariableElement element,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(element.name, element.library), [visit(rhs)]);
  }

  @override
  ir.Primitive errorDynamicTypeLiteralSet(
      ast.SendSet node,
      ConstantExpression constant,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter('dynamic', null), [visit(rhs)]);
  }

  @override
  ir.Primitive visitAbstractClassConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    return buildAbstractClassInstantiationError(element.enclosingClass);
  }

  @override
  ir.Primitive errorClassTypeLiteralCompound(
      ast.Send node,
      ConstantExpression constant,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        rhs: rhs,
        setValue: (value) {}); // The binary operator will throw before this.
  }

  @override
  ir.Primitive errorClassTypeLiteralPostfix(
      ast.Send node,
      ConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
      getValue: () => irBuilder.buildConstant(constant),
      operator: operator,
      setValue: (value) {}, // The binary operator will throw before this.
      isPrefix: false);
  }

  @override
  ir.Primitive errorClassTypeLiteralPrefix(
      ast.Send node,
      ConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
      getValue: () => irBuilder.buildConstant(constant),
      operator: operator,
      setValue: (value) {}, // The binary operator will throw before this.
      isPrefix: true);
  }

  @override
  ir.Primitive errorDynamicTypeLiteralCompound(
      ast.Send node,
      ConstantExpression constant,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        rhs: rhs,
        setValue: (value) {}); // The binary operator will throw before this.
  }

  @override
  ir.Primitive errorDynamicTypeLiteralPostfix(
      ast.Send node,
      ConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: false);
  }

  @override
  ir.Primitive errorDynamicTypeLiteralPrefix(
      ast.Send node,
      ConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: true);
  }

  @override
  ir.Primitive errorFinalLocalVariableCompound(
      ast.Send node,
      LocalVariableElement variable,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    Selector selector = new Selector.setter(variable.name, null);
    return translateCompound(
        getValue: () => irBuilder.buildLocalVariableGet(variable),
        operator: operator,
        rhs: rhs,
        setValue: (value) => buildStaticNoSuchMethod(selector, [value]));
  }

  @override
  ir.Primitive errorFinalLocalVariableSet(
      ast.SendSet node,
      LocalVariableElement variable,
      ast.Node rhs, _) {
    Selector selector = new Selector.setter(variable.name, null);
    return buildStaticNoSuchMethod(selector, [visit(rhs)]);
  }

  @override
  ir.Primitive errorFinalParameterCompound(
      ast.Send node,
      ParameterElement parameter,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    Selector selector = new Selector.setter(parameter.name, null);
    return translateCompound(
        getValue: () => irBuilder.buildLocalVariableGet(parameter),
        operator: operator,
        rhs: rhs,
        setValue: (value) => buildStaticNoSuchMethod(selector, [value]));
  }

  @override
  ir.Primitive errorFinalParameterSet(
      ast.SendSet node,
      ParameterElement parameter,
      ast.Node rhs, _) {
    Selector selector = new Selector.setter(parameter.name, null);
    return buildStaticNoSuchMethod(selector, [visit(rhs)]);
  }

  @override
  ir.Primitive errorFinalStaticFieldCompound(
      ast.Send node,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildStaticFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (value) => buildStaticNoSuchMethod(
            new Selector.setter(field.name, field.library), [value]));
  }

  @override
  ir.Primitive errorFinalStaticFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs, _) {
    // TODO(asgerf): Include class name somehow?
    return buildStaticNoSuchMethod(
        new Selector.setter(field.name, field.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorFinalSuperFieldCompound(
      ast.Send node,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    Selector selector = useSelectorTypeOfNode(
        new Selector.setter(field.name, field.library),
        node);
    return translateCompound(
        getValue: () => irBuilder.buildSuperFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (value) => buildInstanceNoSuchMethod(selector, [value]));
  }

  @override
  ir.Primitive errorFinalSuperFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs, _) {
    Selector selector = useSelectorTypeOfNode(
        new Selector.setter(field.name, field.library),
        node);
    return buildInstanceNoSuchMethod(selector, [visit(rhs)]);
  }

  @override
  ir.Primitive errorFinalTopLevelFieldCompound(
      ast.Send node,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildStaticFieldGet(field),
        operator: operator,
        rhs: rhs,
        setValue: (value) => buildStaticNoSuchMethod(
            new Selector.setter(field.name, field.library), [value]));
  }

  @override
  ir.Primitive errorFinalTopLevelFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(field.name, field.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorLocalFunctionCompound(
      ast.Send node,
      LocalFunctionElement function,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildLocalFunctionGet(function),
        operator: operator,
        rhs: rhs,
        setValue: (value) {}); // Binary operator will throw before this.
  }

  @override
  ir.Primitive errorLocalFunctionPostfix(
      ast.Send node,
      LocalFunctionElement function,
      op.IncDecOperator operator,
      _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildLocalFunctionGet(function),
        operator: operator,
        setValue: (value) {}, // Binary operator will throw before this.
        isPrefix: false);
  }

  @override
  ir.Primitive errorLocalFunctionPrefix(
      ast.Send node,
      LocalFunctionElement function,
      op.IncDecOperator operator,
      _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildLocalFunctionGet(function),
        operator: operator,
        setValue: (value) {}, // Binary operator will throw before this.
        isPrefix: true);
  }

  @override
  ir.Primitive errorLocalFunctionSet(
      ast.SendSet node,
      LocalFunctionElement function,
      ast.Node rhs, _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(function.name, null),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorStaticFunctionSet(
      ast.Send node,
      MethodElement function,
      ast.Node rhs,
      _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(function.name, function.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorStaticGetterSet(
      ast.SendSet node,
      FunctionElement getter,
      ast.Node rhs,
      _) {
    return buildStaticNoSuchMethod(
        new Selector.setter(getter.name, getter.library),
        [visit(rhs)]);
  }

  @override
  ir.Primitive errorStaticSetterGet(
      ast.Send node,
      FunctionElement setter,
      _) {
    return buildStaticNoSuchMethod(
        new Selector.getter(setter.name, setter.library),
        []);
  }

  @override
  ir.Primitive errorStaticSetterInvoke(
      ast.Send node,
      FunctionElement setter,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    // Translate as a method call.
    List<ir.Primitive> args = arguments.nodes.mapToList(visit);
    Name name = new Name(setter.name, setter.library);
    return buildStaticNoSuchMethod(
        new Selector(SelectorKind.CALL, name, callStructure),
        args);
  }

  @override
  ir.Primitive errorSuperGetterSet(
      ast.SendSet node,
      FunctionElement getter,
      ast.Node rhs,
      _) {
    Selector selector = useSelectorTypeOfNode(
        new Selector.setter(getter.name, getter.library),
        node);
    return buildInstanceNoSuchMethod(selector, [visit(rhs)]);
  }

  @override
  ir.Primitive errorSuperMethodSet(
      ast.Send node,
      MethodElement method,
      ast.Node rhs,
      _) {
    Selector selector = useSelectorTypeOfNode(
        new Selector.setter(method.name, method.library),
        node);
    return buildInstanceNoSuchMethod(selector, [visit(rhs)]);
  }

  @override
  ir.Primitive errorSuperSetterGet(
      ast.Send node,
      FunctionElement setter, _) {
    Selector selector = useSelectorTypeOfNode(
        new Selector.setter(setter.name, setter.library),
        node);
    return buildInstanceNoSuchMethod(selector, []);
  }

  @override
  ir.Primitive errorSuperSetterInvoke(
      ast.Send node,
      FunctionElement setter,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    List<ir.Primitive> args =
        translateDynamicArguments(arguments, callStructure);
    Name name = new Name(setter.name, setter.library);
    Selector selector = useSelectorTypeOfNode(
        new Selector(SelectorKind.CALL, name, callStructure),
        node);
    return buildInstanceNoSuchMethod(selector, args);
  }

  @override
  ir.Primitive errorTypeVariableTypeLiteralCompound(
      ast.Send node,
      TypeVariableElement element,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildReifyTypeVariable(element.type),
        operator: operator,
        rhs: rhs,
        setValue: (value) {}); // The binary operator will throw before this.
  }

  @override
  ir.Primitive errorTypeVariableTypeLiteralPostfix(
      ast.Send node,
      TypeVariableElement element,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildReifyTypeVariable(element.type),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: false);
  }

  @override
  ir.Primitive errorTypeVariableTypeLiteralPrefix(
      ast.Send node,
      TypeVariableElement element,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildReifyTypeVariable(element.type),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: true);
  }

  @override
  ir.Primitive errorTypedefTypeLiteralCompound(
      ast.Send node,
      ConstantExpression constant,
      op.AssignmentOperator operator,
      ast.Node rhs, _) {
    return translateCompound(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        rhs: rhs,
        setValue: (value) {}); // The binary operator will throw before this.
  }

  @override
  ir.Primitive errorTypedefTypeLiteralPostfix(
      ast.Send node,
      ConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: false);
  }

  @override
  ir.Primitive errorTypedefTypeLiteralPrefix(
      ast.Send node,
      TypeConstantExpression constant,
      op.IncDecOperator operator, _) {
    return translatePrefixPostfix(
        getValue: () => irBuilder.buildConstant(constant),
        operator: operator,
        setValue: (value) {}, // The binary operator will throw before this.
        isPrefix: true);
  }

  ir.RootNode nullIfGiveup(ir.RootNode action()) {
    try {
      return action();
    } catch(e) {
      if (e == ABORT_IRNODE_BUILDER) {
        return null;
      }
      rethrow;
    }
  }

  void internalError(ast.Node node, String message) {
    giveup(node, message);
  }

  @override
  visitNode(ast.Node node) {
    internalError(node, "Unhandled node");
  }

  dynamic giveup(ast.Node node, [String reason]) {
    bailoutMessage = '($node): $reason';
    throw ABORT_IRNODE_BUILDER;
  }
}

final String ABORT_IRNODE_BUILDER = "IrNode builder aborted";

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

  String bailoutMessage = null;

  giveup(ast.Node node, [String reason]) {
    bailoutMessage = '($node): $reason';
    throw ABORT_IRNODE_BUILDER;
  }

  void markAsCaptured(Local local) {
    capturedVariables.add(local);
  }

  analyze(ast.Node node) {
    visit(node);
    // Variables that are captured by a closure are boxed for their entire
    // lifetime, so they never need to be boxed on entry to a try block.
    // They are not filtered out before this because we cannot identify all
    // of them in the same pass (they may be captured by a closure after the
    // try statement).
    for (TryStatementInfo info in tryStatements.values) {
      info.boxedOnEntry.removeAll(capturedVariables);
    }
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

  DartIrBuilder makeIRBuilder(ExecutableElement element,
                              Set<Local> capturedVariables) {
    return new DartIrBuilder(compiler.backend.constantSystem,
                             element,
                             capturedVariables);
  }

  DartCapturedVariables _analyzeCapturedVariables(ExecutableElement element,
                                                  ast.Node node) {
    DartCapturedVariables variables = new DartCapturedVariables(elements);
    if (!element.isSynthesized) {
      try {
        variables.analyze(node);
      } catch (e) {
        bailoutMessage = variables.bailoutMessage;
        rethrow;
      }
    }
    return variables;
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

  ClosureClassMap get closureClassMap => null;
  ClosureScope getClosureScopeForNode(ast.Node node) => null;
  ClosureEnvironment getClosureEnvironment() => null;

  ir.RootNode buildExecutable(ExecutableElement element) {
    return nullIfGiveup(() {
      ir.RootNode root;
      if (element is FieldElement) {
        root = buildField(element);
      } else if (element is FunctionElement || element is ConstructorElement) {
        root = buildFunction(element);
      } else {
        compiler.internalError(element, "Unexpected element type $element");
      }
      new CleanupPass().visit(root);
      return root;
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

    DartCapturedVariables variables =
        _analyzeCapturedVariables(element, fieldDefinition);
    tryStatements = variables.tryStatements;
    IrBuilder builder = makeIRBuilder(element, variables.capturedVariables);

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

  ir.RootNode buildFunction(FunctionElement element) {
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

    DartCapturedVariables variables =
        _analyzeCapturedVariables(element, node);
    tryStatements = variables.tryStatements;
    IrBuilder builder = makeIRBuilder(element, variables.capturedVariables);

    return withBuilder(builder, () => _makeFunctionBody(element, node));
  }

  List<ir.Primitive> normalizeStaticArguments(
      CallStructure callStructure,
      FunctionElement target,
      List<ir.Primitive> arguments) {
    return arguments;
  }

  List<ir.Primitive> normalizeDynamicArguments(
      CallStructure callStructure,
      List<ir.Primitive> arguments) {
    return arguments;
  }

  @override
  ir.Primitive handleConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement constructor,
      DartType type,
      ast.NodeList arguments,
      CallStructure callStructure, _) {
    List<ir.Primitive> arguments =
        node.send.arguments.mapToList(visit, growable:false);
    return irBuilder.buildConstructorInvocation(
        constructor,
        callStructure,
        type,
        arguments);
  }

  @override
  ir.Primitive buildStaticNoSuchMethod(Selector selector,
                                       List<ir.Primitive> arguments) {
    return giveup(null, 'Static noSuchMethod');
  }

  @override
  ir.Primitive buildInstanceNoSuchMethod(Selector selector,
                                         List<ir.Primitive> arguments) {
    return giveup(null, 'Instance noSuchMethod');
  }

  @override
  ir.Primitive buildRuntimeError(String message) {
    return giveup(null, 'Build runtime error: $message');
  }

  @override
  ir.Primitive buildAbstractClassInstantiationError(ClassElement element) {
    return giveup(null, 'Abstract class instantiation: ${element.name}');
  }
}

/// The [IrBuilder]s view on the information about the program that has been
/// computed in resolution and and type interence.
class GlobalProgramInformation {
  final Compiler _compiler;
  JavaScriptBackend get _backend => _compiler.backend;

  GlobalProgramInformation(this._compiler);

  /// Returns [true], if the analysis could not determine that the type
  /// arguments for the class [cls] are never used in the program.
  bool requiresRuntimeTypesFor(ClassElement cls) {
    return cls.typeVariables.isNotEmpty && _backend.classNeedsRti(cls);
  }
}

/// IR builder specific to the JavaScript backend, coupled to the [JsIrBuilder].
class JsIrBuilderVisitor extends IrBuilderVisitor {
  /// Promote the type of [irBuilder] to [JsIrBuilder].
  JsIrBuilder get irBuilder => super.irBuilder;

  JavaScriptBackend get backend => compiler.backend;

  /// Result of closure conversion for the current body of code.
  ///
  /// Will be initialized upon entering the body of a function.
  /// It is computed by the [ClosureTranslator].
  ClosureClassMap closureClassMap;

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
    if (closureClassMap.closureElement == null) return null;
    return new ClosureEnvironment(
        closureClassMap.closureElement,
        closureClassMap.thisLocal,
        mapValues(closureClassMap.freeVariableMap, getLocation));
  }

  /// If [node] has declarations for variables that should be boxed,
  /// returns a [ClosureScope] naming a box to create, and enumerating the
  /// variables that should be stored in the box.
  ///
  /// Also see [ClosureScope].
  ClosureScope getClosureScopeForNode(ast.Node node) {
    closurelib.ClosureScope scope = closureClassMap.capturingScopes[node];
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

  ir.RootNode buildExecutable(ExecutableElement element) {
    return nullIfGiveup(() {
      ir.RootNode root;
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
          root = buildConstructor(element);
          break;

        case ElementKind.GENERATIVE_CONSTRUCTOR_BODY:
          root = buildConstructorBody(element);
          break;

        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          root = buildFunction(element);
          break;

        default:
          compiler.internalError(element, "Unexpected element type $element");
      }
      new CleanupPass().visit(root);
      return root;
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

  JsIrBuilder getBuilderFor(Element element) {
    return new JsIrBuilder(
        new GlobalProgramInformation(compiler),
        compiler.backend.constantSystem,
        element);
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

    JsIrBuilder builder = getBuilderFor(constructor);

    final bool requiresTypeInformation =
        builder.program.requiresRuntimeTypesFor(classElement);

    return withBuilder(builder, () {
      // Setup parameters and create a box if anything is captured.
      List<Local> parameters = <Local>[];
      constructor.functionSignature.orderedForEachParameter(
          (ParameterElement p) => parameters.add(p));

      int firstTypeArgumentParameterIndex;

      // If instances of the class may need runtime type information, we add a
      // synthetic parameter for each type parameter.
      if (requiresTypeInformation) {
        firstTypeArgumentParameterIndex = parameters.length;
        classElement.typeVariables.forEach((TypeVariableType variable) {
          parameters.add(
              new TypeInformationParameter(variable.element, constructor));
        });
      }

      // Create IR parameters and setup the environment.
      List<ir.Parameter> irParameters = builder.buildFunctionHeader(parameters,
          closureScope: getClosureScopeForFunction(constructor));

      // Create a list of the values of all type argument parameters, if any.
      List<ir.Primitive> typeInformation;
      if (requiresTypeInformation) {
        typeInformation = irParameters.sublist(firstTypeArgumentParameterIndex);
      } else {
        typeInformation = const <ir.Primitive>[];
      }

      // -- Step 1: evaluate field initializers ---
      // Evaluate field initializers in constructor and super constructors.
      irBuilder.enterInitializers();
      List<ConstructorElement> constructorList = <ConstructorElement>[];
      evaluateConstructorFieldInitializers(constructor, constructorList);
      irBuilder.leaveInitializers();

      // All parameters in all constructors are now bound in the environment.
      // BoxLocals for captured parameters are also in the environment.
      // The initial value of all fields are now bound in [fieldValues].

      // --- Step 2: create the object ---
      // Get the initial field values in the canonical order.
      List<ir.Primitive> instanceArguments = <ir.Primitive>[];
      classElement.forEachInstanceField((ClassElement c, FieldElement field) {
        ir.Primitive value = fieldValues[field];
        if (value != null) {
          instanceArguments.add(value);
        } else {
          assert(Elements.isNativeOrExtendsNative(c));
          // Native fields are initialized elsewhere.
        }
      }, includeSuperAndInjectedMembers: true);
      ir.Primitive instance = new ir.CreateInstance(
          classElement,
          instanceArguments,
          typeInformation);
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
          fieldValues[field] = irBuilder.buildNullConstant();
        }
      }
    });
    // Evaluate initializing parameters, e.g. `Foo(this.x)`.
    constructor.functionSignature.orderedForEachParameter(
        (ParameterElement parameter) {
      if (parameter.isInitializingFormal) {
        InitializingFormalElement fieldParameter = parameter;
        fieldValues[fieldParameter.fieldElement] =
            irBuilder.buildLocalVariableGet(parameter);
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
    irBuilder.enterScope(scope);

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
          value = irBuilder.buildNullConstant();
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

  DartCapturedVariables _analyzeCapturedVariables(ast.Node node) {
    DartCapturedVariables variables = new DartCapturedVariables(elements);
    try {
      variables.analyze(node);
    } catch (e) {
      bailoutMessage = variables.bailoutMessage;
      rethrow;
    }
    return variables;
  }

  /// Builds the IR for the body of a constructor.
  ///
  /// This function is invoked from one or more "factory" constructors built by
  /// [buildConstructor].
  ir.FunctionDefinition buildConstructorBody(ConstructorBodyElement body) {
    ConstructorElement constructor = body.constructor;
    ast.FunctionExpression node = constructor.node;
    closureClassMap =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            constructor,
            node,
            elements);

    // We compute variables boxed in mutable variables on entry to each try
    // block, not including variables captured by a closure (which are boxed
    // in the heap).  This duplicates some of the work of closure conversion
    // without directly using the results.  This duplication is wasteful and
    // error-prone.
    // TODO(kmillikin): We should combine closure conversion and try/catch
    // variable analysis in some way.
    DartCapturedVariables variables = _analyzeCapturedVariables(node);
    tryStatements = variables.tryStatements;
    JsIrBuilder builder = getBuilderFor(body);

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

    closureClassMap =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            element,
            node,
            elements);
    DartCapturedVariables variables = _analyzeCapturedVariables(node);
    tryStatements = variables.tryStatements;
    IrBuilder builder = getBuilderFor(element);
    return withBuilder(builder, () => _makeFunctionBody(element, node));
  }

  /// Creates a primitive for the default value of [parameter].
  ir.Primitive translateDefaultValue(ParameterElement parameter) {
    if (parameter.initializer == null) {
      return irBuilder.buildNullConstant();
    } else {
      return inlineConstant(parameter.executableContext, parameter.initializer);
    }
  }

  /// Inserts default arguments and normalizes order of named arguments.
  List<ir.Primitive> normalizeStaticArguments(
      CallStructure callStructure,
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
        int nameIndex = callStructure.namedArguments.indexOf(element.name);
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
      CallStructure callStructure,
      List<ir.Primitive> arguments) {
    assert(arguments.length == callStructure.argumentCount);
    // Optimization: don't copy the argument list for trivial cases.
    if (callStructure.namedArguments.isEmpty) return arguments;
    List<ir.Primitive> result = <ir.Primitive>[];
    for (int i=0; i < callStructure.positionalArgumentCount; i++) {
      result.add(arguments[i]);
    }
    for (String argName in callStructure.getOrderedNamedArguments()) {
      int nameIndex = callStructure.namedArguments.indexOf(argName);
      int translatedIndex = callStructure.positionalArgumentCount + nameIndex;
      result.add(arguments[translatedIndex]);
    }
    return result;
  }
  @override
  ir.Primitive handleConstructorInvoke(
      ast.NewExpression node,
      ConstructorElement constructor,
      DartType type,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    List<ir.Primitive> arguments =
        node.send.arguments.mapToList(visit, growable:false);
    arguments = normalizeStaticArguments(
        callStructure, constructor, arguments);
    return irBuilder.buildConstructorInvocation(
        constructor.effectiveTarget,
        callStructure,
        constructor.computeEffectiveTargetType(type),
        arguments);
  }

  @override
  ir.Primitive buildStaticNoSuchMethod(Selector selector,
                                       List<ir.Primitive> arguments) {
    Element thrower = backend.getThrowNoSuchMethod();
    ir.Primitive receiver = irBuilder.buildStringConstant('');
    ir.Primitive name = irBuilder.buildStringConstant(selector.name);
    ir.Primitive argumentList = irBuilder.buildListLiteral(null, arguments);
    ir.Primitive expectedArgumentNames = irBuilder.buildNullConstant();
    return irBuilder.buildStaticFunctionInvocation(
        thrower,
        new CallStructure.unnamed(4),
        [receiver, name, argumentList, expectedArgumentNames]);
  }

  @override
  ir.Primitive buildInstanceNoSuchMethod(Selector selector,
                                         List<ir.Primitive> arguments) {
    return irBuilder.buildDynamicInvocation(
        irBuilder.buildThis(),
        useSelectorType(compiler.noSuchMethodSelector, selector),
        [irBuilder.buildInvocationMirror(selector, arguments)]);
  }

  @override
  ir.Primitive buildRuntimeError(String message) {
    return irBuilder.buildStaticFunctionInvocation(
        backend.getThrowRuntimeError(),
        new CallStructure.unnamed(1),
        [irBuilder.buildStringConstant(message)]);
  }

  @override
  ir.Primitive buildAbstractClassInstantiationError(ClassElement element) {
    return irBuilder.buildStaticFunctionInvocation(
        backend.getThrowAbstractClassInstantiationError(),
        new CallStructure.unnamed(1),
        [irBuilder.buildStringConstant(element.name)]);
  }
}

/// Perform simple post-processing on the initial CPS-translated root term.
///
/// This pass performs backend-independent post-processing on the translated
/// term.  It is implemented separately from the optimization passes because
/// it is required for correctness of the implementation.
///
/// It performs the following translations:
///   - Replace [ir.LetPrim] binding a [ir.NonTailThrow] with a [ir.Throw]
///     expression.
class CleanupPass extends ir.RecursiveVisitor {
  RemovalVisitor _remover = new RemovalVisitor();

  ir.Expression replacementFor(ir.Expression expression) {
    if (expression != null && expression is ir.LetPrim) {
      ir.Primitive primitive = expression.primitive;
      if (primitive is ir.NonTailThrow) {
        _remover.visit(expression);
        return new ir.Throw(primitive.value.definition);
      }
    }
    return expression;
  }

  processLetPrim(ir.LetPrim node) {
    node.body = replacementFor(node.body);
  }

  processLetCont(ir.LetCont node) {
    node.body = replacementFor(node.body);
  }

  processLetHandler(ir.LetHandler node) {
    node.body = replacementFor(node.body);
  }

  processLetMutable(ir.LetMutable node) {
    node.body = replacementFor(node.body);
  }

  processSetMutableVariable(ir.SetMutableVariable node) {
    node.body = replacementFor(node.body);
  }

  processDeclareFunction(ir.DeclareFunction node) {
    node.body = replacementFor(node.body);
  }

  processSetField(ir.SetField node) {
    node.body = replacementFor(node.body);
  }

  processContinuation(ir.Continuation node) {
    node.body = replacementFor(node.body);
  }

  processBody(ir.Body node) {
    node.body = replacementFor(node.body);
  }
}

/// Visit a just-deleted subterm and unlink all [Reference]s in it.
class RemovalVisitor extends ir.RecursiveVisitor {
  processReference(ir.Reference reference) {
    reference.unlink();
  }
}
