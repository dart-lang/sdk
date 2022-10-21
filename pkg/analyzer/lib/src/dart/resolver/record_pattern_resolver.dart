// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class RecordPatternResolver {
  final ResolverVisitor resolverVisitor;

  int _positionalFieldIndex = 0;

  RecordPatternResolver(this.resolverVisitor);

  TypeProviderImpl get _typeProvider => resolverVisitor.typeProvider;

  void resolve({
    required RecordPatternImpl node,
    required DartType matchedType,
    required Map<PromotableElement, VariableTypeInfo<AstNode, DartType>>
        typeInfos,
    required MatchContext<AstNode, Expression> context,
  }) {
    _positionalFieldIndex = 0;
    for (var field in node.fields) {
      var fieldType = _resolveFieldType(matchedType, field);
      field.pattern
          .resolvePattern(resolverVisitor, fieldType, typeInfos, context);
    }
  }

  DartType _resolveFieldType(
    DartType matchedType,
    RecordPatternFieldImpl field,
  ) {
    if (matchedType is RecordType) {
      var fieldNameNode = field.fieldName;
      if (fieldNameNode != null) {
        var nameToken = fieldNameNode.name;
        nameToken ??= field.pattern.variablePattern?.name;
        if (nameToken == null) {
          resolverVisitor.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.MISSING_EXTRACTOR_PATTERN_GETTER_NAME,
            field,
          );
          return _typeProvider.dynamicType;
        }

        var fieldName = nameToken.lexeme;
        var recordField = matchedType.fieldByName(fieldName);
        if (recordField != null) {
          return recordField.type;
        }
      } else {
        if (_positionalFieldIndex < matchedType.positionalFields.length) {
          return matchedType.positionalFields[_positionalFieldIndex++].type;
        }
      }
    } else if (matchedType.isDynamic) {
      return _typeProvider.dynamicType;
    }

    return resolverVisitor.typeSystem.objectQuestion;
  }
}
