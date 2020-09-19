// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Returns [type] in which all promoted type variables have been replace with
/// their unpromoted equivalents, and, if [library] is non-nullable by default,
/// replaces all legacy types with their non-nullable equivalents.
DartType demoteType(LibraryElement library, DartType type) {
  if (library.isNonNullableByDefault) {
    var visitor = const DemotionNonNullificationVisitor();
    return type.accept(visitor) ?? type;
  } else {
    var visitor = const DemotionNonNullificationVisitor(nonNullifyTypes: false);
    return type.accept(visitor) ?? type;
  }
}

/// Visitor that replaces all promoted type variables the type variable itself
/// and/or replaces all legacy types with non-nullable types.
///
/// The visitor returns `null` if the type wasn't changed.
class DemotionNonNullificationVisitor extends ReplacementVisitor {
  final bool demoteTypeVariables;
  final bool nonNullifyTypes;

  const DemotionNonNullificationVisitor({
    this.demoteTypeVariables = true,
    this.nonNullifyTypes = true,
  }) : assert(demoteTypeVariables || nonNullifyTypes);

  @override
  NullabilitySuffix visitNullability(DartType type) {
    if (nonNullifyTypes && type.nullabilitySuffix == NullabilitySuffix.star) {
      return NullabilitySuffix.none;
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType type) {
    var newNullability = visitNullability(type);

    if (demoteTypeVariables) {
      var typeImpl = type as TypeParameterTypeImpl;
      if (typeImpl.promotedBound != null) {
        return TypeParameterTypeImpl(
          element: type.element,
          nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
        );
      }
    }

    return createTypeParameterType(
      type: type,
      newNullability: newNullability,
    );
  }
}
