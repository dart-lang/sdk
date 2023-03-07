// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

class RecordLiteralContributor extends DartCompletionContributor {
  RecordLiteralContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    final containingNode = request.target.containingNode;

    final parent = containingNode.parent;
    if (parent == null) {
      return;
    }

    final contextType =
        request.featureComputer.computeContextType(parent, request.offset);
    if (contextType is! RecordType) {
      return;
    }

    if (containingNode is ParenthesizedExpression) {
      _compute(contextType, const []);
    } else if (containingNode is RecordLiteral) {
      _compute(contextType, containingNode.fields);
    }
  }

  void _compute(RecordType contextType, List<Expression> literalFields) {
    final includedNames = literalFields
        .whereType<NamedExpression>()
        .map((e) => e.name.label.name)
        .toSet();

    final isEditingName = _isEditingName();

    for (final field in contextType.namedFields) {
      if (!includedNames.contains(field.name)) {
        builder.suggestNamedRecordField(
          field,
          appendColon: !isEditingName,
          appendComma: !isEditingName &&
              !request.target.isFollowedByComma &&
              !request.target.isFollowedByRightParenthesis,
        );
      }
    }
  }

  bool _isEditingName() {
    final entity = request.target.entity;
    if (entity is NamedExpression) {
      final name = entity.name;
      final offset = request.offset;
      return name.offset <= offset && offset <= name.colon.offset;
    }
    return false;
  }
}
