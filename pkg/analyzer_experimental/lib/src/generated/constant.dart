// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.constant;

import 'java_core.dart';
import 'source.dart' show Source;
import 'error.dart' show AnalysisError, ErrorCode, CompileTimeErrorCode;
import 'scanner.dart' show TokenType;
import 'ast.dart';
import 'element.dart';

/**
 * Instances of the class {@code ConstantEvaluator} evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * <ul>
 * <li>A literal number.</li>
 * <li>A literal boolean.</li>
 * <li>A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to {@code null}.</li>
 * <li>{@code null}.</li>
 * <li>A reference to a static constant variable.</li>
 * <li>An identifier expression that denotes a constant variable, a class or a type variable.</li>
 * <li>A constant constructor invocation.</li>
 * <li>A constant list literal.</li>
 * <li>A constant map literal.</li>
 * <li>A simple or qualified identifier denoting a top-level function or a static method.</li>
 * <li>A parenthesized expression {@code (e)} where {@code e} is a constant expression.</li>
 * <li>An expression of one of the forms {@code identical(e1, e2)}, {@code e1 == e2},{@code e1 != e2} where {@code e1} and {@code e2} are constant expressions that evaluate to a
 * numeric, string or boolean value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code !e}, {@code e1 && e2} or {@code e1 || e2}, where{@code e}, {@code e1} and {@code e2} are constant expressions that evaluate to a boolean value or
 * to {@code null}.</li>
 * <li>An expression of one of the forms {@code ~e}, {@code e1 ^ e2}, {@code e1 & e2},{@code e1 | e2}, {@code e1 >> e2} or {@code e1 << e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to an integer value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code -e}, {@code e1 + e2}, {@code e1 - e2},{@code e1 * e2}, {@code e1 / e2}, {@code e1 ~/ e2}, {@code e1 > e2}, {@code e1 < e2},{@code e1 >= e2}, {@code e1 <= e2} or {@code e1 % e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to a numeric value or to {@code null}.</li>
 * </ul>
 * </blockquote> The values returned by instances of this class are therefore {@code null} and
 * instances of the classes {@code Boolean}, {@code BigInteger}, {@code Double}, {@code String}, and{@code DartObject}.
 * <p>
 * In addition, this class defines several values that can be returned to indicate various
 * conditions encountered during evaluation. These are documented with the static field that define
 * those values.
 */
class ConstantEvaluator {
  /**
   * The source containing the expression(s) that will be evaluated.
   */
  Source _source;
  /**
   * Initialize a newly created evaluator to evaluate expressions in the given source.
   * @param source the source containing the expression(s) that will be evaluated
   */
  ConstantEvaluator(Source source) {
    this._source = source;
  }
  EvaluationResult evaluate(Expression expression) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    if (result is ValidResult) {
      return EvaluationResult.forValue(((result as ValidResult)).value);
    }
    List<AnalysisError> errors = new List<AnalysisError>();
    for (ErrorResult_ErrorData data in ((result as ErrorResult)).errorData) {
      ASTNode node2 = data.node;
      errors.add(new AnalysisError.con2(_source, node2.offset, node2.length, data.errorCode, []));
    }
    return EvaluationResult.forErrors(new List.from(errors));
  }
}
/**
 * Instances of the class {@code EvaluationResult} represent the result of attempting to evaluate an
 * expression.
 */
class EvaluationResult {
  /**
   * Return an evaluation result representing the result of evaluating an expression that is not a
   * compile-time constant because of the given errors.
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   * @return the result of evaluating an expression that is not a compile-time constant
   */
  static EvaluationResult forErrors(List<AnalysisError> errors) => new EvaluationResult(null, errors);
  /**
   * Return an evaluation result representing the result of evaluating an expression that is a
   * compile-time constant that evaluates to the given value.
   * @param value the value of the expression
   * @return the result of evaluating an expression that is a compile-time constant
   */
  static EvaluationResult forValue(Object value) => new EvaluationResult(value, null);
  /**
   * The value of the expression.
   */
  Object _value;
  /**
   * The errors that should be reported for the expression(s) that were evaluated.
   */
  List<AnalysisError> _errors;
  /**
   * Initialize a newly created result object with the given state. Clients should use one of the
   * factory methods: {@link #forErrors(AnalysisError[])} and {@link #forValue(Object)}.
   * @param value the value of the expression
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   */
  EvaluationResult(Object value, List<AnalysisError> errors) {
    this._value = value;
    this._errors = errors;
  }
  /**
   * Return an array containing the errors that should be reported for the expression(s) that were
   * evaluated. If there are no such errors, the array will be empty. The array can be empty even if
   * the expression is not a valid compile time constant if the errors would have been reported by
   * other parts of the analysis engine.
   */
  List<AnalysisError> get errors => _errors == null ? AnalysisError.NO_ERRORS : _errors;
  /**
   * Return the value of the expression, or {@code null} if the expression evaluated to {@code null}or if the expression could not be evaluated, either because it was not a compile-time constant
   * expression or because it would throw an exception when evaluated.
   * @return the value of the expression
   */
  Object get value => _value;
  /**
   * Return {@code true} if the expression is a compile-time constant expression that would not
   * throw an exception when evaluated.
   * @return {@code true} if the expression is a valid compile-time constant expression
   */
  bool isValid() => _errors == null;
}
/**
 * Instances of the class {@code ConstantVisitor} evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * <ul>
 * <li>A literal number.</li>
 * <li>A literal boolean.</li>
 * <li>A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to {@code null}.</li>
 * <li>{@code null}.</li>
 * <li>A reference to a static constant variable.</li>
 * <li>An identifier expression that denotes a constant variable, a class or a type variable.</li>
 * <li>A constant constructor invocation.</li>
 * <li>A constant list literal.</li>
 * <li>A constant map literal.</li>
 * <li>A simple or qualified identifier denoting a top-level function or a static method.</li>
 * <li>A parenthesized expression {@code (e)} where {@code e} is a constant expression.</li>
 * <li>An expression of one of the forms {@code identical(e1, e2)}, {@code e1 == e2},{@code e1 != e2} where {@code e1} and {@code e2} are constant expressions that evaluate to a
 * numeric, string or boolean value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code !e}, {@code e1 && e2} or {@code e1 || e2}, where{@code e}, {@code e1} and {@code e2} are constant expressions that evaluate to a boolean value or
 * to {@code null}.</li>
 * <li>An expression of one of the forms {@code ~e}, {@code e1 ^ e2}, {@code e1 & e2},{@code e1 | e2}, {@code e1 >> e2} or {@code e1 << e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to an integer value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code -e}, {@code e1 + e2}, {@code e1 - e2},{@code e1 * e2}, {@code e1 / e2}, {@code e1 ~/ e2}, {@code e1 > e2}, {@code e1 < e2},{@code e1 >= e2}, {@code e1 <= e2} or {@code e1 % e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to a numeric value or to {@code null}.</li>
 * </ul>
 * </blockquote>
 */
class ConstantVisitor extends GeneralizingASTVisitor<EvaluationResultImpl> {
  /**
   * Initialize a newly created constant visitor.
   */
  ConstantVisitor() : super() {
  }
  EvaluationResultImpl visitAdjacentStrings(AdjacentStrings node) {
    EvaluationResultImpl result = null;
    for (StringLiteral string in node.strings) {
      if (result == null) {
        result = string.accept(this);
      } else {
        result = result.concatenate(node, string.accept(this));
      }
    }
    return result;
  }
  EvaluationResultImpl visitBinaryExpression(BinaryExpression node) {
    EvaluationResultImpl leftResult = node.leftOperand.accept(this);
    EvaluationResultImpl rightResult = node.rightOperand.accept(this);
    while (true) {
      if (node.operator.type == TokenType.AMPERSAND) {
        return leftResult.bitAnd(node, rightResult);
      } else if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        return leftResult.logicalAnd(node, rightResult);
      } else if (node.operator.type == TokenType.BANG_EQ) {
        return leftResult.notEqual(node, rightResult);
      } else if (node.operator.type == TokenType.BAR) {
        return leftResult.bitOr(node, rightResult);
      } else if (node.operator.type == TokenType.BAR_BAR) {
        return leftResult.logicalOr(node, rightResult);
      } else if (node.operator.type == TokenType.CARET) {
        return leftResult.bitXor(node, rightResult);
      } else if (node.operator.type == TokenType.EQ_EQ) {
        return leftResult.equalEqual(node, rightResult);
      } else if (node.operator.type == TokenType.GT) {
        return leftResult.greaterThan(node, rightResult);
      } else if (node.operator.type == TokenType.GT_EQ) {
        return leftResult.greaterThanOrEqual(node, rightResult);
      } else if (node.operator.type == TokenType.GT_GT) {
        return leftResult.shiftRight(node, rightResult);
      } else if (node.operator.type == TokenType.LT) {
        return leftResult.lessThan(node, rightResult);
      } else if (node.operator.type == TokenType.LT_EQ) {
        return leftResult.lessThanOrEqual(node, rightResult);
      } else if (node.operator.type == TokenType.LT_LT) {
        return leftResult.shiftLeft(node, rightResult);
      } else if (node.operator.type == TokenType.MINUS) {
        return leftResult.minus(node, rightResult);
      } else if (node.operator.type == TokenType.PERCENT) {
        return leftResult.remainder(node, rightResult);
      } else if (node.operator.type == TokenType.PLUS) {
        return leftResult.add(node, rightResult);
      } else if (node.operator.type == TokenType.STAR) {
        return leftResult.times(node, rightResult);
      } else if (node.operator.type == TokenType.SLASH) {
        return leftResult.divide(node, rightResult);
      } else if (node.operator.type == TokenType.TILDE_SLASH) {
        return leftResult.integerDivide(node, rightResult);
      }
      break;
    }
    return error(node, null);
  }
  EvaluationResultImpl visitBooleanLiteral(BooleanLiteral node) => node.value ? ValidResult.RESULT_TRUE : ValidResult.RESULT_FALSE;
  EvaluationResultImpl visitDoubleLiteral(DoubleLiteral node) => new ValidResult(node.value);
  EvaluationResultImpl visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement constructor = node.element;
    if (constructor != null && constructor.isConst()) {
      node.argumentList.accept(this);
      return ValidResult.RESULT_OBJECT;
    }
    return error(node, null);
  }
  EvaluationResultImpl visitIntegerLiteral(IntegerLiteral node) => new ValidResult(node.value);
  EvaluationResultImpl visitInterpolationExpression(InterpolationExpression node) {
    EvaluationResultImpl result = node.expression.accept(this);
    return result.performToString(node);
  }
  EvaluationResultImpl visitInterpolationString(InterpolationString node) => new ValidResult(node.value);
  EvaluationResultImpl visitListLiteral(ListLiteral node) {
    ErrorResult result = null;
    for (Expression element in node.elements) {
      result = union(result, element.accept(this));
    }
    if (result != null) {
      return result;
    }
    return ValidResult.RESULT_OBJECT;
  }
  EvaluationResultImpl visitMapLiteral(MapLiteral node) {
    ErrorResult result = null;
    for (MapLiteralEntry entry in node.entries) {
      result = union(result, entry.key.accept(this));
      result = union(result, entry.value.accept(this));
    }
    if (result != null) {
      return result;
    }
    return ValidResult.RESULT_OBJECT;
  }
  EvaluationResultImpl visitMethodInvocation(MethodInvocation node) {
    Element element21 = node.methodName.element;
    if (element21 is FunctionElement) {
      FunctionElement function = element21 as FunctionElement;
      if (function.name == "identical") {
        NodeList<Expression> arguments3 = node.argumentList.arguments;
        if (arguments3.length == 2) {
          Element enclosingElement2 = function.enclosingElement;
          if (enclosingElement2 is CompilationUnitElement) {
            LibraryElement library20 = ((enclosingElement2 as CompilationUnitElement)).library;
            if (library20.isDartCore()) {
              EvaluationResultImpl leftArgument = arguments3[0].accept(this);
              EvaluationResultImpl rightArgument = arguments3[1].accept(this);
              return leftArgument.equalEqual(node, rightArgument);
            }
          }
        }
      }
    }
    return error(node, null);
  }
  EvaluationResultImpl visitNode(ASTNode node) => error(node, null);
  EvaluationResultImpl visitNullLiteral(NullLiteral node) => new ValidResult(null);
  EvaluationResultImpl visitParenthesizedExpression(ParenthesizedExpression node) => node.expression.accept(this);
  EvaluationResultImpl visitPrefixedIdentifier(PrefixedIdentifier node) => getConstantValue(node, node.element);
  EvaluationResultImpl visitPrefixExpression(PrefixExpression node) {
    EvaluationResultImpl operand3 = node.operand.accept(this);
    while (true) {
      if (node.operator.type == TokenType.BANG) {
        return operand3.logicalNot(node);
      } else if (node.operator.type == TokenType.TILDE) {
        return operand3.bitNot(node);
      } else if (node.operator.type == TokenType.MINUS) {
        return operand3.negated(node);
      }
      break;
    }
    return error(node, null);
  }
  EvaluationResultImpl visitPropertyAccess(PropertyAccess node) => getConstantValue(node, node.propertyName.element);
  EvaluationResultImpl visitSimpleIdentifier(SimpleIdentifier node) => getConstantValue(node, node.element);
  EvaluationResultImpl visitSimpleStringLiteral(SimpleStringLiteral node) => new ValidResult(node.value);
  EvaluationResultImpl visitStringInterpolation(StringInterpolation node) {
    EvaluationResultImpl result = null;
    for (InterpolationElement element in node.elements) {
      if (result == null) {
        result = element.accept(this);
      } else {
        result = result.concatenate(node, element.accept(this));
      }
    }
    return result;
  }
  /**
   * Return a result object representing an error associated with the given node.
   * @param node the AST node associated with the error
   * @param code the error code indicating the nature of the error
   * @return a result object representing an error associated with the given node
   */
  ErrorResult error(ASTNode node, ErrorCode code) => new ErrorResult.con1(node, code == null ? CompileTimeErrorCode.INVALID_CONSTANT : code);
  /**
   * Return the constant value of the static constant represented by the given element.
   * @param node the node to be used if an error needs to be reported
   * @param element the element whose value is to be returned
   * @return the constant value of the static constant
   */
  EvaluationResultImpl getConstantValue(ASTNode node, Element element) {
    if (element is PropertyAccessorElementImpl) {
      element = ((element as PropertyAccessorElementImpl)).variable;
    }
    if (element is VariableElementImpl) {
      EvaluationResultImpl value = ((element as VariableElementImpl)).evaluationResult;
      if (value != null) {
        return value;
      }
    }
    return error(node, null);
  }
  /**
   * Return the union of the errors encoded in the given results.
   * @param leftResult the first set of errors, or {@code null} if there was no previous collection
   * of errors
   * @param rightResult the errors to be added to the collection, or a valid result if there are no
   * errors to be added
   * @return the union of the errors encoded in the given results
   */
  ErrorResult union(ErrorResult leftResult, EvaluationResultImpl rightResult) {
    if (rightResult is ErrorResult) {
      if (leftResult != null) {
        return new ErrorResult.con2(leftResult, (rightResult as ErrorResult));
      } else {
        return rightResult as ErrorResult;
      }
    }
    return leftResult;
  }
}
/**
 * Instances of the class {@code ErrorResult} represent the result of evaluating an expression that
 * is not a valid compile time constant.
 */
class ErrorResult extends EvaluationResultImpl {
  /**
   * The errors that prevent the expression from being a valid compile time constant.
   */
  List<ErrorResult_ErrorData> _errors = new List<ErrorResult_ErrorData>();
  /**
   * Initialize a newly created result representing the error with the given code reported against
   * the given node.
   * @param node the node against which the error should be reported
   * @param errorCode the error code for the error to be generated
   */
  ErrorResult.con1(ASTNode node, ErrorCode errorCode) {
    _jtd_constructor_156_impl(node, errorCode);
  }
  _jtd_constructor_156_impl(ASTNode node, ErrorCode errorCode) {
    _errors.add(new ErrorResult_ErrorData(node, errorCode));
  }
  /**
   * Initialize a newly created result to represent the union of the errors in the given result
   * objects.
   * @param firstResult the first set of results being merged
   * @param secondResult the second set of results being merged
   */
  ErrorResult.con2(ErrorResult firstResult, ErrorResult secondResult) {
    _jtd_constructor_157_impl(firstResult, secondResult);
  }
  _jtd_constructor_157_impl(ErrorResult firstResult, ErrorResult secondResult) {
    _errors.addAll(firstResult._errors);
    _errors.addAll(secondResult._errors);
  }
  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.addToError(node, this);
  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitAndError(node, this);
  EvaluationResultImpl bitNot(Expression node) => this;
  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitOrError(node, this);
  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitXorError(node, this);
  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand) => rightOperand.concatenateError(node, this);
  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.divideError(node, this);
  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand) => rightOperand.equalEqualError(node, this);
  List<ErrorResult_ErrorData> get errorData => _errors;
  List<AnalysisError> get errors => new List.from(_errors);
  EvaluationResultImpl greaterThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanError(node, this);
  EvaluationResultImpl greaterThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanOrEqualError(node, this);
  EvaluationResultImpl integerDivide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.integerDivideError(node, this);
  EvaluationResultImpl integerDivideValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl lessThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanError(node, this);
  EvaluationResultImpl lessThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanOrEqualError(node, this);
  EvaluationResultImpl logicalAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalAndError(node, this);
  EvaluationResultImpl logicalNot(Expression node) => this;
  EvaluationResultImpl logicalOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalOrError(node, this);
  EvaluationResultImpl minus(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.minusError(node, this);
  EvaluationResultImpl negated(Expression node) => this;
  EvaluationResultImpl notEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.notEqualError(node, this);
  EvaluationResultImpl performToString(ASTNode node) => this;
  EvaluationResultImpl remainder(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.remainderError(node, this);
  EvaluationResultImpl shiftLeft(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftLeftError(node, this);
  EvaluationResultImpl shiftRight(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftRightError(node, this);
  EvaluationResultImpl times(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.timesError(node, this);
  EvaluationResultImpl addToError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl addToValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl bitAndError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl bitAndValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl bitOrError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl bitOrValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl bitXorError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl bitXorValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl concatenateError(Expression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl concatenateValid(Expression node, ValidResult leftOperand) => this;
  EvaluationResultImpl divideError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl divideValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl equalEqualError(Expression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl equalEqualValid(Expression node, ValidResult leftOperand) => this;
  EvaluationResultImpl greaterThanError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl greaterThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl greaterThanOrEqualValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl greaterThanValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl integerDivideError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl lessThanError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl lessThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl lessThanOrEqualValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl lessThanValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl logicalAndError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl logicalAndValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl logicalOrError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl logicalOrValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl minusError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl minusValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl notEqualError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl notEqualValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl remainderError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl remainderValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl shiftLeftError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl shiftLeftValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl shiftRightError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl shiftRightValid(BinaryExpression node, ValidResult leftOperand) => this;
  EvaluationResultImpl timesError(BinaryExpression node, ErrorResult leftOperand) => new ErrorResult.con2(this, leftOperand);
  EvaluationResultImpl timesValid(BinaryExpression node, ValidResult leftOperand) => this;
}
class ErrorResult_ErrorData {
  /**
   * The node against which the error should be reported.
   */
  ASTNode _node;
  /**
   * The error code for the error to be generated.
   */
  ErrorCode _errorCode;
  /**
   * Initialize a newly created data holder to represent the error with the given code reported
   * against the given node.
   * @param node the node against which the error should be reported
   * @param errorCode the error code for the error to be generated
   */
  ErrorResult_ErrorData(ASTNode node, ErrorCode errorCode) {
    this._node = node;
    this._errorCode = errorCode;
  }
  /**
   * Return the error code for the error to be generated.
   * @return the error code for the error to be generated
   */
  ErrorCode get errorCode => _errorCode;
  /**
   * Return the node against which the error should be reported.
   * @return the node against which the error should be reported
   */
  ASTNode get node => _node;
}
/**
 * Instances of the class {@code InternalResult} represent the result of attempting to evaluate a
 * expression.
 */
abstract class EvaluationResultImpl {
  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl bitNot(Expression node);
  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl greaterThan(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl greaterThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl integerDivide(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl lessThan(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl lessThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl logicalAnd(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl logicalNot(Expression node);
  EvaluationResultImpl logicalOr(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl minus(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl negated(Expression node);
  EvaluationResultImpl notEqual(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl performToString(ASTNode node);
  EvaluationResultImpl remainder(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl shiftLeft(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl shiftRight(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl times(BinaryExpression node, EvaluationResultImpl rightOperand);
  EvaluationResultImpl addToError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl addToValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl bitAndError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl bitAndValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl bitOrError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl bitOrValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl bitXorError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl bitXorValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl concatenateError(Expression node, ErrorResult leftOperand);
  EvaluationResultImpl concatenateValid(Expression node, ValidResult leftOperand);
  EvaluationResultImpl divideError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl divideValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl equalEqualError(Expression node, ErrorResult leftOperand);
  EvaluationResultImpl equalEqualValid(Expression node, ValidResult leftOperand);
  EvaluationResultImpl greaterThanError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl greaterThanOrEqualError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl greaterThanOrEqualValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl greaterThanValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl integerDivideError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl integerDivideValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl lessThanError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl lessThanOrEqualError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl lessThanOrEqualValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl lessThanValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl logicalAndError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl logicalAndValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl logicalOrError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl logicalOrValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl minusError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl minusValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl notEqualError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl notEqualValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl remainderError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl remainderValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl shiftLeftError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl shiftLeftValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl shiftRightError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl shiftRightValid(BinaryExpression node, ValidResult leftOperand);
  EvaluationResultImpl timesError(BinaryExpression node, ErrorResult leftOperand);
  EvaluationResultImpl timesValid(BinaryExpression node, ValidResult leftOperand);
}
/**
 * Instances of the class {@code ValidResult} represent the result of attempting to evaluate a valid
 * compile time constant expression.
 */
class ValidResult extends EvaluationResultImpl {
  /**
   * A result object representing the value 'false'.
   */
  static ValidResult RESULT_FALSE = new ValidResult(false);
  /**
   * A result object representing the an arbitrary object on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_OBJECT = new ValidResult(new Object());
  /**
   * A result object representing the value 'true'.
   */
  static ValidResult RESULT_TRUE = new ValidResult(true);
  /**
   * The value of the expression.
   */
  Object _value;
  /**
   * Initialize a newly created result to represent the given value.
   * @param value the value of the expression
   */
  ValidResult(Object value) {
    this._value = value;
  }
  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.addToValid(node, this);
  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitAndValid(node, this);
  EvaluationResultImpl bitNot(Expression node) {
    if (_value == null) {
      return error(node);
    } else if (_value is int) {
      return valueOf(~((_value as int)));
    }
    return error(node);
  }
  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitOrValid(node, this);
  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitXorValid(node, this);
  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand) => rightOperand.concatenateValid(node, this);
  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.divideValid(node, this);
  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand) => rightOperand.equalEqualValid(node, this);
  Object get value => _value;
  EvaluationResultImpl greaterThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanValid(node, this);
  EvaluationResultImpl greaterThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanOrEqualValid(node, this);
  EvaluationResultImpl integerDivide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.integerDivideValid(node, this);
  EvaluationResultImpl lessThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanValid(node, this);
  EvaluationResultImpl lessThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanOrEqualValid(node, this);
  EvaluationResultImpl logicalAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalAndValid(node, this);
  EvaluationResultImpl logicalNot(Expression node) {
    if (_value == null) {
      return RESULT_TRUE;
    } else if (_value is bool) {
      return ((_value as bool)) ? RESULT_FALSE : RESULT_TRUE;
    }
    return error(node);
  }
  EvaluationResultImpl logicalOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalOrValid(node, this);
  EvaluationResultImpl minus(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.minusValid(node, this);
  EvaluationResultImpl negated(Expression node) {
    if (_value == null) {
      return error(node);
    } else if (_value is int) {
      return valueOf(-((_value as int)));
    } else if (_value is double) {
      return valueOf3(-((_value as double)));
    }
    return error(node);
  }
  EvaluationResultImpl notEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.notEqualValid(node, this);
  EvaluationResultImpl performToString(ASTNode node) {
    if (_value == null) {
      return valueOf4("null");
    } else if (_value is bool) {
      return valueOf4(((_value as bool)).toString());
    } else if (_value is int) {
      return valueOf4(((_value as int)).toString());
    } else if (_value is double) {
      return valueOf4(((_value as double)).toString());
    } else if (_value is String) {
      return this;
    }
    return error(node);
  }
  EvaluationResultImpl remainder(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.remainderValid(node, this);
  EvaluationResultImpl shiftLeft(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftLeftValid(node, this);
  EvaluationResultImpl shiftRight(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftRightValid(node, this);
  EvaluationResultImpl times(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.timesValid(node, this);
  String toString() {
    if (_value == null) {
      return "null";
    }
    return _value.toString();
  }
  EvaluationResultImpl addToError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl addToValid(BinaryExpression node, ValidResult leftOperand3) {
    Object leftValue = leftOperand3.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) + (_value as int));
      } else if (_value is double) {
        return valueOf3(((leftValue as int)).toDouble() + ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf3(((leftValue as double)) + ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf3(((leftValue as double)) + ((_value as double)));
      }
    } else if (leftValue is String) {
      if (_value is String) {
        return valueOf4("${((leftValue as String))}${((_value as String))}");
      }
    }
    return error(node);
  }
  EvaluationResultImpl bitAndError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl bitAndValid(BinaryExpression node, ValidResult leftOperand4) {
    Object leftValue = leftOperand4.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) & (_value as int));
      }
      return error(node.leftOperand);
    }
    if (_value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }
  EvaluationResultImpl bitOrError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl bitOrValid(BinaryExpression node, ValidResult leftOperand5) {
    Object leftValue = leftOperand5.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) | (_value as int));
      }
      return error(node.leftOperand);
    }
    if (_value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }
  EvaluationResultImpl bitXorError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl bitXorValid(BinaryExpression node, ValidResult leftOperand6) {
    Object leftValue = leftOperand6.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) ^ (_value as int));
      }
      return error(node.leftOperand);
    }
    if (_value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }
  EvaluationResultImpl concatenateError(Expression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl concatenateValid(Expression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue is String && _value is String) {
      return valueOf4("${((leftValue as String))}${((_value as String))}");
    }
    return error(node);
  }
  EvaluationResultImpl divideError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl divideValid(BinaryExpression node, ValidResult leftOperand7) {
    Object leftValue = leftOperand7.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        if (((_value as int)) == 0) {
          return error2(node.rightOperand, CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO);
        }
        return valueOf(((leftValue as int)) ~/ (_value as int));
      } else if (_value is double) {
        return valueOf3(((leftValue as int)).toDouble() / ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf3(((leftValue as double)) / ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf3(((leftValue as double)) / ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl equalEqualError(Expression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl equalEqualValid(Expression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return valueOf2(_value == null);
    } else if (leftValue is bool) {
      if (_value is bool) {
        return valueOf2(identical(((leftValue as bool)), ((_value as bool))));
      }
      return RESULT_FALSE;
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)) == _value);
      } else if (_value is double) {
        return valueOf2(toDouble((leftValue as int)) == _value);
      }
      return RESULT_FALSE;
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) == toDouble((_value as int)));
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) == _value);
      }
      return RESULT_FALSE;
    } else if (leftValue is String) {
      if (_value is String) {
        return valueOf2(((leftValue as String)) == _value);
      }
      return RESULT_FALSE;
    }
    return RESULT_FALSE;
  }
  EvaluationResultImpl greaterThanError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl greaterThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl greaterThanOrEqualValid(BinaryExpression node, ValidResult leftOperand8) {
    Object leftValue = leftOperand8.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)).compareTo((_value as int)) >= 0);
      } else if (_value is double) {
        return valueOf2(((leftValue as int)).toDouble() >= ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) >= ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) >= ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl greaterThanValid(BinaryExpression node, ValidResult leftOperand9) {
    Object leftValue = leftOperand9.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)).compareTo((_value as int)) > 0);
      } else if (_value is double) {
        return valueOf2(((leftValue as int)).toDouble() > ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) > ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) > ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl integerDivideError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl integerDivideValid(BinaryExpression node, ValidResult leftOperand10) {
    Object leftValue = leftOperand10.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        if (((_value as int)) == 0) {
          return error2(node.rightOperand, CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO);
        }
        return valueOf(((leftValue as int)) ~/ (_value as int));
      } else if (_value is double) {
        double result = ((leftValue as int)).toDouble() / ((_value as double));
        return valueOf((result as int));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        double result = ((leftValue as double)) / ((_value as int)).toDouble();
        return valueOf((result as int));
      } else if (_value is double) {
        double result = ((leftValue as double)) / ((_value as double));
        return valueOf((result as int));
      }
    }
    return error(node);
  }
  EvaluationResultImpl lessThanError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl lessThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl lessThanOrEqualValid(BinaryExpression node, ValidResult leftOperand11) {
    Object leftValue = leftOperand11.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)).compareTo((_value as int)) <= 0);
      } else if (_value is double) {
        return valueOf2(((leftValue as int)).toDouble() <= ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) <= ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) <= ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl lessThanValid(BinaryExpression node, ValidResult leftOperand12) {
    Object leftValue = leftOperand12.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)).compareTo((_value as int)) < 0);
      } else if (_value is double) {
        return valueOf2(((leftValue as int)).toDouble() < ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) < ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) < ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl logicalAndError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl logicalAndValid(BinaryExpression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue is bool && ((leftValue as bool))) {
      return booleanConversion(node.rightOperand, _value);
    }
    return RESULT_FALSE;
  }
  EvaluationResultImpl logicalOrError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl logicalOrValid(BinaryExpression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue is bool && ((leftValue as bool))) {
      return RESULT_TRUE;
    }
    return booleanConversion(node.rightOperand, _value);
  }
  EvaluationResultImpl minusError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl minusValid(BinaryExpression node, ValidResult leftOperand13) {
    Object leftValue = leftOperand13.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) - (_value as int));
      } else if (_value is double) {
        return valueOf3(((leftValue as int)).toDouble() - ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf3(((leftValue as double)) - ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf3(((leftValue as double)) - ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl notEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl notEqualValid(BinaryExpression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return valueOf2(_value != null);
    } else if (leftValue is bool) {
      if (_value is bool) {
        return valueOf2(((leftValue as bool)) != ((_value as bool)));
      }
      return RESULT_TRUE;
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf2(((leftValue as int)) != _value);
      } else if (_value is double) {
        return valueOf2(toDouble((leftValue as int)) != _value);
      }
      return RESULT_TRUE;
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf2(((leftValue as double)) != toDouble((_value as int)));
      } else if (_value is double) {
        return valueOf2(((leftValue as double)) != _value);
      }
      return RESULT_TRUE;
    } else if (leftValue is String) {
      if (_value is String) {
        return valueOf2(((leftValue as String)) != _value);
      }
      return RESULT_TRUE;
    }
    return RESULT_TRUE;
  }
  EvaluationResultImpl remainderError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl remainderValid(BinaryExpression node, ValidResult leftOperand14) {
    Object leftValue = leftOperand14.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (((_value as int)) == 0) {
        return error2(node.rightOperand, CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO);
      }
      if (_value is int) {
        return valueOf(((leftValue as int)).remainder((_value as int)));
      } else if (_value is double) {
        return valueOf3(((leftValue as int)).toDouble() % ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf3(((leftValue as double)) % ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf3(((leftValue as double)) % ((_value as double)));
      }
    }
    return error(node);
  }
  EvaluationResultImpl shiftLeftError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl shiftLeftValid(BinaryExpression node, ValidResult leftOperand15) {
    Object leftValue = leftOperand15.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) << ((_value as int)));
      }
      return error(node.rightOperand);
    }
    if (_value is int) {
      return error(node.leftOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }
  EvaluationResultImpl shiftRightError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl shiftRightValid(BinaryExpression node, ValidResult leftOperand16) {
    Object leftValue = leftOperand16.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) >> ((_value as int)));
      }
      return error(node.rightOperand);
    }
    if (_value is int) {
      return error(node.leftOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }
  EvaluationResultImpl timesError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;
  EvaluationResultImpl timesValid(BinaryExpression node, ValidResult leftOperand17) {
    Object leftValue = leftOperand17.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (_value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (_value is int) {
        return valueOf(((leftValue as int)) * (_value as int));
      } else if (_value is double) {
        return valueOf3(((leftValue as int)).toDouble() * ((_value as double)));
      }
    } else if (leftValue is double) {
      if (_value is int) {
        return valueOf3(((leftValue as double)) * ((_value as int)).toDouble());
      } else if (_value is double) {
        return valueOf3(((leftValue as double)) * ((_value as double)));
      }
    }
    return error(node);
  }
  /**
   * Return the result of applying boolean conversion to the given value.
   * @param node the node against which errors should be reported
   * @param value the value to be converted to a boolean
   * @return the result of applying boolean conversion to the given value
   */
  EvaluationResultImpl booleanConversion(ASTNode node, Object value) {
    if (value == null) {
      return error(node);
    } else if (value is bool && ((value as bool))) {
      return RESULT_TRUE;
    }
    return RESULT_FALSE;
  }
  ErrorResult error(ASTNode node) => error2(node, CompileTimeErrorCode.INVALID_CONSTANT);
  /**
   * Return a result object representing an error associated with the given node.
   * @param node the AST node associated with the error
   * @param code the error code indicating the nature of the error
   * @return a result object representing an error associated with the given node
   */
  ErrorResult error2(ASTNode node, ErrorCode code) => new ErrorResult.con1(node, code);
  double toDouble(int value) => value.toDouble();
  /**
   * Return an error result that is the union of the two given error results.
   * @param firstError the first error to be combined
   * @param secondError the second error to be combined
   * @return an error result that is the union of the two given error results
   */
  ErrorResult union(ErrorResult firstError, ErrorResult secondError) => new ErrorResult.con2(firstError, secondError);
  /**
   * Return a result object representing the given value.
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf(int value) => new ValidResult(value);
  /**
   * Return a result object representing the given value.
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf2(bool value) => value ? RESULT_TRUE : RESULT_FALSE;
  /**
   * Return a result object representing the given value.
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf3(double value) => new ValidResult(value);
  /**
   * Return a result object representing the given value.
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf4(String value) => new ValidResult(value);
}