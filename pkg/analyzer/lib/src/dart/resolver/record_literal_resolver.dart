// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [RecordLiteral]s.
class RecordLiteralResolver {
  final ResolverVisitor _resolver;

  RecordLiteralResolver({required ResolverVisitor resolver})
    : _resolver = resolver;

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  void resolve(RecordLiteralImpl node, {required DartType contextType}) {
    _resolveFields(node, contextType);

    _reportDuplicateFieldDefinitions(node);
    _reportInvalidFieldNames(node);
  }

  /// If [contextType] is a record type, and the type schemas contained in it
  /// should be used for inferring the expressions in [node], returns it as a
  /// [RecordType]. Otherwise returns `null`.
  ///
  /// The type schemas contained in [contextType] should only be used for
  /// inferring the expressions in [node] if it is a record type with a shape
  /// that matches the shape of [node].
  RecordTypeImpl? _matchContextType(
    RecordLiteralImpl node,
    DartType contextType,
  ) {
    if (contextType is! RecordTypeImpl) return null;
    if (contextType.namedFields.length + contextType.positionalFields.length !=
        node.fields.length) {
      return null;
    }
    var numPositionalFields = 0;
    for (var field in node.fields) {
      if (field is NamedExpressionImpl) {
        if (contextType.namedField(field.name.label.name) == null) {
          return null;
        }
      } else {
        numPositionalFields++;
      }
    }
    if (contextType.positionalFields.length != numPositionalFields) {
      return null;
    }
    // At this point we've established that:
    // - The total number of fields in the context matches the total number of
    //   fields in the literal.
    // - The number of positional fields in the context matches the number of
    //   positional fields in the literal.
    // Therefore, the number of named fields in the context must match the
    // number of named fields in the literal.
    //
    // We've also established that for each named field in the literal, there's
    // a corresponding named field in the context. Therefore, the literal and
    // the context have exactly the same set of named fields. So they match up
    // to reordering of named fields.
    return contextType;
  }

  /// Report any named fields in the record literal [node] that use a previously
  /// defined name.
  void _reportDuplicateFieldDefinitions(RecordLiteralImpl node) {
    var usedNames = <String, NamedExpression>{};
    for (var field in node.fields) {
      if (field is NamedExpressionImpl) {
        var name = field.name.label.name;
        var previousField = usedNames[name];
        if (previousField != null) {
          _diagnosticReporter.reportError(
            DiagnosticFactory().duplicateFieldDefinitionInLiteral(
              _diagnosticReporter.source,
              field,
              previousField,
            ),
          );
        } else {
          usedNames[name] = field;
        }
      }
    }
  }

  /// Report any fields in the record literal [node] that use an invalid name.
  void _reportInvalidFieldNames(RecordLiteralImpl node) {
    var fields = node.fields;
    var positionalCount = 0;
    for (var field in fields) {
      if (field is! NamedExpression) {
        positionalCount++;
      }
    }
    for (var field in fields) {
      if (field is NamedExpressionImpl) {
        var nameNode = field.name.label;
        var name = nameNode.name;
        if (name.startsWith('_')) {
          _diagnosticReporter.atNode(
            nameNode,
            CompileTimeErrorCode.invalidFieldNamePrivate,
          );
        } else {
          var index = RecordTypeExtension.positionalFieldIndex(name);
          if (index != null) {
            if (index < positionalCount) {
              _diagnosticReporter.atNode(
                nameNode,
                CompileTimeErrorCode.invalidFieldNamePositional,
              );
            }
          } else if (isForbiddenNameForRecordField(name)) {
            _diagnosticReporter.atNode(
              nameNode,
              CompileTimeErrorCode.invalidFieldNameFromObject,
            );
          }
        }
      }
    }
  }

  DartType _resolveField(ExpressionImpl field, TypeImpl contextType) {
    var staticType = _resolver
        .analyzeExpression(field, SharedTypeSchemaView(contextType))
        .unwrapTypeView<TypeImpl>();
    field = _resolver.popRewrite()!;

    // Implicit cast from `dynamic`.
    if (contextType is! UnknownInferredType && staticType is DynamicType) {
      var greatestClosureOfSchema = _resolver.operations
          .greatestClosureOfSchema(SharedTypeSchemaView(contextType))
          .unwrapTypeView<TypeImpl>();
      if (!_resolver.typeSystem.isSubtypeOf(
        staticType,
        greatestClosureOfSchema,
      )) {
        return greatestClosureOfSchema;
      }
    }

    if (staticType is VoidType) {
      _diagnosticReporter.atNode(field, CompileTimeErrorCode.useOfVoidResult);
    }

    return staticType;
  }

  void _resolveFields(RecordLiteralImpl node, DartType contextType) {
    var positionalFields = <RecordTypePositionalFieldImpl>[];
    var namedFields = <RecordTypeNamedFieldImpl>[];
    var contextTypeAsRecord = _matchContextType(node, contextType);
    var index = 0;
    for (var field in node.fields) {
      if (field is NamedExpressionImpl) {
        var name = field.name.label.name;
        var fieldContextType =
            contextTypeAsRecord?.namedField(name)!.type ??
            UnknownInferredType.instance;
        namedFields.add(
          RecordTypeNamedFieldImpl(
            name: name,
            type: _resolveField(field, fieldContextType),
          ),
        );
      } else {
        var fieldContextType =
            contextTypeAsRecord?.positionalFields[index++].type ??
            UnknownInferredType.instance;
        positionalFields.add(
          RecordTypePositionalFieldImpl(
            type: _resolveField(field, fieldContextType),
          ),
        );
      }
    }

    node.recordStaticType(
      RecordTypeImpl(
        positionalFields: positionalFields,
        namedFields: namedFields,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      resolver: _resolver,
    );
  }

  /// Returns whether [name] is a name forbidden for record fields because it
  /// clashes with members from [Object] as specified by
  /// https://github.com/dart-lang/language/blob/main/accepted/3.0/records/feature-specification.md#record-type-annotations
  static bool isForbiddenNameForRecordField(String name) {
    const forbidden = {'hashCode', 'runtimeType', 'noSuchMethod', 'toString'};

    return forbidden.contains(name);
  }
}
