// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_set_literals;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Expression,
        InterfaceType,
        Let,
        Library,
        MethodInvocation,
        Name,
        Procedure,
        SetLiteral,
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

    // Outermost declaration of let chain: Set<E> setVar = new Set<E>();
    VariableDeclaration setVar = new VariableDeclaration.forValue(
        new StaticInvocation(
            setFactory, new Arguments([], types: [node.typeArgument])),
        type: new InterfaceType(coreTypes.setClass, _currentLibrary.nonNullable,
            [node.typeArgument]));
    // Innermost body of let chain: setVar
    Expression setExp = new VariableGet(setVar);
    for (int i = node.expressions.length - 1; i >= 0; i--) {
      // let _ = setVar.add(expression) in rest
      Expression entry = node.expressions[i].accept<TreeNode>(this);
      setExp = new Let(
          new VariableDeclaration.forValue(new MethodInvocation(
              new VariableGet(setVar),
              new Name("add"),
              new Arguments([entry]),
              addMethod)),
          setExp);
    }
    return new Let(setVar, setExp);
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
