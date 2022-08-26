// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.g.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [RecordTypeAnnotation]s.
class RecordTypeAnnotationResolver {
  /// A regular expression used to match positional field names.
  static final RegExp positionalFieldName = RegExp(r'^\$[0-9]+$');

  final ResolverVisitor _resolver;

  RecordTypeAnnotationResolver({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ErrorReporter get errorReporter => _resolver.errorReporter;

  /// Report any named fields in the record type [node] that use a previously
  /// defined name.
  void reportDuplicateFieldDefinitions(RecordTypeAnnotationImpl node) {
    var usedNames = <String, RecordTypeAnnotationField>{};
    for (var field in node.fields) {
      var name = field.name?.lexeme;
      if (name != null) {
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
    var fields = node.fields;
    for (var field in fields) {
      var nameToken = field.name;
      if (nameToken != null) {
        var name = nameToken.lexeme;
        if (name.startsWith('_')) {
          errorReporter.reportErrorForToken(
              CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, nameToken);
        } else if (positionalFieldName.hasMatch(name)) {
          errorReporter.reportErrorForToken(
              CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, nameToken);
        } else {
          var objectElement = _resolver.typeProvider.objectElement;
          if (objectElement.getGetter(name) != null ||
              objectElement.getMethod(name) != null) {
            errorReporter.reportErrorForToken(
                CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, nameToken);
          }
        }
      }
    }
  }

  void resolve(RecordTypeAnnotationImpl node,
      {required DartType? contextType}) {
    // TODO(brianwilkerson) Move resolution from the `visitRecordTypeAnnotation`
    //  methods of `ResolverVisitor` and `StaticTypeAnalyzer` to this class.
  }
}

extension on RecordTypeAnnotation {
  List<RecordTypeAnnotationField> get fields => [
        ...positionalFields,
        ...?namedFields?.fields,
      ];
}
