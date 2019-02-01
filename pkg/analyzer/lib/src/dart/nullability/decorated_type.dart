// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

class DecoratedType {
  final DartType type;

  /// If `null`, that means that an external constraint (outside the code being
  /// migrated) forces this type to be non-nullable.
  final ConstraintVariable nullable;

  /// If not `null`, this is a variable that indicates whether a null value
  /// assigned to this type will unconditionally lead to an assertion failure.
  final ConstraintVariable nullAsserts;

  final DecoratedType returnType;

  final List<DecoratedType> positionalParameters;

  final Map<String, DecoratedType> namedParameters;

  final List<DecoratedType> typeArguments;

  DecoratedType(this.type, this.nullable,
      {this.nullAsserts,
      this.returnType,
      this.positionalParameters = const [],
      this.namedParameters = const {},
      this.typeArguments = const []});

  String toString() {
    var trailing = nullable == null ? '' : '?($nullable)';
    var type = this.type;
    if (type is TypeParameterType || type is VoidType) {
      return '$type$trailing';
    } else if (type is InterfaceType) {
      var name = type.element.name;
      var args = '';
      if (type.typeArguments.isNotEmpty) {
        args = '<${type.typeArguments.join(', ')}>';
      }
      return '$name$args$trailing';
    } else if (type is FunctionType) {
      assert(type.typeFormals.isEmpty); // TODO(paulberry)
      assert(type.namedParameterTypes.isEmpty &&
          namedParameters.isEmpty); // TODO(paulberry)
      var args = positionalParameters.map((p) => p.toString()).join(', ');
      return '$returnType Function($args)$trailing';
    } else {
      throw '$type'; // TODO(paulberry)
    }
  }
}
