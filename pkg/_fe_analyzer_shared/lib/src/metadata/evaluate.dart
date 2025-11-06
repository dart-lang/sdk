// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ast.dart';

typedef GetFieldInitializer =
    Expression? Function(FieldReference fieldReference);

/// Evaluates an [expression] based on the semantics that can be deduced from
/// the syntax.
///
/// If [getFieldInitializer] is provided, it is used to get constant initializer
/// expressions of const [StaticGet]s in [expression]. The evaluated constant
/// initializer expressions are used as the evaluation result of the
/// [StaticGet]s.
///
/// If [dereferences] is provided, the field references of [StaticGet]s, for
/// which [getFieldInitializer] has provided a constant initializer
/// [Expression], are mapped to there corresponding in constant initializer
/// [Expression]s in [dereferences].
Expression evaluateExpression(
  Expression expression, {
  GetFieldInitializer? getFieldInitializer,
  Map<FieldReference, Expression>? dereferences,
}) {
  return new Evaluator(
    getFieldInitializer: getFieldInitializer,
    dereferences: dereferences,
  ).evaluate(expression);
}

class Evaluator {
  final GetFieldInitializer? _getFieldInitializer;
  final Map<FieldReference, Expression>? _dereferences;

  Evaluator({
    required GetFieldInitializer? getFieldInitializer,
    required Map<FieldReference, Expression>? dereferences,
  }) : _getFieldInitializer = getFieldInitializer,
       _dereferences = dereferences;

  Expression evaluate(Expression expression) {
    return _visitExpression(expression);
  }

  Expression _visitExpression(Expression expression) {
    switch (expression) {
      case StaticGet():
        if (_getFieldInitializer != null) {
          Expression? result = _getFieldInitializer(expression.reference);
          if (result != null) {
            if (_dereferences != null) {
              _dereferences[expression.reference] = result;
            }
            return _visitExpression(result);
          }
        }
        return expression;
      case InvalidExpression():
      case FunctionTearOff():
      case ConstructorTearOff():
      case IntegerLiteral():
      case DoubleLiteral():
      case BooleanLiteral():
      case NullLiteral():
      case SymbolLiteral():
        return expression;
      case ConstructorInvocation():
        return new ConstructorInvocation(
          expression.type,
          expression.constructor,
          _visitArguments(expression.arguments),
        );
      case StringLiteral():
        return _visitStringLiteral(expression);
      case AdjacentStringLiterals():
        return _visitAdjacentStringLiterals(expression);
      case ImplicitInvocation():
        return new ImplicitInvocation(
          _visitExpression(expression.receiver),
          expression.typeArguments,
          _visitArguments(expression.arguments),
        );
      case StaticInvocation():
        return new StaticInvocation(
          expression.function,
          expression.typeArguments,
          _visitArguments(expression.arguments),
        );
      case Instantiation():
        return new Instantiation(
          _visitExpression(expression.receiver),
          expression.typeArguments,
        );
      case MethodInvocation():
        return new MethodInvocation(
          _visitExpression(expression.receiver),
          expression.name,
          expression.typeArguments,
          _visitArguments(expression.arguments),
        );
      case PropertyGet():
        Expression receiver = _visitExpression(expression.receiver);
        if (expression.name == 'length') {
          if (receiver case StringLiteral(parts: [StringPart(:String text)])) {
            return new IntegerLiteral.fromValue(text.length);
          }
        }
        return new PropertyGet(receiver, expression.name);
      case NullAwarePropertyGet():
        Expression receiver = _visitExpression(expression.receiver);
        return switch (_isNull(receiver)) {
          NullValue.isNull => new NullLiteral(),
          NullValue.isNonNull => _visitExpression(
            new PropertyGet(receiver, expression.name),
          ),
          NullValue.unknown => new NullAwarePropertyGet(
            receiver,
            expression.name,
          ),
        };
      case TypeLiteral():
        return expression;
      case ParenthesizedExpression():
        return _visitExpression(expression.expression);
      case ConditionalExpression():
        Expression condition = _visitExpression(expression.condition);
        return switch (condition) {
          BooleanLiteral(value: true) => _visitExpression(expression.then),
          BooleanLiteral(value: false) => _visitExpression(
            expression.otherwise,
          ),
          _ => new ConditionalExpression(
            condition,
            _visitExpression(expression.then),
            _visitExpression(expression.otherwise),
          ),
        };
      case ListLiteral():
        return new ListLiteral(
          expression.typeArguments,
          _visitElements(expression.elements),
        );
      case SetOrMapLiteral():
        return new SetOrMapLiteral(
          expression.typeArguments,
          _visitElements(expression.elements),
        );
      case RecordLiteral():
        return new RecordLiteral(_visitRecordFields(expression.fields));
      case IfNull():
        Expression left = _visitExpression(expression.left);
        return switch (_isNull(left)) {
          NullValue.isNull => _visitExpression(expression.right),
          NullValue.isNonNull => left,
          NullValue.unknown => new IfNull(
            left,
            _visitExpression(expression.right),
          ),
        };
      case LogicalExpression():
        return _visitLogicalExpression(expression);
      case EqualityExpression():
        return _visitEqualityExpression(expression);
      case BinaryExpression():
        return _visitBinaryExpression(expression);
      case UnaryExpression():
        return _visitUnaryExpression(expression);
      case IsTest():
        return new IsTest(
          _visitExpression(expression.expression),
          expression.type,
          isNot: expression.isNot,
        );
      case AsExpression():
        return new AsExpression(
          _visitExpression(expression.expression),
          expression.type,
        );
      case NullCheck():
        Expression operand = _visitExpression(expression.expression);
        return switch (_isNull(operand)) {
          // This is known to fail but we have no way to represent failure.
          NullValue.isNull => new NullCheck(operand),
          NullValue.isNonNull => operand,
          NullValue.unknown => new NullCheck(operand),
        };

      case UnresolvedExpression():
        return expression;
    }
  }

  Expression _visitStringLiteral(StringLiteral expression) {
    if (expression.parts.length == 1 && expression.parts.single is StringPart) {
      return expression;
    }
    List<StringLiteralPart> evaluatedParts = [];
    StringBuffer? stringBuffer;

    void flush() {
      if (stringBuffer != null) {
        String text = stringBuffer.toString();
        if (text.isNotEmpty) {
          evaluatedParts.add(new StringPart(stringBuffer.toString()));
        }
        stringBuffer = null;
      }
    }

    for (StringLiteralPart part in expression.parts) {
      for (StringLiteralPart evaluatedPart in _visitStringLiteralPart(part)) {
        switch (evaluatedPart) {
          case StringPart():
            (stringBuffer ??= new StringBuffer()).write(evaluatedPart.text);
          case InterpolationPart():
            flush();
            evaluatedParts.add(evaluatedPart);
        }
      }
    }
    flush();

    if (evaluatedParts.isEmpty) {
      evaluatedParts.add(new StringPart(stringBuffer.toString()));
    }
    return new StringLiteral(evaluatedParts);
  }

  Expression _visitAdjacentStringLiterals(AdjacentStringLiterals expression) {
    List<Expression> evaluatedParts = [];
    List<StringLiteralPart>? stringLiteralParts;

    void flush() {
      if (stringLiteralParts != null) {
        StringLiteral stringLiteral = new StringLiteral(stringLiteralParts);
        evaluatedParts.add(_visitExpression(stringLiteral));
      }
    }

    for (Expression part in expression.expressions) {
      Expression evaluatedPart = _visitExpression(part);
      switch (evaluatedPart) {
        case StringLiteral(:List<StringLiteralPart> parts):
          (stringLiteralParts ??= []).addAll(parts);
        default:
          flush();
          evaluatedParts.add(evaluatedPart);
      }
    }

    flush();
    if (evaluatedParts.length == 1) {
      return evaluatedParts.single;
    }
    return new AdjacentStringLiterals(evaluatedParts);
  }

  Expression _visitLogicalExpression(LogicalExpression expression) {
    Expression left = _visitExpression(expression.left);
    return switch (left) {
      BooleanLiteral(value: true) => switch (expression.operator) {
        LogicalOperator.and => _visitExpression(expression.right),
        LogicalOperator.or => left,
      },
      BooleanLiteral(value: false) => switch (expression.operator) {
        LogicalOperator.and => left,
        LogicalOperator.or => _visitExpression(expression.right),
      },
      _ => new LogicalExpression(
        left,
        expression.operator,
        _visitExpression(expression.right),
      ),
    };
  }

  Expression _visitEqualityExpression(EqualityExpression expression) {
    Expression leftExpression = _visitExpression(expression.left);
    Expression rightExpression = _visitExpression(expression.right);
    switch ((leftExpression, rightExpression)) {
      case (NullLiteral(), NullLiteral()):
        return new BooleanLiteral(!expression.isNotEquals);
      case (IntegerLiteral(value: int left), IntegerLiteral(value: int right)):
        return new BooleanLiteral(
          expression.isNotEquals ? left != right : left == right,
        );
      default:
        // TODO(johnniwinther): Support all cases.
        return new EqualityExpression(
          leftExpression,
          rightExpression,
          isNotEquals: expression.isNotEquals,
        );
    }
  }

  Expression? _visitBinaryIntExpression(
    int left,
    BinaryOperator operator,
    int right,
  ) {
    switch (operator) {
      case BinaryOperator.lessThan:
        return new BooleanLiteral(left < right);
      case BinaryOperator.lessThanOrEqual:
        return new BooleanLiteral(left <= right);
      case BinaryOperator.greaterThan:
        return new BooleanLiteral(left > right);
      case BinaryOperator.greaterThanOrEqual:
        return new BooleanLiteral(left >= right);
      case BinaryOperator.bitwiseOr:
        return new IntegerLiteral.fromValue(left | right);
      case BinaryOperator.bitwiseXor:
        return new IntegerLiteral.fromValue(left ^ right);
      case BinaryOperator.bitwiseAnd:
        return new IntegerLiteral.fromValue(left & right);
      case BinaryOperator.shiftLeft:
        return new IntegerLiteral.fromValue(left << right);
      case BinaryOperator.unsignedShiftRight:
        return new IntegerLiteral.fromValue(left >> right);
      case BinaryOperator.signedShiftRight:
        return new IntegerLiteral.fromValue(left >>> right);
      case BinaryOperator.plus:
        return new IntegerLiteral.fromValue(left + right);
      case BinaryOperator.minus:
        return new IntegerLiteral.fromValue(left - right);
      case BinaryOperator.times:
        return new IntegerLiteral.fromValue(left * right);
      case BinaryOperator.divide:
        if (right != 0) {
          double value = left / right;
          return new DoubleLiteral('$value', value);
        }
      case BinaryOperator.modulo:
        if (right != 0) {
          return new IntegerLiteral.fromValue(left % right);
        }
      case BinaryOperator.integerDivide:
        if (right != 0) {
          return new IntegerLiteral.fromValue(left ~/ right);
        }
    }
    return null;
  }

  Expression _visitBinaryExpression(BinaryExpression expression) {
    Expression leftExpression = _visitExpression(expression.left);
    Expression rightExpression = _visitExpression(expression.right);

    switch ((leftExpression, rightExpression)) {
      case (IntegerLiteral(value: int left), IntegerLiteral(value: int right)):
        return _visitBinaryIntExpression(left, expression.operator, right) ??
            new BinaryExpression(
              leftExpression,
              expression.operator,
              rightExpression,
            );
      default:
        // TODO(johnniwinther): Support more cases.
        return new BinaryExpression(
          leftExpression,
          expression.operator,
          rightExpression,
        );
    }
  }

  Expression _visitUnaryExpression(UnaryExpression expression) {
    Expression operand = _visitExpression(expression.expression);
    switch ((expression.operator, operand)) {
      case (UnaryOperator.minus, IntegerLiteral(:int value)):
        return new IntegerLiteral.fromValue(-value);
      case (UnaryOperator.bang, BooleanLiteral(:bool value)):
        return new BooleanLiteral(!value);
      case (UnaryOperator.tilde, IntegerLiteral(:int value)):
        return new IntegerLiteral.fromValue(~value);
      default:
        // TODO(johnniwinther): Support more cases.
        return new UnaryExpression(expression.operator, operand);
    }
  }

  List<StringLiteralPart> _visitStringLiteralPart(StringLiteralPart part) {
    switch (part) {
      case StringPart():
        return [part];
      case InterpolationPart():
        Expression expression = _visitExpression(part.expression);
        return switch (expression) {
          StringLiteral() => expression.parts,
          NullLiteral() => [new StringPart('null')],
          BooleanLiteral(:bool value) => [new StringPart('$value')],
          IntegerLiteral(:int value) => [new StringPart('$value')],
          DoubleLiteral(:double value) => [new StringPart('$value')],
          _ => [new InterpolationPart(expression)],
        };
    }
  }

  List<Argument> _visitArguments(List<Argument> arguments) {
    List<Argument> list = [];
    for (Argument argument in arguments) {
      switch (argument) {
        case PositionalArgument():
          list.add(
            new PositionalArgument(_visitExpression(argument.expression)),
          );
        case NamedArgument():
          list.add(
            new NamedArgument(
              argument.name,
              _visitExpression(argument.expression),
            ),
          );
      }
    }
    return list;
  }

  List<RecordField> _visitRecordFields(List<RecordField> fields) {
    List<RecordField> list = [];
    for (RecordField field in fields) {
      switch (field) {
        case RecordNamedField():
          list.add(
            new RecordNamedField(
              field.name,
              _visitExpression(field.expression),
            ),
          );
        case RecordPositionalField():
          list.add(
            new RecordPositionalField(_visitExpression(field.expression)),
          );
      }
    }
    return list;
  }

  List<Element> _visitElements(List<Element> elements) {
    List<Element> list = [];
    for (Element element in elements) {
      switch (element) {
        case ExpressionElement():
          Expression expression = _visitExpression(element.expression);
          bool isNullAware = element.isNullAware;
          if (isNullAware) {
            switch (_isNull(expression)) {
              case NullValue.isNull:
                // Skip element.
                continue;
              case NullValue.isNonNull:
                isNullAware = false;
              case NullValue.unknown:
            }
          }
          list.add(new ExpressionElement(expression, isNullAware: isNullAware));
        case MapEntryElement():
          Expression key = _visitExpression(element.key);
          Expression value = _visitExpression(element.value);
          bool isNullAwareKey = element.isNullAwareKey;
          bool isNullAwareValue = element.isNullAwareValue;
          if (isNullAwareKey) {
            switch (_isNull(key)) {
              case NullValue.isNull:
                // Skip entry.
                continue;
              case NullValue.isNonNull:
                isNullAwareKey = false;
              case NullValue.unknown:
            }
          }
          if (isNullAwareValue) {
            switch (_isNull(value)) {
              case NullValue.isNull:
                // Skip entry.
                continue;
              case NullValue.isNonNull:
                isNullAwareValue = false;
              case NullValue.unknown:
            }
          }
          list.add(
            new MapEntryElement(
              key,
              value,
              isNullAwareKey: isNullAwareKey,
              isNullAwareValue: isNullAwareValue,
            ),
          );
        case SpreadElement():
          Expression expression = _visitExpression(element.expression);
          bool isNullAware = element.isNullAware;
          if (isNullAware) {
            switch (_isNull(expression)) {
              case NullValue.isNull:
                // Skip element.
                continue;
              case NullValue.isNonNull:
                isNullAware = false;
              case NullValue.unknown:
            }
          }
          if (isNullAware) {
            list.add(new SpreadElement(expression, isNullAware: true));
          } else {
            switch (expression) {
              case ListLiteral():
                list.addAll(_visitElements(expression.elements));
              case SetOrMapLiteral():
                list.addAll(_visitElements(expression.elements));
              default:
                list.add(new SpreadElement(expression, isNullAware: false));
            }
          }
        case IfElement():
          Expression condition = _visitExpression(element.condition);
          switch (condition) {
            case BooleanLiteral(value: true):
              list.addAll(_visitElements([element.then]));
            case BooleanLiteral(value: false):
              if (element.otherwise != null) {
                list.addAll(_visitElements([element.otherwise!]));
              }
            default:
              Element? then = _visitElement(element.then);
              Element? otherwise = element.otherwise != null
                  ? _visitElement(element.otherwise!)
                  : null;
              if (then != null) {
                list.add(new IfElement(condition, then, otherwise));
              } else if (otherwise != null) {
                list.add(
                  new IfElement(
                    new UnaryExpression(UnaryOperator.bang, condition),
                    otherwise,
                  ),
                );
              } else {
                // Skip element.
                continue;
              }
          }
      }
    }
    return list;
  }

  Element? _visitElement(Element element) {
    switch (element) {
      case ExpressionElement():
        Expression expression = _visitExpression(element.expression);
        bool isNullAware = element.isNullAware;
        if (isNullAware) {
          switch (_isNull(expression)) {
            case NullValue.isNull:
              // Skip element.
              return null;
            case NullValue.isNonNull:
              isNullAware = false;
            case NullValue.unknown:
          }
        }
        return new ExpressionElement(
          expression,
          isNullAware: element.isNullAware,
        );
      case MapEntryElement():
        Expression key = _visitExpression(element.key);
        Expression value = _visitExpression(element.value);
        bool isNullAwareKey = element.isNullAwareKey;
        bool isNullAwareValue = element.isNullAwareValue;
        if (isNullAwareKey) {
          switch (_isNull(key)) {
            case NullValue.isNull:
              // Skip entry.
              return null;
            case NullValue.isNonNull:
              isNullAwareKey = false;
            case NullValue.unknown:
          }
        }
        if (isNullAwareValue) {
          switch (_isNull(value)) {
            case NullValue.isNull:
              // Skip entry.
              return null;
            case NullValue.isNonNull:
              isNullAwareValue = false;
            case NullValue.unknown:
          }
        }
        return new MapEntryElement(
          key,
          value,
          isNullAwareKey: isNullAwareKey,
          isNullAwareValue: isNullAwareValue,
        );
      case SpreadElement():
        Expression expression = _visitExpression(element.expression);
        bool isNullAware = element.isNullAware;
        if (isNullAware) {
          switch (_isNull(expression)) {
            case NullValue.isNull:
              // Skip element.
              return null;
            case NullValue.isNonNull:
              isNullAware = false;
            case NullValue.unknown:
          }
        }
        if (isNullAware) {
          return new SpreadElement(expression, isNullAware: true);
        } else {
          switch (expression) {
            case ListLiteral(elements: []):
            case SetOrMapLiteral(elements: []):
              // Empty spread.
              return null;
            default:
              return new SpreadElement(expression, isNullAware: false);
          }
        }
      case IfElement():
        Expression condition = _visitExpression(element.condition);
        switch (condition) {
          case BooleanLiteral(value: true):
            return _visitElement(element.then);
          case BooleanLiteral(value: false):
            if (element.otherwise != null) {
              return _visitElement(element.otherwise!);
            } else {
              return null;
            }
          default:
            Element? then = _visitElement(element.then);
            Element? otherwise = element.otherwise != null
                ? _visitElement(element.otherwise!)
                : null;
            if (then != null) {
              return new IfElement(condition, then, otherwise);
            } else if (otherwise != null) {
              return new IfElement(
                new UnaryExpression(UnaryOperator.bang, condition),
                otherwise,
              );
            } else {
              // Skip element.
              return null;
            }
        }
    }
  }

  NullValue _isNull(Expression expression) {
    return switch (expression) {
      NullLiteral() => NullValue.isNull,
      BooleanLiteral() => NullValue.isNonNull,
      IntegerLiteral() => NullValue.isNonNull,
      DoubleLiteral() => NullValue.isNonNull,
      StringLiteral() => NullValue.isNonNull,
      SymbolLiteral() => NullValue.isNonNull,
      AdjacentStringLiterals() => NullValue.isNonNull,
      EqualityExpression() => NullValue.isNonNull,
      FunctionTearOff() => NullValue.isNonNull,
      IsTest() => NullValue.isNonNull,
      ListLiteral() => NullValue.isNonNull,
      SetOrMapLiteral() => NullValue.isNonNull,
      LogicalExpression() => NullValue.isNonNull,
      ConstructorTearOff() => NullValue.isNonNull,
      ConstructorInvocation() => NullValue.isNonNull,
      Instantiation() => NullValue.isNonNull,
      TypeLiteral() => NullValue.isNonNull,
      RecordLiteral() => NullValue.isNonNull,
      NullCheck() => NullValue.isNonNull,

      // TODO(johnniwinther): Should the subexpressions be visited?
      ParenthesizedExpression() => NullValue.unknown,
      ConditionalExpression() => NullValue.unknown,
      IfNull() => NullValue.unknown,
      BinaryExpression() => NullValue.unknown,
      UnaryExpression() => NullValue.unknown,
      PropertyGet() => NullValue.unknown,
      NullAwarePropertyGet() => NullValue.unknown,
      StaticGet() => NullValue.unknown,
      StaticInvocation() => NullValue.unknown,
      InvalidExpression() => NullValue.unknown,
      ImplicitInvocation() => NullValue.unknown,
      MethodInvocation() => NullValue.unknown,
      AsExpression() => NullValue.unknown,
      UnresolvedExpression() => NullValue.unknown,
    };
  }
}

enum NullValue { isNull, isNonNull, unknown }
