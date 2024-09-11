// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

class ListPatternResolver {
  final ResolverVisitor resolverVisitor;

  ListPatternResolver(this.resolverVisitor);

  PatternResult<DartType> resolve({
    required ListPatternImpl node,
    required SharedMatchContext context,
  }) {
    var typeArguments = node.typeArguments;
    if (typeArguments != null) {
      typeArguments.accept(resolverVisitor);
      // Check that we have exactly one type argument.
      var length = typeArguments.arguments.length;
      if (length != 1) {
        resolverVisitor.errorReporter.atNode(
          typeArguments,
          CompileTimeErrorCode.EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS,
          arguments: [length],
        );
      }
    }

    DartType? elementType = typeArguments?.arguments.first.typeOrThrow;
    var result = resolverVisitor.analyzeListPattern(context, node,
        elementType: elementType?.wrapSharedTypeView(),
        elements: node.elements);
    node.requiredType = result.requiredType.unwrapTypeView();

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: node,
      requiredType: result.requiredType.unwrapTypeView(),
      matchedValueType: result.matchedValueType.unwrapTypeView(),
    );

    return result;
  }
}
