// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

class NullabilityEliminator extends ReplacementVisitor {
  final TypeProviderImpl _typeProvider;

  NullabilityEliminator(this._typeProvider);

  @override
  DartType visitNeverType(NeverTypeImpl type) {
    return _typeProvider.nullStar;
  }

  @override
  NullabilitySuffix visitNullability(DartType type) {
    if (type.nullabilitySuffix != NullabilitySuffix.star) {
      return NullabilitySuffix.star;
    }
    return null;
  }

  @override
  ParameterKind visitParameterKind(ParameterKind kind) {
    if (kind == ParameterKind.NAMED_REQUIRED) {
      return ParameterKind.NAMED;
    }
    return null;
  }

  /// If the [type] itself, or any of its components, has any nullability,
  /// return a new type with legacy nullability suffixes. Otherwise return the
  /// original instance.
  static T perform<T extends DartType>(TypeProviderImpl typeProvider, T type) {
    if (type == null) {
      return type;
    }

    return NullabilityEliminator(typeProvider).visit(type) ?? type;
  }
}
