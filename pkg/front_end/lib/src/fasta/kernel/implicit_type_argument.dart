// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.implicit_type_argument;

import 'package:kernel/ast.dart'
    show DartType, DartTypeVisitor, DartTypeVisitor1, Visitor;

import '../problems.dart' show unhandled;

/// Marker type used as type argument on list, set and map literals whenever
/// type arguments are omitted in the source.
///
/// All of these types are replaced by the type inference. It is an internal
/// error if one survives to the final output.
class ImplicitTypeArgument extends DartType {
  const ImplicitTypeArgument();

  @override
  accept(DartTypeVisitor<Object> v) {
    unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  accept1(DartTypeVisitor1<Object, Object> v, arg) {
    unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }

  @override
  visitChildren(Visitor<Object> v) {
    unhandled("$runtimeType", "${v.runtimeType}", -1, null);
  }
}
