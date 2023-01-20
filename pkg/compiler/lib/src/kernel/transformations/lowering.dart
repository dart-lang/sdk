// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

import '../../options.dart';
import 'async_lowering.dart';
import 'factory_specializer.dart';
import 'late_lowering.dart';

/// dart2js-specific lowering transformations and optimizations combined into a
/// single transformation pass.
///
/// Each transformation is applied locally to AST nodes of certain types after
/// transforming children nodes.
void transformLibraries(List<Library> libraries, CoreTypes coreTypes,
    ClassHierarchy hierarchy, CompilerOptions? options) {
  final transformer = _Lowering(coreTypes, hierarchy, options);
  libraries.forEach(transformer.visitLibrary);
}

class _Lowering extends Transformer {
  final FactorySpecializer factorySpecializer;
  final LateLowering _lateLowering;
  final AsyncLowering? _asyncLowering;

  Member? _currentMember;

  _Lowering(
      CoreTypes coreTypes, ClassHierarchy hierarchy, CompilerOptions? _options)
      : factorySpecializer = FactorySpecializer(coreTypes, hierarchy),
        _lateLowering = LateLowering(coreTypes, _options),
        _asyncLowering =
            (_options?.features.simpleAsyncToFuture.isEnabled ?? false)
                ? AsyncLowering(coreTypes)
                : null;

  @override
  TreeNode defaultMember(Member node) {
    _currentMember = node;
    return super.defaultMember(node);
  }

  @override
  TreeNode visitLibrary(Library node) {
    node.transformChildren(this);
    _lateLowering.exitLibrary();
    return node;
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    return factorySpecializer.transformStaticInvocation(node, _currentMember!);
  }

  @override
  TreeNode visitFunctionNode(FunctionNode node) {
    _lateLowering.enterFunction();
    _asyncLowering?.enterFunction(node);
    node.transformChildren(this);
    _lateLowering.exitFunction();
    _asyncLowering?.transformFunctionNodeAndExit(node);
    return node;
  }

  @override
  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableDeclaration(node, _currentMember);
  }

  @override
  TreeNode visitVariableGet(VariableGet node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableGet(node, _currentMember!);
  }

  @override
  TreeNode visitVariableSet(VariableSet node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableSet(node, _currentMember!);
  }

  @override
  TreeNode visitField(Field node) {
    _currentMember = node;
    node.transformChildren(this);
    return _lateLowering.transformField(node, _currentMember!);
  }

  @override
  TreeNode visitAwaitExpression(AwaitExpression expression) {
    _asyncLowering?.visitAwaitExpression(expression);
    expression.transformChildren(this);
    return expression;
  }

  @override
  TreeNode visitReturnStatement(ReturnStatement statement) {
    _asyncLowering?.visitReturnStatement(statement);
    statement.transformChildren(this);
    return statement;
  }

  @override
  TreeNode visitForInStatement(ForInStatement statement) {
    _asyncLowering?.visitForInStatement(statement);
    statement.transformChildren(this);
    return statement;
  }

  @override
  TreeNode visitTryFinally(TryFinally statement) {
    _asyncLowering?.visitTry();
    statement.transformChildren(this);
    return statement;
  }

  @override
  TreeNode visitTryCatch(TryCatch statement) {
    _asyncLowering?.visitTry();
    statement.transformChildren(this);
    return statement;
  }
}
