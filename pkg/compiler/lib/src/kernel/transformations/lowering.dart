// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

import '../../options.dart';
import 'async_lowering.dart';
import 'await_lowering.dart';
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
  final AwaitLowering _awaitLowering;
  final AsyncLowering? _asyncLowering;

  Member? _currentMember;

  _Lowering(
      CoreTypes coreTypes, ClassHierarchy hierarchy, CompilerOptions? _options)
      : factorySpecializer = FactorySpecializer(coreTypes, hierarchy),
        _lateLowering = LateLowering(coreTypes, _options),
        _awaitLowering = AwaitLowering(coreTypes),
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
    _asyncLowering?.enterFunction(node);
    _lateLowering.enterScope();
    node.transformChildren(this);
    _lateLowering.exitScope();
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
    // Field initializers can contain late variable reads via record
    // destructuring. The following patten can result in the CFE using a late
    // local outside the scope of a function:
    // Object? foo = { for (final (String x,) in records) x: x };
    _lateLowering.enterScope();
    node.transformChildren(this);
    _lateLowering.exitScope();
    return _lateLowering.transformField(node, _currentMember!);
  }

  @override
  TreeNode visitConstructor(Constructor node) {
    // Constructor initializers can contain late variable reads via record
    // destructuring. Any of these patterns can result in the CFE using a
    // late local outside the scope of a function:
    // Foo() : super({ for (final (String x,) in records) x: x });
    // Foo() : foo = { for (final (String x,) in records) x: x };
    //
    // We share the scope between the various initializers since variables
    // cannot leak between them.
    _lateLowering.enterScope();
    super.visitConstructor(node);
    _lateLowering.exitScope();
    return node;
  }

  @override
  TreeNode visitAwaitExpression(AwaitExpression expression) {
    expression.transformChildren(this);
    final transformed = _awaitLowering.transformAwaitExpression(expression);
    _asyncLowering?.visitAwaitExpression(transformed);
    return transformed;
  }

  @override
  TreeNode visitReturnStatement(ReturnStatement statement) {
    statement.transformChildren(this);
    _asyncLowering?.visitReturnStatement(statement);
    return statement;
  }

  @override
  TreeNode visitForInStatement(ForInStatement statement) {
    statement.transformChildren(this);
    _asyncLowering?.visitForInStatement(statement);
    return statement;
  }

  @override
  TreeNode visitTryFinally(TryFinally statement) {
    statement.transformChildren(this);
    _asyncLowering?.visitTry();
    return statement;
  }

  @override
  TreeNode visitTryCatch(TryCatch statement) {
    statement.transformChildren(this);
    _asyncLowering?.visitTry();
    return statement;
  }
}
