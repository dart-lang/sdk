// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
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
    var exp = node;
    if (exp case BinaryExpression _) {
      return switch (exp.operator.type) {
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
    } else if (exp case AssignmentExpression _) {
      return switch (exp.operator.type) {
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
  final CorrectionProducerContext _context;

  _UseDifferentDivisionOperator({required super.context, required this.fixKind})
    : _context = context;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var exp = node;
    DartType? leftType;
    Token operator;
    if (exp case BinaryExpression _) {
      leftType = exp.leftOperand.staticType;
      operator = exp.operator;
    } else if (exp case AssignmentExpression _) {
      leftType = exp.writeType;
      operator = exp.operator;
    } else {
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
    var name = Name(
      _context.dartFixContext!.resolvedResult.libraryElement.source.uri,
      otherOperator.lexeme,
    );
    var hasNoExtensionWithOtherDivisionOperator =
        await _context.dartFixContext!
            .librariesWithExtensions(otherOperator.lexeme)
            .where((library) {
              return library.exportedExtensions
                  .havingMemberWithBaseName(name)
                  .applicableTo(
                    targetLibrary: libraryElement,
                    targetType: leftType!,
                  )
                  .isNotEmpty;
            })
            .isEmpty;
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
    // See operators defined for this type element.
    if (element case InterfaceElement interfaceElement) {
      return {
        for (var method in interfaceElement.methods)
          // No need to test for eq operators, as they are not explicitly defined.
          if (method.name == TokenType.SLASH.lexeme)
            _DivisionOperator.division
          else if (method.name == TokenType.TILDE_SLASH.lexeme)
            _DivisionOperator.effectiveIntegerDivision,
        ...interfaceElement.allSupertypes.expand(
          (type) => type.divisionOperators,
        ),
      };
    } else if (element case TypeParameterElement typeParameterElement) {
      return typeParameterElement.bound?.divisionOperators ?? const {};
    }

    return const {};
  }
}
