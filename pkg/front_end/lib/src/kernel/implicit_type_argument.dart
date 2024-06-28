// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.implicit_type_argument;

import 'package:kernel/ast.dart'
    show
        AuxiliaryType,
        DartType,
        DartTypeVisitor,
        DartTypeVisitor1,
        Nullability,
        Visitor;
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/printer.dart';

import '../base/problems.dart' show unhandled, unsupported;

/// Marker type used as type argument on list, set and map literals whenever
/// type arguments are omitted in the source.
///
/// All of these types are replaced by the type inference. It is an internal
/// error if one survives to the final output.
class ImplicitTypeArgument extends AuxiliaryType {
  const ImplicitTypeArgument();

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get declaredNullability =>
      unsupported("declaredNullability", -1, null);

  @override
  // Coverage-ignore(suite): Not run.
  Nullability get nullability => unsupported("nullability", -1, null);

  @override
  // Coverage-ignore(suite): Not run.
  DartType get nonTypeVariableBound {
    throw unsupported("nonTypeVariableBound", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasNonObjectMemberAccess {
    throw unsupported("hasNonObjectMemberAccess", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(DartTypeVisitor<R> v) {
    throw unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    return unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Never visitChildren(Visitor v) {
    unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ImplicitTypeArgument withDeclaredNullability(Nullability nullability) {
    return unsupported("withDeclaredNullability", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  ImplicitTypeArgument toNonNull() {
    return unsupported("toNonNullable", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool equals(Object other, Assumptions? assumptions) => this == other;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-type-argument>');
  }

  @override
  String toString() {
    return "ImplicitTypeArgument(${toStringInternal()})";
  }
}
