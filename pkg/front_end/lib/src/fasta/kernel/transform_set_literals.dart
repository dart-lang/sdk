// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_set_literals;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Block,
        BlockExpression,
        Expression,
        ExpressionStatement,
        InterfaceType,
        Library,
        MethodInvocation,
        Name,
        Procedure,
        SetLiteral,
        Statement,
        StaticInvocation,
        TreeNode,
        VariableDeclaration,
        VariableGet;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show Transformer;

import '../source/source_loader.dart' show SourceLoader;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

// TODO(askesc): Delete this class when all backends support set literals.
class SetLiteralTransformer extends Transformer {
  final CoreTypes coreTypes;
  final Procedure setFactory;
  final Procedure addMethod;

  /// Library that contains the transformed nodes.
  ///
  /// The transformation of the nodes is affected by the NNBD opt-in status of
  /// the library.
  Library _currentLibrary;

  static Procedure _findSetFactory(CoreTypes coreTypes) {
    Procedure factory = coreTypes.index.getMember('dart:core', 'Set', '');
    RedirectingFactoryBody body = factory?.function?.body;
    return body?.target;
  }

  static Procedure _findAddMethod(CoreTypes coreTypes) {
    return coreTypes.index.getMember('dart:core', 'Set', 'add');
  }

  SetLiteralTransformer(SourceLoader loader)
      : coreTypes = loader.coreTypes,
        setFactory = _findSetFactory(loader.coreTypes),
        addMethod = _findAddMethod(loader.coreTypes);

  TreeNode visitSetLiteral(SetLiteral node) {
    if (node.isConst) return node;

    // Create the set: Set<E> setVar = new Set<E>();
    VariableDeclaration setVar = new VariableDeclaration.forValue(
        new StaticInvocation(
            setFactory, new Arguments([], types: [node.typeArgument])),
        type: new InterfaceType(coreTypes.setClass, _currentLibrary.nonNullable,
            [node.typeArgument]));

    // Now create a list of all statements needed.
    List<Statement> statements = [setVar];
    for (int i = 0; i < node.expressions.length; i++) {
      Expression entry = node.expressions[i].accept<TreeNode>(this);
      MethodInvocation methodInvocation = new MethodInvocation(
          new VariableGet(setVar),
          new Name("add"),
          new Arguments([entry]),
          addMethod)
        ..fileOffset = entry.fileOffset
        ..isInvariant = true;
      statements.add(new ExpressionStatement(methodInvocation)
        ..fileOffset = methodInvocation.fileOffset);
    }

    // Finally, return a BlockExpression with the statements, having the value
    // of the (now created) set.
    return new BlockExpression(new Block(statements), new VariableGet(setVar))
      ..fileOffset = node.fileOffset;
  }

  void enterLibrary(Library library) {
    assert(
        _currentLibrary == null,
        "Attempting to enter library '${library.fileUri}' "
        "without having exited library '${_currentLibrary.fileUri}'.");
    _currentLibrary = library;
  }

  void exitLibrary() {
    assert(_currentLibrary != null,
        "Attempting to exit a library without having entered one.");
    _currentLibrary = null;
  }
}
