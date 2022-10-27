// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class RecordPatternResolver {
  final ResolverVisitor resolverVisitor;

  RecordPatternResolver(this.resolverVisitor);

  InterfaceTypeImpl get _objectQuestion {
    return resolverVisitor.typeSystem.objectQuestion;
  }

  TypeProviderImpl get _typeProvider => resolverVisitor.typeProvider;

  void resolve({
    required RecordPatternImpl node,
    required DartType matchedType,
    required Map<PromotableElement, VariableTypeInfo<AstNode, DartType>>
        typeInfos,
    required MatchContext<AstNode, Expression> context,
  }) {
    void resolvePattern(DartPatternImpl pattern, DartType contextType) {
      pattern.resolvePattern(resolverVisitor, contextType, typeInfos, context);
    }

    void resolvePatterns(DartType contextType) {
      for (var field in node.fields) {
        resolvePattern(field.pattern, contextType);
      }
    }

    var patternFields = _buildFields(node);

    if (matchedType is RecordType) {
      if (_checkShape(patternFields, matchedType)) {
        for (var field in patternFields.positional) {
          resolvePattern(field.pattern, field.contextType!);
        }
        for (var field in patternFields.named) {
          resolvePattern(field.pattern, field.contextType!);
        }
      } else {
        // TODO(scheglov) Report a warning?
        resolvePatterns(_objectQuestion);
      }
    } else if (matchedType.isDynamic) {
      resolvePatterns(_typeProvider.dynamicType);
    } else {
      resolvePatterns(_objectQuestion);
    }
  }

  /// Extracts patterns from [node], with explicit names for named fields.
  _PatternFields _buildFields(RecordPatternImpl node) {
    var positional = <_PositionalField>[];
    var named = <_NamedField>[];

    for (var field in node.fields) {
      var fieldNameNode = field.fieldName;
      if (fieldNameNode != null) {
        var nameToken = fieldNameNode.name;
        nameToken ??= field.pattern.variablePattern?.name;
        if (nameToken == null) {
          resolverVisitor.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_EXTRACTOR_PATTERN_GETTER_NAME,
            field,
          );
        }
        named.add(
          _NamedField(
            name: nameToken?.lexeme,
            pattern: field.pattern,
          ),
        );
      } else {
        positional.add(
          _PositionalField(
            pattern: field.pattern,
          ),
        );
      }
    }

    return _PatternFields(positional, named);
  }

  /// If [matchedType] has the same shape as the [fields], sets context types
  /// and returns `true`. Otherwise returns `false`.
  bool _checkShape(_PatternFields fields, RecordType matchedType) {
    if (fields.positional.length != matchedType.positionalFields.length) {
      return false;
    }

    if (fields.named.length != matchedType.namedFields.length) {
      return false;
    }

    for (var i = 0; i < matchedType.positionalFields.length; i++) {
      fields.positional[i].contextType = matchedType.positionalFields[i].type;
    }

    var matchedNamedTypes = <String, DartType>{};
    for (var namedField in matchedType.namedFields) {
      matchedNamedTypes[namedField.name] = namedField.type;
    }

    for (var namedField in fields.named) {
      var type = matchedNamedTypes[namedField.name];
      if (type == null) {
        return false;
      }
      namedField.contextType = type;
    }

    return true;
  }
}

/// A pattern field with explicit [name].
class _NamedField extends _PatternField {
  final String? name;

  _NamedField({
    required this.name,
    required super.pattern,
  });
}

class _PatternField {
  final DartPatternImpl pattern;
  DartType? contextType;

  _PatternField({
    required this.pattern,
  });
}

class _PatternFields {
  final List<_PositionalField> positional;
  final List<_NamedField> named;

  _PatternFields(this.positional, this.named);
}

class _PositionalField extends _PatternField {
  _PositionalField({
    required super.pattern,
  });
}
