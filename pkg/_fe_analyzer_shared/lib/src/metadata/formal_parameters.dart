// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'expressions.dart';
import 'proto.dart';
import 'type_annotations.dart';
import 'util.dart';

/// A formal parameter in a function type annotation.
// TODO(johnniwinther): Use this for function parameters if general expressions
// are supported.
class FormalParameter {
  final List<Expression> metadata;
  final TypeAnnotation? typeAnnotation;
  final String? name;
  final Expression? defaultValue;

  /// `true` if this parameter occurred within `{` `}` brackets.
  final bool isNamed;

  /// `true` if this parameter is required.
  final bool isRequired;

  FormalParameter(
    this.metadata,
    this.typeAnnotation,
    this.name,
    this.defaultValue, {
    required this.isNamed,
    required this.isRequired,
  });

  /// Returns the [FormalParameter] corresponding to this [FormalParameter] in
  /// which all [UnresolvedIdentifier]s have been resolved within their scope.
  ///
  /// If this didn't create a new [FormalParameter], `null` is returned.
  FormalParameter? resolve() {
    List<Expression>? resolvedMetadata = metadata.resolve((e) => e.resolve());
    TypeAnnotation? resolvedTypeAnnotation = typeAnnotation?.resolve();
    Expression? resolvedDefaultValue = defaultValue?.resolve();
    return resolvedMetadata == null &&
            resolvedTypeAnnotation == null &&
            resolvedDefaultValue == null
        ? null
        : new FormalParameter(
            resolvedMetadata ?? metadata,
            resolvedTypeAnnotation ?? typeAnnotation,
            name,
            resolvedDefaultValue ?? defaultValue,
            isNamed: isNamed,
            isRequired: isRequired,
          );
  }

  @override
  String toString() =>
      'FormalParameter($metadata,$typeAnnotation,$name,$defaultValue,'
      'isNamed:$isNamed,isRequired:$isRequired)';
}

/// A list of parameters in `{`, `}`, or `[`, `]`.
class FormalParameterGroup {
  final List<FormalParameter> formalParameters;

  FormalParameterGroup(this.formalParameters);
}
