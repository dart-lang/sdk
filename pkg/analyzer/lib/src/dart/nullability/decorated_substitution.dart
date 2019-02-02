// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';

/// Representation of a type variable substitution with awareness of constraint
/// variables for nullability substitution.
class DecoratedSubstitution {
  /// The replacements to be performed by the substitution.  Keys are type
  /// parameters to replace, and values are the [DecoratedType]s to replace
  /// them with.
  final Map<TypeParameterElement, DecoratedType> _replacements;

  DecoratedSubstitution(this._replacements);

  /// Apply this substitution to [type].
  ///
  /// [undecoratedResult] is the result of the substitution, as determined by
  /// the normal type system.
  DecoratedType apply(DecoratedType type, DartType undecoratedResult) {
    if (_replacements.isEmpty) return type;
    return _apply(type, undecoratedResult);
  }

  /// Internal implementation of [_apply], used as a recursion target.
  DecoratedType _apply(DecoratedType type, DartType undecoratedResult) {
    var typeType = type.type;
    if (typeType is FunctionType && undecoratedResult is FunctionType) {
      assert(typeType.typeFormals.isEmpty); // TODO(paulberry)
      var positionalParameters = <DecoratedType>[];
      for (int i = 0; i < type.positionalParameters.length; i++) {
        var numRequiredParameters =
            undecoratedResult.normalParameterTypes.length;
        var undecoratedParameterType = i < numRequiredParameters
            ? undecoratedResult.normalParameterTypes[i]
            : undecoratedResult
                .optionalParameterTypes[i - numRequiredParameters];
        positionalParameters.add(
            _apply(type.positionalParameters[i], undecoratedParameterType));
      }
      // TODO(paulberry): what do we do for nullAsserts here?
      var nullAsserts = null;
      return DecoratedType(undecoratedResult, type.nullable,
          nullAsserts: nullAsserts,
          returnType: _apply(type.returnType, undecoratedResult.returnType),
          positionalParameters: positionalParameters);
    } else if (typeType is TypeParameterType) {
      var inner = _replacements[typeType.element];
      // TODO(paulberry): what do we do for nullAsserts here?
      var nullAsserts = null;
      return DecoratedType(undecoratedResult,
          ConstraintVariable.or(inner?.nullable, type.nullable),
          nullAsserts: nullAsserts);
    } else if (typeType is VoidType) {
      return type;
    }
    throw 'DecoratedSubstitution($_replacements).apply($type)'; // TODO(paulberry)
  }
}
