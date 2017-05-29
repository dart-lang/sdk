// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/frontend/accessors.dart'
    show
        Accessor,
        IndexAccessor,
        NullAwarePropertyAccessor,
        PropertyAccessor,
        ReadOnlyAccessor,
        StaticAccessor,
        SuperIndexAccessor,
        SuperPropertyAccessor,
        ThisPropertyAccessor,
        VariableAccessor,
        buildIsNull,
        makeBinary,
        makeLet,
        makeOrReuseVariable;
import 'package:kernel/transformations/flags.dart';

import '../common.dart';
import '../common/names.dart';
import '../constants/expressions.dart'
    show
        BoolFromEnvironmentConstantExpression,
        ConstantExpression,
        ConstructedConstantExpression,
        IntFromEnvironmentConstantExpression,
        StringFromEnvironmentConstantExpression,
        TypeConstantExpression;
import '../diagnostics/spannable.dart' show Spannable;
import '../elements/elements.dart'
    show
        AstElement,
        ClassElement,
        ConstructorElement,
        Element,
        FieldElement,
        FunctionElement,
        FunctionSignature,
        GetterElement,
        InitializingFormalElement,
        JumpTarget,
        LibraryElement,
        LocalElement,
        LocalFunctionElement,
        LocalVariableElement,
        MethodElement,
        ParameterElement,
        PrefixElement,
        TypeVariableElement;
import '../elements/entities.dart' show AsyncMarker;
import '../elements/names.dart' show Name;
import '../elements/operators.dart'
    show AssignmentOperator, BinaryOperator, IncDecOperator, UnaryOperator;
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../resolution/semantic_visitor.dart'
    show
        BaseImplementationOfCompoundsMixin,
        BaseImplementationOfLocalsMixin,
        BaseImplementationOfSetIfNullsMixin,
        BaseImplementationOfStaticsMixin,
        CompoundGetter,
        CompoundKind,
        CompoundRhs,
        CompoundSetter,
        SemanticDeclarationResolvedMixin,
        SemanticDeclarationVisitor,
        SemanticSendResolvedMixin,
        SemanticSendVisitor,
        SemanticVisitor;
import '../resolution/send_resolver.dart' show DeclarationResolverMixin;
import '../resolution/send_structure.dart'
    show
        InitializerStructure,
        InitializersStructure,
        ParameterStructure,
        VariableStructure;
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart'
    show
        Assert,
        AsyncForIn,
        Await,
        Block,
        BreakStatement,
        Cascade,
        CascadeReceiver,
        CaseMatch,
        CatchBlock,
        Conditional,
        ConditionalUri,
        ContinueStatement,
        DoWhile,
        DottedName,
        EmptyStatement,
        Enum,
        Expression,
        ExpressionStatement,
        For,
        ForIn,
        FunctionDeclaration,
        FunctionExpression,
        FunctionTypeAnnotation,
        Identifier,
        If,
        Label,
        LabeledStatement,
        LiteralBool,
        LiteralDouble,
        LiteralInt,
        LiteralList,
        LiteralMap,
        LiteralMapEntry,
        LiteralNull,
        LiteralString,
        LiteralSymbol,
        Metadata,
        NamedArgument,
        NewExpression,
        Node,
        NodeList,
        NominalTypeAnnotation,
        Operator,
        ParenthesizedExpression,
        RedirectingFactoryBody,
        Rethrow,
        Return,
        Send,
        SendSet,
        Statement,
        StringInterpolation,
        StringInterpolationPart,
        StringJuxtaposition,
        SwitchCase,
        SwitchStatement,
        SyncForIn,
        Throw,
        TryStatement,
        TypeAnnotation,
        TypeVariable,
        VariableDefinitions,
        While,
        Yield;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../util/util.dart' show Link;
import 'error.dart' show KernelError;
import 'kernel.dart' show ConstructorTarget, Kernel;
import 'unavailable.dart' show UnavailableVisitor;
import 'unresolved.dart' show UnresolvedVisitor;

/// Translates dart2js AST nodes [Node] into Kernel IR [ir.TreeNode].
///
/// Most methods in this class have a prefix that follows these conventions:
///
///   * `visit` for overridden visitor methods.
///   * `handle` for methods that implement common behavior for several `visit`
///     methods. These methods are called by `visit` methods implemented by
///     various mixins below.
///   * `build` helper method that builds a new Kernel IR tree.
///   * `get` helper method that use a cache to build exactly one Kernel IR
///     tree for a given element.
///
/// We reserve the prefixes `visit` and `handle` for superclasses of this
/// class. So those methods should always have an @override annotation. Use
/// `build` instead of `handle` when adding a new helper method to this class.
class KernelVisitor extends Object
    with
        SemanticSendResolvedMixin,
        BaseImplementationOfStaticsMixin,
        BaseImplementationOfLocalsMixin,
        BaseImplementationOfCompoundsMixin,
        BaseImplementationOfSetIfNullsMixin,
        SemanticDeclarationResolvedMixin,
        DeclarationResolverMixin,
        UnavailableVisitor,
        UnresolvedVisitor,
        KernelError
    implements
        SemanticVisitor,
        SemanticSendVisitor,
        SemanticDeclarationVisitor {
  TreeElements elements;
  AstElement currentElement;
  final Kernel kernel;
  int transformerFlags = 0;

  final Map<JumpTarget, ir.LabeledStatement> continueTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<JumpTarget, ir.SwitchCase> continueSwitchTargets =
      <JumpTarget, ir.SwitchCase>{};

  final Map<JumpTarget, ir.LabeledStatement> breakTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<LocalElement, ir.VariableDeclaration> locals =
      <LocalElement, ir.VariableDeclaration>{};

  final Map<CascadeReceiver, ir.VariableGet> cascadeReceivers =
      <CascadeReceiver, ir.VariableGet>{};

  // This maps underlying Library elements to the corresponding DeferredImport
  // object, via the prefix name (aka "bar" in
  // "import foo.dart deferred as bar"). LibraryElement corresponds to the
  // imported library element.
  final Map<LibraryElement, Map<String, ir.LibraryDependency>> deferredImports =
      <LibraryElement, Map<String, ir.LibraryDependency>>{};

  ir.Node associateElement(ir.Node node, Element element) {
    kernel.nodeToElement[node] = element;
    return node;
  }

  ir.Node associateNode(ir.Node node, Node ast) {
    kernel.nodeToAst[node] = ast;
    return node;
  }

  bool isVoidContext = false;

  /// If non-null, reference to a deferred library that a subsequent getter is
  /// using.
  ir.LibraryDependency _deferredLibrary;

  KernelVisitor(this.currentElement, this.elements, this.kernel);

  KernelVisitor get sendVisitor => this;

  KernelVisitor get declVisitor => this;

  ir.TreeNode visitForValue(Expression node) {
    bool wasVoidContext = isVoidContext;
    isVoidContext = false;
    try {
      return node?.accept(this);
    } finally {
      isVoidContext = wasVoidContext;
    }
  }

  ir.TreeNode visitForEffect(Expression node) {
    bool wasVoidContext = isVoidContext;
    isVoidContext = true;
    try {
      return node?.accept(this);
    } finally {
      isVoidContext = wasVoidContext;
    }
  }

  ir.TreeNode visitWithCurrentContext(Expression node) => node?.accept(this);

  withCurrentElement(AstElement element, f()) {
    assert(
        element.library == (kernel.compiler.currentElement as Element).library);
    Element previousElement = currentElement;
    currentElement = element;
    try {
      return f();
    } finally {
      currentElement = previousElement;
    }
  }

  ir.DartType computeType(TypeAnnotation node) {
    if (node == null) return const ir.DynamicType();
    return kernel.typeToIr(elements.getType(node));
  }

  // This works around a bug in dart2js.
  // TODO(ahe): Fix the bug in dart2js and remove this function.
  ir.DartType typeToIrHack(ResolutionDartType type) {
    if (currentElement.isSynthesized &&
        currentElement.enclosingClass.isMixinApplication &&
        !kernel.hasHierarchyProblem(currentElement.enclosingClass)) {
      // Dart2js doesn't compute the correct functionSignature for synthetic
      // constructors in mixin applications. So we compute the correct type:
      // First, find the first superclass that isn't a mixin.
      ClassElement superclass = currentElement.enclosingClass.superclass;
      while (superclass.isMixinApplication) {
        superclass = superclass.superclass;
      }
      // Then translate the "this type" of the mixin application to its
      // supertype with the correct type arguments.
      //
      // Consider this example:
      //
      //     class Super<S> {}
      //     class Sub<T> extends Object with Super<T> {}
      //
      // Here the problem is that dart2js has created a constructor that refers
      // to S (not T) in Sub (for example, the return type of the constructor
      // is Super<S> and it should be Sub<T>, but we settle for Super<T> for
      // now). So we need to translate Sub<T> to an instance of Super, which is
      // Super<T> (not Super<S>).
      ResolutionInterfaceType supertype =
          currentElement.enclosingClass.asInstanceOf(superclass);
      // Once we have [supertype], we know how to substitute S with T: the type
      // arguments of [supertype] corresponds to T, and the type variables of
      // its element correspond to S.
      type =
          type.subst(supertype.typeArguments, supertype.element.typeVariables);
    }
    return kernel.typeToIr(type);
  }

  // TODO(ahe): Hack. Fix dart2js instead.
  ir.Name nameToIrName(Name name) {
    assert(!name.isPrivate || name.library == currentElement.library);
    return kernel.irName(name.text, currentElement);
  }

  List<ir.DartType> computeTypesFromTypes(NodeList nodes, {int expected}) {
    if (expected == null) {
      throw "[expected] is null";
    }
    List<ir.DartType> types = new List<ir.DartType>(expected);
    Iterator<Node> iterator = nodes?.iterator;
    for (int i = 0; i < expected; i++) {
      TypeAnnotation type = null;
      if (iterator != null && iterator.moveNext()) {
        type = iterator.current;
      }
      types[i] = computeType(type);
    }
    if (iterator != null && iterator.moveNext()) {
      // Should already have been reported by resolution.
      // TODO(ahe): Delete this debug message.
      kernel.debugMessage(iterator.current, "Extra type arguments.");
    }
    return types;
  }

  ir.DartType computeTypeFromTypes(NodeList node) {
    return computeTypesFromTypes(node, expected: 1).single;
  }

  ir.MethodInvocation buildInvokeSelector(
      ir.Expression receiver, Selector selector, ir.Arguments arguments) {
    return new ir.MethodInvocation(
        receiver, nameToIrName(selector.memberName), arguments);
  }

  ir.MethodInvocation buildCall(
      ir.Expression receiver, CallStructure callStructure, NodeList arguments) {
    return buildInvokeSelector(
        receiver, callStructure.callSelector, buildArguments(arguments));
  }

  @override
  // ignore: INVALID_METHOD_OVERRIDE_RETURN_TYPE
  ir.Expression visitIdentifier(Identifier node) {
    // TODO(ahe): Shouldn't have to override this method, but
    // [SemanticSendResolvedMixin.visitIdentifier] may return `null` on errors.
    if (node.isThis()) {
      return sendVisitor.visitThisGet(node, null);
    } else {
      return new ir.InvalidExpression();
    }
  }

  @override
  ir.InvalidExpression handleUnresolved(Node node) {
    return new ir.InvalidExpression();
  }

  @override
  ir.Expression handleError(Node node) => new ir.InvalidExpression();

  @override
  void apply(Node node, _) {
    throw new UnsupportedError("apply");
  }

  @override
  void previsitDeferredAccess(Send node, PrefixElement prefix, _) {
    // This is visited before any element access, and if it is deferred,
    // prefix.isDeferred = true.
    if (prefix != null && prefix.isDeferred) {
      _deferredLibrary = getDeferredImport(prefix);
    } else {
      _deferredLibrary = null;
    }
  }

  @override
  internalError(Spannable spannable, String message) {
    kernel.internalError(spannable, message);
  }

  @override
  applyParameters(NodeList parameters, _) {
    throw new UnsupportedError("applyParameters");
  }

  @override
  applyInitializers(FunctionExpression constructor, _) {
    throw new UnsupportedError("applyInitializers");
  }

  @override
  ir.AssertStatement visitAssert(Assert node) {
    return new ir.AssertStatement(
        visitForValue(node.condition), visitForValue(node.message));
  }

  ir.LabeledStatement getBreakTarget(JumpTarget target) {
    return breakTargets.putIfAbsent(target,
        () => associateNode(new ir.LabeledStatement(null), target.statement));
  }

  ir.LabeledStatement getContinueTarget(JumpTarget target) {
    return continueTargets.putIfAbsent(target,
        () => associateNode(new ir.LabeledStatement(null), target.statement));
  }

  ir.SwitchCase getContinueSwitchTarget(JumpTarget target) {
    return continueSwitchTargets[target];
  }

  /// The optional positional parameter isBreakTarget can be added in cases
  /// where a break statement was added but the element model and underlying
  /// JumpTargets don't know about it.
  ir.Statement buildBreakTarget(
      ir.Statement statement, Node node, JumpTarget jumpTarget,
      [bool isBreakTarget = false]) {
    assert(node.isValidBreakTarget());
    assert(jumpTarget == elements.getTargetDefinition(node));
    associateNode(statement, node);
    if (jumpTarget != null && (jumpTarget.isBreakTarget || isBreakTarget)) {
      ir.LabeledStatement breakTarget = getBreakTarget(jumpTarget);
      breakTarget.body = statement;
      statement.parent = breakTarget;
      return breakTarget;
    } else {
      return statement;
    }
  }

  ir.Statement buildContinueTarget(
      ir.Statement statement, Node node, JumpTarget jumpTarget) {
    assert(node.isValidContinueTarget());
    assert(jumpTarget == elements.getTargetDefinition(node));
    if (jumpTarget != null && jumpTarget.isContinueTarget) {
      ir.LabeledStatement continueTarget = getContinueTarget(jumpTarget);
      continueTarget.body = statement;
      statement.parent = continueTarget;
      return continueTarget;
    } else {
      return statement;
    }
  }

  ir.Statement buildForInCommon(
      ForIn node, ir.VariableDeclaration variable, ir.Statement body,
      {bool isAsync}) {
    ir.Expression iterable = visitForValue(node.expression);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    body = buildContinueTarget(body, node, jumpTarget);
    return buildBreakTarget(
        associateNode(
            new ir.ForInStatement(variable, iterable, body, isAsync: isAsync),
            node),
        node,
        jumpTarget);
  }

  /// Builds a for-in statement for this case:
  ///
  ///     for (constOrVarOrType loopVariable in expression) body
  ir.Statement buildForInWithDeclaration(
      ForIn node, VariableDefinitions declaration,
      {bool isAsync}) {
    if (declaration.definitions.slowLength() != 1) {
      // It's not legal to declare more than one variable in a for-in loop.
      return new ir.InvalidStatement();
    }
    ir.VariableDeclaration variable = declaration.accept(this);
    return buildForInCommon(node, variable, buildStatementInBlock(node.body),
        isAsync: isAsync);
  }

  Accessor buildStaticAccessor(Element getter, [Element setter]) {
    if (setter == null &&
        getter != null &&
        getter.isField &&
        !getter.isFinal &&
        !getter.isConst) {
      setter = getter;
    }
    return new StaticAccessor(
        (getter == null) ? null : kernel.elementToIr(getter),
        (setter == null) ? null : kernel.elementToIr(setter),
        ir.TreeNode.noOffset);
  }

  Accessor computeAccessor(ForIn node, Element element) {
    if (element == null) {
      Send send = node.declaredIdentifier.asSend();
      if (send == null) {
        return buildStaticAccessor(null);
      }
      // This should be the situation where `node.declaredIdentifier` is
      // unresolved, but in an instance method context. If it is some different
      // situation, the assignment to [ir.PropertyGet] should act as an
      // assertion.
      ir.PropertyGet expression = visitForValue(send);
      return PropertyAccessor.make(
          expression.receiver, expression.name, null, null);
    } else if (kernel.isSyntheticError(element)) {
      return buildStaticAccessor(null);
    } else if (element.isGetter) {
      if (element.isInstanceMember) {
        return new ThisPropertyAccessor(kernel.irName(element.name, element),
            null, null, ir.TreeNode.noOffset);
      } else {
        GetterElement getter = element;
        Element setter = getter.setter;
        return buildStaticAccessor(getter, setter);
      }
    } else if (element.isLocal) {
      return new VariableAccessor(
          getLocal(element), null, ir.TreeNode.noOffset);
    } else if (element.isField) {
      return buildStaticAccessor(element);
    } else {
      return buildStaticAccessor(null);
    }
  }

  /// Builds a for-in statement for this case:
  ///
  ///     for (element in expression) body
  ///
  /// This is normalized to:
  ///
  ///     for (final #t in expression) {
  ///       element = #t;
  ///       body;
  ///     }
  ir.Statement buildForInWithoutDeclaration(ForIn node, Element element,
      {bool isAsync}) {
    Accessor accessor = computeAccessor(node, elements.getForInVariable(node));
    // Since we've created [variable], we know it's only assigned to in the
    // loop header and can be final.
    ir.VariableDeclaration variable =
        new ir.VariableDeclaration.forValue(null, isFinal: true);
    ir.Statement assigment = new ir.ExpressionStatement(accessor
        .buildAssignment(new ir.VariableGet(variable), voidContext: true));
    ir.Block body = buildStatementInBlock(node.body, forceBlock: true);
    List<ir.Statement> statements = <ir.Statement>[assigment]
      ..addAll(body.statements);
    return buildForInCommon(node, variable, new ir.Block(statements),
        isAsync: isAsync);
  }

  ir.Statement buildForIn(ForIn node, {bool isAsync}) {
    VariableDefinitions declaration =
        node.declaredIdentifier.asVariableDefinitions();
    if (declaration != null) {
      return buildForInWithDeclaration(node, declaration, isAsync: isAsync);
    } else {
      Element element = elements.getForInVariable(node);
      return buildForInWithoutDeclaration(node, element, isAsync: isAsync);
    }
  }

  @override
  ir.Statement visitAsyncForIn(AsyncForIn node) {
    return buildForIn(node, isAsync: true);
  }

  @override
  ir.AwaitExpression visitAwait(Await node) {
    return new ir.AwaitExpression(visitForValue(node.expression));
  }

  @override
  ir.Statement visitBlock(Block node) {
    return buildBreakTarget(
        buildStatementInBlock(node), node, elements.getTargetDefinition(node));
  }

  bool buildStatement(Statement statement, List<ir.Statement> statements) {
    ir.Node irNode = statement.accept(this);
    bool hasVariableDeclaration = false;
    if (irNode is VariableDeclarations) {
      statements.addAll(irNode.variables);
      hasVariableDeclaration = true;
    } else {
      statements.add(irNode);
      if (irNode is ir.VariableDeclaration) {
        hasVariableDeclaration = true;
      }
    }
    return hasVariableDeclaration;
  }

  ir.Statement buildStatementInBlock(Statement node, {bool forceBlock: false}) {
    if (node == null) return null;
    List<ir.Statement> statements = <ir.Statement>[];
    if (node is Block) {
      for (Node statement in node.statements.nodes) {
        buildStatement(statement, statements);
      }
    } else {
      if (buildStatement(node, statements)) forceBlock = true;
      if (!forceBlock && statements.length == 1) {
        return statements.single;
      }
      // One VariableDefinitions statement node (dart2js AST) may generate
      // multiple statements in Kernel IR so we sometimes fall through here.
    }
    return associateNode(new ir.Block(statements), node);
  }

  @override
  ir.Statement visitBreakStatement(BreakStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    if (target == null || !target.statement.isValidBreakTarget()) {
      // This is a break in an invalid position.
      return new ir.InvalidStatement();
    }
    // A break can break to itself in the degenerate case `label: break
    // label'`.
    return buildBreakTarget(new ir.BreakStatement(getBreakTarget(target)), node,
        elements.getTargetDefinition(node));
  }

  CascadeReceiver computeCascadeReceiver(Cascade cascade) {
    CascadeReceiver receiver;
    Expression send = cascade.expression.asSend();
    while (send != null && (receiver = send.asCascadeReceiver()) == null) {
      Expression possibleReceiver = send.asSend()?.receiver;
      if (possibleReceiver != null) {
        send = possibleReceiver;
      } else {
        // Can happen in this case: `a..add(foo)('WHAT')`.
        send = send.asSend()?.selector;
      }
    }
    if (receiver == null) {
      internalError(cascade, "Can't find cascade receiver");
    }
    return receiver;
  }

  @override
  ir.Let visitCascade(Cascade node) {
    // Given this cascade expression `receiver..cascade1()..cascade2()`, the
    // parser has produced a tree like this:
    //     Cascade(Send(
    //         CascadeReceiver(Cascade(Send(
    //             CascadeRecevier(receiver), 'cascade1', []))),
    //         'cascade2', []))
    // If viewed as a tree, `CascadeReceiver(receiver)` is the left-most leaf
    // node.  Below, we create this:
    //     cascades = [
    //         Cascade(Send(CascadeReceiver(...), 'cascade2', [])),
    //         Cascade(Send(CascadeReceiver(...), 'cascade1', []))]
    // Notice that the cascades are in reverse order, which we use to build a
    // `let` expression bottom up.
    // First iteration of the loop produces:
    //     let dummy = rcv.cascade2() in
    //         rcv
    // Second iteration:
    //     let dummy = rcv.cascade1() in
    //         let dummy = rcv.cascade2() in
    //             rcv
    // Finally we return:
    //     let rcv = receiver in
    //         let dummy = rcv.cascade1() in
    //             let dummy = rcv.cascade2() in
    //                 rcv
    int startLength;
    assert((startLength = cascadeReceivers.length) >= 0);

    Cascade cascade = node;
    List<Cascade> cascades = <Cascade>[];
    CascadeReceiver receiver;
    ir.VariableDeclaration receiverVariable = makeOrReuseVariable(null);

    do {
      cascades.add(cascade);
      receiver = computeCascadeReceiver(cascade);
      cascadeReceivers[receiver] = new ir.VariableGet(receiverVariable);
      cascade = receiver.expression.asCascade();
    } while (cascade != null);
    // At this point, all nested [Cascades] targeting the same receiver have
    // been collected in [cascades] in reverse order. [receiver] is the
    // left-most receiver. [receiverVariable] will hold the value of evaluating
    // [receiver]. Each [CascadeReceiver] has a getter for [receiverVariable]
    // in [cascadeReceivers].

    receiverVariable.initializer = visitForValue(receiver.expression);
    receiverVariable.initializer.parent = receiverVariable;

    ir.Expression result = new ir.VariableGet(receiverVariable); // rcv.
    for (Cascade cascade in cascades) {
      // When evaluating `cascade.expression`, we stop the recursion at
      // [visitCascadeReceiver] and instead returns an [ir.VariableGet].
      // TODO(ahe): Use visitForEffect here?
      ir.Expression value = visitForValue(cascade.expression);
      result = new ir.Let(makeOrReuseVariable(value), result);
    }

    assert(startLength == cascadeReceivers.length);
    return new ir.Let(receiverVariable, result);
  }

  @override
  ir.VariableGet visitCascadeReceiver(CascadeReceiver node) {
    return cascadeReceivers.remove(node);
  }

  @override
  visitCaseMatch(CaseMatch node) {
    // Shouldn't be called. Handled by [visitSwitchCase].
    return internalError(node, "CaseMatch");
  }

  @override
  ir.Catch visitCatchBlock(CatchBlock node) {
    ir.VariableDeclaration exception =
        (node.exception == null) ? null : getLocal(elements[node.exception]);
    ir.VariableDeclaration trace =
        (node.trace == null) ? null : getLocal(elements[node.trace]);
    ir.DartType guard = computeType(node.type);
    return new ir.Catch(exception, buildStatementInBlock(node.block),
        guard: guard, stackTrace: trace);
  }

  @override
  ir.ConditionalExpression visitConditional(Conditional node) {
    return new ir.ConditionalExpression(
        visitForValue(node.condition),
        visitWithCurrentContext(node.thenExpression),
        visitWithCurrentContext(node.elseExpression),
        null);
  }

  @override
  ir.Statement visitContinueStatement(ContinueStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    if (target == null || !target.statement.isValidContinueTarget()) {
      // This is a continue in an invalid position.
      return new ir.InvalidStatement();
    }
    ir.SwitchCase switchCase = getContinueSwitchTarget(target);
    return (switchCase == null)
        ? new ir.BreakStatement(getContinueTarget(target))
        : new ir.ContinueSwitchStatement(switchCase);
  }

  @override
  ir.Statement visitDoWhile(DoWhile node) {
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body =
        buildContinueTarget(buildStatementInBlock(node.body), node, jumpTarget);
    ir.Expression condition = visitForValue(node.condition);
    return buildBreakTarget(
        new ir.DoStatement(body, condition), node, jumpTarget);
  }

  @override
  ir.EmptyStatement visitEmptyStatement(EmptyStatement node) {
    return new ir.EmptyStatement();
  }

  @override
  visitEnum(Enum node) {
    // Not called normally. In dart2js, enums are represented as class
    // elements, so `classToIr` handles enums.  All the synthetic members of an
    // enum class have already been installed by dart2js and we don't have to
    // do anything special.
    return internalError(node, "Enum");
  }

  @override
  ir.ExpressionStatement visitExpressionStatement(ExpressionStatement node) {
    return new ir.ExpressionStatement(visitForEffect(node.expression));
  }

  @override
  ir.Statement visitFor(For node) {
    VariableDefinitions initializers =
        node.initializer?.asVariableDefinitions();
    ir.Expression initializer;
    List<ir.VariableDeclaration> variables;
    if (initializers != null) {
      ir.Block block = buildStatementInBlock(initializers, forceBlock: true);
      variables = new List<ir.VariableDeclaration>.from(block.statements);
    } else {
      if (node.initializer != null) {
        initializer = visitForValue(node.initializer);
      }
      variables = const <ir.VariableDeclaration>[];
    }
    ir.Expression condition = visitForValue(node.condition);
    List<ir.Expression> updates = <ir.Expression>[];
    for (Expression update in node.update) {
      updates.add(visitForEffect(update));
    }

    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body =
        buildContinueTarget(buildStatementInBlock(node.body), node, jumpTarget);
    ir.ForStatement forStatement = associateNode(
        new ir.ForStatement(variables, condition, updates, body), node);
    ir.Statement result = buildBreakTarget(forStatement, node, jumpTarget);
    if (initializer != null) {
      result = associateNode(
          new ir.Block(
              <ir.Statement>[new ir.ExpressionStatement(initializer), result]),
          node.initializer);
    }
    return result;
  }

  @override
  ir.FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    return node.function.accept(this);
  }

  @override
  ir.Statement visitIf(If node) {
    return buildBreakTarget(
        new ir.IfStatement(
            visitForValue(node.condition),
            buildStatementInBlock(node.thenPart),
            buildStatementInBlock(node.elsePart)),
        node,
        elements.getTargetDefinition(node));
  }

  @override
  visitLabel(Label node) {
    // Shouldn't be called. Handled by visitLabeledStatement and
    // visitSwitchCase.
    return internalError(node, "Label");
  }

  @override
  ir.Statement visitLabeledStatement(LabeledStatement node) {
    Statement statement = node.statement;
    ir.Statement result = (statement is Block)
        // If [statement] is a Block, we need to ensure that we don't bypass
        // its visit method (so it can build break targets correctly).
        ? statement.accept(this)
        : buildStatementInBlock(statement);
    associateNode(result, statement);

    // A [LabeledStatement] isn't the actual jump target, instead, [statement]
    // is the target. This allows uniform handling of break and continue in
    // loops. The following code simply assert that [result] has been generated
    // correctly with respect to jump targets.
    JumpTarget jumpTarget = elements.getTargetDefinition(node.statement);
    if (jumpTarget != null) {
      if (jumpTarget.isBreakTarget) {
        ir.LabeledStatement target = breakTargets[jumpTarget];
        if (target != null && target != result && target.parent == null) {
          internalError(node, "no parent");
        }
      }
      if (jumpTarget.isContinueTarget) {
        ir.LabeledStatement target = continueTargets[jumpTarget];
        if (target != null && target != result && target.parent == null) {
          internalError(node, "no parent");
        }
      }
    }

    return result;
  }

  @override
  ir.BoolLiteral visitLiteralBool(LiteralBool node) {
    return associateNode(new ir.BoolLiteral(node.value), node);
  }

  @override
  ir.DoubleLiteral visitLiteralDouble(LiteralDouble node) {
    return associateNode(new ir.DoubleLiteral(node.value), node);
  }

  @override
  ir.IntLiteral visitLiteralInt(LiteralInt node) {
    return associateNode(new ir.IntLiteral(node.value), node);
  }

  @override
  ir.ListLiteral visitLiteralList(LiteralList node) {
    // TODO(ahe): Type arguments.
    List<ir.Expression> elements = <ir.Expression>[];
    for (Expression element in node.elements.nodes) {
      elements.add(visitForValue(element));
    }
    return associateNode(
        new ir.ListLiteral(elements,
            typeArgument: computeTypeFromTypes(node.typeArguments),
            // TODO(ahe): Should constness be validated?
            isConst: node.isConst),
        node);
  }

  @override
  ir.MapLiteral visitLiteralMap(LiteralMap node) {
    // TODO(ahe): Type arguments.
    List<ir.MapEntry> entries = <ir.MapEntry>[];
    for (LiteralMapEntry entry in node.entries.nodes) {
      entries.add(new ir.MapEntry(
          visitForValue(entry.key), visitForValue(entry.value)));
    }
    List<ir.DartType> typeArguments =
        computeTypesFromTypes(node.typeArguments, expected: 2);
    return associateNode(
        new ir.MapLiteral(entries,
            keyType: typeArguments.first,
            valueType: typeArguments.last,
            // TODO(ahe): Should Constness be validated?
            isConst: node.isConst),
        node);
  }

  @override
  visitLiteralMapEntry(LiteralMapEntry node) {
    // Shouldn't be called. Handled by [visitLiteralMap].
    return internalError(node, "LiteralMapEntry");
  }

  @override
  ir.NullLiteral visitLiteralNull(LiteralNull node) {
    return new ir.NullLiteral();
  }

  @override
  ir.Expression visitLiteralString(LiteralString node) {
    if (node.dartString == null) return new ir.InvalidExpression();
    return associateNode(
        new ir.StringLiteral(node.dartString.slowToString()), node);
  }

  @override
  ir.SymbolLiteral visitLiteralSymbol(LiteralSymbol node) {
    var result = new ir.SymbolLiteral(node.slowNameString);
    return associateNode(result, node);
  }

  @override
  visitMetadata(Metadata node) {
    // Shouldn't be called. Metadata should already have been analyzed and
    // converted to a constant expression in the resolver.
    return internalError(node, "Metadata not handled as constant.");
  }

  @override
  ir.NamedExpression visitNamedArgument(NamedArgument node) {
    return new ir.NamedExpression(
        node.name.source, visitForValue(node.expression));
  }

  @override
  visitOperator(Operator node) {
    // This is a special subclass of [Identifier], and we should never see that
    // in the semantic visitor.
    return internalError(node, "Operator");
  }

  @override
  ir.Expression visitParenthesizedExpression(ParenthesizedExpression node) {
    return visitWithCurrentContext(node.expression);
  }

  @override
  ir.InvalidStatement visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    // Not implemented yet, only serves to recover from parser errors as
    // dart2js is lenient in parsing something that looks like a redirecting
    // factory method.
    return new ir.InvalidStatement();
  }

  @override
  ir.ExpressionStatement visitRethrow(Rethrow node) {
    return new ir.ExpressionStatement(new ir.Rethrow());
  }

  @override
  ir.ReturnStatement visitReturn(Return node) {
    return new ir.ReturnStatement(visitForValue(node.expression));
  }

  @override
  ir.StringConcatenation visitStringInterpolation(StringInterpolation node) {
    List<ir.Expression> expressions = <ir.Expression>[];
    expressions.add(visitForValue(node.string));
    for (StringInterpolationPart part in node.parts) {
      expressions.add(visitForValue(part.expression));
      expressions.add(visitForValue(part.string));
    }
    return new ir.StringConcatenation(expressions);
  }

  @override
  ir.StringConcatenation visitStringJuxtaposition(StringJuxtaposition node) {
    return new ir.StringConcatenation(
        <ir.Expression>[visitForValue(node.first), visitForValue(node.second)]);
  }

  @override
  ir.SwitchCase visitSwitchCase(SwitchCase node) {
    List<ir.Expression> expressions = <ir.Expression>[];
    List<int> expressionOffsets = <int>[];
    for (var labelOrCase in node.labelsAndCases.nodes) {
      CaseMatch match = labelOrCase.asCaseMatch();
      if (match != null) {
        ir.TreeNode expression = visitForValue(match.expression);
        expressions.add(expression);
        expressionOffsets.add(expression.fileOffset);
      } else {
        // Assert that labelOrCase is one of two known types: [CaseMatch] or
        // [Label]. We ignore cases, as any users have been resolved to use the
        // case directly.
        assert(labelOrCase.asLabel() != null);
      }
    }
    // We ignore the node's statements here, they're generated below in
    // [visitSwitchStatement] once we've set up all the jump targets.
    return associateNode(
        new ir.SwitchCase(expressions, expressionOffsets, null,
            isDefault: node.isDefaultCase),
        node);
  }

  /// Returns true if [node] would let execution reach the next node (aka
  /// fall-through in switch cases).
  bool fallsThrough(ir.Statement node) {
    return !(node is ir.BreakStatement ||
        node is ir.ReturnStatement ||
        node is ir.ContinueSwitchStatement ||
        (node is ir.ExpressionStatement && node.expression is ir.Throw));
  }

  @override
  ir.Statement visitSwitchStatement(SwitchStatement node) {
    ir.Expression expression = visitForValue(node.expression);
    List<ir.SwitchCase> cases = <ir.SwitchCase>[];
    bool switchIsBreakTarget = elements.getTargetDefinition(node).isBreakTarget;
    for (SwitchCase caseNode in node.cases.nodes) {
      cases.add(caseNode.accept(this));
      JumpTarget jumpTarget = elements.getTargetDefinition(caseNode);
      if (jumpTarget != null) {
        assert(jumpTarget.isContinueTarget);
        assert(!continueSwitchTargets.containsKey(jumpTarget));
        continueSwitchTargets[jumpTarget] = cases.last;
      }
    }

    Iterator<ir.SwitchCase> casesIterator = cases.iterator;
    for (Link<Node> link = node.cases.nodes;
        link.isNotEmpty;
        link = link.tail) {
      SwitchCase caseNode = link.head;
      bool isLastCase = link.tail.isEmpty;
      if (!casesIterator.moveNext()) {
        internalError(caseNode, "case node mismatch");
      }
      ir.SwitchCase irCase = casesIterator.current;
      List<ir.Statement> statements = <ir.Statement>[];
      for (Statement statement in caseNode.statements.nodes) {
        buildStatement(statement, statements);
      }
      if (statements.isEmpty || fallsThrough(statements.last)) {
        if (isLastCase) {
          if (!caseNode.isDefaultCase) {
            statements.add(new ir.BreakStatement(
                getBreakTarget(elements.getTargetDefinition(node))));
            // Because we "helpfully" add a break here, in the underlying
            // element model the jump target doesn't actually know it's a break
            // target, so we have to pass that information.
            switchIsBreakTarget = true;
          }
        } else {
          statements.add(new ir.ExpressionStatement(new ir.Throw(
              new ir.ConstructorInvocation(
                  kernel.getFallThroughErrorConstructor(),
                  new ir.Arguments.empty()))));
        }
      }
      ir.Statement body = new ir.Block(statements);
      irCase.body = body;
      body.parent = irCase;
    }
    assert(!casesIterator.moveNext());

    return buildBreakTarget(new ir.SwitchStatement(expression, cases), node,
        elements.getTargetDefinition(node), switchIsBreakTarget);
  }

  @override
  ir.Statement visitSyncForIn(SyncForIn node) {
    return buildForIn(node, isAsync: false);
  }

  @override
  ir.Throw visitThrow(Throw node) {
    return new ir.Throw(visitForValue(node?.expression));
  }

  @override
  ir.Statement visitTryStatement(TryStatement node) {
    ir.Statement result = buildStatementInBlock(node.tryBlock);
    if (node.catchBlocks != null && !node.catchBlocks.isEmpty) {
      List<ir.Catch> catchBlocks = <ir.Catch>[];
      for (CatchBlock block in node.catchBlocks.nodes) {
        catchBlocks.add(block.accept(this));
      }
      result = new ir.TryCatch(result, catchBlocks);
    }
    if (node.finallyBlock != null) {
      result =
          new ir.TryFinally(result, buildStatementInBlock(node.finallyBlock));
    }
    return buildBreakTarget(result, node, elements.getTargetDefinition(node));
  }

  @override
  visitTypeAnnotation(TypeAnnotation node) {
    // Shouldn't be called, as the resolver has already resolved types and
    // created [DartType] objects.
    return internalError(node, "TypeAnnotation");
  }

  @override
  visitNominalTypeAnnotation(NominalTypeAnnotation node) {
    // Shouldn't be called, as the resolver has already resolved types and
    // created [DartType] objects.
    return internalError(node, "NominalTypeAnnotation");
  }

  @override
  visitFunctionTypeAnnotation(FunctionTypeAnnotation node) {
    // Shouldn't be called, as the resolver has already resolved types and
    // created [DartType] objects.
    return internalError(node, "FunctionTypeAnnotation");
  }

  @override
  visitTypeVariable(TypeVariable node) {
    // Shouldn't be called, as the resolver has already resolved types and
    // created [DartType] objects.
    return internalError(node, "TypeVariable");
  }

  @override
  ir.Statement visitWhile(While node) {
    ir.Expression condition = visitForValue(node.condition);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body =
        buildContinueTarget(buildStatementInBlock(node.body), node, jumpTarget);
    return buildBreakTarget(
        new ir.WhileStatement(condition, body), node, jumpTarget);
  }

  @override
  ir.YieldStatement visitYield(Yield node) {
    return new ir.YieldStatement(visitForValue(node.expression),
        isYieldStar: node.hasStar);
  }

  @override
  ir.InvalidExpression visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.InvalidExpression();
  }

  IrFunction buildIrFunction(
      ir.ProcedureKind kind, FunctionElement function, Node body) {
    return new IrFunction.procedure(kind, buildFunctionNode(function, body));
  }

  @override
  IrFunction visitAbstractGetterDeclaration(
      FunctionExpression node, MethodElement getter, _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, null);
  }

  @override
  IrFunction visitAbstractSetterDeclaration(
      FunctionExpression node, MethodElement setter, NodeList parameters, _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, null);
  }

  @override
  ir.AsExpression visitAs(
      Send node, Node expression, ResolutionDartType type, _) {
    return new ir.AsExpression(
        visitForValue(expression), kernel.typeToIr(type));
  }

  @override
  ir.MethodInvocation visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return associateNode(
        buildBinaryOperator(left, operator.selectorName, right), node);
  }

  ir.Expression buildConstructorInvoke(NewExpression node, {bool isConst}) {
    ConstructorElement constructor = elements[node.send];
    ConstructorTarget target =
        kernel.computeEffectiveTarget(constructor, elements.getType(node));
    NodeList arguments = node.send.argumentsNode;
    if (kernel.isSyntheticError(target.element)) {
      return new ir.MethodInvocation(new ir.InvalidExpression(),
          kernel.irName("call", currentElement), buildArguments(arguments));
    }
    ir.InvocationExpression invoke = target.element.isGenerativeConstructor
        ? buildGenerativeConstructorInvoke(target.element, arguments,
            isConst: isConst)
        : buildStaticInvoke(target.element, arguments, isConst: isConst);
    if (target.type.isInterfaceType) {
      ResolutionInterfaceType type = target.type;
      if (type.isGeneric) {
        invoke.arguments.types.addAll(kernel.typesToIr(type.typeArguments));
      }
    }
    return invoke;
  }

  @override
  ir.InvocationExpression visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node, BoolFromEnvironmentConstantExpression constant, _) {
    return associateNode(buildConstructorInvoke(node, isConst: true), node);
  }

  ir.TypeLiteral buildTypeLiteral(TypeConstantExpression constant) {
    return new ir.TypeLiteral(kernel.typeLiteralToIr(constant));
  }

  @override
  ir.Expression visitClassTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    var loadedCheckFunc =
        _createCheckLibraryLoadedFuncIfNeeded(_deferredLibrary);
    _deferredLibrary = null;
    return loadedCheckFunc(buildTypeLiteral(constant));
  }

  @override
  ir.MethodInvocation visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return associateNode(
        buildCall(buildTypeLiteral(constant), callStructure, arguments), node);
  }

  ir.Expression buildTypeLiteralSet(TypeConstantExpression constant, Node rhs) {
    return new ReadOnlyAccessor(
            buildTypeLiteral(constant), ir.TreeNode.noOffset)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression visitClassTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, _) {
    return buildTypeLiteralSet(constant, rhs);
  }

  @override
  ir.FunctionExpression visitClosureDeclaration(FunctionExpression node,
      LocalFunctionElement closure, NodeList parameters, Node body, _) {
    return withCurrentElement(closure, () {
      ir.FunctionExpression function =
          new ir.FunctionExpression(buildFunctionNode(closure, body));
      kernel.localFunctions[closure] = function;
      return function;
    });
  }

  @override
  ir.Expression visitCompoundIndexSet(SendSet node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, _) {
    return buildCompoundAssignment(
        node,
        buildIndexAccessor(receiver, index),
        kernel.irName(operator.selectorName, currentElement),
        visitForValue(rhs));
  }

  @override
  ir.InvocationExpression visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, _) {
    return associateNode(buildConstructorInvoke(node, isConst: true), node);
  }

  @override
  visitConstantGet(Send node, ConstantExpression constant, _) {
    // TODO(ahe): This method is never called. Is it a bug in semantic visitor?
    return internalError(node, "ConstantGet");
  }

  @override
  visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, _) {
    // TODO(ahe): This method is never called. Is it a bug in semantic visitor?
    return internalError(node, "ConstantInvoke");
  }

  @override
  ir.InvalidExpression visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.InvalidExpression();
  }

  @override
  ir.PropertyGet visitDynamicPropertyGet(
      Send node, Node receiver, Name name, _) {
    return associateNode(
        new ir.PropertyGet(visitForValue(receiver), nameToIrName(name))
          ..fileOffset = node.selector.getBeginToken().charOffset,
        node);
  }

  @override
  ir.MethodInvocation visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, _) {
    return associateNode(
        buildInvokeSelector(
            visitForValue(receiver), selector, buildArguments(arguments))
          ..fileOffset = node.selector.getBeginToken().charOffset,
        node);
  }

  @override
  ir.Expression handleDynamicCompounds(
      Send node, Node receiver, Name name, CompoundRhs rhs, _) {
    ir.Expression receiverNode =
        receiver == null ? new ir.ThisExpression() : visitForValue(receiver);
    ir.Expression compound = buildCompound(
        PropertyAccessor.make(receiverNode, nameToIrName(name), null, null),
        rhs,
        node);
    if (compound is ir.VariableSet) {
      associateNode(compound.value, node);
    } else {
      associateNode(compound, node);
    }
    return compound;
  }

  @override
  ir.PropertySet visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, _) {
    ir.Expression value = visitForValue(rhs);
    return new ir.PropertySet(
        visitForValue(receiver), nameToIrName(name), value);
  }

  @override
  ir.Expression handleDynamicSetIfNulls(
      Send node, Node receiver, Name name, Node rhs, _) {
    ir.Name irName = nameToIrName(name);
    Accessor accessor = (receiver == null)
        ? new ThisPropertyAccessor(irName, null, null, ir.TreeNode.noOffset)
        : PropertyAccessor.make(visitForValue(receiver), irName, null, null);
    return _finishSetIfNull(node, accessor, rhs);
  }

  ir.Expression _finishSetIfNull(Send node, Accessor accessor, Node rhs) {
    ir.Expression result = accessor.buildNullAwareAssignment(
        visitForValue(rhs), null,
        voidContext: isVoidContext);
    if (accessor.builtGetter != null) {
      kernel.nodeToAst[accessor.builtGetter] = node;
    }
    return result;
  }

  @override
  ir.TypeLiteral visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return buildTypeLiteral(constant);
  }

  @override
  ir.MethodInvocation visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildCall(buildTypeLiteral(constant), callStructure, arguments);
  }

  @override
  ir.Expression visitDynamicTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, _) {
    return buildTypeLiteralSet(constant, rhs);
  }

  ir.MethodInvocation buildBinaryOperator(
      Node left, String operator, Node right) {
    ir.Name name = kernel.irName(operator, currentElement);
    return makeBinary(visitForValue(left), name, null, visitForValue(right));
  }

  @override
  ir.MethodInvocation visitEquals(Send node, Node left, Node right, _) {
    return associateNode(buildBinaryOperator(left, '==', right), node);
  }

  @override
  ir.MethodInvocation visitExpressionInvoke(Send node, Node expression,
      NodeList arguments, CallStructure callStructure, _) {
    return associateNode(
        buildCall(visitForValue(expression), callStructure, arguments), node);
  }

  @override
  IrFunction visitFactoryConstructorDeclaration(FunctionExpression node,
      ConstructorElement constructor, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Factory, constructor, body);
  }

  @override
  ir.InvocationExpression visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildConstructorInvoke(node, isConst: false);
  }

  @override
  ir.Initializer visitFieldInitializer(
      SendSet node, FieldElement field, Node expression, _) {
    if (kernel.isSyntheticError(field)) {
      return new ir.InvalidInitializer();
    } else {
      return new ir.FieldInitializer(
          kernel.fieldToIr(field), visitForValue(expression));
    }
  }

  ir.Expression buildStaticFieldSet(FieldElement field, Node rhs) {
    return buildStaticAccessor(field)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression handleFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildStaticFieldSet(field, rhs);
  }

  @override
  ir.Expression visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildSuperPropertyAccessor(field)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  IrFunction buildGenerativeConstructor(
      ConstructorElement constructor, NodeList parameters, Node body) {
    List<ir.Initializer> constructorInitializers = <ir.Initializer>[];
    if (kernel.hasHierarchyProblem(constructor.enclosingClass)) {
      constructorInitializers.add(new ir.InvalidInitializer());
    } else if (constructor.isSynthesized) {
      List<ir.Expression> arguments = const <ir.Expression>[];
      List<ir.NamedExpression> named = const <ir.NamedExpression>[];
      FunctionSignature signature = constructor.functionSignature;
      if (signature.parameterCount != 0) {
        // Mixin application implicit super call.
        arguments = <ir.Expression>[];
        named = <ir.NamedExpression>[];
        signature.orderedForEachParameter((ParameterElement parameter) {
          ir.VariableGet argument = buildLocalGet(parameter);
          if (parameter.isNamed) {
            named.add(new ir.NamedExpression(parameter.name, argument));
          } else {
            arguments.add(argument);
          }
        });
      }
      if (kernel.isSyntheticError(constructor.definingConstructor)) {
        constructorInitializers.add(new ir.InvalidInitializer());
      } else {
        constructorInitializers.add(new ir.SuperInitializer(
            kernel.functionToIr(constructor.definingConstructor),
            new ir.Arguments(arguments, named: named, types: null)));
      }
    } else {
      if (parameters != null) {
        // TODO(ahe): the following is a (modified) copy of
        // [SemanticDeclarationResolvedMixin.visitParameters].
        List<ParameterStructure> structures =
            computeParameterStructures(parameters);
        for (ParameterStructure structure in structures) {
          if (structure.parameter.isInitializingFormal) {
            constructorInitializers.add(structure.dispatch(declVisitor, null));
          }
        }
      }
      // TODO(ahe): the following is a (modified) copy of
      // [SemanticDeclarationResolvedMixin.visitInitializers].
      InitializersStructure initializers =
          computeInitializersStructure(constructor.node);
      for (InitializerStructure structure in initializers.initializers) {
        constructorInitializers.add(structure.dispatch(declVisitor, null));
      }
    }
    return new IrFunction.constructor(
        buildFunctionNode(constructor, body), constructorInitializers);
  }

  @override
  IrFunction visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    return buildGenerativeConstructor(constructor, parameters, body);
  }

  ir.ConstructorInvocation buildGenerativeConstructorInvoke(
      ConstructorElement constructor, NodeList arguments,
      {bool isConst}) {
    if (const bool.fromEnvironment("require_kernel_arguments")) {
      // Check that all constructors from kernel/ast.dart (that are invoked
      // from this package) provide all arguments (including optional
      // arguments).
      // TODO(ahe): Remove this when the implementation has matured.
      if (("package:kernel/ast.dart" ==
              "${constructor.library.canonicalUri}") &&
          "${currentElement.library.canonicalUri}"
              .startsWith("package:rasta/")) {
        if (constructor.functionSignature.parameterCount !=
            arguments.slowLength()) {
          kernel.debugMessage(arguments, "Missing arguments");
          kernel.debugMessage(constructor, "When calling the constructor");
        }
      }
    }
    ir.Arguments argumentsNode = buildArguments(arguments);
    ir.Constructor target = kernel.functionToIr(constructor);
    return new ir.ConstructorInvocation(target, argumentsNode,
        isConst: isConst);
  }

  @override
  ir.InvocationExpression visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildConstructorInvoke(node, isConst: false);
  }

  Accessor buildNullAwarePropertyAccessor(Node receiver, Name name) {
    return new NullAwarePropertyAccessor(visitForValue(receiver),
        nameToIrName(name), null, null, null, ir.TreeNode.noOffset);
  }

  @override
  ir.Expression visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, _) {
    Accessor accessor = buildNullAwarePropertyAccessor(receiver, name);
    ir.Expression result = accessor.buildSimpleRead();
    if (accessor.builtGetter != null) {
      kernel.nodeToAst[accessor.builtGetter] = node;
    }
    return result;
  }

  @override
  ir.Let visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiverNode, NodeList arguments, Selector selector, _) {
    ir.VariableDeclaration receiver =
        makeOrReuseVariable(visitForValue(receiverNode));
    return makeLet(
        receiver,
        new ir.ConditionalExpression(
            buildIsNull(new ir.VariableGet(receiver)),
            new ir.NullLiteral(),
            associateNode(
                buildInvokeSelector(new ir.VariableGet(receiver), selector,
                    buildArguments(arguments)),
                receiverNode),
            null));
  }

  @override
  ir.Expression visitIfNotNullDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, _) {
    return buildNullAwarePropertyAccessor(receiver, name)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, _) {
    return _finishSetIfNull(
        node, buildNullAwarePropertyAccessor(receiver, name), rhs);
  }

  ir.LogicalExpression buildLogicalExpression(
      Node left, Operator operator, Node right) {
    return new ir.LogicalExpression(
        visitForValue(left), operator.source, visitForValue(right));
  }

  @override
  ir.Expression visitIfNull(Send node, Node left, Node right, _) {
    var leftValue = new ir.VariableDeclaration.forValue(visitForValue(left));
    return new ir.Let(
        leftValue,
        new ir.ConditionalExpression(buildIsNull(new ir.VariableGet(leftValue)),
            visitForValue(right), new ir.VariableGet(leftValue), null));
  }

  @override
  ir.Initializer visitImplicitSuperConstructorInvoke(FunctionExpression node,
      ConstructorElement superConstructor, ResolutionInterfaceType type, _) {
    if (superConstructor == null) {
      // TODO(ahe): Semantic visitor shouldn't call this.
      return new ir.InvalidInitializer();
    }
    return new ir.SuperInitializer(
        kernel.functionToIr(superConstructor), new ir.Arguments.empty());
  }

  Accessor buildIndexAccessor(Node receiver, Node index) {
    return IndexAccessor.make(
        visitForValue(receiver), visitForValue(index), null, null);
  }

  @override
  ir.Expression visitIndex(Send node, Node receiver, Node index, _) {
    return associateNode(
        buildIndexAccessor(receiver, index).buildSimpleRead(), node);
  }

  ir.Expression buildIndexPostfix(
      Send node, Accessor accessor, IncDecOperator operator) {
    ir.Name name = kernel.irName(operator.selectorName, currentElement);
    return buildPostfixIncrement(node, accessor, name);
  }

  @override
  ir.Expression visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, _) {
    return buildIndexPostfix(
        node, buildIndexAccessor(receiver, index), operator);
  }

  ir.Expression buildIndexPrefix(
      Send node, Accessor accessor, IncDecOperator operator) {
    ir.Name name = kernel.irName(operator.selectorName, currentElement);
    return buildPrefixIncrement(node, accessor, name);
  }

  @override
  ir.Expression visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, _) {
    return buildIndexPrefix(
        node, buildIndexAccessor(receiver, index), operator);
  }

  @override
  ir.Expression visitIndexSet(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return associateNode(
        buildIndexAccessor(receiver, index)
            .buildAssignment(visitForValue(rhs), voidContext: isVoidContext),
        node);
  }

  ir.Initializer buildInitializingFormal(InitializingFormalElement parameter) {
    FieldElement field = parameter.fieldElement;
    if (kernel.isSyntheticError(field)) {
      return new ir.InvalidInitializer();
    } else {
      return new ir.FieldInitializer(
          kernel.fieldToIr(field), buildLocalGet(parameter));
    }
  }

  @override
  ir.Initializer visitInitializingFormalDeclaration(VariableDefinitions node,
      Node definition, InitializingFormalElement parameter, int index, _) {
    return buildInitializingFormal(parameter);
  }

  @override
  visitInstanceFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, _) {
    // Shouldn't be called, handled by fieldToIr.
    return internalError(node, "InstanceFieldDeclaration");
  }

  @override
  IrFunction visitInstanceGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  @override
  IrFunction visitInstanceSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  @override
  ir.InvocationExpression visitIntFromEnvironmentConstructorInvoke(
      NewExpression node, IntFromEnvironmentConstantExpression constant, _) {
    return associateNode(buildConstructorInvoke(node, isConst: true), node);
  }

  ir.IsExpression buildIs(Node expression, ResolutionDartType type) {
    return new ir.IsExpression(
        visitForValue(expression), kernel.typeToIr(type));
  }

  @override
  ir.IsExpression visitIs(
      Send node, Node expression, ResolutionDartType type, _) {
    return buildIs(expression, type);
  }

  @override
  ir.Not visitIsNot(Send node, Node expression, ResolutionDartType type, _) {
    return new ir.Not(buildIs(expression, type));
  }

  ir.VariableDeclaration buildLocalVariableDeclaration(
      LocalVariableElement variable, Node initializer) {
    ir.Expression initializerNode = visitForValue(initializer);
    ir.VariableDeclaration local = getLocal(variable);
    if (initializer != null) {
      local.initializer = initializerNode;
      initializerNode.parent = local;
    }
    return local;
  }

  @override
  ir.VariableDeclaration visitLocalConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      ConstantExpression constant,
      _) {
    // TODO(ahe): Use [constant]?
    return buildLocalVariableDeclaration(variable, variable.initializer)
      ..isConst = true;
  }

  @override
  ir.FunctionDeclaration visitLocalFunctionDeclaration(FunctionExpression node,
      LocalFunctionElement localFunction, NodeList parameters, Node body, _) {
    return withCurrentElement(localFunction, () {
      ir.VariableDeclaration local = getLocal(localFunction)..isFinal = true;
      ir.FunctionDeclaration function = new ir.FunctionDeclaration(
          local, buildFunctionNode(localFunction, body));
      // Closures can escape their context and we must therefore store them
      // globally to include them in the world computation.
      kernel.localFunctions[localFunction] = function;
      return function;
    });
  }

  @override
  ir.VariableDeclaration visitLocalVariableDeclaration(VariableDefinitions node,
      Node definition, LocalVariableElement variable, Node initializer, _) {
    return buildLocalVariableDeclaration(variable, initializer);
  }

  ir.VariableGet buildLocalGet(LocalElement local) {
    return new ir.VariableGet(getLocal(local));
  }

  @override
  ir.VariableGet handleLocalGet(Send node, LocalElement element, _) {
    return buildLocalGet(element);
  }

  // ignore: MISSING_RETURN
  ir.Expression buildCompound(
      Accessor accessor, CompoundRhs rhs, SendSet node) {
    ir.Name name = kernel.irName(rhs.operator.selectorName, currentElement);
    switch (rhs.kind) {
      case CompoundKind.POSTFIX:
        return buildPostfixIncrement(node, accessor, name);

      case CompoundKind.PREFIX:
        return buildPrefixIncrement(node, accessor, name);

      case CompoundKind.ASSIGNMENT:
        return buildCompoundAssignment(
            node, accessor, name, visitForValue(rhs.rhs));
    }
  }

  ir.Expression buildCompoundAssignment(
      SendSet node, Accessor accessor, ir.Name name, ir.Expression rhs) {
    ir.Expression result =
        accessor.buildCompoundAssignment(name, rhs, voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression buildPrefixIncrement(
      SendSet node, Accessor accessor, ir.Name name) {
    ir.Expression result =
        accessor.buildPrefixIncrement(name, voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  ir.Expression buildPostfixIncrement(
      SendSet node, Accessor accessor, ir.Name name) {
    ir.Expression result =
        accessor.buildPostfixIncrement(name, voidContext: isVoidContext);
    associateCompoundComponents(accessor, node);
    return result;
  }

  void associateCompoundComponents(Accessor accessor, Node node) {
    assert(accessor.builtBinary != null);
    kernel.nodeToAstOperator[accessor.builtBinary] = node;
    if (accessor.builtGetter != null) {
      kernel.nodeToAst[accessor.builtGetter] = node;
    }
  }

  @override
  ir.Expression handleLocalCompounds(
      SendSet node, LocalElement local, CompoundRhs rhs, _,
      {bool isSetterValid}) {
    ir.Expression compound = buildCompound(
        new VariableAccessor(getLocal(local), null, ir.TreeNode.noOffset),
        rhs,
        node);
    if (compound is ir.VariableSet) {
      associateNode(compound.value, node);
    } else {
      associateNode(compound, node);
    }
    return compound;
  }

  @override
  ir.VariableSet handleLocalSet(
      SendSet node, LocalElement element, Node rhs, _) {
    return new ir.VariableSet(getLocal(element), visitForValue(rhs));
  }

  @override
  ir.VariableSet handleImmutableLocalSet(
      SendSet node, LocalElement element, Node rhs, _) {
    // TODO(ahe): Build invalid?
    return handleLocalSet(node, element, rhs, _);
  }

  @override
  ir.LogicalExpression visitLogicalAnd(Send node, Node left, Node right, _) {
    return buildLogicalExpression(left, node.selector, right);
  }

  @override
  ir.LogicalExpression visitLogicalOr(Send node, Node left, Node right, _) {
    return buildLogicalExpression(left, node.selector, right);
  }

  @override
  ir.Initializer visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    return buildInitializingFormal(parameter);
  }

  @override
  visitNamedParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, ConstantExpression defaultValue, _) {
    // Shouldn't be called, we handle parameters via [FunctionSignture].
    return internalError(node, "NamedParameterDeclaration");
  }

  @override
  ir.Not visitNot(Send node, Node expression, _) {
    return new ir.Not(visitForValue(expression));
  }

  @override
  ir.Not visitNotEquals(Send node, Node left, Node right, _) {
    return associateNode(
        new ir.Not(associateNode(buildBinaryOperator(left, '==', right), node)),
        node);
  }

  @override
  ir.Initializer visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return buildInitializingFormal(parameter);
  }

  @override
  visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    // Shouldn't be called, we handle parameters via [FunctionSignture].
    return internalError(node, "OptionalParameterDeclaration");
  }

  @override
  visitParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, int index, _) {
    // Shouldn't be called, we handle parameters via [FunctionSignture].
    return internalError(node, "ParameterDeclaration");
  }

  @override
  ir.MethodInvocation handleLocalInvoke(Send node, LocalElement element,
      NodeList arguments, CallStructure callStructure, _) {
    return associateNode(
        buildCall(buildLocalGet(element), callStructure, arguments), node);
  }

  @override
  ir.Expression handleLocalSetIfNulls(
      SendSet node, LocalElement local, Node rhs, _,
      {bool isSetterValid}) {
    return _finishSetIfNull(node,
        new VariableAccessor(getLocal(local), null, ir.TreeNode.noOffset), rhs);
  }

  @override
  IrFunction visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      ResolutionDartType redirectionType, // TODO(ahe): Should be InterfaceType.
      ConstructorElement redirectionTarget,
      _) {
    if (!constructor.isFactoryConstructor) {
      // TODO(ahe): This seems like a bug in semantic visitor and how it
      // recovers from a bad constructor.
      return new IrFunction.constructor(buildFunctionNode(constructor, null),
          <ir.Initializer>[new ir.InvalidInitializer()]);
    }
    ir.Statement body = null;
    if (kernel.isSyntheticError(redirectionTarget)) {
      body = new ir.InvalidStatement();
    } else {
      // TODO(ahe): This should be implemented, but doesn't matter much unless
      // we support reflection. At the call-site, we bypass this factory and
      // call its effective target directly. So this factory is only necessary
      // for reflection.
      body = new ir.InvalidStatement();
    }
    IrFunction function =
        buildIrFunction(ir.ProcedureKind.Factory, constructor, null);
    function.node.body = body..parent = function.node;
    return function;
  }

  @override
  ir.InvocationExpression visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildConstructorInvoke(node, isConst: false);
  }

  @override
  IrFunction visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    return buildGenerativeConstructor(constructor, parameters, null);
  }

  @override
  ir.InvocationExpression visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildConstructorInvoke(node, isConst: false);
  }

  @override
  visitStaticConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, _) {
    // Shouldn't be called, handled by fieldToIr.
    return internalError(node, "StaticConstantDeclaration");
  }

  @override
  visitStaticFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, _) {
    // Shouldn't be called, handled by fieldToIr.
    return internalError(node, "StaticFieldDeclaration");
  }

  ir.Expression buildStaticGet(Element element) {
    var loadedCheckFunc =
        _createCheckLibraryLoadedFuncIfNeeded(_deferredLibrary);
    _deferredLibrary = null;
    return loadedCheckFunc(buildStaticAccessor(element).buildSimpleRead());
  }

  @override
  ir.Expression handleStaticFieldGet(Send node, FieldElement field, _) {
    return associateNode(buildStaticGet(field), node);
  }

  @override
  ir.MethodInvocation handleStaticFieldInvoke(Send node, FieldElement field,
      NodeList arguments, CallStructure callStructure, _) {
    return associateNode(
        buildCall(buildStaticGet(field), callStructure, arguments), node);
  }

  @override
  ir.Expression handleStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildStaticFieldSet(field, rhs);
  }

  @override
  ir.Expression handleStaticSetIfNulls(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      Node rhs,
      _) {
    if (setterKind == CompoundSetter.INVALID) {
      setter = null;
    }
    return _finishSetIfNull(node, buildStaticAccessor(getter, setter), rhs);
  }

  ir.VariableDeclaration getLocal(LocalElement local) {
    return locals.putIfAbsent(local, () {
      // Currently, initializing formals are not final.
      bool isFinal = local.isFinal && !local.isInitializingFormal;
      return associateElement(
          new ir.VariableDeclaration(local.name,
              initializer: null,
              type: typeToIrHack(local.type),
              isFinal: isFinal,
              isConst: local.isConst),
          local);
    });
  }

  ir.FunctionNode buildFunctionNode(FunctionElement function, Node bodyNode) {
    List<ir.TypeParameter> typeParameters = <ir.TypeParameter>[];
    List<ir.VariableDeclaration> positionalParameters =
        <ir.VariableDeclaration>[];
    List<ir.VariableDeclaration> namedParameters = <ir.VariableDeclaration>[];
    int requiredParameterCount = 0;
    ir.DartType returnType = const ir.DynamicType();
    if (function.hasFunctionSignature) {
      FunctionSignature signature = function.functionSignature;
      requiredParameterCount = signature.requiredParameterCount;
      signature.forEachParameter((ParameterElement parameter) {
        ir.VariableDeclaration variable = getLocal(parameter);
        if (parameter.isNamed) {
          namedParameters.add(variable);
        } else {
          positionalParameters.add(variable);
        }
      });
      signature.forEachParameter((ParameterElement parameter) {
        if (!parameter.isOptional) return;
        ir.Expression initializer = visitForValue(parameter.initializer);
        ir.VariableDeclaration variable = getLocal(parameter);
        if (initializer != null) {
          variable.initializer = initializer;
          initializer.parent = variable;
          kernel.parameterInitializerNodeToConstant[initializer] =
              parameter.constant;
        }
      });
      if (function.isGenerativeConstructor) {
        returnType = const ir.VoidType();
      } else {
        returnType = typeToIrHack(signature.type.returnType);
      }
      if (function.isFactoryConstructor) {
        ResolutionInterfaceType type = function.enclosingClass.thisType;
        if (type.isGeneric) {
          typeParameters = new List<ir.TypeParameter>();
          for (ResolutionDartType parameter in type.typeArguments) {
            typeParameters.add(kernel.typeVariableToIr(parameter.element));
          }
        }
      }
    }
    ir.AsyncMarker asyncMarker = ir.AsyncMarker.Sync;
    if (!kernel.isSyntheticError(function)) {
      switch (function.asyncMarker) {
        case AsyncMarker.SYNC:
          asyncMarker = ir.AsyncMarker.Sync;
          break;

        case AsyncMarker.SYNC_STAR:
          asyncMarker = ir.AsyncMarker.SyncStar;
          break;

        case AsyncMarker.ASYNC:
          asyncMarker = ir.AsyncMarker.Async;
          break;

        case AsyncMarker.ASYNC_STAR:
          asyncMarker = ir.AsyncMarker.AsyncStar;
          break;

        default:
          internalError(
              function, "Unknown async maker: ${function.asyncMarker}");
          break;
      }
    }
    ir.Statement body;
    if (function.isExternal) {
      // [body] must be `null`.
    } else if (function.isConstructor) {
      // TODO(johnniwinther): Clean this up pending kernel issue #28.
      if (bodyNode == null || bodyNode.asEmptyStatement() != null) {
        body = new ir.EmptyStatement();
      } else {
        body = buildStatementInBlock(bodyNode);
      }
    } else if (bodyNode != null) {
      Return returnStatement = bodyNode.asReturn();
      if ((function.isSetter || function.name == Names.INDEX_SET_NAME.text) &&
          returnStatement != null) {
        // Avoid encoding the implicit return of setters with arrow body:
        //    set setter(value) => this.value = value;
        //    operator []=(index, value) => this[index] = value;
        body = new ir.ExpressionStatement(
            visitForEffect(returnStatement.expression));
      } else {
        body = buildStatementInBlock(bodyNode);
      }
    }
    return associateElement(
        new ir.FunctionNode(body,
            asyncMarker: asyncMarker,
            returnType: returnType,
            typeParameters: typeParameters,
            positionalParameters: positionalParameters,
            namedParameters: namedParameters,
            requiredParameterCount: requiredParameterCount),
        function);
  }

  @override
  IrFunction visitStaticFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Method, function, body);
  }

  ir.ProcedureKind computeInstanceMethodKind(MethodElement method) {
    assert(method.isFunction);
    return method.isOperator
        ? ir.ProcedureKind.Operator
        : ir.ProcedureKind.Method;
  }

  @override
  IrFunction visitInstanceMethodDeclaration(FunctionExpression node,
      MethodElement method, NodeList parameters, Node body, _) {
    return buildIrFunction(
        computeInstanceMethodKind(currentElement), currentElement, body);
  }

  @override
  IrFunction visitAbstractMethodDeclaration(
      FunctionExpression node, MethodElement method, NodeList parameters, _) {
    return buildIrFunction(
        computeInstanceMethodKind(currentElement), currentElement, null);
  }

  @override
  ir.Expression handleStaticFunctionGet(Send node, MethodElement function, _) {
    return buildStaticGet(function);
  }

  @override
  ir.Expression handleStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    if (!kernel.compiler.resolution.hasBeenResolved(function) &&
        !function.isMalformed) {
      // TODO(sigmund): consider calling nSM or handle recovery differently
      // here. This case occurs only when this call was the only call to
      // function, and knowing that the call was erroneous, our resolver didn't
      // enqueue function itself.
      return new ir.InvalidExpression();
    }
    return buildStaticInvoke(function, arguments, isConst: false);
  }

  ir.StaticInvocation buildStaticInvoke(
      FunctionElement function, NodeList arguments,
      {bool isConst}) {
    ir.Arguments argumentsNode = buildArguments(arguments);
    return new ir.StaticInvocation(kernel.functionToIr(function), argumentsNode,
        isConst: isConst);
  }

  @override
  ir.Expression handleStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, _) {
    var loadedCheckFunc =
        _createCheckLibraryLoadedFuncIfNeeded(_deferredLibrary);
    _deferredLibrary = null;
    return loadedCheckFunc(associateNode(
        buildStaticInvoke(function, arguments, isConst: false), node));
  }

  @override
  ir.Expression handleStaticFunctionSet(
      Send node, MethodElement function, Node rhs, _) {
    return buildStaticAccessor(function)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  IrFunction visitStaticGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  ir.LibraryDependency getDeferredImport(PrefixElement prefix) {
    var map = deferredImports[prefix.deferredImport.importedLibrary] ??=
        <String, ir.LibraryDependency>{};
    return map[prefix.name] ??= associateElement(
        new ir.LibraryDependency.deferredImport(
            kernel.libraries[prefix.deferredImport.importedLibrary],
            prefix.name),
        prefix);
  }

  @override
  ir.Expression handleStaticGetterGet(Send node, FunctionElement getter, _) {
    if (getter.isDeferredLoaderGetter) {
      return new ir.LoadLibrary(getDeferredImport(getter.enclosingElement));
    }
    var expression = buildStaticGet(getter);
    return expression;
  }

  @override
  ir.Expression handleStaticGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, _) {
    var expression;
    if (getter.isDeferredLoaderGetter) {
      expression =
          new ir.LoadLibrary(getDeferredImport(getter.enclosingElement));
    } else {
      expression = buildStaticGet(getter);
    }
    return associateNode(buildCall(expression, callStructure, arguments), node);
  }

  @override
  ir.Expression handleStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return buildStaticAccessor(getter)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  IrFunction visitStaticSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  @override
  ir.Expression handleStaticSetterGet(Send node, FunctionElement setter, _) {
    return buildStaticAccessor(null, setter).buildSimpleRead();
  }

  @override
  ir.Expression handleStaticSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, _) {
    return new ir.InvalidExpression();
  }

  @override
  ir.Expression handleStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return buildStaticAccessor(null, setter)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.InvocationExpression visitStringFromEnvironmentConstructorInvoke(
      NewExpression node, StringFromEnvironmentConstantExpression constant, _) {
    return associateNode(buildConstructorInvoke(node, isConst: true), node);
  }

  @override
  ir.SuperMethodInvocation visitSuperBinary(Send node, FunctionElement function,
      BinaryOperator operator, Node argument, _) {
    transformerFlags |= TransformerFlag.superCalls;
    return new ir.SuperMethodInvocation(
        kernel.irName(operator.selectorName, currentElement),
        new ir.Arguments(<ir.Expression>[visitForValue(argument)]),
        kernel.functionToIr(function));
  }

  @override
  ir.Expression visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildCompoundAssignment(
        node,
        buildSuperIndexAccessor(index, getter, setter),
        kernel.irName(operator.selectorName, currentElement),
        visitForValue(rhs));
  }

  @override
  ir.Initializer visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    if (kernel.isSyntheticError(superConstructor)) {
      // TODO(ahe): Semantic visitor shouldn't call in this case.
      return new ir.InvalidInitializer();
    }
    return new ir.SuperInitializer(
        kernel.functionToIr(superConstructor), buildArguments(arguments));
  }

  ir.SuperMethodInvocation buildSuperEquals(
      FunctionElement function, Node argument) {
    transformerFlags |= TransformerFlag.superCalls;
    return new ir.SuperMethodInvocation(
        kernel.irName(function.name, function),
        new ir.Arguments(<ir.Expression>[visitForValue(argument)],
            types: null, named: null),
        kernel.functionToIr(function));
  }

  @override
  ir.SuperMethodInvocation visitSuperEquals(
      Send node, FunctionElement function, Node argument, _) {
    return buildSuperEquals(function, argument);
  }

  @override
  ir.Expression handleSuperCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    if (setterKind == CompoundSetter.INVALID) {
      setter = null;
    }
    return buildCompound(buildSuperPropertyAccessor(getter, setter), rhs, node);
  }

  @override
  ir.Expression handleStaticCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    if (setterKind == CompoundSetter.INVALID) {
      setter = null;
    }
    return buildCompound(buildStaticAccessor(getter, setter), rhs, node);
  }

  @override
  ir.Expression handleTypeLiteralConstantCompounds(
      SendSet node, ConstantExpression constant, CompoundRhs rhs, _) {
    return buildCompound(
        new ReadOnlyAccessor(buildTypeLiteral(constant), ir.TreeNode.noOffset),
        rhs,
        node);
  }

  ir.TypeLiteral buildTypeVariable(TypeVariableElement element) {
    return new ir.TypeLiteral(kernel.typeToIr(element.type));
  }

  @override
  ir.Expression handleTypeVariableTypeLiteralCompounds(
      SendSet node, TypeVariableElement element, CompoundRhs rhs, _) {
    return buildCompound(
        new ReadOnlyAccessor(buildTypeVariable(element), ir.TreeNode.noOffset),
        rhs,
        node);
  }

  @override
  ir.SuperPropertyGet visitSuperFieldGet(Send node, FieldElement field, _) {
    return buildSuperPropertyAccessor(field).buildSimpleRead();
  }

  @override
  ir.MethodInvocation visitSuperFieldInvoke(Send node, FieldElement field,
      NodeList arguments, CallStructure callStructure, _) {
    return buildCall(buildSuperPropertyAccessor(field).buildSimpleRead(),
        callStructure, arguments);
  }

  @override
  ir.Expression visitSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildSuperPropertyAccessor(field)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  Accessor buildSuperPropertyAccessor(Element getter, [Element setter]) {
    transformerFlags |= TransformerFlag.superCalls;
    if (setter == null &&
        getter.isField &&
        !getter.isFinal &&
        !getter.isConst) {
      setter = getter;
    }
    Element element = getter ?? setter;
    return new SuperPropertyAccessor(
        kernel.irName(element.name, element),
        (getter == null) ? null : kernel.elementToIr(getter),
        (setter == null) ? null : kernel.elementToIr(setter),
        ir.TreeNode.noOffset);
  }

  Accessor buildSuperIndexAccessor(Expression index, Element getter,
      [Element setter]) {
    if (setter == null &&
        getter.isField &&
        !getter.isFinal &&
        !getter.isConst) {
      setter = getter;
    }
    return new SuperIndexAccessor(
        visitForValue(index),
        (getter == null) ? null : kernel.elementToIr(getter),
        (setter == null) ? null : kernel.elementToIr(setter),
        ir.TreeNode.noOffset);
  }

  @override
  ir.SuperPropertyGet visitSuperGetterGet(
      Send node, FunctionElement getter, _) {
    return buildSuperPropertyAccessor(getter).buildSimpleRead();
  }

  @override
  ir.MethodInvocation visitSuperGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, _) {
    return buildCall(buildSuperPropertyAccessor(getter).buildSimpleRead(),
        callStructure, arguments);
  }

  @override
  ir.Expression visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return buildSuperPropertyAccessor(getter)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression handleSuperSetIfNulls(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      Node rhs,
      _) {
    if (setterKind == CompoundSetter.INVALID) {
      setter = null;
    }
    return _finishSetIfNull(
        node, buildSuperPropertyAccessor(getter, setter), rhs);
  }

  @override
  ir.SuperMethodInvocation visitSuperIndex(
      Send node, FunctionElement function, Node index, _) {
    return buildSuperIndexAccessor(index, function).buildSimpleRead();
  }

  @override
  ir.Expression visitSuperIndexPostfix(Send node, MethodElement indexFunction,
      MethodElement indexSetFunction, Node index, IncDecOperator operator, _) {
    Accessor accessor =
        buildSuperIndexAccessor(index, indexFunction, indexSetFunction);
    return buildIndexPostfix(node, accessor, operator);
  }

  @override
  ir.Expression visitSuperIndexPrefix(Send node, MethodElement indexFunction,
      MethodElement indexSetFunction, Node index, IncDecOperator operator, _) {
    Accessor accessor =
        buildSuperIndexAccessor(index, indexFunction, indexSetFunction);
    return buildIndexPrefix(node, accessor, operator);
  }

  @override
  ir.Expression visitSuperIndexSet(
      SendSet node, FunctionElement function, Node index, Node rhs, _) {
    return buildSuperIndexAccessor(index, null, function)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression visitSuperMethodGet(Send node, MethodElement method, _) {
    return buildSuperPropertyAccessor(method).buildSimpleRead();
  }

  ir.SuperMethodInvocation buildSuperMethodInvoke(
      MethodElement method, NodeList arguments) {
    transformerFlags |= TransformerFlag.superCalls;
    return new ir.SuperMethodInvocation(kernel.irName(method.name, method),
        buildArguments(arguments), kernel.functionToIr(method));
  }

  @override
  ir.SuperMethodInvocation visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildSuperMethodInvoke(method, arguments);
  }

  @override
  ir.SuperMethodInvocation visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return associateNode(buildSuperMethodInvoke(method, arguments), node);
  }

  @override
  ir.Expression visitSuperMethodSet(
      Send node, MethodElement method, Node rhs, _) {
    return buildSuperPropertyAccessor(method)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Not visitSuperNotEquals(
      Send node, FunctionElement function, Node argument, _) {
    return new ir.Not(buildSuperEquals(function, argument));
  }

  @override
  ir.Expression visitSuperSetterGet(Send node, FunctionElement setter, _) {
    return buildSuperPropertyAccessor(null, setter).buildSimpleRead();
  }

  @override
  ir.MethodInvocation visitSuperSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, _) {
    return buildCall(buildSuperPropertyAccessor(null, setter).buildSimpleRead(),
        callStructure, arguments);
  }

  @override
  ir.Expression visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return buildSuperPropertyAccessor(null, setter)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.SuperMethodInvocation visitSuperUnary(
      Send node, UnaryOperator operator, FunctionElement function, _) {
    transformerFlags |= TransformerFlag.superCalls;
    return new ir.SuperMethodInvocation(kernel.irName(function.name, function),
        new ir.Arguments.empty(), kernel.functionToIr(function));
  }

  @override
  ir.Initializer visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    if (kernel.isSyntheticError(thisConstructor)) {
      return new ir.InvalidInitializer();
    } else {
      return new ir.RedirectingInitializer(
          kernel.functionToIr(thisConstructor), buildArguments(arguments));
    }
  }

  @override
  ir.ThisExpression visitThisGet(Identifier node, _) {
    return new ir.ThisExpression();
  }

  @override
  ir.MethodInvocation visitThisInvoke(
      Send node, NodeList arguments, CallStructure callStructure, _) {
    return associateNode(
        buildCall(new ir.ThisExpression(), callStructure, arguments), node);
  }

  Accessor buildThisPropertyAccessor(Name name) {
    return new ThisPropertyAccessor(
        nameToIrName(name), null, null, ir.TreeNode.noOffset);
  }

  @override
  ir.Expression visitThisPropertyGet(Send node, Name name, _) {
    return associateNode(
        buildThisPropertyAccessor(name).buildSimpleRead(), node);
  }

  @override
  ir.MethodInvocation visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, _) {
    return associateNode(
        buildInvokeSelector(
            new ir.ThisExpression(), selector, buildArguments(arguments)),
        node);
  }

  @override
  ir.Expression visitThisPropertySet(SendSet node, Name name, Node rhs, _) {
    return buildThisPropertyAccessor(name)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression visitTopLevelConstantDeclaration(VariableDefinitions node,
      Node definition, FieldElement field, ConstantExpression constant, _) {
    // Shouldn't be called, handled by fieldToIr.
    return internalError(node, "TopLevelFieldDeclaration");
  }

  @override
  ir.Expression visitTopLevelFieldDeclaration(VariableDefinitions node,
      Node definition, FieldElement field, Node initializer, _) {
    // Shouldn't be called, handled by fieldToIr.
    return internalError(node, "TopLevelFieldDeclaration");
  }

  @override
  IrFunction visitTopLevelFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Method, function, body);
  }

  ir.Arguments buildArguments(NodeList arguments) {
    List<ir.Expression> positional = <ir.Expression>[];
    List<ir.NamedExpression> named = <ir.NamedExpression>[];
    for (Expression expression in arguments.nodes) {
      ir.TreeNode argument = visitForValue(expression);
      if (argument is ir.NamedExpression) {
        named.add(argument);
      } else {
        positional.add(argument);
      }
    }
    return new ir.Arguments(positional, named: named, types: null);
  }

  @override
  IrFunction visitTopLevelGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  @override
  IrFunction visitTopLevelSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  /// Return a function that accepts an expression and returns an expression. If
  /// deferredImport is null, then the function returned is the identity
  /// expression. Otherwise, it inserts a CheckLibraryIsLoaded call before
  /// evaluating the expression.
  _createCheckLibraryLoadedFuncIfNeeded(ir.LibraryDependency deferredImport) {
    if (deferredImport != null) {
      return (ir.Expression inputExpression) => new ir.Let(
          makeOrReuseVariable(new ir.CheckLibraryIsLoaded(deferredImport)),
          inputExpression);
    } else {
      return (ir.Expression expr) => expr;
    }
  }

  @override
  ir.Expression visitTypeVariableTypeLiteralGet(
      Send node, TypeVariableElement element, _) {
    var loadedCheckFunc =
        _createCheckLibraryLoadedFuncIfNeeded(_deferredLibrary);
    _deferredLibrary = null;
    return loadedCheckFunc(buildTypeVariable(element));
  }

  @override
  ir.MethodInvocation visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return associateNode(
        buildCall(buildTypeVariable(element), callStructure, arguments), node);
  }

  @override
  ir.Expression visitTypeVariableTypeLiteralSet(
      SendSet node, TypeVariableElement element, Node rhs, _) {
    return new ReadOnlyAccessor(
            buildTypeVariable(element), ir.TreeNode.noOffset)
        .buildAssignment(visitForValue(rhs), voidContext: isVoidContext);
  }

  @override
  ir.Expression visitTypeVariableTypeLiteralSetIfNull(
      Send node, TypeVariableElement element, Node rhs, _) {
    return _finishSetIfNull(
        node,
        new ReadOnlyAccessor(buildTypeVariable(element), ir.TreeNode.noOffset),
        rhs);
  }

  @override
  ir.Expression visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    var loadedCheckFunc =
        _createCheckLibraryLoadedFuncIfNeeded(_deferredLibrary);
    _deferredLibrary = null;
    return loadedCheckFunc(buildTypeLiteral(constant));
  }

  @override
  ir.MethodInvocation visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return associateNode(
        buildCall(buildTypeLiteral(constant), callStructure, arguments), node);
  }

  @override
  ir.Expression visitTypedefTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, _) {
    return buildTypeLiteralSet(constant, rhs);
  }

  @override
  ir.Expression handleTypeLiteralConstantSetIfNulls(
      SendSet node, ConstantExpression constant, Node rhs, _) {
    // Degenerate case: ignores [rhs] as a type literal is never null.
    return buildTypeLiteral(constant);
  }

  @override
  ir.MethodInvocation visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return associateNode(
        new ir.MethodInvocation(
            visitForValue(expression),
            kernel.irName(operator.selectorName, currentElement),
            new ir.Arguments.empty()),
        node);
  }

  @override
  visitConditionalUri(ConditionalUri node) {
    // Shouldn't be called, handled by library loader.
    return internalError(node, "ConditionalUri");
  }

  @override
  visitDottedName(DottedName node) {
    // Shouldn't be called, handled by library loader.
    return internalError(node, "DottedName");
  }

  @override
  visitForIn(ForIn node) {
    // Shouldn't be called, handled by [visitAsyncForIn] or [visitSyncForIn].
    return internalError(node, "ForIn");
  }

  @override
  ir.Expression visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return _finishSetIfNull(node, buildIndexAccessor(receiver, index), rhs);
  }

  @override
  ir.Expression visitSuperIndexSetIfNull(SendSet node, MethodElement getter,
      MethodElement setter, Node index, Node rhs, _) {
    return _finishSetIfNull(
        node, buildSuperIndexAccessor(index, getter, setter), rhs);
  }

  @override
  // ignore: INVALID_METHOD_OVERRIDE_RETURN_TYPE
  ir.Node visitVariableDefinitions(VariableDefinitions definitions) {
    // TODO(ahe): This method is copied from [SemanticDeclarationResolvedMixin]
    // and modified. Perhaps we can find a way to avoid code duplication.
    List<ir.VariableDeclaration> variables = <ir.VariableDeclaration>[];
    computeVariableStructures(definitions,
        (Node node, VariableStructure structure) {
      if (structure == null) {
        return internalError(node, 'No structure for $node');
      } else {
        ir.VariableDeclaration variable =
            structure.dispatch(declVisitor, node, null);
        variables.add(variable);
        return variable;
      }
    });
    if (variables.length == 1) return variables.single;
    return new VariableDeclarations(variables);
  }

  IrFunction buildFunction() {
    return kernel.compiler.reporter.withCurrentElement(currentElement, () {
      if (kernel.isSyntheticError(currentElement)) {
        kernel.internalError(currentElement,
            "Can't build synthetic function element: $currentElement");
      } else if (currentElement.isMalformed) {
        ir.FunctionNode node = buildFunctionNode(currentElement, null);
        if (currentElement.isGenerativeConstructor) {
          return new IrFunction.constructor(
              node, <ir.Initializer>[new ir.InvalidInitializer()]);
        } else {
          node.body = new ir.InvalidStatement()..parent = node;
          return new IrFunction.procedure(ir.ProcedureKind.Method, node);
        }
      } else if (currentElement.isSynthesized) {
        if (currentElement.isGenerativeConstructor) {
          return buildGenerativeConstructor(currentElement, null, null);
        } else {
          return internalError(currentElement, "Unhandled synthetic function.");
        }
      } else {
        Node node = currentElement.node;
        if (node.isErroneous) {
          return internalError(currentElement, "Unexpected syntax error.");
        } else {
          return node.accept(this);
        }
      }
    });
  }

  ir.Expression buildInitializer() {
    return kernel.compiler.reporter.withCurrentElement(currentElement, () {
      FieldElement field = currentElement;
      return field.isMalformed
          ? new ir.InvalidExpression()
          : associateNode(visitForValue(field.initializer), field.initializer);
    });
  }
}

class VariableDeclarations implements ir.Node {
  final List<ir.VariableDeclaration> variables;

  VariableDeclarations(this.variables);

  accept(ir.Visitor v) => throw "unsupported";

  visitChildren(ir.Visitor v) => throw "unsupported";

  String toString() => "VariableDeclarations($variables)";
}

class IrFunction implements ir.Node {
  final ir.ProcedureKind kind;
  final bool isConstructor;
  final ir.FunctionNode node;
  final List<ir.Initializer> initializers;

  IrFunction(this.kind, this.isConstructor, this.node, this.initializers);

  IrFunction.procedure(ir.ProcedureKind kind, ir.FunctionNode node)
      : this(kind, false, node, null);

  IrFunction.constructor(
      ir.FunctionNode node, List<ir.Initializer> initializers)
      : this(null, true, node, initializers);

  accept(ir.Visitor v) => throw "unsupported";

  visitChildren(ir.Visitor v) => throw "unsupported";

  String toString() {
    return "IrFunction($kind, $isConstructor, $node, $initializers)";
  }
}
