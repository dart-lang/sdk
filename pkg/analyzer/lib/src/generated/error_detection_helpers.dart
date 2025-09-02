// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/best_practices_verifier.dart';
library;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Methods useful in detecting errors.  This mixin exists to allow code to be
/// more easily shared between the two visitors that do the majority of error
/// reporting (ResolverVisitor and ErrorVerifier).
mixin ErrorDetectionHelpers {
  DiagnosticReporter get diagnosticReporter;

  InheritanceManager3 get inheritance;

  bool get strictCasts;

  TypeSystemImpl get typeSystem;

  /// Verify that the given [expression] can be assigned to its corresponding
  /// parameters. The [expectedStaticType] is the expected static type of the
  /// parameter. The [actualStaticType] is the actual static type of the
  /// argument.
  void checkForArgumentTypeNotAssignable(
    Expression expression,
    TypeImpl expectedStaticType,
    TypeImpl actualStaticType,
    DiagnosticCode diagnosticCode, {
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (expectedStaticType is! VoidType &&
        checkForUseOfVoidResult(expression)) {
      return;
    }

    checkForAssignableExpressionAtType(
      expression,
      actualStaticType,
      expectedStaticType,
      diagnosticCode,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Verify that the given [argument] can be assigned to its corresponding
  /// parameter.
  ///
  /// See [CompileTimeErrorCode.argumentTypeNotAssignable].
  void checkForArgumentTypeNotAssignableForArgument(
    ExpressionImpl argument, {
    bool promoteParameterToNullable = false,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    _checkForArgumentTypeNotAssignableForArgument(
      argument: argument is NamedExpressionImpl
          ? argument.expression
          : argument,
      parameter: argument.correspondingParameter,
      promoteParameterToNullable: promoteParameterToNullable,
      whyNotPromoted: whyNotPromoted,
    );
  }

  void checkForAssignableExpressionAtType(
    Expression expression,
    TypeImpl actualStaticType,
    TypeImpl expectedStaticType,
    DiagnosticCode diagnosticCode, {
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (expectedStaticType is! VoidType &&
        checkForUseOfVoidResult(expression)) {
      return;
    }

    if (!typeSystem.isAssignableTo(
      actualStaticType,
      expectedStaticType,
      strictCasts: strictCasts,
    )) {
      AstNode getErrorNode(AstNode node) {
        if (node is CascadeExpression) {
          return getErrorNode(node.target);
        }
        if (node is ParenthesizedExpression) {
          return getErrorNode(node.expression);
        }
        return node;
      }

      if (expectedStaticType is RecordTypeImpl &&
          expectedStaticType.positionalFields.length == 1 &&
          actualStaticType is! RecordType &&
          expression is ParenthesizedExpression) {
        var field = expectedStaticType.positionalFields.first;
        if (typeSystem.isAssignableTo(
          field.type,
          actualStaticType,
          strictCasts: strictCasts,
        )) {
          diagnosticReporter.atNode(
            expression,
            CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          );
          return;
        }
      }
      if (diagnosticCode == CompileTimeErrorCode.argumentTypeNotAssignable) {
        var additionalInfo = <String>[];
        if (expectedStaticType is RecordTypeImpl &&
            actualStaticType is RecordTypeImpl) {
          var actualPositionalFields = actualStaticType.positionalFields.length;
          var expectedPositionalFields =
              expectedStaticType.positionalFields.length;
          if (expectedPositionalFields != 0 &&
              actualPositionalFields != expectedPositionalFields) {
            additionalInfo.add(
              'Expected $expectedPositionalFields positional arguments, but got $actualPositionalFields instead.',
            );
          }
          var actualNamedFieldsLength = actualStaticType.namedFields.length;
          var expectedNamedFieldsLength = expectedStaticType.namedFields.length;
          if (expectedNamedFieldsLength != 0 &&
              actualNamedFieldsLength != expectedNamedFieldsLength) {
            additionalInfo.add(
              'Expected $expectedNamedFieldsLength named arguments, but got $actualNamedFieldsLength instead.',
            );
          }
          var namedFields = expectedStaticType.namedFields;
          if (namedFields.isNotEmpty) {
            for (var field in actualStaticType.namedFields) {
              if (!namedFields.any(
                (element) =>
                    element.name == field.name && field.type == element.type,
              )) {
                additionalInfo.add(
                  'Unexpected named argument `${field.name}` with type `${field.type.getDisplayString()}`.',
                );
              }
            }
          }
        }
        diagnosticReporter.atNode(
          getErrorNode(expression),
          diagnosticCode,
          arguments: [
            actualStaticType,
            expectedStaticType,
            additionalInfo.join(' '),
          ],
          contextMessages: computeWhyNotPromotedMessages(
            expression,
            whyNotPromoted?.call(),
          ),
        );
        return;
      }
      diagnosticReporter.atNode(
        getErrorNode(expression),
        diagnosticCode,
        arguments: [actualStaticType, expectedStaticType],
        contextMessages: computeWhyNotPromotedMessages(
          expression,
          whyNotPromoted?.call(),
        ),
      );
    }
  }

  /// Verify that the given constructor field [initializer] has compatible field
  /// and initializer expression types. The [fieldElement] is the static element
  /// from the name in the [ConstructorFieldInitializer].
  ///
  /// See [CompileTimeErrorCode.constFieldInitializerNotAssignable], and
  /// [CompileTimeErrorCode.fieldInitializerNotAssignable].
  void checkForFieldInitializerNotAssignable(
    ConstructorFieldInitializerImpl initializer,
    InternalFieldElement fieldElement, {
    required bool isConstConstructor,
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    // prepare field type
    var fieldType = fieldElement.type;
    // prepare expression type
    Expression expression = initializer.expression;
    // test the static type of the expression
    var staticType = expression.typeOrThrow;
    if (typeSystem.isAssignableTo(
      staticType,
      fieldType,
      strictCasts: strictCasts,
    )) {
      if (fieldType is! VoidType) {
        checkForUseOfVoidResult(expression);
      }
      return;
    }
    var messages = computeWhyNotPromotedMessages(
      expression,
      whyNotPromoted?.call(),
    );
    // report problem
    if (isConstConstructor) {
      // TODO(paulberry): this error should be based on the actual type of the
      // constant, not the static type.  See dartbug.com/21119.
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.constFieldInitializerNotAssignable,
        arguments: [staticType, fieldType],
        contextMessages: messages,
      );
    } else {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.fieldInitializerNotAssignable,
        arguments: [staticType, fieldType],
        contextMessages: messages,
      );
    }

    // TODO(brianwilkerson): Define a hint corresponding to these errors and
    // report it if appropriate.
    //        // test the propagated type of the expression
    //        Type propagatedType = expression.getPropagatedType();
    //        if (propagatedType != null && propagatedType.isAssignableTo(fieldType)) {
    //          return false;
    //        }
    //        // report problem
    //        if (isEnclosingConstructorConst) {
    //          errorReporter.reportTypeErrorForNode(
    //              CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
    //              expression,
    //              propagatedType == null ? staticType : propagatedType,
    //              fieldType);
    //        } else {
    //          errorReporter.reportTypeErrorForNode(
    //              StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
    //              expression,
    //              propagatedType == null ? staticType : propagatedType,
    //              fieldType);
    //        }
    //        return true;
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.useOfVoidResult].
  bool checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      diagnosticReporter.atNode(
        methodName,
        CompileTimeErrorCode.useOfVoidResult,
      );
    } else {
      diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.useOfVoidResult,
      );
    }

    return true;
  }

  void checkIndexExpressionIndex(
    Expression index, {
    required InternalExecutableElement? readElement,
    required InternalExecutableElement? writeElement,
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (readElement is InternalMethodElement) {
      var parameters = readElement.formalParameters;
      if (parameters.isNotEmpty) {
        _checkForArgumentTypeNotAssignableForArgument(
          argument: index,
          parameter: parameters[0],
          promoteParameterToNullable: false,
          whyNotPromoted: whyNotPromoted,
        );
      }
    }

    if (writeElement is InternalMethodElement) {
      var parameters = writeElement.formalParameters;
      if (parameters.isNotEmpty) {
        _checkForArgumentTypeNotAssignableForArgument(
          argument: index,
          parameter: parameters[0],
          promoteParameterToNullable: false,
          whyNotPromoted: whyNotPromoted,
        );
      }
    }
  }

  /// Computes the appropriate set of context messages to report along with an
  /// error that may have occurred because an expression was not type promoted.
  ///
  /// If the expression is `null`, it means the expression that was not type
  /// promoted was an implicit `this`.
  ///
  /// [errorEntity] is the entity whose location will be associated with the
  /// error.  This is needed for test instrumentation.
  ///
  /// [whyNotPromoted] should be the non-promotion details returned by the flow
  /// analysis engine.
  List<DiagnosticMessage> computeWhyNotPromotedMessages(
    SyntacticEntity errorEntity,
    Map<SharedTypeView, NonPromotionReason>? whyNotPromoted,
  );

  /// If an assignment from [type] to [context] is a case of an implicit 'call'
  /// method, returns the element of the 'call' method.
  ///
  /// From the spec:
  ///
  /// > Let `e` be an expression whose static type is an interface type that has
  /// > a method named `call`. In the case where the context type for `e`
  /// > is a function type or the type `Function`, `e` is treated as `e.call`.
  InternalMethodElement? getImplicitCallMethod(
    DartType type,
    DartType context,
    SyntacticEntity errorNode,
  ) {
    var visitedTypes = {type};
    while (type is TypeParameterType) {
      if (type.nullabilitySuffix != NullabilitySuffix.none) {
        // The value might be `null`, so implicit `.call` tearoff is invalid.
        return null;
      }
      type = type.bound;
      if (!visitedTypes.add(type)) {
        // A cycle!
        return null;
      }
    }
    if (typeSystem.acceptsFunctionType(context) &&
        type is InterfaceType &&
        type.nullabilitySuffix != NullabilitySuffix.question) {
      return inheritance
          .getMember3(
            type,
            Name.forLibrary(
              type.element.library,
              MethodElement.CALL_METHOD_NAME,
            ),
          )
          .ifTypeOrNull();
    } else {
      return null;
    }
  }

  /// Return the variable element represented by the given [expression], or
  /// `null` if there is no such element.
  VariableElement? getVariableElement(Expression? expression) {
    if (expression is Identifier) {
      var element = expression.element;
      if (element is VariableElement) {
        return element;
      }
    }
    return null;
  }

  void _checkForArgumentTypeNotAssignableForArgument({
    required Expression argument,
    required InternalFormalParameterElement? parameter,
    required bool promoteParameterToNullable,
    Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    var staticParameterType = parameter?.type;
    if (staticParameterType != null) {
      if (promoteParameterToNullable) {
        staticParameterType = typeSystem.makeNullable(staticParameterType);
      }
      checkForArgumentTypeNotAssignable(
        argument,
        staticParameterType,
        argument.typeOrThrow,
        CompileTimeErrorCode.argumentTypeNotAssignable,
        whyNotPromoted: whyNotPromoted,
      );
    }
  }
}
