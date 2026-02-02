// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/promotion_key_store.dart';
import 'package:kernel/ast.dart';

class AssignedVariablesImpl
    implements AssignedVariables<TreeNode, ExpressionVariable> {
  final AssignedVariables<TreeNode, ExpressionVariable> _delegate;
  final AssignedVariables<TreeNode, ExpressionVariable>? _insideAsserts;
  final AssignedVariables<TreeNode, ExpressionVariable>? _outsideAsserts;
  int _assertDepth = 0;
  final Map<AssignedVariablesNodeInfo, AssignedVariablesNodeInfo>?
  _deferredInsideAssertsByDeferredDelegate;
  final Map<AssignedVariablesNodeInfo, AssignedVariablesNodeInfo>?
  _deferredOutsideAssertsByDeferredDelegate;

  AssignedVariablesImpl(
    this._delegate, {
    required bool isClosureContextLoweringEnabled,
  }) : _insideAsserts = isClosureContextLoweringEnabled
           ? new AssignedVariables<TreeNode, ExpressionVariable>()
           : null,
       _outsideAsserts = isClosureContextLoweringEnabled
           ? new AssignedVariables<TreeNode, ExpressionVariable>()
           : null,
       _deferredInsideAssertsByDeferredDelegate =
           isClosureContextLoweringEnabled
           ? new Map<
               AssignedVariablesNodeInfo,
               AssignedVariablesNodeInfo
             >.identity()
           : null,
       _deferredOutsideAssertsByDeferredDelegate =
           isClosureContextLoweringEnabled
           ? new Map<
               AssignedVariablesNodeInfo,
               AssignedVariablesNodeInfo
             >.identity()
           : null;

  bool get _isInsideAssert => _assertDepth > 0;

  void enterAssert() {
    _assertDepth++;
  }

  void exitAssert() {
    _assertDepth--;
  }

  @override
  AssignedVariablesNodeInfo get anywhere {
    return _delegate.anywhere;
  }

  AssignedVariablesNodeInfo get insideAsserts {
    return _insideAsserts!.anywhere;
  }

  AssignedVariablesNodeInfo get outsideAsserts {
    return _outsideAsserts!.anywhere;
  }

  @override
  void beginNode() {
    _delegate.beginNode();
    _insideAsserts?.beginNode();
    _outsideAsserts?.beginNode();
  }

  @override
  void declare(ExpressionVariable variable, {bool ignoreDuplicates = false}) {
    _delegate.declare(variable, ignoreDuplicates: ignoreDuplicates);
    _insideAsserts?.declare(variable, ignoreDuplicates: ignoreDuplicates);
    _outsideAsserts?.declare(variable, ignoreDuplicates: ignoreDuplicates);
  }

  @override
  AssignedVariablesNodeInfo deferNode({
    bool isClosureOrLateVariableInitializer = false,
  }) {
    AssignedVariablesNodeInfo delegateDeferred = _delegate.deferNode(
      isClosureOrLateVariableInitializer: isClosureOrLateVariableInitializer,
    );
    _deferredInsideAssertsByDeferredDelegate?[delegateDeferred] =
        _insideAsserts!.deferNode(
          isClosureOrLateVariableInitializer:
              isClosureOrLateVariableInitializer,
        );
    _deferredOutsideAssertsByDeferredDelegate?[delegateDeferred] =
        _outsideAsserts!.deferNode(
          isClosureOrLateVariableInitializer:
              isClosureOrLateVariableInitializer,
        );
    return delegateDeferred;
  }

  @override
  void discardNode() {
    _delegate.discardNode();
    _insideAsserts
        // Coverage-ignore(suite): Not run.
        ?.discardNode();
    _outsideAsserts
        // Coverage-ignore(suite): Not run.
        ?.discardNode();
  }

  @override
  void endNode(
    TreeNode node, {
    bool isClosureOrLateVariableInitializer = false,
  }) {
    _delegate.endNode(
      node,
      isClosureOrLateVariableInitializer: isClosureOrLateVariableInitializer,
    );
    _insideAsserts?.endNode(
      node,
      isClosureOrLateVariableInitializer: isClosureOrLateVariableInitializer,
    );
    _outsideAsserts?.endNode(
      node,
      isClosureOrLateVariableInitializer: isClosureOrLateVariableInitializer,
    );
  }

  @override
  void finish() {
    _delegate.finish();
    _insideAsserts?.finish();
    _outsideAsserts?.finish();
  }

  @override
  AssignedVariablesNodeInfo getInfoForNode(TreeNode node) {
    return _delegate.getInfoForNode(node);
  }

  @override
  bool get isFinished {
    return _delegate.isFinished;
  }

  @override
  AssignedVariablesNodeInfo popNode() {
    _insideAsserts?.popNode();
    _outsideAsserts?.popNode();
    return _delegate.popNode();
  }

  @override
  PromotionKeyStore<ExpressionVariable> get promotionKeyStore {
    return _delegate.promotionKeyStore;
  }

  @override
  void pushNode(AssignedVariablesNodeInfo node) {
    _delegate.pushNode(node);
    _insideAsserts?.pushNode(node);
    _outsideAsserts?.pushNode(node);
  }

  @override
  void read(ExpressionVariable variable) {
    _delegate.read(variable);
    if (_isInsideAssert) {
      _insideAsserts?.read(variable);
    } else {
      _outsideAsserts?.read(variable);
    }
  }

  @override
  void reassignInfo(TreeNode from, TreeNode to) {
    _delegate.reassignInfo(from, to);
    _insideAsserts
    // Coverage-ignore(suite): Not run.
    ?.reassignInfo(from, to);
    _outsideAsserts
    // Coverage-ignore(suite): Not run.
    ?.reassignInfo(from, to);
  }

  @override
  void storeInfo(TreeNode node, AssignedVariablesNodeInfo info) {
    assert(_deferredInsideAssertsByDeferredDelegate?.containsKey(info) ?? true);
    assert(
      _deferredOutsideAssertsByDeferredDelegate?.containsKey(info) ?? true,
    );
    _delegate.storeInfo(node, info);
    _insideAsserts?.storeInfo(
      node,
      _deferredInsideAssertsByDeferredDelegate!.remove(info)!,
    );
    _outsideAsserts?.storeInfo(
      node,
      _deferredOutsideAssertsByDeferredDelegate!.remove(info)!,
    );
  }

  @override
  void write(ExpressionVariable variable) {
    _delegate.write(variable);
    if (_isInsideAssert) {
      // Coverage-ignore-block(suite): Not run.
      _insideAsserts?.write(variable);
    } else {
      _outsideAsserts?.write(variable);
    }
  }
}
