// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_types_inferrer;

import '../closure.dart' show ClosureRepresentationInfo;
import '../common.dart';
import '../common/names.dart' show Identifiers, Selectors;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart' show ConstantValue, IntConstantValue;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/operators.dart' as op;
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../native/native.dart' as native;
import '../resolution/semantic_visitor.dart';
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart' as ast;
import '../types/constants.dart' show computeTypeMask;
import '../types/types.dart' show TypeMask, GlobalTypeInferenceElementData;
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/side_effects.dart' show SideEffects;
import '../util/util.dart' show Link, Setlet;
import '../world.dart' show ClosedWorld;
import 'inferrer_engine.dart';
import 'locals_handler.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

/// [ElementGraphBuilder] can be thought of as a type-inference graph
/// builder for a single element.
///
/// Calling [run] will start the work of visiting the body of the code to
/// construct a set of infernece-nodes that abstractly represent what the code
/// is doing.
///
/// This visitor is parameterized by an [InferenceEngine], which internally
/// decides how to represent inference nodes.
class ElementGraphBuilder extends ast.Visitor<TypeInformation>
    with
        SemanticSendResolvedMixin<TypeInformation, dynamic>,
        CompoundBulkMixin<TypeInformation, dynamic>,
        SetIfNullBulkMixin<TypeInformation, dynamic>,
        PrefixBulkMixin<TypeInformation, dynamic>,
        PostfixBulkMixin<TypeInformation, dynamic>,
        ErrorBulkMixin<TypeInformation, dynamic>,
        NewBulkMixin<TypeInformation, dynamic>,
        SetBulkMixin<TypeInformation, dynamic>
    implements SemanticSendVisitor<TypeInformation, dynamic> {
  final Compiler compiler;
  final AstElement analyzedElement;
  final ResolvedAst resolvedAst;
  final TypeSystem types;
  final Map<JumpTarget, List<LocalsHandler>> breaksFor =
      new Map<JumpTarget, List<LocalsHandler>>();
  final Map<JumpTarget, List<LocalsHandler>> continuesFor =
      new Map<JumpTarget, List<LocalsHandler>>();
  LocalsHandler locals;
  final List<TypeInformation> cascadeReceiverStack =
      new List<TypeInformation>();

  TypeInformation returnType;
  bool visitingInitializers = false;
  bool isConstructorRedirect = false;
  bool seenSuperConstructorCall = false;
  SideEffects sideEffects = new SideEffects.empty();
  final Element outermostElement;
  final InferrerEngine inferrer;
  final Setlet<Entity> capturedVariables = new Setlet<Entity>();
  final GlobalTypeInferenceElementData inTreeData;

  ElementGraphBuilder.internal(
      AstElement analyzedElement,
      this.resolvedAst,
      this.outermostElement,
      InferrerEngine inferrer,
      this.compiler,
      this.locals)
      : this.analyzedElement = analyzedElement,
        this.inferrer = inferrer,
        this.types = inferrer.types,
        this.inTreeData = inferrer.dataOf(analyzedElement) {
    assert(outermostElement != null);
    if (locals != null) return;
    ast.Node node;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      node = resolvedAst.node;
    }
    FieldInitializationScope fieldScope =
        analyzedElement.isGenerativeConstructor
            ? new FieldInitializationScope(types)
            : null;
    locals =
        new LocalsHandler(inferrer, types, compiler.options, node, fieldScope);
  }

  ElementGraphBuilder(Element element, ResolvedAst resolvedAst,
      Compiler compiler, InferrerEngine inferrer, [LocalsHandler handler])
      : this.internal(
            element,
            resolvedAst,
            element.outermostEnclosingMemberOrTopLevel.implementation,
            inferrer,
            compiler,
            handler);

  TreeElements get elements => resolvedAst.elements;

  bool accumulateIsChecks = false;
  bool conditionIsSimple = false;
  List<ast.Send> isChecks;
  int loopLevel = 0;

  bool get inLoop => loopLevel > 0;
  bool get isThisExposed {
    return analyzedElement.isGenerativeConstructor
        ? locals.fieldScope.isThisExposed
        : true;
  }

  void set isThisExposed(value) {
    if (analyzedElement.isGenerativeConstructor) {
      locals.fieldScope.isThisExposed = value;
    }
  }

  void initializationIsIndefinite() {
    if (analyzedElement.isGenerativeConstructor) {
      locals.fieldScope.isIndefinite = true;
    }
  }

  DiagnosticReporter get reporter => compiler.reporter;

  ClosedWorld get closedWorld => inferrer.closedWorld;

  @override
  SemanticSendVisitor get sendVisitor => this;

  @override
  TypeInformation apply(ast.Node node, _) => visit(node);

  TypeInformation visitAssert(ast.Assert node) {
    // Avoid pollution from assert statement unless enabled.
    if (!compiler.options.enableUserAssertions) {
      return null;
    }
    List<ast.Send> tests = <ast.Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node);
    updateIsChecks(tests, usePositive: true);

    LocalsHandler thenLocals = locals;
    locals = new LocalsHandler.from(saved, node);
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.message);
    locals.seenReturnOrThrow = true;
    saved.mergeDiamondFlow(thenLocals, locals);
    locals = saved;
    return null;
  }

  @override
  TypeInformation bulkHandleSet(ast.SendSet node, _) {
    return handleSendSet(node);
  }

  @override
  TypeInformation bulkHandleCompound(ast.SendSet node, _) {
    return handleSendSet(node);
  }

  @override
  TypeInformation bulkHandleSetIfNull(ast.SendSet node, _) {
    return handleSendSet(node);
  }

  @override
  TypeInformation bulkHandlePrefix(ast.SendSet node, _) {
    return handleSendSet(node);
  }

  @override
  TypeInformation bulkHandlePostfix(ast.SendSet node, _) {
    return handleSendSet(node);
  }

  @override
  TypeInformation bulkHandleError(ast.Node node, ErroneousElement error, _) {
    return types.dynamicType;
  }

  TypeInformation visitNode(ast.Node node) {
    return node.visitChildren(this);
  }

  TypeInformation visit(ast.Node node) {
    return node == null ? null : node.accept(this);
  }

  TypeInformation visitLiteralString(ast.LiteralString node) {
    return types.stringLiteralType(node.dartString.slowToString());
  }

  TypeInformation visitStringJuxtaposition(ast.StringJuxtaposition node) {
    node.visitChildren(this);
    return types.stringType;
  }

  TypeInformation visitLiteralBool(ast.LiteralBool node) {
    return types.boolLiteralType(node.value);
  }

  TypeInformation visitLiteralDouble(ast.LiteralDouble node) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    // The JavaScript backend may turn this literal into an integer at
    // runtime.
    return types.getConcreteTypeFor(
        computeTypeMask(closedWorld, constantSystem.createDouble(node.value)));
  }

  TypeInformation visitLiteralInt(ast.LiteralInt node) {
    ConstantSystem constantSystem = compiler.backend.constantSystem;
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return types.getConcreteTypeFor(
        computeTypeMask(closedWorld, constantSystem.createInt(node.value)));
  }

  TypeInformation visitLiteralNull(ast.LiteralNull node) {
    return types.nullType;
  }

  TypeInformation visitLiteralSymbol(ast.LiteralSymbol node) {
    // TODO(kasperl): We should be able to tell that the type of a literal
    // symbol is always a non-null exact symbol implementation -- not just
    // any non-null subtype of the symbol interface.
    return types
        .nonNullSubtype(closedWorld.commonElements.symbolImplementationClass);
  }

  @override
  void previsitDeferredAccess(ast.Send node, PrefixElement prefix, _) {
    // Deferred access does not affect inference.
  }

  TypeInformation handleTypeLiteralGet() {
    return types.typeType;
  }

  @override
  TypeInformation bulkHandleNode(ast.Node node, String message, _) {
    return internalError(node, message.replaceAll('#', '$node'));
  }

  @override
  TypeInformation visitConstantGet(
      ast.Send node, ConstantExpression constant, _) {
    return bulkHandleNode(node, "Constant read `#` unhandled.", _);
  }

  @override
  TypeInformation visitConstantInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return bulkHandleNode(node, "Constant invoke `#` unhandled.", _);
  }

  TypeInformation visitClassTypeLiteralGet(
      ast.Send node, ConstantExpression constant, _) {
    return handleTypeLiteralGet();
  }

  TypeInformation visitClassTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleTypeLiteralInvoke(arguments);
  }

  TypeInformation visitTypedefTypeLiteralGet(
      ast.Send node, ConstantExpression constant, _) {
    return handleTypeLiteralGet();
  }

  TypeInformation visitTypedefTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleTypeLiteralInvoke(arguments);
  }

  TypeInformation visitTypeVariableTypeLiteralGet(
      ast.Send node, TypeVariableElement element, _) {
    return handleTypeLiteralGet();
  }

  TypeInformation visitTypeVariableTypeLiteralInvoke(
      ast.Send node,
      TypeVariableElement element,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleTypeLiteralInvoke(arguments);
  }

  TypeInformation visitDynamicTypeLiteralGet(
      ast.Send node, ConstantExpression constant, _) {
    return handleTypeLiteralGet();
  }

  TypeInformation visitDynamicTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleTypeLiteralInvoke(arguments);
  }

  TypeInformation _thisType;
  TypeInformation get thisType {
    if (_thisType != null) return _thisType;
    ClassElement cls = outermostElement.enclosingClass;
    if (closedWorld.isUsedAsMixin(cls)) {
      return _thisType = types.nonNullSubtype(cls);
    } else {
      return _thisType = types.nonNullSubclass(cls);
    }
  }

  @override
  TypeInformation visitThisGet(ast.Identifier node, _) {
    return thisType;
  }

  TypeInformation visitIdentifier(ast.Identifier node) {
    if (node.isThis()) {
      return thisType;
    } else if (node.isSuper()) {
      return internalError(node, 'Unexpected expression $node.');
    } else {
      Element element = elements[node];
      if (Elements.isLocal(element)) {
        LocalElement local = element;
        return locals.use(local);
      }
      return null;
    }
  }

  void potentiallyAddIsCheck(ast.Send node) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[node.receiver])) return;
    isChecks.add(node);
  }

  void potentiallyAddNullCheck(ast.Send node, ast.Node receiver) {
    if (!accumulateIsChecks) return;
    if (!Elements.isLocal(elements[receiver])) return;
    isChecks.add(node);
  }

  void updateIsChecks(List<ast.Node> tests, {bool usePositive}) {
    void narrow(Element element, ResolutionDartType type, ast.Node node) {
      if (element is LocalElement) {
        TypeInformation existing = locals.use(element);
        TypeInformation newType =
            types.narrowType(existing, type, isNullable: false);
        locals.update(element, newType, node);
      }
    }

    if (tests == null) return;
    for (ast.Send node in tests) {
      if (node.isTypeTest) {
        if (node.isIsNotCheck) {
          if (usePositive) continue;
        } else {
          if (!usePositive) continue;
        }
        ResolutionDartType type =
            elements.getType(node.typeAnnotationFromIsCheckOrCast);
        narrow(elements[node.receiver], type, node);
      } else {
        Element receiverElement = elements[node.receiver];
        Element argumentElement = elements[node.arguments.first];
        String operator = node.selector.asOperator().source;
        if ((operator == '==' && usePositive) ||
            (operator == '!=' && !usePositive)) {
          // Type the elements as null.
          if (Elements.isLocal(receiverElement)) {
            locals.update(receiverElement, types.nullType, node);
          }
          if (Elements.isLocal(argumentElement)) {
            locals.update(argumentElement, types.nullType, node);
          }
        } else {
          // Narrow the elements to a non-null type.
          ResolutionInterfaceType objectType =
              closedWorld.commonElements.objectType;
          if (Elements.isLocal(receiverElement)) {
            narrow(receiverElement, objectType, node);
          }
          if (Elements.isLocal(argumentElement)) {
            narrow(argumentElement, objectType, node);
          }
        }
      }
    }
  }

  @override
  TypeInformation visitIndex(
      ast.Send node, ast.Node receiver, ast.Node index, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitDynamicPropertyInvoke(ast.Send node, ast.Node receiver,
      ast.NodeList arguments, Selector selector, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitIfNotNullDynamicPropertyInvoke(ast.Send node,
      ast.Node receiver, ast.NodeList arguments, Selector selector, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitThisPropertyInvoke(
      ast.Send node, ast.NodeList arguments, Selector selector, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitIfNull(ast.Send node, ast.Node left, ast.Node right, _) {
    TypeInformation firstType = visit(left);
    TypeInformation secondType = visit(right);
    return types.allocateDiamondPhi(types.narrowNotNull(firstType), secondType);
  }

  @override
  TypeInformation visitLogicalAnd(
      ast.Send node, ast.Node left, ast.Node right, _) {
    conditionIsSimple = false;
    bool oldAccumulateIsChecks = accumulateIsChecks;
    List<ast.Send> oldIsChecks = isChecks;
    if (!accumulateIsChecks) {
      accumulateIsChecks = true;
      isChecks = <ast.Send>[];
    }
    visit(left);
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node);
    updateIsChecks(isChecks, usePositive: true);
    LocalsHandler narrowed;
    if (oldAccumulateIsChecks) {
      narrowed = new LocalsHandler.topLevelCopyOf(locals);
    } else {
      accumulateIsChecks = false;
      isChecks = oldIsChecks;
    }
    visit(right);
    if (oldAccumulateIsChecks) {
      bool invalidatedInRightHandSide(ast.Send test) {
        Element receiver = elements[test.receiver];
        if (receiver is LocalElement) {
          return narrowed.locals[receiver] != locals.locals[receiver];
        }
        return false;
      }

      isChecks.removeWhere(invalidatedInRightHandSide);
    }
    saved.mergeDiamondFlow(locals, null);
    locals = saved;
    return types.boolType;
  }

  @override
  TypeInformation visitLogicalOr(
      ast.Send node, ast.Node left, ast.Node right, _) {
    conditionIsSimple = false;
    List<ast.Send> tests = <ast.Send>[];
    bool isSimple = handleCondition(left, tests);
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node);
    if (isSimple) updateIsChecks(tests, usePositive: false);
    bool oldAccumulateIsChecks = accumulateIsChecks;
    accumulateIsChecks = false;
    visit(right);
    accumulateIsChecks = oldAccumulateIsChecks;
    saved.mergeDiamondFlow(locals, null);
    locals = saved;
    return types.boolType;
  }

  @override
  TypeInformation visitNot(ast.Send node, ast.Node expression, _) {
    bool oldAccumulateIsChecks = accumulateIsChecks;
    accumulateIsChecks = false;
    visit(expression);
    accumulateIsChecks = oldAccumulateIsChecks;
    return types.boolType;
  }

  @override
  TypeInformation visitIs(
      ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    potentiallyAddIsCheck(node);
    visit(expression);
    return types.boolType;
  }

  @override
  TypeInformation visitIsNot(
      ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    potentiallyAddIsCheck(node);
    visit(expression);
    return types.boolType;
  }

  @override
  TypeInformation visitAs(
      ast.Send node, ast.Node expression, ResolutionDartType type, _) {
    TypeInformation receiverType = visit(expression);
    return types.narrowType(receiverType, type);
  }

  @override
  TypeInformation visitUnary(
      ast.Send node, op.UnaryOperator operator, ast.Node expression, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitNotEquals(
      ast.Send node, ast.Node left, ast.Node right, _) {
    handleDynamicInvoke(node);
    return types.boolType;
  }

  @override
  TypeInformation visitEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    return handleDynamicInvoke(node);
  }

  @override
  TypeInformation visitBinary(ast.Send node, ast.Node left,
      op.BinaryOperator operator, ast.Node right, _) {
    return handleDynamicInvoke(node);
  }

  // Because some nodes just visit their children, we may end up
  // visiting a type annotation, that may contain a send in case of a
  // prefixed type. Therefore we explicitly visit the type annotation
  // to avoid confusing the [ResolvedVisitor].
  visitTypeAnnotation(ast.TypeAnnotation node) {}

  TypeInformation visitConditional(ast.Conditional node) {
    List<ast.Send> tests = <ast.Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node);
    updateIsChecks(tests, usePositive: true);
    TypeInformation firstType = visit(node.thenExpression);
    LocalsHandler thenLocals = locals;
    locals = new LocalsHandler.from(saved, node);
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    TypeInformation secondType = visit(node.elseExpression);
    saved.mergeDiamondFlow(thenLocals, locals);
    locals = saved;
    TypeInformation type = types.allocateDiamondPhi(firstType, secondType);
    return type;
  }

  TypeInformation visitVariableDefinitions(ast.VariableDefinitions node) {
    for (Link<ast.Node> link = node.definitions.nodes;
        !link.isEmpty;
        link = link.tail) {
      ast.Node definition = link.head;
      if (definition is ast.Identifier) {
        locals.update(elements[definition], types.nullType, node);
      } else {
        assert(definition.asSendSet() != null);
        handleSendSet(definition);
      }
    }
    return null;
  }

  bool handleCondition(ast.Node node, List<ast.Send> tests) {
    bool oldConditionIsSimple = conditionIsSimple;
    bool oldAccumulateIsChecks = accumulateIsChecks;
    List<ast.Send> oldIsChecks = isChecks;
    accumulateIsChecks = true;
    conditionIsSimple = true;
    isChecks = tests;
    visit(node);
    bool simpleCondition = conditionIsSimple;
    accumulateIsChecks = oldAccumulateIsChecks;
    isChecks = oldIsChecks;
    conditionIsSimple = oldConditionIsSimple;
    return simpleCondition;
  }

  TypeInformation visitIf(ast.If node) {
    List<ast.Send> tests = <ast.Send>[];
    bool simpleCondition = handleCondition(node.condition, tests);
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node);
    updateIsChecks(tests, usePositive: true);
    visit(node.thenPart);
    LocalsHandler thenLocals = locals;
    locals = new LocalsHandler.from(saved, node);
    if (simpleCondition) updateIsChecks(tests, usePositive: false);
    visit(node.elsePart);
    saved.mergeDiamondFlow(thenLocals, locals);
    locals = saved;
    return null;
  }

  void setupBreaksAndContinues(JumpTarget element) {
    if (element == null) return;
    if (element.isContinueTarget) continuesFor[element] = <LocalsHandler>[];
    if (element.isBreakTarget) breaksFor[element] = <LocalsHandler>[];
  }

  void clearBreaksAndContinues(JumpTarget element) {
    continuesFor.remove(element);
    breaksFor.remove(element);
  }

  List<LocalsHandler> getBreaks(JumpTarget element) {
    List<LocalsHandler> list = <LocalsHandler>[locals];
    if (element == null) return list;
    if (!element.isBreakTarget) return list;
    return list..addAll(breaksFor[element]);
  }

  List<LocalsHandler> getLoopBackEdges(JumpTarget element) {
    List<LocalsHandler> list = <LocalsHandler>[locals];
    if (element == null) return list;
    if (!element.isContinueTarget) return list;
    return list..addAll(continuesFor[element]);
  }

  TypeInformation handleLoop(ast.Node node, void logic()) {
    loopLevel++;
    bool changed = false;
    JumpTarget target = elements.getTargetDefinition(node);
    LocalsHandler saved = locals;
    saved.startLoop(node);
    do {
      // Setup (and clear in case of multiple iterations of the loop)
      // the lists of breaks and continues seen in the loop.
      setupBreaksAndContinues(target);
      locals = new LocalsHandler.from(saved, node);
      logic();
      changed = saved.mergeAll(getLoopBackEdges(target));
    } while (changed);
    loopLevel--;
    saved.endLoop(node);
    bool keepOwnLocals = node.asDoWhile() == null;
    saved.mergeAfterBreaks(getBreaks(target), keepOwnLocals: keepOwnLocals);
    locals = saved;
    clearBreaksAndContinues(target);
    return null;
  }

  TypeInformation visitWhile(ast.While node) {
    return handleLoop(node, () {
      List<ast.Send> tests = <ast.Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
    });
  }

  TypeInformation visitDoWhile(ast.DoWhile node) {
    return handleLoop(node, () {
      visit(node.body);
      List<ast.Send> tests = <ast.Send>[];
      handleCondition(node.condition, tests);
      // TODO(29309): This condition appears to stengthen both the back-edge and
      // exit-edge. For now, avoid strengthening on the condition until the
      // proper fix is found.
      //
      //     updateIsChecks(tests, usePositive: true);
    });
  }

  TypeInformation visitFor(ast.For node) {
    visit(node.initializer);
    return handleLoop(node, () {
      List<ast.Send> tests = <ast.Send>[];
      handleCondition(node.condition, tests);
      updateIsChecks(tests, usePositive: true);
      visit(node.body);
      visit(node.update);
    });
  }

  TypeInformation visitTryStatement(ast.TryStatement node) {
    LocalsHandler saved = locals;
    locals = new LocalsHandler.from(locals, node, useOtherTryBlock: false);
    initializationIsIndefinite();
    visit(node.tryBlock);
    saved.mergeDiamondFlow(locals, null);
    locals = saved;
    for (ast.Node catchBlock in node.catchBlocks) {
      saved = locals;
      locals = new LocalsHandler.from(locals, catchBlock);
      visit(catchBlock);
      saved.mergeDiamondFlow(locals, null);
      locals = saved;
    }
    visit(node.finallyBlock);
    return null;
  }

  TypeInformation visitThrow(ast.Throw node) {
    node.visitChildren(this);
    locals.seenReturnOrThrow = true;
    return types.nonNullEmpty();
  }

  TypeInformation visitCatchBlock(ast.CatchBlock node) {
    ast.Node exception = node.exception;
    if (exception != null) {
      ResolutionDartType type = elements.getType(node.type);
      TypeInformation mask =
          type == null || type.treatAsDynamic || type.isTypeVariable
              ? types.dynamicType
              : types.nonNullSubtype(type.element);
      locals.update(elements[exception], mask, node);
    }
    ast.Node trace = node.trace;
    if (trace != null) {
      locals.update(elements[trace], types.dynamicType, node);
    }
    visit(node.block);
    return null;
  }

  TypeInformation visitParenthesizedExpression(
      ast.ParenthesizedExpression node) {
    return visit(node.expression);
  }

  TypeInformation visitBlock(ast.Block node) {
    if (node.statements != null) {
      for (ast.Node statement in node.statements) {
        visit(statement);
        if (locals.aborts) break;
      }
    }
    return null;
  }

  TypeInformation visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop ||
        body is ast.SwitchStatement ||
        Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
    } else {
      JumpTarget targetElement = elements.getTargetDefinition(body);
      setupBreaksAndContinues(targetElement);
      visit(body);
      locals.mergeAfterBreaks(getBreaks(targetElement));
      clearBreaksAndContinues(targetElement);
    }
    return null;
  }

  TypeInformation visitBreakStatement(ast.BreakStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    breaksFor[target].add(new LocalsHandler.deepCopyOf(locals));
    return null;
  }

  TypeInformation visitContinueStatement(ast.ContinueStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    locals.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // continue will change them.
    continuesFor[target].add(new LocalsHandler.deepCopyOf(locals));
    return null;
  }

  internalError(Spannable node, String reason) {
    reporter.internalError(node, reason);
  }

  TypeInformation visitSwitchStatement(ast.SwitchStatement node) {
    visit(node.parenthesizedExpression);

    setupBreaksAndContinues(elements.getTargetDefinition(node));
    if (Elements.switchStatementHasContinue(node, elements)) {
      void forEachLabeledCase(void action(JumpTarget target)) {
        for (ast.SwitchCase switchCase in node.cases) {
          for (ast.Node labelOrCase in switchCase.labelsAndCases) {
            if (labelOrCase.asLabel() == null) continue;
            LabelDefinition labelElement =
                elements.getLabelDefinition(labelOrCase);
            if (labelElement != null) {
              action(labelElement.target);
            }
          }
        }
      }

      forEachLabeledCase((JumpTarget target) {
        setupBreaksAndContinues(target);
      });

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      locals.startLoop(node);
      do {
        changed = false;
        for (ast.Node switchCase in node.cases) {
          LocalsHandler saved = locals;
          locals = new LocalsHandler.from(locals, switchCase);
          visit(switchCase);
          changed = saved.mergeAll([locals]) || changed;
          locals = saved;
        }
      } while (changed);
      locals.endLoop(node);

      forEachLabeledCase((JumpTarget target) {
        clearBreaksAndContinues(target);
      });
    } else {
      LocalsHandler saved = locals;
      List<LocalsHandler> localsToMerge = <LocalsHandler>[];
      bool hasDefaultCase = false;

      for (ast.SwitchCase switchCase in node.cases) {
        if (switchCase.isDefaultCase) {
          hasDefaultCase = true;
        }
        locals = new LocalsHandler.from(saved, switchCase);
        visit(switchCase);
        localsToMerge.add(locals);
      }
      saved.mergeAfterBreaks(localsToMerge, keepOwnLocals: !hasDefaultCase);
      locals = saved;
    }
    clearBreaksAndContinues(elements.getTargetDefinition(node));
    return null;
  }

  TypeInformation visitCascadeReceiver(ast.CascadeReceiver node) {
    var type = visit(node.expression);
    cascadeReceiverStack.add(type);
    return type;
  }

  TypeInformation visitCascade(ast.Cascade node) {
    // Ignore the result of the cascade send and return the type of the cascade
    // receiver.
    visit(node.expression);
    return cascadeReceiverStack.removeLast();
  }

  void analyzeSuperConstructorCall(
      AstElement target, ArgumentsTypes arguments) {
    ResolvedAst resolvedAst = target.resolvedAst;
    inferrer.analyze(resolvedAst, arguments);
    isThisExposed = isThisExposed || inferrer.checkIfExposesThis(target);
  }

  TypeInformation run() {
    var node;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      node = resolvedAst.node;
    }
    ast.Expression initializer;
    if (analyzedElement.isField) {
      initializer = resolvedAst.body;
      if (initializer == null) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return types.nullType;
      }
    }
    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureRepresentationInfo closureData = compiler.closureDataLookup
        .getClosureRepresentationInfo(analyzedElement);
    closureData.forEachCapturedVariable((variable, field) {
      locals.setCaptured(variable, field);
    });
    closureData.forEachBoxedVariable((variable, field) {
      locals.setCapturedAndBoxed(variable, field);
    });
    if (analyzedElement.isField) {
      return visit(initializer);
    }

    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.functionSignature;
    signature.forEachOptionalParameter((FormalElement _element) {
      ParameterElement element = _element;
      ast.Expression defaultValue = element.initializer;
      // TODO(25566): The default value of a parameter of a redirecting factory
      // constructor comes from the corresponding parameter of the target.

      // If this is a default value from a different context (because
      // the current function is synthetic, e.g., a constructor from
      // a mixin application), we have to start a new inferrer visitor
      // with the correct context.
      // TODO(johnniwinther): Remove once function signatures are fixed.
      ElementGraphBuilder visitor = this;
      if (inferrer.hasAlreadyComputedTypeOfParameterDefault(element)) return;
      if (element.functionDeclaration != analyzedElement) {
        visitor = new ElementGraphBuilder(element.functionDeclaration,
            element.functionDeclaration.resolvedAst, compiler, inferrer);
      }
      TypeInformation type =
          (defaultValue == null) ? types.nullType : visitor.visit(defaultValue);
      inferrer.setDefaultTypeOfParameter(element, type);
    });

    if (inferrer.isNativeMember(analyzedElement)) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic.
      return types.dynamicType;
    }

    if (analyzedElement.isGenerativeConstructor) {
      isThisExposed = false;
      signature.forEachParameter((FormalElement _element) {
        ParameterElement element = _element;
        TypeInformation parameterType = inferrer.typeOfElement(element);
        if (element.isInitializingFormal) {
          InitializingFormalElement initializingFormal = element;
          if (initializingFormal.fieldElement.isFinal) {
            inferrer.recordTypeOfFinalField(node, analyzedElement,
                initializingFormal.fieldElement, parameterType);
          } else {
            locals.updateField(initializingFormal.fieldElement, parameterType);
            inferrer.recordTypeOfNonFinalField(initializingFormal.node,
                initializingFormal.fieldElement, parameterType);
          }
        }
        locals.update(element, parameterType, node);
      });
      ClassElement cls = analyzedElement.enclosingClass;
      Spannable spannable = node;
      if (analyzedElement.isSynthesized) {
        spannable = analyzedElement;
        ConstructorElement constructor = analyzedElement;
        synthesizeForwardingCall(spannable, constructor.definingConstructor);
      } else {
        visitingInitializers = true;
        if (node.initializers != null) {
          for (ast.Node initializer in node.initializers) {
            ast.SendSet fieldInitializer = initializer.asSendSet();
            if (fieldInitializer != null) {
              handleSendSet(fieldInitializer);
            } else {
              Element element = elements[initializer];
              handleConstructorSend(initializer, element);
            }
          }
        }
        visitingInitializers = false;
        // For a generative constructor like: `Foo();`, we synthesize
        // a call to the default super constructor (the one that takes
        // no argument). Resolution ensures that such a constructor
        // exists.
        if (!isConstructorRedirect &&
            !seenSuperConstructorCall &&
            !cls.isObject) {
          ConstructorElement target = cls.superclass.lookupDefaultConstructor();
          ArgumentsTypes arguments = new ArgumentsTypes([], {});
          analyzeSuperConstructorCall(target, arguments);
          inferrer.registerCalledElement(node, null, null, outermostElement,
              target.implementation, arguments, sideEffects, inLoop);
        }
        visit(node.body);
        inferrer.recordExposesThis(analyzedElement, isThisExposed);
      }
      if (!isConstructorRedirect) {
        // Iterate over all instance fields, and give a null type to
        // fields that we haven'TypeInformation initialized for sure.
        cls.forEachInstanceField((_, FieldElement field) {
          if (field.isFinal) return;
          TypeInformation type = locals.fieldScope.readField(field);
          ResolvedAst resolvedAst = field.resolvedAst;
          if (type == null && resolvedAst.body == null) {
            inferrer.recordTypeOfNonFinalField(
                spannable, field, types.nullType);
          }
        });
      }
      if (analyzedElement.isGenerativeConstructor && cls.isAbstract) {
        if (closedWorld.isInstantiated(cls)) {
          returnType = types.nonNullSubclass(cls);
        } else {
          // TODO(johnniwinther): Avoid analyzing [analyzedElement] in this
          // case; it's never called.
          returnType = types.nonNullEmpty();
        }
      } else {
        returnType = types.nonNullExact(cls);
      }
    } else {
      signature.forEachParameter((FormalElement _element) {
        ParameterElement element = _element;
        locals.update(element, inferrer.typeOfElement(element), node);
      });
      visit(node.body);
      switch (function.asyncMarker) {
        case AsyncMarker.SYNC:
          if (returnType == null) {
            // No return in the body.
            returnType = locals.seenReturnOrThrow
                ? types.nonNullEmpty() // Body always throws.
                : types.nullType;
          } else if (!locals.seenReturnOrThrow) {
            // We haven'TypeInformation seen returns on all branches. So the method may
            // also return null.
            returnType = inferrer.addReturnTypeFor(
                analyzedElement, returnType, types.nullType);
          }
          break;

        case AsyncMarker.SYNC_STAR:
          // TODO(asgerf): Maybe make a ContainerTypeMask for these? The type
          //               contained is the method body's return type.
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.syncStarIterableType);
          break;

        case AsyncMarker.ASYNC:
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.asyncFutureType);
          break;

        case AsyncMarker.ASYNC_STAR:
          returnType = inferrer.addReturnTypeFor(
              analyzedElement, returnType, types.asyncStarStreamType);
          break;
      }
    }

    inferrer.closedWorldRefiner
        .registerSideEffects(analyzedElement.declaration, sideEffects);
    assert(breaksFor.isEmpty);
    assert(continuesFor.isEmpty);
    return returnType;
  }

  TypeInformation visitFunctionExpression(ast.FunctionExpression node) {
    // We loose track of [this] in closures (see issue 20840). To be on
    // the safe side, we mark [this] as exposed here. We could do better by
    // analyzing the closure.
    // TODO(herhut): Analyze whether closure exposes this.
    isThisExposed = true;
    LocalFunctionElement element = elements.getFunctionDefinition(node);
    // We don'TypeInformation put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalsHandler closureLocals =
        new LocalsHandler.from(locals, node, useOtherTryBlock: false);
    ElementGraphBuilder visitor = new ElementGraphBuilder(
        element, element.resolvedAst, compiler, inferrer, closureLocals);
    visitor.run();
    inferrer.recordReturnType(element, visitor.returnType);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure.
    ClosureRepresentationInfo nestedClosureData =
        compiler.closureDataLookup.getClosureRepresentationInfo(element);
    nestedClosureData.forEachCapturedVariable((variable, field) {
      if (!nestedClosureData.isVariableBoxed(variable)) {
        if (variable == nestedClosureData.thisLocal) {
          inferrer.recordType(field, thisType);
        }
        // The type is null for type parameters.
        if (locals.locals[variable] == null) return;
        inferrer.recordType(field, locals.locals[variable]);
      }
      capturedVariables.add(variable);
    });

    return inferrer.concreteTypes.putIfAbsent(node, () {
      return types.allocateClosure(node, element);
    });
  }

  TypeInformation visitFunctionDeclaration(ast.FunctionDeclaration node) {
    LocalFunctionElement element =
        elements.getFunctionDefinition(node.function);
    TypeInformation type =
        inferrer.concreteTypes.putIfAbsent(node.function, () {
      return types.allocateClosure(node.function, element);
    });
    locals.update(element, type, node);
    visit(node.function);
    return type;
  }

  TypeInformation visitStringInterpolation(ast.StringInterpolation node) {
    // Interpolation could have any effects since it could call any toString()
    // method.
    // TODO(sra): This could be modelled by a call to toString() but with a
    // guaranteed String return type.  Interpolation of known types would get
    // specialized effects.  This would not currently be effective since the JS
    // code in the toString methods for intercepted primitive types is assumed
    // to have all effects.  Effect annotations on JS code would be needed to
    // get the benefit.
    sideEffects.setAllSideEffects();
    node.visitChildren(this);
    return types.stringType;
  }

  TypeInformation visitLiteralList(ast.LiteralList node) {
    // We only set the type once. We don'TypeInformation need to re-visit the children
    // when re-analyzing the node.
    return inferrer.concreteTypes.putIfAbsent(node, () {
      TypeInformation elementType;
      int length = 0;
      for (ast.Node element in node.elements.nodes) {
        TypeInformation type = visit(element);
        elementType = elementType == null
            ? types.allocatePhi(null, null, type)
            : types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? types.nonNullEmpty()
          : types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          node.isConst ? types.constListType : types.growableListType;
      return types.allocateList(
          containerType, node, outermostElement, elementType, length);
    });
  }

  TypeInformation visitLiteralMap(ast.LiteralMap node) {
    return inferrer.concreteTypes.putIfAbsent(node, () {
      ast.NodeList entries = node.entries;
      List keyTypes = [];
      List valueTypes = [];

      for (ast.LiteralMapEntry entry in entries) {
        keyTypes.add(visit(entry.key));
        valueTypes.add(visit(entry.value));
      }

      TypeInformation type = node.isConst ? types.constMapType : types.mapType;
      return types.allocateMap(
          type, node, outermostElement, keyTypes, valueTypes);
    });
  }

  bool isThisOrSuper(ast.Node node) => node.isThis() || node.isSuper();

  bool isInClassOrSubclass(Element element) {
    ClassElement cls = outermostElement.enclosingClass;
    ClassElement enclosing = element.enclosingClass;
    return closedWorld.isSubclassOf(enclosing, cls);
  }

  void checkIfExposesThis(Selector selector, TypeMask mask) {
    if (isThisExposed) return;
    inferrer.forEachElementMatching(selector, mask, (dynamic element) {
      if (element.isField) {
        ResolvedAst elementResolvedAst = element.resolvedAst;
        if (!selector.isSetter &&
            isInClassOrSubclass(element) &&
            !element.isFinal &&
            locals.fieldScope.readField(element) == null &&
            elementResolvedAst.body == null) {
          // If the field is being used before this constructor
          // actually had a chance to initialize it, say it can be
          // null.
          inferrer.recordTypeOfNonFinalField(
              resolvedAst.node, element, types.nullType);
        }
        // Accessing a field does not expose [:this:].
        return true;
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = true;
      return false;
    });
  }

  bool get inInstanceContext {
    return (outermostElement.isInstanceMember && !outermostElement.isField) ||
        outermostElement.isGenerativeConstructor;
  }

  bool treatAsInstanceMember(Element element) {
    return (Elements.isUnresolved(element) && inInstanceContext) ||
        (element != null && element.isInstanceMember);
  }

  TypeInformation handleSendSet(ast.SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType) {
      node.visitChildren(this);
      return types.dynamicType;
    }

    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);
    TypeMask getterMask = inTreeData.typeOfGetter(node);
    TypeMask operatorMask = inTreeData.typeOfOperator(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);

    String op = node.assignmentOperator.source;
    bool isIncrementOrDecrement = op == '++' || op == '--';

    TypeInformation receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        receiverType = thisType;
        isCallOnThis = true;
      }
    } else {
      if (node.receiver != null) {
        Element receiver = elements[node.receiver];
        if (receiver is! PrefixElement && receiver is! ClassElement) {
          // TODO(johnniwinther): Avoid blindly recursing on the receiver.
          receiverType = visit(node.receiver);
        }
      }
      isCallOnThis = isThisOrSuper(node.receiver);
    }

    TypeInformation rhsType;

    if (isIncrementOrDecrement) {
      rhsType = types.uint31Type;
      if (node.isIndex) visit(node.arguments.head);
    } else if (node.isIndex) {
      visit(node.arguments.head);
      rhsType = visit(node.arguments.tail.head);
    } else {
      rhsType = visit(node.arguments.head);
    }

    if (!visitingInitializers && !isThisExposed) {
      for (ast.Node node in node.arguments) {
        if (isThisOrSuper(node)) {
          isThisExposed = true;
          break;
        }
      }
      if (!isThisExposed && isCallOnThis) {
        checkIfExposesThis(
            setterSelector, types.newTypedSelector(receiverType, setterMask));
        if (getterSelector != null) {
          checkIfExposesThis(
              getterSelector, types.newTypedSelector(receiverType, getterMask));
        }
      }
    }

    if (node.isIndex) {
      return internalError(node, "Unexpected index operation");
    } else if (op == '=') {
      return handlePlainAssignment(node, element, setterSelector, setterMask,
          receiverType, rhsType, node.arguments.head);
    } else {
      // [foo ??= bar], [: foo++ :] or [: foo += 1 :].
      TypeInformation getterType;
      TypeInformation newType;

      if (Elements.isMalformed(element)) return types.dynamicType;

      if (Elements.isStaticOrTopLevelField(element)) {
        Element getterElement = elements[node.selector];
        getterType = handleStaticSend(
            node, getterSelector, getterMask, getterElement, null);
      } else if (Elements.isUnresolved(element) ||
          element.isSetter ||
          element.isField) {
        getterType = handleDynamicSend(
            node, getterSelector, getterMask, receiverType, null);
      } else if (element.isLocal) {
        LocalElement local = element;
        getterType = locals.use(local);
      } else {
        // Bogus SendSet, for example [: myMethod += 42 :].
        getterType = types.dynamicType;
      }

      if (op == '??=') {
        newType = types.allocateDiamondPhi(getterType, rhsType);
      } else {
        Selector operatorSelector =
            elements.getOperatorSelectorInComplexSendSet(node);
        newType = handleDynamicSend(node, operatorSelector, operatorMask,
            getterType, new ArgumentsTypes([rhsType], null));
      }

      if (Elements.isStaticOrTopLevelField(element)) {
        handleStaticSend(node, setterSelector, setterMask, element,
            new ArgumentsTypes([newType], null));
      } else if (Elements.isUnresolved(element) ||
          element.isSetter ||
          element.isField) {
        handleDynamicSend(node, setterSelector, setterMask, receiverType,
            new ArgumentsTypes([newType], null));
      } else if (element.isLocal) {
        locals.update(element, newType, node);
      }

      return node.isPostfix ? getterType : newType;
    }
  }

  /// Handle compound index set, like `foo[0] += 42` or `foo[0]++`.
  TypeInformation handleCompoundIndexSet(
      ast.SendSet node,
      TypeInformation receiverType,
      TypeInformation indexType,
      TypeInformation rhsType) {
    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);

    TypeMask getterMask = inTreeData.typeOfGetter(node);
    Selector operatorSelector =
        elements.getOperatorSelectorInComplexSendSet(node);
    TypeMask operatorMask = inTreeData.typeOfOperator(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);

    TypeInformation getterType = handleDynamicSend(node, getterSelector,
        getterMask, receiverType, new ArgumentsTypes([indexType], null));

    TypeInformation returnType;
    if (node.isIfNullAssignment) {
      returnType = types.allocateDiamondPhi(getterType, rhsType);
    } else {
      returnType = handleDynamicSend(node, operatorSelector, operatorMask,
          getterType, new ArgumentsTypes([rhsType], null));
    }
    handleDynamicSend(node, setterSelector, setterMask, receiverType,
        new ArgumentsTypes([indexType, returnType], null));

    if (node.isPostfix) {
      return getterType;
    } else {
      return returnType;
    }
  }

  /// Handle compound prefix/postfix operations, like `a[0]++`.
  TypeInformation handleCompoundPrefixPostfix(
      ast.Send node, TypeInformation receiverType, TypeInformation indexType) {
    return handleCompoundIndexSet(
        node, receiverType, indexType, types.uint31Type);
  }

  @override
  TypeInformation visitIndexPostfix(ast.Send node, ast.Node receiver,
      ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation receiverType = visit(receiver);
    TypeInformation indexType = visit(index);
    return handleCompoundPrefixPostfix(node, receiverType, indexType);
  }

  @override
  TypeInformation visitIndexPrefix(ast.Send node, ast.Node receiver,
      ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation receiverType = visit(receiver);
    TypeInformation indexType = visit(index);
    return handleCompoundPrefixPostfix(node, receiverType, indexType);
  }

  @override
  TypeInformation visitCompoundIndexSet(ast.SendSet node, ast.Node receiver,
      ast.Node index, op.AssignmentOperator operator, ast.Node rhs, _) {
    TypeInformation receiverType = visit(receiver);
    TypeInformation indexType = visit(index);
    TypeInformation rhsType = visit(rhs);
    return handleCompoundIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  TypeInformation visitIndexSetIfNull(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    TypeInformation receiverType = visit(receiver);
    TypeInformation indexType = visit(index);
    TypeInformation rhsType = visit(rhs);
    return handleCompoundIndexSet(node, receiverType, indexType, rhsType);
  }

  @override
  TypeInformation visitSuperIndexPrefix(ast.Send node, MethodElement getter,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, getter, setter, indexType);
  }

  @override
  TypeInformation visitSuperIndexPostfix(ast.Send node, MethodElement getter,
      MethodElement setter, ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, getter, setter, indexType);
  }

  /// Handle compound prefix/postfix operations, like `super[0]++`.
  TypeInformation handleSuperIndexPrefixPostfix(ast.Send node, Element getter,
      Element setter, TypeInformation indexType) {
    return _handleSuperCompoundIndexSet(
        node, getter, setter, indexType, types.uint31Type);
  }

  /// Handle compound super index set, like `super[42] =+ 2`.
  TypeInformation handleSuperCompoundIndexSet(ast.SendSet node, Element getter,
      Element setter, ast.Node index, ast.Node rhs) {
    TypeInformation indexType = visit(index);
    TypeInformation rhsType = visit(rhs);
    return _handleSuperCompoundIndexSet(
        node, getter, setter, indexType, rhsType);
  }

  TypeInformation _handleSuperCompoundIndexSet(ast.SendSet node, Element getter,
      Element setter, TypeInformation indexType, TypeInformation rhsType) {
    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);

    TypeMask getterMask = inTreeData.typeOfGetter(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);

    TypeInformation getterType = handleSuperSend(node, getterSelector,
        getterMask, getter, new ArgumentsTypes([indexType], null));

    TypeInformation returnType;
    if (node.isIfNullAssignment) {
      returnType = types.allocateDiamondPhi(getterType, rhsType);
    } else {
      Selector operatorSelector =
          elements.getOperatorSelectorInComplexSendSet(node);
      TypeMask operatorMask = inTreeData.typeOfOperator(node);
      returnType = handleDynamicSend(node, operatorSelector, operatorMask,
          getterType, new ArgumentsTypes([rhsType], null));
    }
    handleSuperSend(node, setterSelector, setterMask, setter,
        new ArgumentsTypes([indexType, returnType], null));

    return node.isPostfix ? getterType : returnType;
  }

  TypeInformation handleSuperSend(ast.Node node, Selector selector,
      TypeMask mask, Element element, ArgumentsTypes arguments) {
    if (element.isMalformed) {
      return handleSuperNoSuchMethod(node, selector, mask, arguments);
    } else {
      return handleStaticSend(node, selector, mask, element, arguments);
    }
  }

  @override
  TypeInformation visitSuperCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      MethodElement setter,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, getter, setter, index, rhs);
  }

  @override
  TypeInformation visitSuperIndexSetIfNull(
      ast.SendSet node,
      MethodElement getter,
      MethodElement setter,
      ast.Node index,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, getter, setter, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperCompoundIndexSet(
      ast.Send node,
      Element element,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, element, element, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperIndexSetIfNull(
      ast.Send node, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, element, element, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterCompoundIndexSet(
      ast.SendSet node,
      Element element,
      MethodElement setter,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, element, setter, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterIndexSetIfNull(ast.SendSet node,
      Element element, MethodElement setter, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, element, setter, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompoundIndexSet(node, getter, element, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterIndexSetIfNull(ast.SendSet node,
      MethodElement getter, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperCompoundIndexSet(node, getter, element, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperIndexPrefix(ast.Send node,
      Element element, ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, element, element, indexType);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterIndexPrefix(
      ast.SendSet node,
      Element element,
      MethodElement setter,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, element, setter, indexType);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterIndexPrefix(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, getter, element, indexType);
  }

  @override
  TypeInformation visitUnresolvedSuperIndexPostfix(ast.Send node,
      Element element, ast.Node index, op.IncDecOperator operator, _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, element, element, indexType);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterIndexPostfix(
      ast.SendSet node,
      Element element,
      MethodElement setter,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, element, setter, indexType);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterIndexPostfix(
      ast.SendSet node,
      MethodElement getter,
      Element element,
      ast.Node index,
      op.IncDecOperator operator,
      _) {
    TypeInformation indexType = visit(index);
    return handleSuperIndexPrefixPostfix(node, getter, element, indexType);
  }

  @override
  TypeInformation visitSuperFieldCompound(ast.Send node, FieldElement field,
      op.AssignmentOperator operator, ast.Node rhs, _) {
    return handleSuperCompound(node, field, field, rhs);
  }

  @override
  TypeInformation visitSuperFieldSetterCompound(
      ast.Send node,
      FieldElement field,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, field, setter, rhs);
  }

  @override
  TypeInformation visitSuperGetterFieldCompound(
      ast.Send node,
      FunctionElement getter,
      FieldElement field,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, getter, field, rhs);
  }

  @override
  TypeInformation visitSuperGetterSetterCompound(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, getter, setter, rhs);
  }

  @override
  TypeInformation visitSuperMethodSetterCompound(
      ast.Send node,
      FunctionElement method,
      FunctionElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, method, setter, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperCompound(ast.Send node, Element element,
      op.AssignmentOperator operator, ast.Node rhs, _) {
    return handleSuperCompound(node, element, element, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterCompound(
      ast.Send node,
      Element getter,
      SetterElement setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, getter, setter, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterCompound(
      ast.Send node,
      GetterElement getter,
      Element setter,
      op.AssignmentOperator operator,
      ast.Node rhs,
      _) {
    return handleSuperCompound(node, getter, setter, rhs);
  }

  @override
  TypeInformation visitSuperFieldFieldSetIfNull(ast.Send node,
      FieldElement readField, FieldElement writtenField, ast.Node rhs, _) {
    return handleSuperCompound(node, readField, writtenField, rhs);
  }

  @override
  TypeInformation visitSuperFieldSetIfNull(
      ast.Send node, FieldElement field, ast.Node rhs, _) {
    return handleSuperCompound(node, field, field, rhs);
  }

  @override
  TypeInformation visitSuperFieldSetterSetIfNull(ast.Send node,
      FieldElement field, FunctionElement setter, ast.Node rhs, _) {
    return handleSuperCompound(node, field, setter, rhs);
  }

  @override
  TypeInformation visitSuperGetterFieldSetIfNull(ast.Send node,
      FunctionElement getter, FieldElement field, ast.Node rhs, _) {
    return handleSuperCompound(node, getter, field, rhs);
  }

  @override
  TypeInformation visitSuperGetterSetterSetIfNull(ast.Send node,
      FunctionElement getter, FunctionElement setter, ast.Node rhs, _) {
    return handleSuperCompound(node, getter, setter, rhs);
  }

  @override
  TypeInformation visitSuperMethodSetIfNull(
      ast.Send node, FunctionElement method, ast.Node rhs, _) {
    return handleSuperCompound(node, method, null, rhs);
  }

  @override
  TypeInformation visitSuperMethodSetterSetIfNull(ast.Send node,
      FunctionElement method, FunctionElement setter, ast.Node rhs, _) {
    return handleSuperCompound(node, method, setter, rhs);
  }

  TypeInformation handleSuperCompound(
      ast.SendSet node, Element getter, Element setter, ast.Node rhs) {
    TypeInformation rhsType = visit(rhs);
    return _handleSuperCompound(node, getter, setter, rhsType);
  }

  @override
  TypeInformation visitSuperFieldFieldPostfix(
      ast.SendSet node,
      FieldElement readField,
      FieldElement writtenField,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, readField, writtenField);
  }

  @override
  TypeInformation visitSuperFieldFieldPrefix(
      ast.SendSet node,
      FieldElement readField,
      FieldElement writtenField,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, readField, writtenField);
  }

  @override
  TypeInformation visitSuperFieldPostfix(
      ast.SendSet node, FieldElement field, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, field, field);
  }

  @override
  TypeInformation visitSuperFieldPrefix(
      ast.SendSet node, FieldElement field, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, field, field);
  }

  @override
  TypeInformation visitSuperFieldSetterPostfix(
      ast.SendSet node,
      FieldElement field,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, field, setter);
  }

  @override
  TypeInformation visitSuperFieldSetterPrefix(
      ast.SendSet node,
      FieldElement field,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, field, setter);
  }

  @override
  TypeInformation visitSuperGetterFieldPostfix(
      ast.SendSet node,
      FunctionElement getter,
      FieldElement field,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, getter, field);
  }

  @override
  TypeInformation visitSuperGetterFieldPrefix(
      ast.SendSet node,
      FunctionElement getter,
      FieldElement field,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, getter, field);
  }

  @override
  TypeInformation visitSuperGetterSetterPostfix(
      ast.SendSet node,
      FunctionElement getter,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  @override
  TypeInformation visitSuperGetterSetterPrefix(
      ast.SendSet node,
      FunctionElement getter,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  @override
  TypeInformation visitSuperMethodSetterPostfix(
      ast.SendSet node,
      FunctionElement method,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, method, setter);
  }

  @override
  TypeInformation visitSuperMethodSetterPrefix(
      ast.SendSet node,
      FunctionElement method,
      FunctionElement setter,
      op.IncDecOperator operator,
      _) {
    return handleSuperPrefixPostfix(node, method, setter);
  }

  @override
  TypeInformation visitUnresolvedSuperPrefix(
      ast.SendSet node, Element element, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, element, element);
  }

  @override
  TypeInformation visitUnresolvedSuperPostfix(
      ast.SendSet node, Element element, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, element, element);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterPrefix(ast.SendSet node,
      Element getter, SetterElement setter, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  @override
  TypeInformation visitUnresolvedSuperGetterPostfix(ast.SendSet node,
      Element getter, SetterElement setter, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterPrefix(ast.SendSet node,
      GetterElement getter, Element setter, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  @override
  TypeInformation visitUnresolvedSuperSetterPostfix(ast.SendSet node,
      GetterElement getter, Element setter, op.IncDecOperator operator, _) {
    return handleSuperPrefixPostfix(node, getter, setter);
  }

  TypeInformation handleSuperPrefixPostfix(
      ast.SendSet node, Element getter, Element setter) {
    return _handleSuperCompound(node, getter, setter, types.uint31Type);
  }

  TypeInformation _handleSuperCompound(ast.SendSet node, Element getter,
      Element setter, TypeInformation rhsType) {
    Selector getterSelector = elements.getGetterSelectorInComplexSendSet(node);
    TypeMask getterMask = inTreeData.typeOfGetter(node);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);

    TypeInformation getterType =
        handleSuperSend(node, getterSelector, getterMask, getter, null);

    TypeInformation returnType;
    if (node.isIfNullAssignment) {
      returnType = types.allocateDiamondPhi(getterType, rhsType);
    } else {
      Selector operatorSelector =
          elements.getOperatorSelectorInComplexSendSet(node);
      TypeMask operatorMask = inTreeData.typeOfOperator(node);
      returnType = handleDynamicSend(node, operatorSelector, operatorMask,
          getterType, new ArgumentsTypes([rhsType], null));
    }
    handleSuperSend(node, setterSelector, setterMask, setter,
        new ArgumentsTypes([returnType], null));

    return node.isPostfix ? getterType : returnType;
  }

  /// Handle index set, like `foo[0] = 42`.
  TypeInformation handleIndexSet(ast.SendSet node, TypeInformation receiverType,
      TypeInformation indexType, TypeInformation rhsType) {
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);
    handleDynamicSend(node, setterSelector, setterMask, receiverType,
        new ArgumentsTypes([indexType, rhsType], null));
    return rhsType;
  }

  @override
  TypeInformation visitIndexSet(
      ast.SendSet node, ast.Node receiver, ast.Node index, ast.Node rhs, _) {
    TypeInformation receiverType = visit(receiver);
    TypeInformation indexType = visit(index);
    TypeInformation rhsType = visit(rhs);
    return handleIndexSet(node, receiverType, indexType, rhsType);
  }

  /// Handle super index set, like `super[42] = true`.
  TypeInformation handleSuperIndexSet(
      ast.SendSet node, Element element, ast.Node index, ast.Node rhs) {
    TypeInformation indexType = visit(index);
    TypeInformation rhsType = visit(rhs);
    Selector setterSelector = elements.getSelector(node);
    TypeMask setterMask = inTreeData.typeOfSend(node);
    handleStaticSend(node, setterSelector, setterMask, element,
        new ArgumentsTypes([indexType, rhsType], null));
    return rhsType;
  }

  @override
  TypeInformation visitSuperIndexSet(ast.SendSet node, FunctionElement function,
      ast.Node index, ast.Node rhs, _) {
    return handleSuperIndexSet(node, function, index, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperIndexSet(
      ast.SendSet node, Element element, ast.Node index, ast.Node rhs, _) {
    return handleSuperIndexSet(node, element, index, rhs);
  }

  TypeInformation handlePlainAssignment(
      ast.Node node,
      Element element,
      Selector setterSelector,
      TypeMask setterMask,
      TypeInformation receiverType,
      TypeInformation rhsType,
      ast.Node rhs) {
    ArgumentsTypes arguments = new ArgumentsTypes([rhsType], null);
    if (Elements.isMalformed(element)) {
      // Code will always throw.
    } else if (Elements.isStaticOrTopLevelField(element)) {
      handleStaticSend(node, setterSelector, setterMask, element, arguments);
    } else if (Elements.isUnresolved(element) || element.isSetter) {
      if (analyzedElement.isGenerativeConstructor &&
          (node.asSendSet() != null) &&
          (node.asSendSet().receiver != null) &&
          node.asSendSet().receiver.isThis()) {
        Iterable<MemberEntity> targets = closedWorld.locateMembers(
            setterSelector, types.newTypedSelector(thisType, setterMask));
        // We just recognized a field initialization of the form:
        // `this.foo = 42`. If there is only one target, we can update
        // its type.
        if (targets.length == 1) {
          MemberElement single = targets.first;
          if (single.isField) {
            locals.updateField(single, rhsType);
          }
        }
      }
      handleDynamicSend(
          node, setterSelector, setterMask, receiverType, arguments);
    } else if (element.isField) {
      if (element.isFinal) {
        inferrer.recordTypeOfFinalField(
            node, outermostElement, element, rhsType);
      } else {
        if (analyzedElement.isGenerativeConstructor) {
          locals.updateField(element, rhsType);
        }
        if (visitingInitializers) {
          inferrer.recordTypeOfNonFinalField(node, element, rhsType);
        } else {
          handleDynamicSend(
              node, setterSelector, setterMask, receiverType, arguments);
        }
      }
    } else if (element.isLocal) {
      locals.update(element, rhsType, node);
    }
    return rhsType;
  }

  /// Handle a super access or invocation that results in a `noSuchMethod` call.
  TypeInformation handleErroneousSuperSend(ast.Send node) {
    ArgumentsTypes arguments =
        node.isPropertyAccess ? null : analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    // TODO(johnniwinther): Do we still need this when calling directly?
    isThisExposed = true;
    return handleSuperNoSuchMethod(node, selector, mask, arguments);
  }

  TypeInformation handleSuperNoSuchMethod(ast.Send node, Selector selector,
      TypeMask mask, ArgumentsTypes arguments) {
    // Ensure we create a node, to make explicit the call to the
    // `noSuchMethod` handler.
    ClassElement cls = outermostElement.enclosingClass;
    MethodElement element = cls.lookupSuperMember(Identifiers.noSuchMethod_);
    if (!Selectors.noSuchMethod_.signatureApplies(element)) {
      ClassElement objectClass = closedWorld.commonElements.objectClass;
      element = objectClass.lookupMember(Identifiers.noSuchMethod_);
    }
    return handleStaticSend(node, selector, mask, element, arguments);
  }

  /// Handle a .call invocation on the values retrieved from the super
  /// [element]. For instance `super.foo(bar)` where `foo` is a field or getter.
  TypeInformation handleSuperClosureCall(
      ast.Send node, Element element, ast.NodeList arguments) {
    ArgumentsTypes argumentTypes = analyzeArguments(arguments.nodes);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    return inferrer.registerCalledClosure(
        node,
        selector,
        mask,
        inferrer.typeOfElement(element),
        outermostElement,
        argumentTypes,
        sideEffects,
        inLoop);
  }

  /// Handle an invocation of super [method].
  TypeInformation handleSuperMethodInvoke(
      ast.Send node, MethodElement method, ArgumentsTypes arguments) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, method, arguments);
  }

  /// Handle access to a super field or getter [element].
  TypeInformation handleSuperGet(ast.Send node, Element element) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, element, null);
  }

  /// Handle update to a super field or setter [element].
  TypeInformation handleSuperSet(ast.Send node, Element element, ast.Node rhs) {
    TypeInformation rhsType = visit(rhs);
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    isThisExposed = true;
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    handleStaticSend(
        node, selector, mask, element, new ArgumentsTypes([rhsType], null));
    return rhsType;
  }

  @override
  TypeInformation visitSuperFieldSet(
      ast.Send node, FieldElement method, ast.Node rhs, _) {
    return handleSuperSet(node, method, rhs);
  }

  @override
  TypeInformation visitSuperSetterSet(
      ast.Send node, SetterElement field, ast.Node rhs, _) {
    return handleSuperSet(node, field, rhs);
  }

  @override
  TypeInformation visitUnresolvedSuperIndex(
      ast.Send node, Element element, ast.Node index, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitUnresolvedSuperUnary(
      ast.Send node, op.UnaryOperator operator, Element element, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitUnresolvedSuperBinary(ast.Send node, Element element,
      op.BinaryOperator operator, ast.Node argument, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitUnresolvedSuperGet(ast.Send node, Element element, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitSuperSetterGet(ast.Send node, MethodElement setter, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitSuperGetterSet(
      ast.Send node, MethodElement getter, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitSuperMethodSet(
      ast.Send node, MethodElement method, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitFinalSuperFieldSet(
      ast.Send node, FieldElement method, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitUnresolvedSuperSet(
      ast.Send node, Element element, ast.Node rhs, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitUnresolvedSuperInvoke(
      ast.Send node, Element element, ast.Node argument, Selector selector, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitSuperFieldGet(ast.Send node, FieldElement field, _) {
    return handleSuperGet(node, field);
  }

  @override
  TypeInformation visitSuperGetterGet(ast.Send node, MethodElement method, _) {
    return handleSuperGet(node, method);
  }

  @override
  TypeInformation visitSuperMethodGet(ast.Send node, MethodElement method, _) {
    return handleSuperGet(node, method);
  }

  @override
  TypeInformation visitSuperFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperClosureCall(node, field, arguments);
  }

  @override
  TypeInformation visitSuperGetterInvoke(ast.Send node, MethodElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperClosureCall(node, getter, arguments);
  }

  @override
  TypeInformation visitSuperMethodInvoke(ast.Send node, MethodElement method,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(arguments.nodes));
  }

  @override
  TypeInformation visitSuperSetterInvoke(ast.Send node, FunctionElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleErroneousSuperSend(node);
  }

  @override
  TypeInformation visitSuperIndex(
      ast.Send node, MethodElement method, ast.Node index, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  TypeInformation visitSuperEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    // TODO(johnniwinther): Special case ==.
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  TypeInformation visitSuperNotEquals(
      ast.Send node, MethodElement method, ast.Node argument, _) {
    // TODO(johnniwinther): Special case !=.
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  TypeInformation visitSuperBinary(ast.Send node, MethodElement method,
      op.BinaryOperator operator, ast.Node argument, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  TypeInformation visitSuperUnary(
      ast.Send node, op.UnaryOperator operator, MethodElement method, _) {
    return handleSuperMethodInvoke(
        node, method, analyzeArguments(node.arguments));
  }

  @override
  TypeInformation visitSuperMethodIncompatibleInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleErroneousSuperSend(node);
  }

  // Try to find the length given to a fixed array constructor call.
  int findLength(ast.Send node) {
    ast.Node firstArgument = node.arguments.head;
    Element element = elements[firstArgument];
    ast.LiteralInt length = firstArgument.asLiteralInt();
    if (length != null) {
      return length.value;
    } else if (element != null &&
        element.isField &&
        Elements.isStaticOrTopLevelField(element)) {
      FieldElement fieldElement = element;
      if (closedWorld.fieldNeverChanges(fieldElement)) {
        ConstantValue value =
            compiler.backend.constants.getConstantValue(fieldElement.constant);
        if (value != null && value.isInt) {
          IntConstantValue intValue = value;
          return intValue.primitiveValue;
        }
      }
    }
    return null;
  }

  TypeInformation visitAwait(ast.Await node) {
    TypeInformation futureType = node.expression.accept(this);
    return inferrer.registerAwait(node, futureType);
  }

  TypeInformation visitYield(ast.Yield node) {
    TypeInformation operandType = node.expression.accept(this);
    return inferrer.registerYield(node, operandType);
  }

  TypeInformation handleTypeLiteralInvoke(ast.NodeList arguments) {
    // This is reached when users forget to put a `new` in front of a type
    // literal. The emitter will generate an actual call (even though it is
    // likely invalid), and for that it needs to have the arguments processed
    // as well.
    analyzeArguments(arguments.nodes);
    return types.dynamicType;
  }

  /// Handle constructor invocation of [constructor].
  TypeInformation handleConstructorSend(
      ast.Send node, ConstructorElement constructor) {
    ConstructorElement target = constructor.implementation;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (visitingInitializers) {
      if (ast.Initializers.isConstructorRedirect(node)) {
        isConstructorRedirect = true;
      } else if (ast.Initializers.isSuperConstructorCall(node)) {
        seenSuperConstructorCall = true;
        analyzeSuperConstructorCall(constructor, arguments);
      }
    }
    // If we are looking at a new expression on a forwarding factory, we have to
    // forward the call to the effective target of the factory.
    // TODO(herhut): Remove the loop once effectiveTarget forwards to patches.
    while (target.isFactoryConstructor) {
      if (!target.isRedirectingFactory) break;
      target = target.effectiveTarget.implementation;
    }
    if (compiler.backend.isForeign(closedWorld.commonElements, target)) {
      return handleForeignSend(node, target);
    }
    Selector selector = elements.getSelector(node);
    CallStructure callStructure = selector.callStructure;
    TypeMask mask = inTreeData.typeOfSend(node);
    // In erroneous code the number of arguments in the selector might not
    // match the function element.
    // TODO(polux): return nonNullEmpty and check it doesn'TypeInformation break anything
    if (target.isMalformed ||
        !callStructure.signatureApplies(target.parameterStructure)) {
      return types.dynamicType;
    }

    TypeInformation returnType =
        handleStaticSend(node, selector, mask, target, arguments);
    if (Elements.isGrowableListConstructorCall(
        constructor, node, closedWorld.commonElements)) {
      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.growableListType, node,
              outermostElement, types.nonNullEmpty(), 0));
    } else if (Elements.isFixedListConstructorCall(
            constructor, node, closedWorld.commonElements) ||
        Elements.isFilledListConstructorCall(
            constructor, node, closedWorld.commonElements)) {
      int length = findLength(node);
      TypeInformation elementType = Elements.isFixedListConstructorCall(
              constructor, node, closedWorld.commonElements)
          ? types.nullType
          : arguments.positional[1];

      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.fixedListType, node, outermostElement,
              elementType, length));
    } else if (Elements.isConstructorOfTypedArraySubclass(
        constructor, closedWorld)) {
      int length = findLength(node);
      TypeInformation elementType = inferrer
          .returnTypeOfElement(target.enclosingClass.lookupMember('[]'));
      return inferrer.concreteTypes.putIfAbsent(
          node,
          () => types.allocateList(types.nonNullExact(target.enclosingClass),
              node, outermostElement, elementType, length));
    } else {
      return returnType;
    }
  }

  @override
  TypeInformation bulkHandleNew(ast.NewExpression node, _) {
    Element element = elements[node.send];
    return handleConstructorSend(node.send, element);
  }

  @override
  TypeInformation errorNonConstantConstructorInvoke(
      ast.NewExpression node,
      Element element,
      ResolutionDartType type,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return bulkHandleNew(node, _);
  }

  /// Handle invocation of a top level or static field or getter [element].
  TypeInformation handleStaticFieldOrGetterInvoke(
      ast.Send node, Element element) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    handleStaticSend(node, selector, mask, element, arguments);
    return inferrer.registerCalledClosure(
        node,
        selector,
        mask,
        inferrer.typeOfElement(element),
        outermostElement,
        arguments,
        sideEffects,
        inLoop);
  }

  /// Handle invocation of a top level or static [function].
  TypeInformation handleStaticFunctionInvoke(
      ast.Send node, MethodElement function) {
    if (compiler.backend.isForeign(closedWorld.commonElements, function)) {
      return handleForeignSend(node, function);
    }
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, function, arguments);
  }

  /// Handle an static invocation of an unresolved target or with incompatible
  /// arguments to a resolved target.
  TypeInformation handleInvalidStaticInvoke(ast.Send node) {
    analyzeArguments(node.arguments);
    return types.dynamicType;
  }

  @override
  TypeInformation visitStaticFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, field);
  }

  @override
  TypeInformation visitStaticFunctionInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleStaticFunctionInvoke(node, function);
  }

  @override
  TypeInformation visitStaticFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  TypeInformation visitStaticGetterInvoke(ast.Send node, FunctionElement getter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, getter);
  }

  @override
  TypeInformation visitTopLevelFieldInvoke(ast.Send node, FieldElement field,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleStaticFieldOrGetterInvoke(node, field);
  }

  @override
  TypeInformation visitTopLevelFunctionInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleStaticFunctionInvoke(node, function);
  }

  @override
  TypeInformation visitTopLevelFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  TypeInformation visitTopLevelGetterInvoke(
      ast.Send node,
      FunctionElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleStaticFieldOrGetterInvoke(node, getter);
  }

  @override
  TypeInformation visitStaticSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  TypeInformation visitTopLevelSetterInvoke(ast.Send node, MethodElement setter,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleInvalidStaticInvoke(node);
  }

  @override
  TypeInformation visitUnresolvedInvoke(ast.Send node, Element element,
      ast.NodeList arguments, Selector selector, _) {
    return handleInvalidStaticInvoke(node);
  }

  TypeInformation handleForeignSend(ast.Send node, Element element) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    String name = element.name;
    handleStaticSend(node, selector, mask, element, arguments);
    if (name == JavaScriptBackend.JS ||
        name == JavaScriptBackend.JS_EMBEDDED_GLOBAL ||
        name == JavaScriptBackend.JS_BUILTIN) {
      native.NativeBehavior nativeBehavior = elements.getNativeData(node);
      sideEffects.add(nativeBehavior.sideEffects);
      return inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == 'JS_OPERATOR_AS_PREFIX' || name == 'JS_STRING_CONCAT') {
      return types.stringType;
    } else {
      sideEffects.setAllSideEffects();
      return types.dynamicType;
    }
  }

  ArgumentsTypes analyzeArguments(Link<ast.Node> arguments) {
    List positional = [];
    Map<String, TypeInformation> named;
    for (var argument in arguments) {
      ast.NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        argument = namedArgument.expression;
        if (named == null) named = new Map<String, TypeInformation>();
        named[namedArgument.name.source] = argument.accept(this);
      } else {
        positional.add(argument.accept(this));
      }
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      isThisExposed = isThisExposed || argument.isThis();
    }
    return new ArgumentsTypes(positional, named);
  }

  /// Read a local variable, function or parameter.
  TypeInformation handleLocalGet(ast.Send node, LocalElement local) {
    assert(locals.use(local) != null);
    return locals.use(local);
  }

  /// Read a static or top level field.
  TypeInformation handleStaticFieldGet(ast.Send node, FieldElement field) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, field, null);
  }

  /// Invoke a static or top level getter.
  TypeInformation handleStaticGetterGet(ast.Send node, MethodElement getter) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, getter, null);
  }

  /// Closurize a static or top level function.
  TypeInformation handleStaticFunctionGet(
      ast.Send node, MethodElement function) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return handleStaticSend(node, selector, mask, function, null);
  }

  @override
  TypeInformation visitDynamicPropertyGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  TypeInformation visitIfNotNullDynamicPropertyGet(
      ast.Send node, ast.Node receiver, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  TypeInformation visitLocalVariableGet(
      ast.Send node, LocalVariableElement variable, _) {
    return handleLocalGet(node, variable);
  }

  @override
  TypeInformation visitParameterGet(
      ast.Send node, ParameterElement parameter, _) {
    return handleLocalGet(node, parameter);
  }

  @override
  TypeInformation visitLocalFunctionGet(
      ast.Send node, LocalFunctionElement function, _) {
    return handleLocalGet(node, function);
  }

  @override
  TypeInformation visitStaticFieldGet(ast.Send node, FieldElement field, _) {
    return handleStaticFieldGet(node, field);
  }

  @override
  TypeInformation visitStaticFunctionGet(
      ast.Send node, MethodElement function, _) {
    return handleStaticFunctionGet(node, function);
  }

  @override
  TypeInformation visitStaticGetterGet(
      ast.Send node, FunctionElement getter, _) {
    return handleStaticGetterGet(node, getter);
  }

  @override
  TypeInformation visitThisPropertyGet(ast.Send node, Name name, _) {
    return handleDynamicGet(node);
  }

  @override
  TypeInformation visitTopLevelFieldGet(ast.Send node, FieldElement field, _) {
    return handleStaticFieldGet(node, field);
  }

  @override
  TypeInformation visitTopLevelFunctionGet(
      ast.Send node, MethodElement function, _) {
    return handleStaticFunctionGet(node, function);
  }

  @override
  TypeInformation visitTopLevelGetterGet(
      ast.Send node, FunctionElement getter, _) {
    return handleStaticGetterGet(node, getter);
  }

  @override
  TypeInformation visitStaticSetterGet(ast.Send node, MethodElement setter, _) {
    return types.dynamicType;
  }

  @override
  TypeInformation visitTopLevelSetterGet(
      ast.Send node, MethodElement setter, _) {
    return types.dynamicType;
  }

  @override
  TypeInformation visitUnresolvedGet(ast.Send node, Element element, _) {
    return types.dynamicType;
  }

  /// Handle .call invocation on [closure].
  TypeInformation handleCallInvoke(ast.Send node, TypeInformation closure) {
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    return inferrer.registerCalledClosure(node, selector, mask, closure,
        outermostElement, arguments, sideEffects, inLoop);
  }

  @override
  TypeInformation visitExpressionInvoke(ast.Send node, ast.Node expression,
      ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, expression.accept(this));
  }

  @override
  TypeInformation visitThisInvoke(
      ast.Send node, ast.NodeList arguments, CallStructure callStructure, _) {
    return handleCallInvoke(node, thisType);
  }

  @override
  TypeInformation visitParameterInvoke(
      ast.Send node,
      ParameterElement parameter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleCallInvoke(node, locals.use(parameter));
  }

  @override
  TypeInformation visitLocalVariableInvoke(
      ast.Send node,
      LocalVariableElement variable,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleCallInvoke(node, locals.use(variable));
  }

  @override
  TypeInformation visitLocalFunctionInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    ArgumentsTypes argumentTypes = analyzeArguments(node.arguments);
    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    // This only works for function statements. We need a
    // more sophisticated type system with function types to support
    // more.
    return inferrer.registerCalledElement(node, selector, mask,
        outermostElement, function, argumentTypes, sideEffects, inLoop);
  }

  @override
  TypeInformation visitLocalFunctionIncompatibleInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    analyzeArguments(node.arguments);
    return types.dynamicType;
  }

  TypeInformation handleStaticSend(ast.Node node, Selector selector,
      TypeMask mask, Element element, ArgumentsTypes arguments) {
    assert(!element.isFactoryConstructor ||
        !(element as ConstructorElement).isRedirectingFactory);
    // Erroneous elements may be unresolved, for example missing getters.
    if (Elements.isUnresolved(element)) return types.dynamicType;
    // TODO(herhut): should we follow redirecting constructors here? We would
    // need to pay attention if the constructor is pointing to an erroneous
    // element.
    return inferrer.registerCalledElement(node, selector, mask,
        outermostElement, element, arguments, sideEffects, inLoop);
  }

  TypeInformation handleDynamicSend(ast.Node node, Selector selector,
      TypeMask mask, TypeInformation receiverType, ArgumentsTypes arguments) {
    assert(receiverType != null);
    if (types.selectorNeedsUpdate(receiverType, mask)) {
      mask = receiverType == types.dynamicType
          ? null
          : types.newTypedSelector(receiverType, mask);
      inferrer.updateSelectorInTree(analyzedElement, node, selector, mask);
    }

    // If the receiver of the call is a local, we may know more about
    // its type by refining it with the potential targets of the
    // calls.
    ast.Send send = node.asSend();
    if (send != null) {
      ast.Node receiver = send.receiver;
      if (receiver != null) {
        Element element = elements[receiver];
        if (Elements.isLocal(element) && !capturedVariables.contains(element)) {
          TypeInformation refinedType = types.refineReceiver(
              selector, mask, receiverType, send.isConditional);
          locals.update(element, refinedType, node);
        }
      }
    }

    return inferrer.registerCalledSelector(node, selector, mask, receiverType,
        outermostElement, arguments, sideEffects, inLoop);
  }

  TypeInformation handleDynamicInvoke(ast.Send node) {
    return _handleDynamicSend(node);
  }

  TypeInformation handleDynamicGet(ast.Send node) {
    return _handleDynamicSend(node);
  }

  TypeInformation _handleDynamicSend(ast.Send node) {
    Element element = elements[node];
    TypeInformation receiverType;
    bool isCallOnThis = false;
    if (node.receiver == null) {
      if (treatAsInstanceMember(element)) {
        isCallOnThis = true;
        receiverType = thisType;
      }
    } else {
      ast.Node receiver = node.receiver;
      isCallOnThis = isThisOrSuper(receiver);
      receiverType = visit(receiver);
    }

    Selector selector = elements.getSelector(node);
    TypeMask mask = inTreeData.typeOfSend(node);
    if (!isThisExposed && isCallOnThis) {
      checkIfExposesThis(selector, types.newTypedSelector(receiverType, mask));
    }

    ArgumentsTypes arguments =
        node.isPropertyAccess ? null : analyzeArguments(node.arguments);
    if (selector.name == '==' || selector.name == '!=') {
      if (types.isNull(receiverType)) {
        potentiallyAddNullCheck(node, node.arguments.head);
        return types.boolType;
      } else if (types.isNull(arguments.positional[0])) {
        potentiallyAddNullCheck(node, node.receiver);
        return types.boolType;
      }
    }
    return handleDynamicSend(node, selector, mask, receiverType, arguments);
  }

  void recordReturnType(TypeInformation type) {
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  TypeInformation synthesizeForwardingCall(
      Spannable node, ConstructorElement element) {
    element = element.implementation;
    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.functionSignature;
    FunctionSignature calleeSignature = element.functionSignature;
    if (!calleeSignature.isCompatibleWith(signature)) {
      return types.nonNullEmpty();
    }

    List<TypeInformation> unnamed = <TypeInformation>[];
    signature.forEachRequiredParameter((FormalElement _element) {
      ParameterElement element = _element;
      assert(locals.use(element) != null);
      unnamed.add(locals.use(element));
    });

    Map<String, TypeInformation> named;
    if (signature.optionalParametersAreNamed) {
      named = new Map<String, TypeInformation>();
      signature.forEachOptionalParameter((FormalElement _element) {
        ParameterElement element = _element;
        named[element.name] = locals.use(element);
      });
    } else {
      signature.forEachOptionalParameter((FormalElement _element) {
        ParameterElement element = _element;
        unnamed.add(locals.use(element));
      });
    }

    ArgumentsTypes arguments = new ArgumentsTypes(unnamed, named);
    return inferrer.registerCalledElement(node, null, null, outermostElement,
        element, arguments, sideEffects, inLoop);
  }

  TypeInformation visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    ConstructorElement element = elements.getRedirectingTargetConstructor(node);
    if (Elements.isMalformed(element)) {
      recordReturnType(types.dynamicType);
    } else {
      // We don'TypeInformation create a selector for redirecting factories, and
      // the send is just a property access. Therefore we must
      // manually create the [ArgumentsTypes] of the call, and
      // manually register [analyzedElement] as a caller of [element].
      TypeInformation mask =
          synthesizeForwardingCall(node.constructorReference, element);
      recordReturnType(mask);
    }
    locals.seenReturnOrThrow = true;
    return null;
  }

  TypeInformation visitReturn(ast.Return node) {
    ast.Node expression = node.expression;
    recordReturnType(
        expression == null ? types.nullType : expression.accept(this));
    locals.seenReturnOrThrow = true;
    initializationIsIndefinite();
    return null;
  }

  TypeInformation handleForInLoop(
      ast.ForIn node,
      TypeInformation iteratorType,
      Selector currentSelector,
      TypeMask currentMask,
      Selector moveNextSelector,
      TypeMask moveNextMask) {
    handleDynamicSend(node, moveNextSelector, moveNextMask, iteratorType,
        new ArgumentsTypes.empty());
    TypeInformation currentType = handleDynamicSend(node, currentSelector,
        currentMask, iteratorType, new ArgumentsTypes.empty());

    if (node.expression.isThis()) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      isThisExposed = true;
    }

    ast.Node identifier = node.declaredIdentifier;
    Element element = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);
    TypeMask mask = inTreeData.typeOfSend(identifier.asSend());

    TypeInformation receiverType;
    if (element != null && element.isInstanceMember) {
      receiverType = thisType;
    } else {
      receiverType = types.dynamicType;
    }

    handlePlainAssignment(identifier, element, selector, mask, receiverType,
        currentType, node.expression);
    return handleLoop(node, () {
      visit(node.body);
    });
  }

  TypeInformation visitAsyncForIn(ast.AsyncForIn node) {
    TypeInformation expressionType = visit(node.expression);

    Selector currentSelector = Selectors.current;
    TypeMask currentMask = inTreeData.typeOfIteratorCurrent(node);
    Selector moveNextSelector = Selectors.moveNext;
    TypeMask moveNextMask = inTreeData.typeOfIteratorMoveNext(node);

    ConstructorElement ctor =
        closedWorld.commonElements.streamIteratorConstructor;

    /// Synthesize a call to the [StreamIterator] constructor.
    TypeInformation iteratorType = handleStaticSend(
        node, null, null, ctor, new ArgumentsTypes([expressionType], null));

    return handleForInLoop(node, iteratorType, currentSelector, currentMask,
        moveNextSelector, moveNextMask);
  }

  TypeInformation visitSyncForIn(ast.SyncForIn node) {
    TypeInformation expressionType = visit(node.expression);
    Selector iteratorSelector = Selectors.iterator;
    TypeMask iteratorMask = inTreeData.typeOfIterator(node);
    Selector currentSelector = Selectors.current;
    TypeMask currentMask = inTreeData.typeOfIteratorCurrent(node);
    Selector moveNextSelector = Selectors.moveNext;
    TypeMask moveNextMask = inTreeData.typeOfIteratorMoveNext(node);

    TypeInformation iteratorType = handleDynamicSend(node, iteratorSelector,
        iteratorMask, expressionType, new ArgumentsTypes.empty());

    return handleForInLoop(node, iteratorType, currentSelector, currentMask,
        moveNextSelector, moveNextMask);
  }
}
