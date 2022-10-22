// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class ListPatternResolver {
  final ResolverVisitor resolverVisitor;

  ListPatternResolver(this.resolverVisitor);

  void resolve({
    required ListPatternImpl node,
    required DartType matchedType,
    required Map<PromotableElement, VariableTypeInfo<AstNode, DartType>>
        typeInfos,
    required MatchContext<AstNode, Expression> context,
  }) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      typeArguments.accept(resolverVisitor);
      // Check that we have exactly one type argument.
      var length = typeArguments.arguments.length;
      if (length != 1) {
        resolverVisitor.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS,
          typeArguments,
          [length],
        );
      }
    }

    node.requiredType = resolverVisitor.analyzeListPattern(
        matchedType, typeInfos, context, node,
        elementType: typeArguments?.arguments.first.typeOrThrow,
        elements: node.elements);
  }
}
