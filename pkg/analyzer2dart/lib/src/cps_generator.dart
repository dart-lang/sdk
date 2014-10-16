// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.cps_generator;

import 'package:analyzer/analyzer.dart';

import 'package:compiler/implementation/elements/elements.dart' as dart2js;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/element.dart' as analyzer;

import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart' as ir;
import 'package:compiler/implementation/cps_ir/cps_ir_builder.dart';
import 'package:compiler/implementation/universe/universe.dart';

import 'semantic_visitor.dart';
import 'element_converter.dart';
import 'util.dart';
import 'package:analyzer2dart/src/identifier_semantics.dart';

class CpsGeneratingVisitor extends SemanticVisitor<ir.Node> {
  final analyzer.Element element;
  final ElementConverter converter;
  final IrBuilder irBuilder = new IrBuilder();

  CpsGeneratingVisitor(this.converter, this.element);

  Source get currentSource => element.source;

  @override
  ir.FunctionDefinition visitFunctionDeclaration(FunctionDeclaration node) {
    analyzer.FunctionElement function = node.element;
    function.parameters.forEach((analyzer.ParameterElement parameter) {
      // TODO(johnniwinther): Support "closure variables", that is variables
      // accessed from an inner function.
      irBuilder.createParameter(converter.convertElement(parameter),
                                isClosureVariable: false);
    });
    // Visit the body directly to avoid processing the signature as expressions.
    node.functionExpression.body.accept(this);
    return irBuilder.buildFunctionDefinition(
        converter.convertElement(function), const [], const []);
  }

  @override
  visitStaticMethodInvocation(MethodInvocation node,
                              AccessSemantics semantics) {
    analyzer.Element staticElement = semantics.element;
    dart2js.Element element = converter.convertElement(staticElement);
    List<ir.Definition> arguments = <ir.Definition>[];
    for (Expression argument in node.argumentList.arguments) {
      ir.Definition value = argument.accept(this);
      if (value == null) {
        giveUp(argument,
            'Unsupported argument: $argument (${argument.runtimeType}).');
      }
      arguments.add(value);
    }
    return irBuilder.buildStaticInvocation(
        element,
        createSelectorFromMethodInvocation(node, node.methodName.name),
        arguments);
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
    if (node.expression != null) {
      irBuilder.buildReturn(node.expression.accept(this));
    } else {
      irBuilder.buildReturn();
    }
  }

  @override
  ir.Node visitLocalVariableAccess(AstNode node, AccessSemantics semantics) {
    return handleLocalAccess(node, semantics);
  }

  @override
  ir.Node visitParameterAccess(AstNode node, AccessSemantics semantics) {
    return handleLocalAccess(node, semantics);
  }

  ir.Primitive handleLocalAccess(AstNode node, AccessSemantics semantics) {
    analyzer.Element element = semantics.element;
    dart2js.Element target = converter.convertElement(element);
    assert(invariant(node, target.isLocal, '$target expected to be local.'));
    return irBuilder.buildGetLocal(target);
  }

  @override
  ir.Node visitStaticFieldAccess(AstNode node, AccessSemantics semantics) {
    analyzer.Element element = semantics.element;
    dart2js.Element target = converter.convertElement(element);
    // TODO(johnniwinther): Selector information should be computed in the
    // [TreeShaker] and shared with the [CpsGeneratingVisitor].
    assert(invariant(node, target.isTopLevel || target.isStatic,
        '$target expected to be top-level or static.'));
    return irBuilder.buildGetStatic(target,
        new Selector.getter(target.name, target.library));
  }
}
