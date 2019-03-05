// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_collections;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Block,
        BlockExpression,
        Expression,
        ExpressionStatement,
        ForInStatement,
        InterfaceType,
        InvalidExpression,
        ListLiteral,
        MethodInvocation,
        Name,
        Procedure,
        Statement,
        TreeNode,
        VariableDeclaration,
        VariableGet;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show Transformer;

import 'collections.dart' show SpreadElement;

import '../source/source_loader.dart' show SourceLoader;

class CollectionTransformer extends Transformer {
  final CoreTypes coreTypes;
  final Procedure listAdd;

  CollectionTransformer(SourceLoader loader)
      : coreTypes = loader.coreTypes,
        listAdd = loader.coreTypes.index.getMember('dart:core', 'List', 'add');

  @override
  TreeNode visitListLiteral(ListLiteral node) {
    int i = 0;
    for (; i < node.expressions.length; ++i) {
      if (node.expressions[i] is SpreadElement) break;
      node.expressions[i] = node.expressions[i].accept(this)..parent = node;
    }

    if (i == node.expressions.length) return node;

    if (node.isConst) {
      // We don't desugar const lists here.  Remove spread for now so that they
      // don't leak out.
      for (; i < node.expressions.length; ++i) {
        Expression element = node.expressions[i];
        if (element is SpreadElement) {
          element.parent.replaceChild(
              element,
              InvalidExpression('unimplemented spread element')
                ..fileOffset = element.fileOffset);
        }
      }
    }

    VariableDeclaration list = new VariableDeclaration.forValue(
        new ListLiteral([], typeArgument: node.typeArgument),
        type: new InterfaceType(coreTypes.listClass, [node.typeArgument]),
        isFinal: true);
    List<Statement> body = [list];
    for (int j = 0; j < i; ++j) {
      body.add(new ExpressionStatement(new MethodInvocation(
          new VariableGet(list),
          new Name('add'),
          new Arguments([node.expressions[j]]),
          listAdd)));
    }
    for (; i < node.expressions.length; ++i) {
      Expression element = node.expressions[i];
      if (element is SpreadElement) {
        VariableDeclaration elt = new VariableDeclaration(null,
            type: node.typeArgument, isFinal: true);
        body.add(new ForInStatement(
            elt,
            element.expression.accept(this),
            new ExpressionStatement(new MethodInvocation(
                new VariableGet(list),
                new Name('add'),
                new Arguments([new VariableGet(elt)]),
                listAdd))));
      } else {
        body.add(new ExpressionStatement(new MethodInvocation(
            new VariableGet(list),
            new Name('add'),
            new Arguments([element.accept(this)]),
            listAdd)));
      }
    }

    return new BlockExpression(new Block(body), new VariableGet(list));
  }
}
