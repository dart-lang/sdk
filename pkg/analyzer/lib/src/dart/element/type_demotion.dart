// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';

/// Replaces all promoted type variables with the type variable itself.
///
/// The visitor returns `null` if the type wasn't changed.
class DemotionVisitor extends ReplacementVisitor {
  const DemotionVisitor();

  @override
  TypeParameterTypeImpl? visitTypeParameterType(TypeParameterType type) {
    type as TypeParameterTypeImpl;

    if (type.promotedBound == null) {
      return null;
    }

    return TypeParameterTypeImpl(
      element: type.element,
      nullabilitySuffix: type.nullabilitySuffix,
      alias: type.alias,
    );
  }
}
