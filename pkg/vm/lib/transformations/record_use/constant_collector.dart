// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:front_end/src/kernel/record_use.dart' as recordUse;

/// Expose only the [collect] method of a [_ConstantCollector] to outside use.
extension type ConstantCollector(_ConstantCollector _collector) {
  ConstantCollector.collectWith(
      Function(
        ConstantExpression context,
        InstanceConstant constant,
      ) collector)
      : _collector = _ConstantCollector(collector);

  void collect(ConstantExpression expression) => _collector.collect(expression);
}

/// A visitor traversing constants and storing instance constants with the
/// `@RecordUse` annotation using the [collector] callback.
class _ConstantCollector implements ConstantVisitor {
  /// The collector callback which records the constant.
  final void Function(
    ConstantExpression context,
    InstanceConstant constant,
  ) collector;

  /// The expression in which the constant was found.
  ConstantExpression? _expression;

  /// A cache to avoid having to re-check for annotations.
  final Map<Class, bool> _hasRecordUseAnnotation = {};

  final Set<Constant> _visited = {};

  _ConstantCollector(this.collector);

  void collect(ConstantExpression node) {
    _expression = node;
    handleConstantReference(node.constant);
    _expression = null;
  }

  void handleConstantReference(Constant constant) {
    if (_visited.add(constant)) {
      constant.accept(this);
    }
  }

  @override
  void visitListConstant(ListConstant constant) {
    for (final entry in constant.entries) {
      handleConstantReference(entry);
    }
  }

  @override
  void visitMapConstant(MapConstant constant) {
    for (final entry in constant.entries) {
      handleConstantReference(entry.key);
      handleConstantReference(entry.value);
    }
  }

  @override
  void visitSetConstant(SetConstant constant) {
    for (final entry in constant.entries) {
      handleConstantReference(entry);
    }
  }

  @override
  void visitRecordConstant(RecordConstant constant) {
    for (final value in constant.positional) {
      handleConstantReference(value);
    }
    for (final value in constant.named.values) {
      handleConstantReference(value);
    }
  }

  @override
  void visitInstanceConstant(InstanceConstant constant) {
    assert(_expression != null);
    final classNode = constant.classNode;
    if (_hasRecordUseAnnotation[classNode] ??=
        recordUse.findRecordUseAnnotation(classNode).isNotEmpty) {
      collector(_expression!, constant);
    }
    for (final value in constant.fieldValues.values) {
      handleConstantReference(value);
    }
  }

  @override
  visitAuxiliaryConstant(AuxiliaryConstant node) {
    throw UnsupportedError('Cannot record an `AuxiliaryConstant`.');
  }

  @override
  visitBoolConstant(BoolConstant node) {}

  @override
  visitConstructorTearOffConstant(ConstructorTearOffConstant node) {}

  @override
  visitDoubleConstant(DoubleConstant node) {}

  @override
  visitInstantiationConstant(InstantiationConstant node) {}

  @override
  visitIntConstant(IntConstant node) {}

  @override
  visitNullConstant(NullConstant node) {}

  @override
  visitRedirectingFactoryTearOffConstant(
      RedirectingFactoryTearOffConstant node) {}

  @override
  visitStaticTearOffConstant(StaticTearOffConstant node) {}

  @override
  visitStringConstant(StringConstant node) {}

  @override
  visitSymbolConstant(SymbolConstant node) {}

  @override
  visitTypeLiteralConstant(TypeLiteralConstant node) {}

  @override
  visitTypedefTearOffConstant(TypedefTearOffConstant node) {}

  @override
  visitUnevaluatedConstant(UnevaluatedConstant node) {}
}
