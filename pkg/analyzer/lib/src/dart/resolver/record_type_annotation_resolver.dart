// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/record_literal_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Helper for resolving [RecordTypeAnnotation]s.
class RecordTypeAnnotationResolver {
  final TypeProviderImpl typeProvider;
  final ErrorReporter errorReporter;
  final LibraryElement libraryElement;

  RecordTypeAnnotationResolver({
    required this.typeProvider,
    required this.errorReporter,
    required this.libraryElement,
  });

  bool get isWildCardVariablesEnabled =>
      libraryElement.featureSet.isEnabled(Feature.wildcard_variables);

  bool isPositionalWildCard(AstNode field, String name) =>
      field is RecordTypeAnnotationPositionalField &&
      name == '_' &&
      isWildCardVariablesEnabled;

  /// Report any named fields in the record type [node] that use a previously
  /// defined name.
  void reportDuplicateFieldDefinitions(RecordTypeAnnotationImpl node) {
    var usedNames = <String, RecordTypeAnnotationField>{};
    for (var field in node.fields) {
      var name = field.name?.lexeme;
      if (name != null) {
        // Multiple positional `_`s are legal with wildcards.
        if (isPositionalWildCard(field, name)) continue;

        var previousField = usedNames[name];
        if (previousField != null) {
          errorReporter.reportError(DiagnosticFactory()
              .duplicateFieldDefinitionInType(
                  errorReporter.source, field, previousField));
        } else {
          usedNames[name] = field;
        }
      }
    }
  }

  /// Report any fields in the record type [node] that use an invalid name.
  void reportInvalidFieldNames(RecordTypeAnnotationImpl node) {
    var positionalFields = node.positionalFields;
    var positionalCount = positionalFields.length;
    for (var field in node.fields) {
      var nameToken = field.name;
      if (nameToken != null) {
        var name = nameToken.lexeme;
        if (name.startsWith('_')) {
          // Positional record fields named `_` are legal w/ wildcards.
          if (!isPositionalWildCard(field, name)) {
            errorReporter.atToken(
              nameToken,
              CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE,
            );
          }
        } else {
          var index = RecordTypeExtension.positionalFieldIndex(name);
          if (index != null) {
            if (index < positionalCount &&
                positionalFields.indexOf(field) != index) {
              errorReporter.atToken(
                nameToken,
                CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL,
              );
            }
          } else if (RecordLiteralResolver.isForbiddenNameForRecordField(
              name)) {
            errorReporter.atToken(
              nameToken,
              CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT,
            );
          }
        }
      }
    }
  }

  void resolve(RecordTypeAnnotationImpl node) {
    _buildType(node);
    reportDuplicateFieldDefinitions(node);
    reportInvalidFieldNames(node);
  }

  void _buildType(RecordTypeAnnotationImpl node) {
    var positionalFields = node.positionalFields.map((field) {
      return RecordTypePositionalFieldImpl(
        type: field.type.typeOrThrow,
      );
    }).toList();

    var namedFields = node.namedFields?.fields.map((field) {
      return RecordTypeNamedFieldImpl(
        name: field.name.lexeme,
        type: field.type.typeOrThrow,
      );
    }).toList();

    node.type = RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields ?? const [],
      nullabilitySuffix: node.question != null
          ? NullabilitySuffix.question
          : NullabilitySuffix.none,
    );
  }
}
