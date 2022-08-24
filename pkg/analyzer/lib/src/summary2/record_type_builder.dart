// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/summary2/type_builder.dart';

/// The type builder for a [RecordType].
class RecordTypeBuilder extends TypeBuilder {
  /// The type system of the library with the type name.
  final TypeSystemImpl typeSystem;

  /// The node for which this builder is created.
  final RecordTypeAnnotationImpl node;

  /// This flag is set to `true` while building this type.
  bool _isBuilding = false;

  /// The actual built type, not a [TypeBuilder] anymore.
  RecordTypeImpl? _type;

  RecordTypeBuilder(this.typeSystem, this.node);

  @override
  RecordTypeImpl build() {
    final type = _type;
    if (type != null) {
      return type;
    }

    if (_isBuilding) {
      return _type = buildType(
        node,
        dynamicType: typeSystem.typeProvider.dynamicType,
      );
    }

    _isBuilding = true;
    try {
      return _type = buildType(node);
    } finally {
      _isBuilding = false;
    }
  }

  @override
  String toString() {
    return node.toSource();
  }

  /// If [dynamicType] is not `null`, we found a cycle, and recovering by
  /// using the same shape, but replacing all field types with `dynamic`.
  static RecordTypeImpl buildType(
    RecordTypeAnnotationImpl node, {
    DartType? dynamicType,
  }) {
    final positionalFields = node.positionalFields.map((field) {
      return RecordPositionalFieldElementImpl(
        name: field.name?.lexeme,
        nameOffset: -1,
        type: dynamicType ?? _buildFieldType(field),
      );
    }).toList();

    final namedFields = node.namedFields?.fields.map((field) {
      return RecordNamedFieldElementImpl(
        name: field.name.lexeme,
        nameOffset: -1,
        type: dynamicType ?? _buildFieldType(field),
      );
    }).toList();

    return node.type = RecordElementImpl(
      positionalFields: positionalFields,
      namedFields: namedFields ?? const [],
    ).instantiate(
      nullabilitySuffix: node.question != null
          ? NullabilitySuffix.question
          : NullabilitySuffix.none,
    );
  }

  static DartType _buildFieldType(RecordTypeAnnotationField field) {
    return _buildType(field.type.typeOrThrow);
  }

  /// If the [type] is a [TypeBuilder], build it; otherwise return as is.
  static DartType _buildType(DartType type) {
    if (type is TypeBuilder) {
      return type.build();
    } else {
      return type;
    }
  }
}
