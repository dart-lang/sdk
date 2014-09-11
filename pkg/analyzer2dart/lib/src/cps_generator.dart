// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer2dart.cps_generator;

import 'package:analyzer/analyzer.dart';

import 'package:compiler/implementation/elements/elements.dart' as dart2js;
import 'package:analyzer/src/generated/element.dart' as analyzer;

import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart' as ir;
import 'package:compiler/implementation/cps_ir/cps_ir_builder.dart';

import 'element_converter.dart';
import 'tree_shaker.dart';


class CpsGeneratingVisitor extends RecursiveAstVisitor<ir.Node> {
  final ElementConverter converter;
  final IrBuilder irBuilder = new IrBuilder();

  CpsGeneratingVisitor(this.converter);

  giveUp(String reason) {
    throw new UnsupportedError(reason);
  }

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
  visitMethodInvocation(MethodInvocation node) {
    analyzer.Element staticElement = node.methodName.staticElement;
    if (staticElement != null) {
      dart2js.Element element = converter.convertElement(staticElement);
      List<ir.Definition> arguments = <ir.Definition>[];
      for (Expression argument in node.argumentList.arguments) {
        ir.Definition value = argument.accept(this);
        if (value == null) {
          giveUp('Unsupported argument: $argument (${argument.runtimeType}).');
        }
        arguments.add(value);
      }
      return irBuilder.buildStaticInvocation(
          element, createSelectorFromMethodInvocation(node), arguments);
    }
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
    giveUp("Non constant adjacent strings.");
  }

  @override
  ir.Constant visitSimpleStringLiteral(SimpleStringLiteral node) {
    return irBuilder.buildStringLiteral(node.value);
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    giveUp("String interpolation.");
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
  visitSimpleIdentifier(SimpleIdentifier node) {
    analyzer.Element element = node.staticElement;
    if (element != null) {
      dart2js.Element target = converter.convertElement(element);
      if (dart2js.Elements.isLocal(target)) {
        return irBuilder.buildGetLocal(target);
      }
      giveUp('Unhandled static reference: '
             '$node -> $target (${target.runtimeType})');
    }
    giveUp('Unresolved identifier: $node.');
  }
}
