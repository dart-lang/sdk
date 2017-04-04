// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer;

import 'package:analyzer/analyzer.dart' show AstNode;

import 'package:analyzer/dart/element/element.dart' show LocalElement;

import 'package:analyzer/src/kernel/ast_from_analyzer.dart'
    show ExpressionScope;

import 'package:kernel/ast.dart' show Library, TreeNode;

import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show Builder, KernelFormalParameterBuilder, Scope;

import 'element_store.dart' show ElementStore;

export 'ast_builder.dart' show AstBuilder;

export 'element_store.dart' show ElementStore;

TreeNode toKernel(
    AstNode node, ElementStore store, Library library, Scope scope) {
  ExpressionScope expressionScope = new ExpressionScope(store, library);
  scope.forEach((String name, Builder builder) {
    if (builder is KernelFormalParameterBuilder) {
      LocalElement local = store[builder];
      assert(local != null);
      assert(builder.declaration != null);
      expressionScope.localVariables[local] = builder.declaration;
    }
  });
  return expressionScope.buildStatement(node);
}
