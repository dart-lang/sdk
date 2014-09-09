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
  final ElementConverter elementConverter;
  final IrBuilder irBuilder = new IrBuilder();

  CpsGeneratingVisitor(this.elementConverter);

  @override
  ir.FunctionDefinition visitFunctionDeclaration(FunctionDeclaration node) {
    analyzer.FunctionElement function = node.element;
    super.visitFunctionDeclaration(node);
    return irBuilder.buildFunctionDefinition(
        elementConverter.convertElement(function),
            const [], const [], const []);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    analyzer.Element staticElement = node.methodName.staticElement;
    if (staticElement != null) {
      dart2js.Element element = elementConverter.convertElement(staticElement);
      return irBuilder.buildStaticInvocation(
          element, createSelectorFromMethodInvocation(node), []);
    }
  }
}
