// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.cps_generator;

import 'package:analyzer/analyzer.dart';

import 'package:compiler/src/dart_types.dart' as dart2js;
import 'package:compiler/src/elements/elements.dart' as dart2js;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/element.dart' as analyzer;

import 'package:compiler/src/dart2jslib.dart'
    show DART_CONSTANT_SYSTEM;
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart' as ir;
import 'package:compiler/src/cps_ir/cps_ir_builder.dart';
import 'package:compiler/src/universe/universe.dart';

import 'semantic_visitor.dart';
import 'element_converter.dart';
import 'util.dart';
import 'identifier_semantics.dart';

class CpsGeneratingVisitor extends SemanticVisitor<ir.Node>
    with IrBuilderMixin<AstNode> {
  final analyzer.Element element;
  final ElementConverter converter;

  CpsGeneratingVisitor(this.converter, this.element);

  Source get currentSource => element.source;

  analyzer.LibraryElement get currentLibrary => element.library;

  ir.Node visit(AstNode node) => node.accept(this);

  @override
  ir.Primitive visitFunctionExpression(FunctionExpression node) {
    return irBuilder.buildFunctionExpression(
        handleFunctionDeclaration(node.element, node));
  }

  ir.FunctionDefinition handleFunctionDeclaration(
      analyzer.FunctionElement function, FunctionExpression node) {
    dart2js.FunctionElement element = converter.convertElement(function);
    return withBuilder(
        new IrBuilder(DART_CONSTANT_SYSTEM,
                      element,
                      // TODO(johnniwinther): Supported closure variables.
                      const <dart2js.Local>[]),
        () {
      function.parameters.forEach((analyzer.ParameterElement parameter) {
        // TODO(johnniwinther): Support "closure variables", that is variables
        // accessed from an inner function.
        irBuilder.createParameter(converter.convertElement(parameter));
      });
      // Visit the body directly to avoid processing the signature as
      // expressions.
      visit(node.body);
      return irBuilder.buildFunctionDefinition(element, const []);
    });
  }

  @override
  ir.FunctionDefinition visitFunctionDeclaration(FunctionDeclaration node) {
    return handleFunctionDeclaration(node.element, node.functionExpression);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclaration functionDeclaration = node.functionDeclaration;
    analyzer.FunctionElement function = functionDeclaration.element;
    dart2js.FunctionElement element = converter.convertElement(function);
    ir.FunctionDefinition definition = handleFunctionDeclaration(
        function, functionDeclaration.functionExpression);
    irBuilder.declareLocalFunction(element, definition);
  }

  List<ir.Primitive> visitArguments(ArgumentList argumentList) {
    List<ir.Primitive> arguments = <ir.Primitive>[];
    for (Expression argument in argumentList.arguments) {
      ir.Primitive value = build(argument);
      if (value == null) {
        giveUp(argument,
            'Unsupported argument: $argument (${argument.runtimeType}).');
      }
      arguments.add(value);
    }
    return arguments;
  }

  @override
  ir.Node visitMethodInvocation(MethodInvocation node) {
    // Overridden to avoid eager visits of the receiver and arguments.
    return handleMethodInvocation(node);
  }

  @override
  ir.Primitive visitDynamicInvocation(MethodInvocation node,
                                      AccessSemantics semantics) {
    // TODO(johnniwinther): Handle implicit `this`.
    ir.Primitive receiver = build(semantics.target);
    List<ir.Primitive> arguments = visitArguments(node.argumentList);
    return irBuilder.buildDynamicInvocation(
        receiver,
        createSelectorFromMethodInvocation(
            node.argumentList, node.methodName.name),
        arguments);
  }

  @override
  ir.Primitive visitStaticMethodInvocation(MethodInvocation node,
                                           AccessSemantics semantics) {
    analyzer.Element staticElement = semantics.element;
    dart2js.Element element = converter.convertElement(staticElement);
    List<ir.Primitive> arguments = visitArguments(node.argumentList);
    return irBuilder.buildStaticInvocation(
        element,
        createSelectorFromMethodInvocation(
            node.argumentList, node.methodName.name),
        arguments);
  }

  @override
  ir.Node visitLocalFunctionAccess(AstNode node, AccessSemantics semantics) {
    return handleLocalAccess(node, semantics);
  }

  ir.Primitive handleLocalInvocation(MethodInvocation node,
                                     AccessSemantics semantics) {
    analyzer.Element staticElement = semantics.element;
    dart2js.Element element = converter.convertElement(staticElement);
    List<ir.Definition> arguments = visitArguments(node.argumentList);
    return irBuilder.buildLocalInvocation(
      element,
      createSelectorFromMethodInvocation(
          node.argumentList, node.methodName.name),
      arguments);
  }

  @override
  ir.Node visitLocalVariableInvocation(MethodInvocation node,
                                       AccessSemantics semantics) {
    return handleLocalInvocation(node, semantics);
  }

  @override
  ir.Primitive visitLocalFunctionInvocation(MethodInvocation node,
                                            AccessSemantics semantics) {
    return handleLocalInvocation(node, semantics);
  }

  @override
  ir.Primitive visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    ir.Primitive target = build(node.function);
    List<ir.Definition> arguments = visitArguments(node.argumentList);
    return irBuilder.buildFunctionExpressionInvocation(
        target,
        createSelectorFromMethodInvocation(node.argumentList, 'call'),
        arguments);
  }

  @override
  ir.Primitive visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    analyzer.Element staticElement = node.staticElement;
    if (staticElement != null) {
      dart2js.Element element = converter.convertElement(staticElement);
      dart2js.DartType type = converter.convertType(node.staticType);
      List<ir.Primitive> arguments = visitArguments(node.argumentList);
      String name = '';
      if (node.constructorName.name != null) {
        name = node.constructorName.name.name;
      }
      return irBuilder.buildConstructorInvocation(
          element,
          createSelectorFromMethodInvocation(node.argumentList, name),
          type,
          arguments);
    }
    return giveUp(node, "Unresolved constructor invocation.");
  }

  @override
  ir.Constant visitNullLiteral(NullLiteral node) {
    return irBuilder.buildNullLiteral();
  }

  @override
  ir.Constant visitBooleanLiteral(BooleanLiteral node) {
    return irBuilder.buildBooleanLiteral(node.value);
  }

  @override
  ir.Constant visitDoubleLiteral(DoubleLiteral node) {
    return irBuilder.buildDoubleLiteral(node.value);
  }

  @override
  ir.Constant visitIntegerLiteral(IntegerLiteral node) {
    return irBuilder.buildIntegerLiteral(node.value);
  }

  @override
  visitAdjacentStrings(AdjacentStrings node) {
    String value = node.stringValue;
    if (value != null) {
      return irBuilder.buildStringLiteral(value);
    }
    giveUp(node, "Non constant adjacent strings.");
  }

  @override
  ir.Constant visitSimpleStringLiteral(SimpleStringLiteral node) {
    return irBuilder.buildStringLiteral(node.value);
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    giveUp(node, "String interpolation.");
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    irBuilder.buildReturn(build(node.expression));
  }

  @override
  ir.Node visitPropertyAccess(PropertyAccess node) {
    // Overridden to avoid eager visits of the receiver.
    return handlePropertyAccess(node);
  }

  @override
  ir.Node visitLocalVariableAccess(AstNode node, AccessSemantics semantics) {
    return handleLocalAccess(node, semantics);
  }

  @override
  ir.Node visitParameterAccess(AstNode node, AccessSemantics semantics) {
    return handleLocalAccess(node, semantics);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    // TODO(johnniwinther): Handle constant local variables.
    ir.Node initialValue = build(node.initializer);
    irBuilder.declareLocalVariable(
        converter.convertElement(node.element),
        initialValue: initialValue);
  }

  dart2js.Element getLocal(AstNode node, AccessSemantics semantics) {
    analyzer.Element element = semantics.element;
    dart2js.Element target = converter.convertElement(element);
    assert(invariant(node, target.isLocal, '$target expected to be local.'));
    return target;
  }

  ir.Primitive handleLocalAccess(AstNode node, AccessSemantics semantics) {
    return irBuilder.buildLocalGet(getLocal(node, semantics));
  }

  ir.Primitive handleLocalAssignment(AssignmentExpression node,
                                     AccessSemantics semantics) {
    if (node.operator.lexeme != '=') {
      return giveUp(node, 'Assignment operator: ${node.operator.lexeme}');
    }
    return irBuilder.buildLocalSet(
        getLocal(node, semantics),
        build(node.rightHandSide));
  }

  @override
  ir.Node visitAssignmentExpression(AssignmentExpression node) {
    // Avoid eager visiting of left and right hand side.
    return handleAssignmentExpression(node);
  }

  @override
  ir.Node visitLocalVariableAssignment(AssignmentExpression node,
                                       AccessSemantics semantics) {
    return handleLocalAssignment(node, semantics);
  }

  @override
  ir.Node visitParameterAssignment(AssignmentExpression node,
                                   AccessSemantics semantics) {
    return handleLocalAssignment(node, semantics);
  }

  @override
  ir.Node visitDynamicAccess(AstNode node, AccessSemantics semantics) {
    // TODO(johnniwinther): Handle implicit `this`.
    ir.Primitive receiver = build(semantics.target);
    return irBuilder.buildDynamicGet(receiver,
        new Selector.getter(semantics.identifier.name,
                            converter.convertElement(element.library)));
  }

  @override
  ir.Node visitStaticFieldAccess(AstNode node, AccessSemantics semantics) {
    analyzer.Element element = semantics.element;
    dart2js.Element target = converter.convertElement(element);
    // TODO(johnniwinther): Selector information should be computed in the
    // [TreeShaker] and shared with the [CpsGeneratingVisitor].
    assert(invariant(node, target.isTopLevel || target.isStatic,
                     '$target expected to be top-level or static.'));
    return irBuilder.buildStaticGet(target,
        new Selector.getter(target.name, target.library));
  }

  ir.Primitive handleBinaryExpression(BinaryExpression node,
                                      String op) {
    ir.Primitive left = build(node.leftOperand);
    ir.Primitive right = build(node.rightOperand);
    Selector selector = new Selector.binaryOperator(op);
    return irBuilder.buildDynamicInvocation(
        left, selector, <ir.Primitive>[right]);
  }

  ir.Node handleLazyOperator(BinaryExpression node, {bool isLazyOr: false}) {
    return irBuilder.buildLogicalOperator(
        build(node.leftOperand),
        subbuild(node.rightOperand),
        isLazyOr: isLazyOr);
  }

  @override
  ir.Node visitBinaryExpression(BinaryExpression node) {
    // TODO(johnniwinther,paulberry,brianwilkerson): The operator should be
    // available through an enum.
    String op = node.operator.lexeme;
    switch (op) {
    case '||':
    case '&&':
      return handleLazyOperator(node, isLazyOr: op == '||');
    case '!=':
      return irBuilder.buildNegation(handleBinaryExpression(node, '=='));
    default:
      return handleBinaryExpression(node, op);
    }
  }

  @override
  ir.Node visitConditionalExpression(ConditionalExpression node) {
    return irBuilder.buildConditional(
        build(node.condition),
        subbuild(node.thenExpression),
        subbuild(node.elseExpression));
  }

  @override
  visitIfStatement(IfStatement node) {
    irBuilder.buildIf(
        build(node.condition),
        subbuild(node.thenStatement),
        subbuild(node.elseStatement));
  }

  @override
  visitBlock(Block node) {
    irBuilder.buildBlock(node.statements, build);
  }

  @override
  ir.Node visitListLiteral(ListLiteral node) {
    dart2js.InterfaceType type = converter.convertType(node.staticType);
    // TODO(johnniwinther): Use `build` instead of `(e) => build(e)` when issue
    // 18630 has been resolved.
    Iterable<ir.Primitive> values = node.elements.map((e) => build(e));
    return irBuilder.buildListLiteral(type, values);
  }

  @override
  ir.Node visitMapLiteral(MapLiteral node) {
    dart2js.InterfaceType type = converter.convertType(node.staticType);
    return irBuilder.buildMapLiteral(
        type,
        node.entries.map((e) => e.key),
        node.entries.map((e) => e.value),
        build);
  }

  @override
  visitForStatement(ForStatement node) {
    // TODO(johnniwinther): Support `for` as a jump target.
    SubbuildFunction buildInitializer;
    if (node.variables != null) {
      buildInitializer = subbuild(node.variables);
    } else {
      buildInitializer = subbuild(node.initialization);
    }
    irBuilder.buildFor(buildInitializer: buildInitializer,
                       buildCondition: subbuild(node.condition),
                       buildBody: subbuild(node.body),
                       buildUpdate: subbuildSequence(node.updaters));
  }

  @override
  visitWhileStatement(WhileStatement node) {
    // TODO(johnniwinther): Support `while` as a jump target.
    irBuilder.buildWhile(buildCondition: subbuild(node.condition),
                         buildBody: subbuild(node.body));
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    giveUp(node, "Unexpected node: DeclaredIdentifier");
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    SubbuildFunction buildVariableDeclaration;
    dart2js.Element variableElement;
    Selector variableSelector;
    if (node.identifier != null) {
       AccessSemantics accessSemantics =
           node.identifier.accept(ACCESS_SEMANTICS_VISITOR);
       if (accessSemantics.kind == AccessKind.DYNAMIC) {
         variableSelector = new Selector.setter(
             node.identifier.name, converter.convertElement(currentLibrary));
       } else if (accessSemantics.element != null) {
         variableElement = converter.convertElement(accessSemantics.element);
         variableSelector = new Selector.setter(
             variableElement.name,
             converter.convertElement(accessSemantics.element.library));
       } else {
         giveUp(node, 'For-in of unresolved variable: $accessSemantics');
       }
    } else {
      assert(invariant(
          node, node.loopVariable != null, "Loop variable expected"));
      variableElement = converter.convertElement(node.loopVariable.element);
      buildVariableDeclaration = (IrBuilder builder) {
        builder.declareLocalVariable(variableElement);
      };
    }
    // TODO(johnniwinther): Support `for-in` as a jump target.
    irBuilder.buildForIn(
        buildExpression: subbuild(node.iterable),
        buildVariableDeclaration: buildVariableDeclaration,
        variableElement: variableElement,
        variableSelector: variableSelector,
        buildBody: subbuild(node.body));
  }
  @override
  ir.Primitive visitIsExpression(IsExpression node) {
    return irBuilder.buildTypeOperator(
        visit(node.expression),
        converter.convertType(node.type.type),
        isTypeTest: true,
        isNotCheck: node.notOperator != null);
  }

  @override
  ir.Primitive visitAsExpression(AsExpression node) {
    return irBuilder.buildTypeOperator(
        visit(node.expression),
        converter.convertType(node.type.type),
        isTypeTest: false);
  }
}
