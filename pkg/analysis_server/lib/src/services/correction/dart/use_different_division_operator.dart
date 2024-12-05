// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseDifferentDivisionOperator extends MultiCorrectionProducer {
  UseDifferentDivisionOperator({required super.context});

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    switch (node) {
      case BinaryExpression node:
        return switch (node.operator.type) {
          TokenType.SLASH => [
            _UseDifferentDivisionOperator(
              context: context,
              fixKind: DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION,
            ),
          ],
          TokenType.TILDE_SLASH => [
            _UseDifferentDivisionOperator(
              context: context,
              fixKind: DartFixKind.USE_DIVISION,
            ),
          ],
          _ => const [],
        };
      case AssignmentExpression node:
        return switch (node.operator.type) {
          TokenType.SLASH_EQ => [
            _UseDifferentDivisionOperator(
              context: context,
              fixKind: DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION,
            ),
          ],
          TokenType.TILDE_SLASH_EQ => [
            _UseDifferentDivisionOperator(
              context: context,
              fixKind: DartFixKind.USE_DIVISION,
            ),
          ],
          _ => const [],
        };
    }
    return const [];
  }
}

enum _DivisionOperator { division, effectiveIntegerDivision }

class _UseDifferentDivisionOperator extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  _UseDifferentDivisionOperator({
    required super.context,
    required this.fixKind,
  });

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    DartType? leftType;
    Token operator;
    switch (node) {
      case BinaryExpression node:
        leftType = node.leftOperand.staticType;
        operator = node.operator;
      case AssignmentExpression node:
        leftType = node.writeType;
        operator = node.operator;
      default:
        return;
    }
    if (leftType == null) {
      return;
    }
    var operators = leftType.divisionOperators;
    var otherOperator = switch (operator.type) {
      TokenType.SLASH => TokenType.TILDE_SLASH,
      TokenType.TILDE_SLASH => TokenType.SLASH,
      TokenType.SLASH_EQ => TokenType.TILDE_SLASH_EQ,
      TokenType.TILDE_SLASH_EQ => TokenType.SLASH_EQ,
      _ => null,
    };
    if (otherOperator == null) {
      return;
    }
    // All extensions available in the current scope for the left operand that
    // define the other division operator.
    var name = Name.forLibrary(
      unitResult.libraryElement2,
      otherOperator.lexeme,
    );
    var hasNoExtensionWithOtherDivisionOperator =
        await librariesWithExtensions2(otherOperator.lexeme).where((library) {
          return library.exportedExtensions
              .havingMemberWithBaseName(name)
              .applicableTo(
                targetLibrary: libraryElement2,
                targetType: leftType!,
              )
              .isNotEmpty;
        }).isEmpty;
    if (hasNoExtensionWithOtherDivisionOperator && operators.isEmpty) {
      return;
    }
    if (operators.length > 1) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(operator), otherOperator.lexeme);
    });
  }
}

extension on DartType {
  Set<_DivisionOperator> get divisionOperators {
    switch (element3) {
      case InterfaceElement2 element:
        return {
          for (var method in element.methods2)
            // No need to test for eq operators, as they are not explicitly defined.
            if (method.name3 == TokenType.SLASH.lexeme)
              _DivisionOperator.division
            else if (method.name3 == TokenType.TILDE_SLASH.lexeme)
              _DivisionOperator.effectiveIntegerDivision,
          ...element.allSupertypes.expand((type) => type.divisionOperators),
        };
      case TypeParameterElement2 element:
        return element.bound?.divisionOperators ?? const {};
    }
    return const {};
  }
}
