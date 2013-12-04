// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.constant;

import 'java_core.dart';
import 'source.dart' show Source;
import 'error.dart' show AnalysisError, ErrorCode, CompileTimeErrorCode;
import 'scanner.dart' show TokenType;
import 'ast.dart';
import 'element.dart';
import 'engine.dart' show AnalysisEngine;

/**
 * Instances of the class `ConstantEvaluator` evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 *
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to `null`.
 * * `null`.
 * * A reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, a class or a type parameter.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static method.
 * * A parenthesized expression `(e)` where `e` is a constant expression.
 * * An expression of one of the forms `identical(e1, e2)`, `e1 == e2`,
 * `e1 != e2` where `e1` and `e2` are constant expressions that evaluate to a
 * numeric, string or boolean value or to `null`.
 * * An expression of one of the forms `!e`, `e1 && e2` or `e1 || e2`, where
 * `e`, `e1` and `e2` are constant expressions that evaluate to a boolean value or
 * to `null`.
 * * An expression of one of the forms `~e`, `e1 ^ e2`, `e1 & e2`,
 * `e1 | e2`, `e1 >> e2` or `e1 << e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to an integer value or to `null`.
 * * An expression of one of the forms `-e`, `e1 + e2`, `e1 - e2`,
 * `e1 * e2`, `e1 / e2`, `e1 ~/ e2`, `e1 > e2`, `e1 < e2`,
 * `e1 >= e2`, `e1 <= e2` or `e1 % e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to a numeric value or to `null`.
 *
 * </blockquote> The values returned by instances of this class are therefore `null` and
 * instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
 * `DartObject`.
 *
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
   *
   * @param source the source containing the expression(s) that will be evaluated
   */
  ConstantEvaluator(Source source) {
    this._source = source;
  }

  EvaluationResult evaluate(Expression expression) {
    EvaluationResultImpl result = expression.accept(new ConstantVisitor());
    if (result is ValidResult) {
      return EvaluationResult.forValue((result as ValidResult).value);
    }
    List<AnalysisError> errors = new List<AnalysisError>();
    for (ErrorResult_ErrorData data in (result as ErrorResult).errorData) {
      ASTNode node = data.node;
      errors.add(new AnalysisError.con2(_source, node.offset, node.length, data.errorCode, []));
    }
    return EvaluationResult.forErrors(new List.from(errors));
  }
}

/**
 * Instances of the class `EvaluationResult` represent the result of attempting to evaluate an
 * expression.
 */
class EvaluationResult {
  /**
   * Return an evaluation result representing the result of evaluating an expression that is not a
   * compile-time constant because of the given errors.
   *
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   * @return the result of evaluating an expression that is not a compile-time constant
   */
  static EvaluationResult forErrors(List<AnalysisError> errors) => new EvaluationResult(null, errors);

  /**
   * Return an evaluation result representing the result of evaluating an expression that is a
   * compile-time constant that evaluates to the given value.
   *
   * @param value the value of the expression
   * @return the result of evaluating an expression that is a compile-time constant
   */
  static EvaluationResult forValue(Object value) => new EvaluationResult(value, null);

  /**
   * The value of the expression.
   */
  Object value;

  /**
   * The errors that should be reported for the expression(s) that were evaluated.
   */
  List<AnalysisError> _errors;

  /**
   * Initialize a newly created result object with the given state. Clients should use one of the
   * factory methods: [forErrors] and [forValue].
   *
   * @param value the value of the expression
   * @param errors the errors that should be reported for the expression(s) that were evaluated
   */
  EvaluationResult(Object value, List<AnalysisError> errors) {
    this.value = value;
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
   * Return `true` if the expression is a compile-time constant expression that would not
   * throw an exception when evaluated.
   *
   * @return `true` if the expression is a valid compile-time constant expression
   */
  bool get isValid => _errors == null;
}

/**
 * Instances of the class `ConstantFinder` are used to traverse the AST structures of all of
 * the compilation units being resolved and build a table mapping constant variable elements to the
 * declarations of those variables.
 */
class ConstantFinder extends RecursiveASTVisitor<Object> {
  /**
   * A table mapping constant variable elements to the declarations of those variables.
   */
  final Map<VariableElement, VariableDeclaration> variableMap = new Map<VariableElement, VariableDeclaration>();

  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    Expression initializer = node.initializer;
    if (initializer != null && node.isConst) {
      VariableElement element = node.element;
      if (element != null) {
        variableMap[element] = node;
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ConstantValueComputer` compute the values of constant variables in
 * one or more compilation units. The expected usage pattern is for the compilation units to be
 * added to this computer using the method [add] and then for the method
 * [computeValues] to invoked exactly once. Any use of an instance after invoking the
 * method [computeValues] will result in unpredictable behavior.
 */
class ConstantValueComputer {
  /**
   * The object used to find constant variables in the compilation units that were added.
   */
  ConstantFinder _constantFinder = new ConstantFinder();

  /**
   * A graph in which the nodes are the constant variables and the edges are from each variable to
   * the other constant variables that are referenced in the head's initializer.
   */
  DirectedGraph<VariableElement> _referenceGraph = new DirectedGraph<VariableElement>();

  /**
   * A table mapping constant variables to the declarations of those variables.
   */
  Map<VariableElement, VariableDeclaration> _declarationMap;

  /**
   * Add the constant variables in the given compilation unit to the list of constant variables
   * whose value needs to be computed.
   *
   * @param unit the compilation unit defining the constant variables to be added
   */
  void add(CompilationUnit unit) {
    unit.accept(_constantFinder);
  }

  /**
   * Compute values for all of the constant variables in the compilation units that were added.
   */
  void computeValues() {
    _declarationMap = _constantFinder.variableMap;
    for (MapEntry<VariableElement, VariableDeclaration> entry in getMapEntrySet(_declarationMap)) {
      VariableElement element = entry.getKey();
      ReferenceFinder referenceFinder = new ReferenceFinder(element, _referenceGraph);
      _referenceGraph.addNode(element);
      entry.getValue().initializer.accept(referenceFinder);
    }
    while (!_referenceGraph.isEmpty) {
      VariableElement element = _referenceGraph.removeSink();
      while (element != null) {
        computeValueFor(element);
        element = _referenceGraph.removeSink();
      }
      if (!_referenceGraph.isEmpty) {
        List<VariableElement> variablesInCycle = _referenceGraph.findCycle();
        if (variablesInCycle == null) {
          AnalysisEngine.instance.logger.logError("Exiting constant value computer with ${_referenceGraph.nodeCount} variables that are neither sinks no in a cycle");
          return;
        }
        for (VariableElement variable in variablesInCycle) {
          generateCycleError(variablesInCycle, variable);
        }
        _referenceGraph.removeAllNodes(variablesInCycle);
      }
    }
  }

  /**
   * Compute a value for the given variable.
   *
   * @param variable the variable for which a value is to be computed
   */
  void computeValueFor(VariableElement variable) {
    VariableDeclaration declaration = _declarationMap[variable];
    if (declaration == null) {
      return;
    }
    EvaluationResultImpl result = declaration.initializer.accept(new ConstantVisitor());
    (variable as VariableElementImpl).evaluationResult = result;
    if (result is ErrorResult) {
      List<AnalysisError> errors = new List<AnalysisError>();
      for (ErrorResult_ErrorData data in (result as ErrorResult).errorData) {
        ASTNode node = data.node;
        Source source = variable.getAncestor(CompilationUnitElement).source;
        errors.add(new AnalysisError.con2(source, node.offset, node.length, data.errorCode, []));
      }
    }
  }

  /**
   * Generate an error indicating that the given variable is not a valid compile-time constant
   * because it references at least one of the variables in the given cycle, each of which directly
   * or indirectly references the variable.
   *
   * @param variablesInCycle the variables in the cycle that includes the given variable
   * @param variable the variable that is not a valid compile-time constant
   */
  void generateCycleError(List<VariableElement> variablesInCycle, VariableElement variable) {
  }
}

/**
 * Instances of the class `ConstantVisitor` evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 *
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to `null`.
 * * `null`.
 * * A reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, a class or a type parameter.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static method.
 * * A parenthesized expression `(e)` where `e` is a constant expression.
 * * An expression of one of the forms `identical(e1, e2)`, `e1 == e2`,
 * `e1 != e2` where `e1` and `e2` are constant expressions that evaluate to a
 * numeric, string or boolean value or to `null`.
 * * An expression of one of the forms `!e`, `e1 && e2` or `e1 || e2`, where
 * `e`, `e1` and `e2` are constant expressions that evaluate to a boolean value or
 * to `null`.
 * * An expression of one of the forms `~e`, `e1 ^ e2`, `e1 & e2`,
 * `e1 | e2`, `e1 >> e2` or `e1 << e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to an integer value or to `null`.
 * * An expression of one of the forms `-e`, `e1 + e2`, `e1 - e2`,
 * `e1 * e2`, `e1 / e2`, `e1 ~/ e2`, `e1 > e2`, `e1 < e2`,
 * `e1 >= e2`, `e1 <= e2` or `e1 % e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to a numeric value or to `null`.
 *
 * </blockquote>
 */
class ConstantVisitor extends UnifyingASTVisitor<EvaluationResultImpl> {
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
    TokenType operatorType = node.operator.type;
    if (operatorType != TokenType.BANG_EQ && operatorType != TokenType.EQ_EQ) {
      if (leftResult is ValidResult && (leftResult as ValidResult).isNull || rightResult is ValidResult && (rightResult as ValidResult).isNull) {
        return error(node, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
      }
    }
    while (true) {
      if (operatorType == TokenType.AMPERSAND) {
        return leftResult.bitAnd(node, rightResult);
      } else if (operatorType == TokenType.AMPERSAND_AMPERSAND) {
        return leftResult.logicalAnd(node, rightResult);
      } else if (operatorType == TokenType.BANG_EQ) {
        return leftResult.notEqual(node, rightResult);
      } else if (operatorType == TokenType.BAR) {
        return leftResult.bitOr(node, rightResult);
      } else if (operatorType == TokenType.BAR_BAR) {
        return leftResult.logicalOr(node, rightResult);
      } else if (operatorType == TokenType.CARET) {
        return leftResult.bitXor(node, rightResult);
      } else if (operatorType == TokenType.EQ_EQ) {
        return leftResult.equalEqual(node, rightResult);
      } else if (operatorType == TokenType.GT) {
        return leftResult.greaterThan(node, rightResult);
      } else if (operatorType == TokenType.GT_EQ) {
        return leftResult.greaterThanOrEqual(node, rightResult);
      } else if (operatorType == TokenType.GT_GT) {
        return leftResult.shiftRight(node, rightResult);
      } else if (operatorType == TokenType.LT) {
        return leftResult.lessThan(node, rightResult);
      } else if (operatorType == TokenType.LT_EQ) {
        return leftResult.lessThanOrEqual(node, rightResult);
      } else if (operatorType == TokenType.LT_LT) {
        return leftResult.shiftLeft(node, rightResult);
      } else if (operatorType == TokenType.MINUS) {
        return leftResult.minus(node, rightResult);
      } else if (operatorType == TokenType.PERCENT) {
        return leftResult.remainder(node, rightResult);
      } else if (operatorType == TokenType.PLUS) {
        return leftResult.add(node, rightResult);
      } else if (operatorType == TokenType.STAR) {
        return leftResult.times(node, rightResult);
      } else if (operatorType == TokenType.SLASH) {
        return leftResult.divide(node, rightResult);
      } else if (operatorType == TokenType.TILDE_SLASH) {
        return leftResult.integerDivide(node, rightResult);
      }
      break;
    }
    return error(node, null);
  }

  EvaluationResultImpl visitBooleanLiteral(BooleanLiteral node) => node.value ? ValidResult.RESULT_TRUE : ValidResult.RESULT_FALSE;

  EvaluationResultImpl visitConditionalExpression(ConditionalExpression node) {
    Expression condition = node.condition;
    EvaluationResultImpl conditionResult = condition.accept(this);
    conditionResult = conditionResult.applyBooleanConversion(condition);
    if (conditionResult is ErrorResult) {
      return conditionResult;
    }
    EvaluationResultImpl thenResult = node.thenExpression.accept(this);
    if (thenResult is ErrorResult) {
      return thenResult;
    }
    EvaluationResultImpl elseResult = node.elseExpression.accept(this);
    if (elseResult is ErrorResult) {
      return elseResult;
    }
    return (identical(conditionResult, ValidResult.RESULT_TRUE)) ? thenResult : elseResult;
  }

  EvaluationResultImpl visitDoubleLiteral(DoubleLiteral node) => new ValidResult(node.value);

  EvaluationResultImpl visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.isConst) {
      return error(node, null);
    }
    ConstructorElement constructor = node.staticElement;
    if (constructor != null && constructor.isConst) {
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
    if (node.constKeyword == null) {
      return new ErrorResult.con1(node, CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL);
    }
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
    if (node.constKeyword == null) {
      return new ErrorResult.con1(node, CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL);
    }
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
    Element element = node.methodName.staticElement;
    if (element is FunctionElement) {
      FunctionElement function = element as FunctionElement;
      if (function.name == "identical") {
        NodeList<Expression> arguments = node.argumentList.arguments;
        if (arguments.length == 2) {
          Element enclosingElement = function.enclosingElement;
          if (enclosingElement is CompilationUnitElement) {
            LibraryElement library = (enclosingElement as CompilationUnitElement).library;
            if (library.isDartCore) {
              EvaluationResultImpl leftArgument = arguments[0].accept(this);
              EvaluationResultImpl rightArgument = arguments[1].accept(this);
              return leftArgument.equalEqual(node, rightArgument);
            }
          }
        }
      }
    }
    return error(node, null);
  }

  EvaluationResultImpl visitNamedExpression(NamedExpression node) => node.expression.accept(this);

  EvaluationResultImpl visitNode(ASTNode node) => error(node, null);

  EvaluationResultImpl visitNullLiteral(NullLiteral node) => ValidResult.RESULT_NULL;

  EvaluationResultImpl visitParenthesizedExpression(ParenthesizedExpression node) => node.expression.accept(this);

  EvaluationResultImpl visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixNode = node.prefix;
    Element prefixElement = prefixNode.staticElement;
    if (prefixElement is! PrefixElement) {
      EvaluationResultImpl prefixResult = prefixNode.accept(this);
      if (prefixResult is! ValidResult) {
        return error(node, null);
      }
    }
    return getConstantValue(node, node.staticElement);
  }

  EvaluationResultImpl visitPrefixExpression(PrefixExpression node) {
    EvaluationResultImpl operand = node.operand.accept(this);
    if (operand is ValidResult && (operand as ValidResult).isNull) {
      return error(node, CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION);
    }
    while (true) {
      if (node.operator.type == TokenType.BANG) {
        return operand.logicalNot(node);
      } else if (node.operator.type == TokenType.TILDE) {
        return operand.bitNot(node);
      } else if (node.operator.type == TokenType.MINUS) {
        return operand.negated(node);
      }
      break;
    }
    return error(node, null);
  }

  EvaluationResultImpl visitPropertyAccess(PropertyAccess node) => getConstantValue(node, node.propertyName.staticElement);

  EvaluationResultImpl visitSimpleIdentifier(SimpleIdentifier node) => getConstantValue(node, node.staticElement);

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

  EvaluationResultImpl visitSymbolLiteral(SymbolLiteral node) => ValidResult.RESULT_SYMBOL;

  /**
   * Return a result object representing an error associated with the given node.
   *
   * @param node the AST node associated with the error
   * @param code the error code indicating the nature of the error
   * @return a result object representing an error associated with the given node
   */
  ErrorResult error(ASTNode node, ErrorCode code) => new ErrorResult.con1(node, code == null ? CompileTimeErrorCode.INVALID_CONSTANT : code);

  /**
   * Return the constant value of the static constant represented by the given element.
   *
   * @param node the node to be used if an error needs to be reported
   * @param element the element whose value is to be returned
   * @return the constant value of the static constant
   */
  EvaluationResultImpl getConstantValue(ASTNode node, Element element) {
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElementImpl) {
      VariableElementImpl variableElementImpl = element as VariableElementImpl;
      EvaluationResultImpl value = variableElementImpl.evaluationResult;
      if (variableElementImpl.isConst && value != null) {
        return value;
      }
    } else if (element is ExecutableElement) {
      if ((element as ExecutableElement).isStatic) {
        return new ValidResult(element);
      }
    } else if (element is ClassElement || element is FunctionTypeAliasElement) {
      return ValidResult.RESULT_OBJECT;
    }
    return error(node, null);
  }

  /**
   * Return the union of the errors encoded in the given results.
   *
   * @param leftResult the first set of errors, or `null` if there was no previous collection
   *          of errors
   * @param rightResult the errors to be added to the collection, or a valid result if there are no
   *          errors to be added
   * @return the union of the errors encoded in the given results
   */
  ErrorResult union(ErrorResult leftResult, EvaluationResultImpl rightResult) {
    if (rightResult is ErrorResult) {
      if (leftResult != null) {
        return new ErrorResult.con2(leftResult, rightResult as ErrorResult);
      } else {
        return rightResult as ErrorResult;
      }
    }
    return leftResult;
  }
}

/**
 * Instances of the class `DirectedGraph` implement a directed graph in which the nodes are
 * arbitrary (client provided) objects and edges are represented implicitly. The graph will allow an
 * edge from any node to any other node, including itself, but will not represent multiple edges
 * between the same pair of nodes.
 *
 * @param N the type of the nodes in the graph
 */
class DirectedGraph<N> {
  /**
   * The table encoding the edges in the graph. An edge is represented by an entry mapping the head
   * to a set of tails. Nodes that are not the head of any edge are represented by an entry mapping
   * the node to an empty set of tails.
   */
  Map<N, Set<N>> _edges = new Map<N, Set<N>>();

  /**
   * Add an edge from the given head node to the given tail node. Both nodes will be a part of the
   * graph after this method is invoked, whether or not they were before.
   *
   * @param head the node at the head of the edge
   * @param tail the node at the tail of the edge
   */
  void addEdge(N head, N tail) {
    Set<N> tails = _edges[tail];
    if (tails == null) {
      _edges[tail] = new Set<N>();
    }
    tails = _edges[head];
    if (tails == null) {
      tails = new Set<N>();
      _edges[head] = tails;
    }
    tails.add(tail);
  }

  /**
   * Add the given node to the set of nodes in the graph.
   *
   * @param node the node to be added
   */
  void addNode(N node) {
    Set<N> tails = _edges[node];
    if (tails == null) {
      _edges[node] = new Set<N>();
    }
  }

  /**
   * Return a list of nodes that form a cycle, or `null` if there are no cycles in this graph.
   *
   * @return a list of nodes that form a cycle
   */
  List<N> findCycle() => null;

  /**
   * Return the number of nodes in this graph.
   *
   * @return the number of nodes in this graph
   */
  int get nodeCount => _edges.length;

  /**
   * Return a set containing the tails of edges that have the given node as their head. The set will
   * be empty if there are no such edges or if the node is not part of the graph. Clients must not
   * modify the returned set.
   *
   * @param head the node at the head of all of the edges whose tails are to be returned
   * @return a set containing the tails of edges that have the given node as their head
   */
  Set<N> getTails(N head) {
    Set<N> tails = _edges[head];
    if (tails == null) {
      return new Set<N>();
    }
    return tails;
  }

  /**
   * Return `true` if this graph is empty.
   *
   * @return `true` if this graph is empty
   */
  bool get isEmpty => _edges.isEmpty;

  /**
   * Remove all of the given nodes from this graph. As a consequence, any edges for which those
   * nodes were either a head or a tail will also be removed.
   *
   * @param nodes the nodes to be removed
   */
  void removeAllNodes(List<N> nodes) {
    for (N node in nodes) {
      removeNode(node);
    }
  }

  /**
   * Remove the edge from the given head node to the given tail node. If there was no such edge then
   * the graph will be unmodified: the number of edges will be the same and the set of nodes will be
   * the same (neither node will either be added or removed).
   *
   * @param head the node at the head of the edge
   * @param tail the node at the tail of the edge
   * @return `true` if the graph was modified as a result of this operation
   */
  void removeEdge(N head, N tail) {
    Set<N> tails = _edges[head];
    if (tails != null) {
      tails.remove(tail);
    }
  }

  /**
   * Remove the given node from this graph. As a consequence, any edges for which that node was
   * either a head or a tail will also be removed.
   *
   * @param node the node to be removed
   */
  void removeNode(N node) {
    _edges.remove(node);
    for (Set<N> tails in _edges.values) {
      tails.remove(node);
    }
  }

  /**
   * Find one node (referred to as a sink node) that has no outgoing edges (that is, for which there
   * are no edges that have that node as the head of the edge) and remove it from this graph. Return
   * the node that was removed, or `null` if there are no such nodes either because the graph
   * is empty or because every node in the graph has at least one outgoing edge. As a consequence of
   * removing the node from the graph any edges for which that node was a tail will also be removed.
   *
   * @return the sink node that was removed
   */
  N removeSink() {
    N sink = findSink();
    if (sink == null) {
      return null;
    }
    removeNode(sink);
    return sink;
  }

  /**
   * Return one node that has no outgoing edges (that is, for which there are no edges that have
   * that node as the head of the edge), or `null` if there are no such nodes.
   *
   * @return a sink node
   */
  N findSink() {
    for (N key in _edges.keys) {
      if (_edges[key].isEmpty) return key;
    }
    return null;
  }
}

/**
 * Instances of the class `ErrorResult` represent the result of evaluating an expression that
 * is not a valid compile time constant.
 */
class ErrorResult extends EvaluationResultImpl {
  /**
   * The errors that prevent the expression from being a valid compile time constant.
   */
  final List<ErrorResult_ErrorData> errorData = new List<ErrorResult_ErrorData>();

  /**
   * Initialize a newly created result representing the error with the given code reported against
   * the given node.
   *
   * @param node the node against which the error should be reported
   * @param errorCode the error code for the error to be generated
   */
  ErrorResult.con1(ASTNode node, ErrorCode errorCode) {
    errorData.add(new ErrorResult_ErrorData(node, errorCode));
  }

  /**
   * Initialize a newly created result to represent the union of the errors in the given result
   * objects.
   *
   * @param firstResult the first set of results being merged
   * @param secondResult the second set of results being merged
   */
  ErrorResult.con2(ErrorResult firstResult, ErrorResult secondResult) {
    errorData.addAll(firstResult.errorData);
    errorData.addAll(secondResult.errorData);
  }

  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.addToError(node, this);

  EvaluationResultImpl applyBooleanConversion(ASTNode node) => this;

  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitAndError(node, this);

  EvaluationResultImpl bitNot(Expression node) => this;

  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitOrError(node, this);

  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitXorError(node, this);

  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand) => rightOperand.concatenateError(node, this);

  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.divideError(node, this);

  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand) => rightOperand.equalEqualError(node, this);

  bool equalValues(EvaluationResultImpl result) => false;

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
  ASTNode node;

  /**
   * The error code for the error to be generated.
   */
  ErrorCode errorCode;

  /**
   * Initialize a newly created data holder to represent the error with the given code reported
   * against the given node.
   *
   * @param node the node against which the error should be reported
   * @param errorCode the error code for the error to be generated
   */
  ErrorResult_ErrorData(ASTNode node, ErrorCode errorCode) {
    this.node = node;
    this.errorCode = errorCode;
  }
}

/**
 * Instances of the class `InternalResult` represent the result of attempting to evaluate a
 * expression.
 */
abstract class EvaluationResultImpl {
  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand);

  /**
   * Return the result of applying boolean conversion to this result.
   *
   * @param node the node against which errors should be reported
   * @return the result of applying boolean conversion to the given value
   */
  EvaluationResultImpl applyBooleanConversion(ASTNode node);

  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand);

  EvaluationResultImpl bitNot(Expression node);

  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand);

  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand);

  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand);

  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand);

  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand);

  bool equalValues(EvaluationResultImpl result);

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
 * Instances of the class `ReferenceFinder` add reference information for a given variable to
 * the bi-directional mapping used to order the evaluation of constants.
 */
class ReferenceFinder extends RecursiveASTVisitor<Object> {
  /**
   * The element representing the variable whose initializer will be visited.
   */
  VariableElement _source;

  /**
   * A graph in which the nodes are the constant variables and the edges are from each variable to
   * the other constant variables that are referenced in the head's initializer.
   */
  DirectedGraph<VariableElement> _referenceGraph;

  /**
   * Initialize a newly created reference finder to find references from the given variable to other
   * variables and to add those references to the given graph.
   *
   * @param source the element representing the variable whose initializer will be visited
   * @param referenceGraph a graph recording which variables (heads) reference which other variables
   *          (tails) in their initializers
   */
  ReferenceFinder(VariableElement source, DirectedGraph<VariableElement> referenceGraph) {
    this._source = source;
    this._referenceGraph = referenceGraph;
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    if (element is VariableElement) {
      VariableElement variable = element as VariableElement;
      if (variable.isConst) {
        _referenceGraph.addEdge(_source, variable);
      }
    }
    return null;
  }
}

/**
 * Instances of the class `ValidResult` represent the result of attempting to evaluate a valid
 * compile time constant expression.
 */
class ValidResult extends EvaluationResultImpl {
  /**
   * A result object representing the value 'false'.
   */
  static ValidResult RESULT_FALSE = new ValidResult(false);

  /**
   * A result object representing the an object without specific type on which no further operations
   * can be performed.
   */
  static ValidResult RESULT_DYNAMIC = new ValidResult(null);

  /**
   * A result object representing the an arbitrary integer on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_INT = new ValidResult(0);

  /**
   * A result object representing the `null` value.
   */
  static ValidResult RESULT_NULL = new ValidResult(null);

  /**
   * A result object representing the an arbitrary numeric on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_NUM = new ValidResult(null);

  /**
   * A result object representing the an arbitrary boolean on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_BOOL = new ValidResult(null);

  /**
   * A result object representing the an arbitrary object on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_OBJECT = new ValidResult(new Object());

  /**
   * A result object representing the an arbitrary symbol on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_SYMBOL = new ValidResult(new Object());

  /**
   * A result object representing the an arbitrary string on which no further operations can be
   * performed.
   */
  static ValidResult RESULT_STRING = new ValidResult("<string>");

  /**
   * A result object representing the value 'true'.
   */
  static ValidResult RESULT_TRUE = new ValidResult(true);

  /**
   * The value of the expression.
   */
  Object value;

  /**
   * Initialize a newly created result to represent the given value.
   *
   * @param value the value of the expression
   */
  ValidResult(Object value) {
    this.value = value;
  }

  EvaluationResultImpl add(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.addToValid(node, this);

  /**
   * Return the result of applying boolean conversion to this result.
   *
   * @param node the node against which errors should be reported
   * @return the result of applying boolean conversion to the given value
   */
  EvaluationResultImpl applyBooleanConversion(ASTNode node) => booleanConversion(node, value);

  EvaluationResultImpl bitAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitAndValid(node, this);

  EvaluationResultImpl bitNot(Expression node) {
    if (isSomeInt) {
      return RESULT_INT;
    }
    if (value == null) {
      return error(node);
    } else if (value is int) {
      return valueOf(~(value as int));
    }
    return error(node);
  }

  EvaluationResultImpl bitOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitOrValid(node, this);

  EvaluationResultImpl bitXor(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.bitXorValid(node, this);

  EvaluationResultImpl concatenate(Expression node, EvaluationResultImpl rightOperand) => rightOperand.concatenateValid(node, this);

  EvaluationResultImpl divide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.divideValid(node, this);

  EvaluationResultImpl equalEqual(Expression node, EvaluationResultImpl rightOperand) => rightOperand.equalEqualValid(node, this);

  bool equalValues(EvaluationResultImpl result) => identical(equalEqual(null, result), RESULT_TRUE);

  EvaluationResultImpl greaterThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanValid(node, this);

  EvaluationResultImpl greaterThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.greaterThanOrEqualValid(node, this);

  EvaluationResultImpl integerDivide(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.integerDivideValid(node, this);

  EvaluationResultImpl lessThan(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanValid(node, this);

  EvaluationResultImpl lessThanOrEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.lessThanOrEqualValid(node, this);

  EvaluationResultImpl logicalAnd(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalAndValid(node, this);

  EvaluationResultImpl logicalNot(Expression node) {
    if (isSomeBool) {
      return RESULT_BOOL;
    }
    if (value == null) {
      return RESULT_TRUE;
    } else if (value is bool) {
      return (value as bool) ? RESULT_FALSE : RESULT_TRUE;
    }
    return error(node);
  }

  EvaluationResultImpl logicalOr(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.logicalOrValid(node, this);

  EvaluationResultImpl minus(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.minusValid(node, this);

  EvaluationResultImpl negated(Expression node) {
    if (isSomeNum) {
      return RESULT_INT;
    }
    if (value == null) {
      return error(node);
    } else if (value is int) {
      return valueOf(-(value as int));
    } else if (value is double) {
      return valueOf3(-(value as double));
    }
    return error(node);
  }

  EvaluationResultImpl notEqual(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.notEqualValid(node, this);

  EvaluationResultImpl performToString(ASTNode node) {
    if (value == null) {
      return valueOf4("null");
    } else if (value is bool) {
      return valueOf4((value as bool).toString());
    } else if (value is int) {
      return valueOf4((value as int).toString());
    } else if (value is double) {
      return valueOf4((value as double).toString());
    } else if (value is String) {
      return this;
    } else if (isSomeBool) {
      return valueOf4("<some bool>");
    } else if (isSomeInt) {
      return valueOf4("<some int>");
    } else if (isSomeNum) {
      return valueOf4("<some num>");
    }
    return error(node);
  }

  EvaluationResultImpl remainder(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.remainderValid(node, this);

  EvaluationResultImpl shiftLeft(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftLeftValid(node, this);

  EvaluationResultImpl shiftRight(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.shiftRightValid(node, this);

  EvaluationResultImpl times(BinaryExpression node, EvaluationResultImpl rightOperand) => rightOperand.timesValid(node, this);

  String toString() {
    if (value == null) {
      return "null";
    }
    return value.toString();
  }

  EvaluationResultImpl addToError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl addToValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    } else if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_NUM;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) + (value as int));
      } else if (value is double) {
        return valueOf3((leftValue as int).toDouble() + (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf3((leftValue as double) + (value as int).toDouble());
      } else if (value is double) {
        return valueOf3((leftValue as double) + (value as double));
      }
    } else if (leftValue is String) {
      if (value is String) {
        return valueOf4("${(leftValue as String)}${(value as String)}");
      }
    }
    return error(node);
  }

  EvaluationResultImpl bitAndError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl bitAndValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyInt || !leftOperand.isAnyInt) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) & (value as int));
      }
      return error(node.leftOperand);
    }
    if (value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }

  EvaluationResultImpl bitOrError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl bitOrValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyInt || !leftOperand.isAnyInt) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) | (value as int));
      }
      return error(node.leftOperand);
    }
    if (value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }

  EvaluationResultImpl bitXorError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl bitXorValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyInt || !leftOperand.isAnyInt) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) ^ (value as int));
      }
      return error(node.leftOperand);
    }
    if (value is int) {
      return error(node.rightOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }

  EvaluationResultImpl concatenateError(Expression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl concatenateValid(Expression node, ValidResult leftOperand) {
    Object leftValue = leftOperand.value;
    if (leftValue is String && value is String) {
      return valueOf4("${(leftValue as String)}${(value as String)}");
    }
    return error(node);
  }

  EvaluationResultImpl divideError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl divideValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_NUM;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        if ((value as int) == 0) {
          return valueOf3((leftValue as int).toDouble() / (value as int).toDouble());
        }
        return valueOf((leftValue as int) ~/ (value as int));
      } else if (value is double) {
        return valueOf3((leftValue as int).toDouble() / (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf3((leftValue as double) / (value as int).toDouble());
      } else if (value is double) {
        return valueOf3((leftValue as double) / (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl equalEqualError(Expression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl equalEqualValid(Expression node, ValidResult leftOperand) {
    if (node is BinaryExpression) {
      if (!isAnyNullBoolNumString || !leftOperand.isAnyNullBoolNumString) {
        return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
      }
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return valueOf2(value == null);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int) == value);
      } else if (value is double) {
        return valueOf2(toDouble(leftValue as int) == value);
      }
      return RESULT_FALSE;
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) == toDouble(value as int));
      } else if (value is double) {
        return valueOf2((leftValue as double) == value);
      }
      return RESULT_FALSE;
    } else {
      return valueOf2(leftValue == value);
    }
  }

  EvaluationResultImpl greaterThanError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl greaterThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl greaterThanOrEqualValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int).compareTo(value as int) >= 0);
      } else if (value is double) {
        return valueOf2((leftValue as int).toDouble() >= (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) >= (value as int).toDouble());
      } else if (value is double) {
        return valueOf2((leftValue as double) >= (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl greaterThanValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int).compareTo(value as int) > 0);
      } else if (value is double) {
        return valueOf2((leftValue as int).toDouble() > (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) > (value as int).toDouble());
      } else if (value is double) {
        return valueOf2((leftValue as double) > (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl integerDivideError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl integerDivideValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        if ((value as int) == 0) {
          return error2(node, CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE);
        }
        return valueOf((leftValue as int) ~/ (value as int));
      } else if (value is double) {
        double result = (leftValue as int).toDouble() / (value as double);
        return valueOf(result.toInt());
      }
    } else if (leftValue is double) {
      if (value is int) {
        double result = (leftValue as double) / (value as int).toDouble();
        return valueOf(result.toInt());
      } else if (value is double) {
        double result = (leftValue as double) / (value as double);
        return valueOf(result.toInt());
      }
    }
    return error(node);
  }

  EvaluationResultImpl lessThanError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl lessThanOrEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl lessThanOrEqualValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int).compareTo(value as int) <= 0);
      } else if (value is double) {
        return valueOf2((leftValue as int).toDouble() <= (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) <= (value as int).toDouble());
      } else if (value is double) {
        return valueOf2((leftValue as double) <= (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl lessThanValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int).compareTo(value as int) < 0);
      } else if (value is double) {
        return valueOf2((leftValue as int).toDouble() < (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) < (value as int).toDouble());
      } else if (value is double) {
        return valueOf2((leftValue as double) < (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl logicalAndError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl logicalAndValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyBool || !leftOperand.isAnyBool) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
    if (isSomeBool || leftOperand.isSomeBool) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue is bool) {
      if (leftValue as bool) {
        return booleanConversion(node.rightOperand, value);
      }
      return RESULT_FALSE;
    }
    return error(node);
  }

  EvaluationResultImpl logicalOrError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl logicalOrValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyBool || !leftOperand.isAnyBool) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL);
    }
    if (isSomeBool || leftOperand.isSomeBool) {
      return RESULT_BOOL;
    }
    Object leftValue = leftOperand.value;
    if (leftValue is bool && (leftValue as bool)) {
      return RESULT_TRUE;
    }
    return booleanConversion(node.rightOperand, value);
  }

  EvaluationResultImpl minusError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl minusValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    } else if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_NUM;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) - (value as int));
      } else if (value is double) {
        return valueOf3((leftValue as int).toDouble() - (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf3((leftValue as double) - (value as int).toDouble());
      } else if (value is double) {
        return valueOf3((leftValue as double) - (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl notEqualError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl notEqualValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNullBoolNumString || !leftOperand.isAnyNullBoolNumString) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING);
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return valueOf2(value != null);
    } else if (leftValue is bool) {
      if (value is bool) {
        return valueOf2((leftValue as bool) != (value as bool));
      }
      return RESULT_TRUE;
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf2((leftValue as int) != value);
      } else if (value is double) {
        return valueOf2(toDouble(leftValue as int) != value);
      }
      return RESULT_TRUE;
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf2((leftValue as double) != toDouble(value as int));
      } else if (value is double) {
        return valueOf2((leftValue as double) != value);
      }
      return RESULT_TRUE;
    } else if (leftValue is String) {
      if (value is String) {
        return valueOf2((leftValue as String) != value);
      }
      return RESULT_TRUE;
    }
    return RESULT_TRUE;
  }

  EvaluationResultImpl remainderError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl remainderValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    } else if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_NUM;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        if ((value as int) == 0) {
          return valueOf3((leftValue as int).toDouble() % (value as int).toDouble());
        }
        return valueOf((leftValue as int).remainder(value as int));
      } else if (value is double) {
        return valueOf3((leftValue as int).toDouble() % (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf3((leftValue as double) % (value as int).toDouble());
      } else if (value is double) {
        return valueOf3((leftValue as double) % (value as double));
      }
    }
    return error(node);
  }

  EvaluationResultImpl shiftLeftError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl shiftLeftValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyInt || !leftOperand.isAnyInt) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return RESULT_INT;
      }
      return error(node.rightOperand);
    }
    if (value is int) {
      return error(node.leftOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }

  EvaluationResultImpl shiftRightError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl shiftRightValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyInt || !leftOperand.isAnyInt) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_INT);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) >> (value as int));
      }
      return error(node.rightOperand);
    }
    if (value is int) {
      return error(node.leftOperand);
    }
    return union(error(node.leftOperand), error(node.rightOperand));
  }

  EvaluationResultImpl timesError(BinaryExpression node, ErrorResult leftOperand) => leftOperand;

  EvaluationResultImpl timesValid(BinaryExpression node, ValidResult leftOperand) {
    if (!isAnyNum || !leftOperand.isAnyNum) {
      return error2(node, CompileTimeErrorCode.CONST_EVAL_TYPE_NUM);
    }
    if (isSomeInt || leftOperand.isSomeInt) {
      return RESULT_INT;
    } else if (isSomeNum || leftOperand.isSomeNum) {
      return RESULT_NUM;
    }
    Object leftValue = leftOperand.value;
    if (leftValue == null) {
      return error(node.leftOperand);
    } else if (value == null) {
      return error(node.rightOperand);
    } else if (leftValue is int) {
      if (value is int) {
        return valueOf((leftValue as int) * (value as int));
      } else if (value is double) {
        return valueOf3((leftValue as int).toDouble() * (value as double));
      }
    } else if (leftValue is double) {
      if (value is int) {
        return valueOf3((leftValue as double) * (value as int).toDouble());
      } else if (value is double) {
        return valueOf3((leftValue as double) * (value as double));
      }
    }
    return error(node);
  }

  bool get isNull => identical(this, RESULT_NULL);

  /**
   * Return the result of applying boolean conversion to the given value.
   *
   * @param node the node against which errors should be reported
   * @param value the value to be converted to a boolean
   * @return the result of applying boolean conversion to the given value
   */
  EvaluationResultImpl booleanConversion(ASTNode node, Object value) {
    if (value is bool) {
      if (value as bool) {
        return RESULT_TRUE;
      } else {
        return RESULT_FALSE;
      }
    }
    return error(node);
  }

  ErrorResult error(ASTNode node) => error2(node, CompileTimeErrorCode.INVALID_CONSTANT);

  /**
   * Return a result object representing an error associated with the given node.
   *
   * @param node the AST node associated with the error
   * @param code the error code indicating the nature of the error
   * @return a result object representing an error associated with the given node
   */
  ErrorResult error2(ASTNode node, ErrorCode code) => new ErrorResult.con1(node, code);

  /**
   * Checks if this result has type "bool", with known or unknown value.
   */
  bool get isAnyBool => isSomeBool || identical(this, RESULT_TRUE) || identical(this, RESULT_FALSE);

  /**
   * Checks if this result has type "int", with known or unknown value.
   */
  bool get isAnyInt => identical(this, RESULT_INT) || value is int;

  /**
   * Checks if this result has one of the types - "bool", "num" or "string"; or may be `null`.
   */
  bool get isAnyNullBoolNumString => isNull || isAnyBool || isAnyNum || value is String;

  /**
   * Checks if this result has type "num", with known or unknown value.
   */
  bool get isAnyNum => isSomeNum || value is num;

  /**
   * Checks if this result has type "bool", exact value of which we don't know.
   */
  bool get isSomeBool => identical(this, RESULT_BOOL);

  /**
   * Checks if this result has type "int", exact value of which we don't know.
   */
  bool get isSomeInt => identical(this, RESULT_INT);

  /**
   * Checks if this result has type "num" (or "int"), exact value of which we don't know.
   */
  bool get isSomeNum => identical(this, RESULT_DYNAMIC) || identical(this, RESULT_INT) || identical(this, RESULT_NUM);

  double toDouble(int value) => value.toDouble();

  /**
   * Return an error result that is the union of the two given error results.
   *
   * @param firstError the first error to be combined
   * @param secondError the second error to be combined
   * @return an error result that is the union of the two given error results
   */
  ErrorResult union(ErrorResult firstError, ErrorResult secondError) => new ErrorResult.con2(firstError, secondError);

  /**
   * Return a result object representing the given value.
   *
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf(int value) => new ValidResult(value);

  /**
   * Return a result object representing the given value.
   *
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf2(bool value) => value ? RESULT_TRUE : RESULT_FALSE;

  /**
   * Return a result object representing the given value.
   *
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf3(double value) => new ValidResult(value);

  /**
   * Return a result object representing the given value.
   *
   * @param value the value to be represented as a result object
   * @return a result object representing the given value
   */
  ValidResult valueOf4(String value) => new ValidResult(value);
}