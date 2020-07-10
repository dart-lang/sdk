// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.implicit_type_argument;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Nullability, Visitor;
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/printer.dart';

import '../problems.dart' show unhandled, unsupported;

/// Marker type used as type argument on list, set and map literals whenever
/// type arguments are omitted in the source.
///
/// All of these types are replaced by the type inference. It is an internal
/// error if one survives to the final output.
class ImplicitTypeArgument extends DartType {
  const ImplicitTypeArgument();

  @override
  Nullability get declaredNullability =>
      unsupported("declaredNullability", -1, null);

  @override
  Nullability get nullability => unsupported("nullability", -1, null);

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    throw unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, A arg) {
    throw unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  visitChildren(Visitor<Object> v) {
    unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  ImplicitTypeArgument withDeclaredNullability(Nullability nullability) {
    return unsupported("withDeclaredNullability", -1, null);
  }

  @override
  bool equals(Object other, Assumptions assumptions) => this == other;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<implicit-type-argument>');
  }

  @override
  String toString() {
    return "ImplicitTypeArgument(${toStringInternal()})";
  }
}
