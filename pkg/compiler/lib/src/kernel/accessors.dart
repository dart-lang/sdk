// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/frontend/accessors.dart' as ir_accessors;

import 'kernel.dart' show Kernel;
import 'unresolved.dart' show UnresolvedVisitor;

export 'package:kernel/frontend/accessors.dart' show Accessor;

class TopLevelStaticAccessor extends ir_accessors.StaticAccessor {
  final UnresolvedVisitor builder;

  /// Name of the property attempted to be accessed, used to generate an
  /// error if unresolved.
  final String name;

  Kernel get kernel => builder.kernel;

  TopLevelStaticAccessor(
      this.builder, this.name, ir.Member readTarget, ir.Member writeTarget)
      : super(readTarget, writeTarget);

  @override
  makeInvalidRead() {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedTopLevelGetterBuilder(),
        new ir.NullLiteral(),
        name,
        new ir.Arguments.empty());
  }

  @override
  makeInvalidWrite(ir.Expression value) {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedTopLevelSetterBuilder(),
        new ir.NullLiteral(),
        name,
        new ir.Arguments(<ir.Expression>[value]));
  }
}

class ClassStaticAccessor extends ir_accessors.StaticAccessor {
  final UnresolvedVisitor builder;

  /// Name of the property attempted to be accessed, used to generate an
  /// error if unresolved.
  final String name;

  Kernel get kernel => builder.kernel;

  ClassStaticAccessor(
      this.builder, this.name, ir.Member readTarget, ir.Member writeTarget)
      : super(readTarget, writeTarget);

  @override
  makeInvalidRead() {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedStaticGetterBuilder(),
        new ir.NullLiteral(),
        name,
        new ir.Arguments.empty());
  }

  @override
  makeInvalidWrite(ir.Expression value) {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedStaticSetterBuilder(),
        new ir.NullLiteral(),
        name,
        new ir.Arguments(<ir.Expression>[value]));
  }
}

class SuperPropertyAccessor extends ir_accessors.SuperPropertyAccessor {
  final UnresolvedVisitor builder;

  SuperPropertyAccessor(
      this.builder, ir.Name name, ir.Member getter, ir.Member setter)
      : super(name, getter, setter);

  @override
  makeInvalidRead() {
    // TODO(asgerf): Technically, we should invoke 'super.noSuchMethod' for
    //   this and the other invalid super cases.
    return builder.buildThrowUnresolvedSuperGetter(name.name);
  }

  @override
  makeInvalidWrite(ir.Expression value) {
    return builder.buildThrowUnresolvedSuperSetter(name.name, value);
  }
}

class SuperIndexAccessor extends ir_accessors.SuperIndexAccessor {
  final UnresolvedVisitor builder;

  Kernel get kernel => builder.kernel;

  SuperIndexAccessor(
      this.builder, ir.Expression index, ir.Member getter, ir.Member setter)
      : super(index, getter, setter);

  @override
  makeInvalidRead() {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedSuperMethodBuilder(),
        new ir.ThisExpression(),
        '[]',
        new ir.Arguments(<ir.Expression>[indexAccess()]));
  }

  @override
  makeInvalidWrite(ir.Expression value) {
    return builder.buildThrowNoSuchMethodError(
        kernel.getUnresolvedSuperMethodBuilder(),
        new ir.ThisExpression(),
        '[]=',
        new ir.Arguments(<ir.Expression>[indexAccess(), value]));
  }
}
