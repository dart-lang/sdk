// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(asgerf): Include metadata.
// TODO(asgerf): Include cascade operator.
library dart_printer;

import '../dart2jslib.dart' as dart2js;
import '../tree/tree.dart' as tree;
import '../util/characters.dart' as characters;
import '../elements/elements.dart' as elements;
import '../dart_types.dart' as types;

/// The following nodes correspond to [tree.Send] expressions:
/// [FieldExpression], [IndexExpression], [Assignment], [Increment],
/// [CallFunction], [CallMethod], [CallNew], [CallStatic], [UnaryOperator],
/// [BinaryOperator], and [TypeOperator].
abstract class Node {}

/// Receiver is an [Expression] or the [SuperReceiver].
abstract class Receiver extends Node {}

/// Argument is an [Expression] or a [NamedArgument].
abstract class Argument extends Node {}

abstract class Expression extends Node implements Receiver, Argument {
  bool get assignable => false;
}

abstract class Statement extends Node {}

/// Used as receiver in expressions that dispatch to the super class.
/// For instance, an expression such as `super.f()` is represented
/// by a [CallMethod] node with [SuperReceiver] as its receiver.
class SuperReceiver extends Receiver {
  static final SuperReceiver _instance = new SuperReceiver._create();

  factory SuperReceiver() => _instance;
  SuperReceiver._create();
}

/// Named arguments may occur in the argument list of
/// [CallFunction], [CallMethod], [CallNew], and [CallStatic].
class NamedArgument extends Argument {
  final String name;
  final Expression expression;

  NamedArgument(this.name, this.expression);
}

class TypeAnnotation extends Node {
  final String name;
  final List<TypeAnnotation> typeArguments;

  types.DartType dartType;

  TypeAnnotation(this.name, [this.typeArguments = const <TypeAnnotation>[]]);
}

// STATEMENTS


class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements);
}

class Break extends Statement {
  final String label;

  Break([this.label]);
}

class Continue extends Statement {
  final String label;

  Continue([this.label]);
}

class EmptyStatement extends Statement {
  static final EmptyStatement _instance = new EmptyStatement._create();

  factory EmptyStatement() => _instance;
  EmptyStatement._create();
}

class ExpressionStatement extends Statement {
  final Expression expression;

  ExpressionStatement(this.expression);
}

class For extends Statement {
  final Node initializer;
  final Expression condition;
  final List<Expression> updates;
  final Statement body;

  /// Initializer must be [VariableDeclarations] or [Expression] or null.
  For(this.initializer, this.condition, this.updates, this.body) {
    assert(initializer == null
        || initializer is VariableDeclarations
        || initializer is Expression);
  }
}

class ForIn extends Statement {
  final Node leftHandValue;
  final Expression expression;
  final Statement body;

  /// [leftHandValue] must be [Identifier] or [VariableDeclarations] with
  /// exactly one definition, and that variable definition must have no
  /// initializer.
  ForIn(Node leftHandValue, this.expression, this.body)
      : this.leftHandValue = leftHandValue {
    assert(leftHandValue is Identifier
        || (leftHandValue is VariableDeclarations
            && leftHandValue.declarations.length == 1
            && leftHandValue.declarations[0].initializer == null));
  }
}

class While extends Statement {
  final Expression condition;
  final Statement body;

  While(this.condition, this.body);
}

class DoWhile extends Statement {
  final Statement body;
  final Expression condition;

  DoWhile(this.body, this.condition);
}

class If extends Statement {
  final Expression condition;
  final Statement thenStatement;
  final Statement elseStatement;

  If(this.condition, this.thenStatement, [this.elseStatement]);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement statement;

  LabeledStatement(this.label, this.statement);
}

class Rethrow extends Statement {
}

class Return extends Statement {
  final Expression expression;

  Return([this.expression]);
}

class Switch extends Statement {
  final Expression expression;
  final List<SwitchCase> cases;

  Switch(this.expression, this.cases);
}

/// A sequence of case clauses followed by a sequence of statements.
/// Represents the default case if [expressions] is null.
///
/// NOTE:
/// Control will never fall through to the following SwitchCase, even if
/// the list of statements is empty. An empty list of statements will be
/// unparsed to a semicolon to guarantee this behaviour.
class SwitchCase extends Node {
  final List<Expression> expressions;
  final List<Statement> statements;

  SwitchCase(this.expressions, this.statements);
  SwitchCase.defaultCase(this.statements) : expressions = null;

  bool get isDefaultCase => expressions == null;
}

/// A try statement. The try, catch and finally blocks will automatically
/// be printed inside a block statement if necessary.
class Try extends Statement {
  final Statement tryBlock;
  final List<CatchBlock> catchBlocks;
  final Statement finallyBlock;

  Try(this.tryBlock, this.catchBlocks, [this.finallyBlock]) {
    assert(catchBlocks.length > 0 || finallyBlock != null);
  }
}

class CatchBlock extends Node {
  final TypeAnnotation onType;
  final String exceptionVar;
  final String stackVar;
  final Statement body;

  /// At least onType or exceptionVar must be given.
  /// stackVar may only be given if exceptionVar is also given.
  CatchBlock(this.body, {this.onType, this.exceptionVar, this.stackVar}) {
    // Must specify at least a type or an exception binding.
    assert(onType != null || exceptionVar != null);

    // We cannot bind the stack trace without binding the exception too.
    assert(stackVar == null || exceptionVar != null);
  }
}

class VariableDeclarations extends Statement {
  final TypeAnnotation type;
  final bool isFinal;
  final bool isConst;
  final List<VariableDeclaration> declarations;

  VariableDeclarations(this.declarations,
                      { this.type,
                        this.isFinal: false,
                        this.isConst: false }) {
    // Cannot be both final and const.
    assert(!isFinal || !isConst);
  }
}

class VariableDeclaration extends Node {
  final String name;
  final Expression initializer;

  elements.Element element;

  VariableDeclaration(this.name, [this.initializer]);
}


class FunctionDeclaration extends Statement {
  final TypeAnnotation returnType;
  final Parameters parameters;
  final String name;
  final Statement body;

  FunctionDeclaration(this.name,
                      this.parameters,
                      this.body,
                      [ this.returnType ]);
}

class Parameters extends Node {
  final List<Parameter> requiredParameters;
  final List<Parameter> optionalParameters;
  final bool hasNamedParameters;

  Parameters(this.requiredParameters,
             [ this.optionalParameters,
               this.hasNamedParameters = false ]);

  Parameters.named(this.requiredParameters, this.optionalParameters)
      : hasNamedParameters = true;

  Parameters.positional(this.requiredParameters, this.optionalParameters)
        : hasNamedParameters = false;

  bool get hasOptionalParameters =>
      optionalParameters != null && optionalParameters.length > 0;
}

class Parameter extends Node {
  final String name;

  /// Type of parameter, or return type of function parameter.
  final TypeAnnotation type;

  final Expression defaultValue;

  /// Parameters to function parameter. Null for non-function parameters.
  final Parameters parameters;

  elements.ParameterElement element;

  Parameter(this.name, {this.type, this.defaultValue})
      : parameters = null;

  Parameter.function(this.name,
                     TypeAnnotation returnType,
                     this.parameters,
                     [ this.defaultValue ]) : type = returnType {
    assert(parameters != null);
  }

  /// True if this is a function parameter.
  bool get isFunction => parameters != null;

  // TODO(asgerf): Support modifiers on parameters (final, ...).
}

// EXPRESSIONS

class FunctionExpression extends Expression {
  final TypeAnnotation returnType;
  final String name;
  final Parameters parameters;
  final Statement body;

  elements.FunctionElement element;

  FunctionExpression(this.parameters,
                     this.body,
                     { this.name,
                       this.returnType }) {
    // Function must have a name if it has a return type
    assert(returnType == null || name != null);
  }
}

class Conditional extends Expression {
  final Expression condition;
  final Expression thenExpression;
  final Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);
}

/// An identifier expression.
/// The unparser does not concern itself with scoping rules, and it is the
/// responsibility of the AST creator to ensure that the identifier resolves
/// to the proper definition.
/// For the time being, this class is also used to reference static fields and
/// top-level variables that are qualified with a class and/or library name,
/// assuming the [element] is set. This is likely to change when the old backend
/// is replaced.
class Identifier extends Expression {
  final String name;

  elements.Element element;

  Identifier(this.name);

  bool get assignable => true;
}

class Literal extends Expression {
  final dart2js.PrimitiveConstant value;

  Literal(this.value);
}

class LiteralList extends Expression {
  final bool isConst;
  final TypeAnnotation typeArgument;
  final List<Expression> values;

  LiteralList(this.values, { this.typeArgument, this.isConst: false });
}

class LiteralMap extends Expression {
  final bool isConst;
  final List<TypeAnnotation> typeArguments;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.entries, { this.typeArguments, this.isConst: false }) {
    assert(this.typeArguments == null
        || this.typeArguments.length == 0
        || this.typeArguments.length == 2);
  }
}

class LiteralMapEntry extends Node {
  final Expression key;
  final Expression value;

  LiteralMapEntry(this.key, this.value);
}

class LiteralSymbol extends Expression {
  final String id;

  /// [id] should not include the # symbol
  LiteralSymbol(this.id);
}

/// A type literal. This is distinct from [Identifier] since the unparser
/// needs to this distinguish a static invocation from a method invocation
/// on a type literal.
class LiteralType extends Expression {
  final String name;

  elements.TypeDeclarationElement element;

  LiteralType(this.name);
}

/// Reference to a type variable.
/// This is distinct from [Identifier] since the unparser needs to this
/// distinguish a function invocation `T()` from a type variable invocation
/// `(T)()` (the latter is invalid, but must be generated anyway).
class ReifyTypeVar extends Expression {
  final String name;

  elements.TypeVariableElement element;

  ReifyTypeVar(this.name);
}

/// StringConcat is used in place of string interpolation and juxtaposition.
/// Semantically, each subexpression is evaluated and converted to a string
/// by `toString()`. These string are then concatenated and returned.
/// StringConcat unparses to a string literal, possibly with interpolations.
/// The unparser will flatten nested StringConcats.
/// A StringConcat node may have any number of children, including zero and one.
class StringConcat extends Expression {
  final List<Expression> expressions;

  StringConcat(this.expressions);
}

/// Expression of form `e.f`.
class FieldExpression extends Expression {
  final Receiver object;
  final String fieldName;

  FieldExpression(this.object, this.fieldName);

  bool get assignable => true;
}

/// Expression of form `e1[e2]`.
class IndexExpression extends Expression {
  final Receiver object;
  final Expression index;

  IndexExpression(this.object, this.index);

  bool get assignable => true;
}

/// Expression of form `e(..)`
/// Note that if [callee] is a [FieldExpression] this will translate into
/// `(e.f)(..)` and not `e.f(..)`. Use a [CallMethod] to generate
/// the latter type of expression.
class CallFunction extends Expression {
  final Expression callee;
  final List<Argument> arguments;

  CallFunction(this.callee, this.arguments);
}

/// Expression of form `e.f(..)`.
class CallMethod extends Expression {
  final Receiver object;
  final String methodName;
  final List<Argument> arguments;

  CallMethod(this.object, this.methodName, this.arguments);
}

/// Expression of form `new T(..)`, `new T.f(..)`, `const T(..)`,
/// or `const T.f(..)`.
class CallNew extends Expression {
  final bool isConst;
  final TypeAnnotation type;
  final String constructorName;
  final List<Argument> arguments;

  elements.FunctionElement constructor;
  types.DartType dartType;

  CallNew(this.type,
          this.arguments,
         { this.constructorName,
           this.isConst: false });
}

/// Expression of form `T.f(..)`.
class CallStatic extends Expression {
  final String className;
  final String methodName;
  final List<Argument> arguments;

  elements.Element element;

  CallStatic(this.className, this.methodName, this.arguments);
}

/// Expression of form `!e` or `-e` or `~e`.
class UnaryOperator extends Expression {
  final String operatorName;
  final Receiver operand;

  UnaryOperator(this.operatorName, this.operand) {
    assert(isUnaryOperator(operatorName));
  }
}

/// Expression of form `e1 + e2`, `e1 - e2`, etc.
/// This node also represents application of the logical operators && and ||.
class BinaryOperator extends Expression {
  final Receiver left;
  final String operator;
  final Expression right;

  BinaryOperator(this.left, this.operator, this.right) {
    assert(isBinaryOperator(operator));
  }
}

/// Expression of form `e is T` or `e is! T` or `e as T`.
class TypeOperator extends Expression {
  final Expression expression;
  final String operator;
  final TypeAnnotation type;

  TypeOperator(this.expression, this.operator, this.type) {
    assert(operator == 'is'
        || operator == 'as'
        || operator == 'is!');
  }
}

class Increment extends Expression {
  final Expression expression;
  final String operator;
  final bool isPrefix;

  Increment(this.expression, this.operator, this.isPrefix) {
    assert(operator == '++' || operator == '--');
    assert(expression.assignable);
  }

  Increment.prefix(Expression expression, String operator)
      : this(expression, operator, true);

  Increment.postfix(Expression expression, String operator)
      : this(expression, operator, false);
}

class Assignment extends Expression {
  static final _operators =
      new Set.from(['=', '|=', '^=', '&=', '<<=', '>>=',
                    '+=', '-=', '*=', '/=', '%=', '~/=']);

  final Expression left;
  final String operator;
  final Expression right;

  Assignment(this.left, this.operator, this.right) {
    assert(_operators.contains(operator));
    assert(left.assignable);
  }
}

class Throw extends Expression {
  final Expression expression;

  Throw(this.expression);
}

class This extends Expression {
  static final This _instance = new This._create();

  factory This() => _instance;
  This._create();
}

// UNPARSER

bool isUnaryOperator(String op) {
  return op == '!' || op == '-' || op == '~';
}
bool isBinaryOperator(String op) {
  return BINARY_PRECEDENCE.containsKey(op);
}
/// True if the given operator can be converted to a compound assignment.
bool isCompoundableOperator(String op) {
  switch (BINARY_PRECEDENCE[op]) {
    case BITWISE_OR:
    case BITWISE_XOR:
    case BITWISE_AND:
    case SHIFT:
    case ADDITIVE:
    case MULTIPLICATIVE:
      return true;
    default:
      return false;
  }
}


// Precedence levels
const int EXPRESSION = 1;
const int CONDITIONAL = 2;
const int LOGICAL_OR = 3;
const int LOGICAL_AND = 4;
const int EQUALITY = 6;
const int RELATIONAL = 7;
const int BITWISE_OR = 8;
const int BITWISE_XOR = 9;
const int BITWISE_AND = 10;
const int SHIFT = 11;
const int ADDITIVE = 12;
const int MULTIPLICATIVE = 13;
const int UNARY = 14;
const int POSTFIX_INCREMENT = 15;
const int TYPE_LITERAL = 19;
const int PRIMARY = 20;

/// Precedence level required for the callee in a [FunctionCall].
const int CALLEE = 21;

const Map<String,int> BINARY_PRECEDENCE = const {
  '&&': LOGICAL_AND,
  '||': LOGICAL_OR,

  '==': EQUALITY,
  '!=': EQUALITY,

  '>': RELATIONAL,
  '>=': RELATIONAL,
  '<': RELATIONAL,
  '<=': RELATIONAL,

  '|': BITWISE_OR,
  '^': BITWISE_XOR,
  '&': BITWISE_AND,

  '>>': SHIFT,
  '<<': SHIFT,

  '+': ADDITIVE,
  '-': ADDITIVE,

  '*': MULTIPLICATIVE,
  '%': MULTIPLICATIVE,
  '/': MULTIPLICATIVE,
  '~/': MULTIPLICATIVE,
};

/// Return true if binary operators with the given precedence level are
/// (left) associative. False if they are non-associative.
bool isAssociativeBinaryOperator(int precedence) {
  return precedence != EQUALITY && precedence != RELATIONAL;
}

/// True if [x] is a letter, digit, or underscore.
/// Such characters may not follow a shorthand string interpolation.
bool isIdentifierPartNoDollar(dynamic x) {
  if (x is! int) {
    return false;
  }
  return (characters.$0 <= x && x <= characters.$9) ||
         (characters.$A <= x && x <= characters.$Z) ||
         (characters.$a <= x && x <= characters.$z) ||
         (x == characters.$_);
}

/// The unparser will apply the following syntactic rewritings:
///   Use short-hand function returns:
///     foo(){return E} ==> foo() => E;
///   Remove empty else branch:
///     if (E) S else ; ==> if (E) S
///   Flatten nested blocks:
///     {S; {S; S}; S} ==> {S; S; S; S}
///   Remove empty statements from block:
///     {S; ; S} ==> {S; S}
///   Unfold singleton blocks:
///     {S} ==> S
///   Empty block to empty statement:
///     {} ==> ;
///   Introduce not-equals operator:
///     !(E == E) ==> E != E
///   Introduce is-not operator:
///     !(E is T) ==> E is!T
///
/// The following transformations will NOT be applied here:
///   Use implicit this:
///     this.foo ==> foo              (preconditions too complex for unparser)
///   Merge adjacent variable definitions:
///     var x; var y  ==> var x,y;    (hoisting will be done elsewhere)
///   Merge adjacent labels:
///     foo: bar: S ==> foobar: S     (scoping is categorically ignored)
///
/// The following transformations might be applied here in the future:
///   Use implicit dynamic types:
///     dynamic x = E ==> var x = E
///     <dynamic>[]   ==> []
class Unparser {
  StringSink output;

  Unparser(this.output);


  void write(String s) {
    output.write(s);
  }

  /// Outputs each element from [items] separated by [separator].
  /// The actual printing must be performed by the [callback].
  void writeEach(String separator, Iterable items, void callback(any)) {
    bool first = true;
    for (var x in items) {
      if (first) {
        first = false;
      } else {
        write(separator);
      }
      callback(x);
    }
  }

  void writeOperator(String operator) {
    write(" "); // TODO(asgerf): Minimize use of whitespace.
    write(operator);
    write(" ");
  }

  /// Unfolds singleton blocks and returns the inner statement.
  /// If an empty block is found, the [EmptyStatement] is returned instead.
  Statement unfoldBlocks(Statement stmt) {
    while (stmt is Block && stmt.statements.length == 1) {
      Statement inner = (stmt as Block).statements[0];
      if (definesVariable(inner)) {
        return stmt; // Do not unfold block with lexical scope.
      }
      stmt = inner;
    }
    if (stmt is Block && stmt.statements.length == 0)
      return new EmptyStatement();
    return stmt;
  }

  void writeArgument(Argument arg) {
    if (arg is NamedArgument) {
      write(arg.name);
      write(':');
      writeExpression(arg.expression);
    } else {
      writeExpression(arg);
    }
  }

  /// Prints the expression [e].
  void writeExpression(Expression e) {
    writeExp(e, EXPRESSION);
  }

  /// Prints [e] as an expression with precedence of at least [minPrecedence],
  /// using parentheses if necessary to raise the precedence level.
  /// Abusing terminology slightly, the function accepts a [Receiver] which
  /// may also be the [SuperReceiver] object.
  void writeExp(Receiver e, int minPrecedence, {beginStmt:false}) {
    // TODO(asgerf):
    //   Would there be a significant speedup using a Visitor or a method
    //   on the AST instead of a chain of "if (e is T)" statements?
    void withPrecedence(int actual, void action()) {
      if (actual < minPrecedence) {
        write("(");
        beginStmt = false;
        action();
        write(")");
      } else {
        action();
      }
    }
    if (e is SuperReceiver) {
      write('super');
    } else if (e is FunctionExpression) {
      Statement stmt = unfoldBlocks(e.body);
      int precedence = stmt is Return ? EXPRESSION : PRIMARY;
      withPrecedence(precedence, () {
        // A named function expression at the beginning of a statement
        // can be mistaken for a function declaration.
        // (Note: Functions with a return type also have a name)
        bool needParen = beginStmt && e.name != null;
        if (needParen) {
          write('(');
        }
        if (e.returnType != null) {
          writeType(e.returnType);
          write(' ');
        }
        if (e.name != null) {
          write(e.name);
        }
        writeParameters(e.parameters);
        if (stmt is Return) { // TODO(asgerf): Print {} for "return null;"
          write('=> '); // TODO(asgerf): Minimize use of whitespace.
          writeExp(stmt.expression, EXPRESSION);
        } else {
          writeBlock(stmt);
        }
        if (needParen) {
          write(')');
        }
      });
    } else if (e is Conditional) {
      withPrecedence(CONDITIONAL, () {
        writeExp(e.condition, LOGICAL_OR, beginStmt: beginStmt);
        write(' ? '); // TODO(asgerf): Minimize use of whitespace.
        writeExp(e.thenExpression, EXPRESSION);
        write(' : ');
        writeExp(e.elseExpression, EXPRESSION);
      });
    } else if (e is Identifier) {
      write(e.name);
    } else if (e is Literal) {
      if (e.value is dart2js.StringConstant) {
        writeStringLiteral(e);
      }
      else if (e.value is dart2js.DoubleConstant) {
        double v = e.value.value;
        if (v == double.INFINITY) {
          withPrecedence(MULTIPLICATIVE, () {
            write('1/0.0');
          });
        } else if (v == double.NEGATIVE_INFINITY) {
          withPrecedence(MULTIPLICATIVE, () {
            write('-1/0.0');
          });
        } else if (v.isNaN) {
          withPrecedence(MULTIPLICATIVE, () {
            write('0/0.0');
          });
        } else {
          write(v.toString());
        }
      } else {
        write(e.value.toString());
      }
    } else if (e is LiteralList) {
      if (e.isConst) {
        write(' const '); // TODO(asgerf): Minimize use of whitespace.
      }
      if (e.typeArgument != null) {
        write('<');
        writeType(e.typeArgument);
        write('>');
      }
      write('[');
      writeEach(',', e.values, writeExpression);
      write(']');
    }
    else if (e is LiteralMap) {
      // The curly brace can be mistaken for a block statement if we
      // are at the beginning of a statement.
      bool needParen = beginStmt;
      if (e.isConst) {
        write(' const '); // TODO(asgerf): Minimize use of whitespace.
        needParen = false;
      }
      if (e.typeArguments.length > 0) {
        write('<');
        writeEach(',', e.typeArguments, writeType);
        write('>');
        needParen = false;
      }
      if (needParen) {
        write('(');
      }
      write('{');
      writeEach(',', e.entries, (LiteralMapEntry en) {
        writeExp(en.key, EXPRESSION);
        write(' : '); // TODO(asgerf): Minimize use of whitespace.
        writeExp(en.value, EXPRESSION);
      });
      write('}');
      if (needParen) {
        write(')');
      }
    } else if (e is LiteralSymbol) {
      write('#');
      write(e.id); // TODO(asgerf): Do we need to escape something here?
    } else if (e is LiteralType) {
      withPrecedence(TYPE_LITERAL, () {
        write(e.name);
      });
    } else if (e is ReifyTypeVar) {
      withPrecedence(PRIMARY, () {
        write(e.name);
      });
    } else if (e is StringConcat) {
      writeStringLiteral(e);
    } else if (e is UnaryOperator) {
      Receiver operand = e.operand;
      // !(x == y) ==> x != y.
      if (e.operatorName == '!' &&
          operand is BinaryOperator && operand.operator == '==') {
        withPrecedence(EQUALITY, () {
          writeExp(operand.left, RELATIONAL);
          writeOperator('!=');
          writeExp(operand.right, RELATIONAL);
        });
      }
      // !(x is T) ==> x is!T
      else if (e.operatorName == '!' &&
          operand is TypeOperator && operand.operator == 'is') {
        withPrecedence(RELATIONAL, () {
          writeExp(operand.expression, BITWISE_OR, beginStmt: beginStmt);
          write(' is!'); // TODO(asgerf): Minimize use of whitespace.
          writeType(operand.type);
        });
      }
      else {
        withPrecedence(UNARY, () {
          writeOperator(e.operatorName);
          writeExp(e.operand, UNARY);
        });
      }
    } else if (e is BinaryOperator) {
      int precedence = BINARY_PRECEDENCE[e.operator];
      withPrecedence(precedence, () {
        // All binary operators are left-associative or non-associative.
        // For each operand, we use either the same precedence level as
        // the current operator, or one higher.
        int deltaLeft = isAssociativeBinaryOperator(precedence) ? 0 : 1;
        writeExp(e.left, precedence + deltaLeft, beginStmt: beginStmt);
        writeOperator(e.operator);
        writeExp(e.right, precedence + 1);
      });
    } else if (e is TypeOperator) {
      withPrecedence(RELATIONAL, () {
        writeExp(e.expression, BITWISE_OR, beginStmt: beginStmt);
        write(' ');
        write(e.operator);
        write(' ');
        writeType(e.type);
      });
    } else if (e is Assignment) {
      withPrecedence(EXPRESSION, () {
        writeExp(e.left, PRIMARY, beginStmt: beginStmt);
        writeOperator(e.operator);
        writeExp(e.right, EXPRESSION);
      });
    } else if (e is FieldExpression) {
      withPrecedence(PRIMARY, () {
        writeExp(e.object, PRIMARY, beginStmt: beginStmt);
        write('.');
        write(e.fieldName);
      });
    } else if (e is IndexExpression) {
      withPrecedence(CALLEE, () {
        writeExp(e.object, PRIMARY, beginStmt: beginStmt);
        write('[');
        writeExp(e.index, EXPRESSION);
        write(']');
      });
    } else if (e is CallFunction) {
      withPrecedence(CALLEE, () {
        writeExp(e.callee, CALLEE, beginStmt: beginStmt);
        write('(');
        writeEach(',', e.arguments, writeArgument);
        write(')');
      });
    } else if (e is CallMethod) {
      withPrecedence(CALLEE, () {
        writeExp(e.object, PRIMARY, beginStmt: beginStmt);
        write('.');
        write(e.methodName);
        write('(');
        writeEach(',', e.arguments, writeArgument);
        write(')');
      });
    } else if (e is CallNew) {
      withPrecedence(CALLEE, () {
        write(' '); // TODO(asgerf): Minimize use of whitespace.
        write(e.isConst ? 'const ' : 'new ');
        writeType(e.type);
        if (e.constructorName != null) {
          write('.');
          write(e.constructorName);
        }
        write('(');
        writeEach(',', e.arguments, writeArgument);
        write(')');
      });
    } else if (e is CallStatic) {
      withPrecedence(CALLEE, () {
        write(e.className);
        write('.');
        write(e.methodName);
        write('(');
        writeEach(',', e.arguments, writeArgument);
        write(')');
      });
    } else if (e is Increment) {
      int precedence = e.isPrefix ? UNARY : POSTFIX_INCREMENT;
      withPrecedence(precedence, () {
        if (e.isPrefix) {
          write(e.operator);
          writeExp(e.expression, PRIMARY);
        } else {
          writeExp(e.expression, PRIMARY, beginStmt: beginStmt);
          write(e.operator);
        }
      });
    } else if (e is Throw) {
      withPrecedence(EXPRESSION, () {
        write('throw ');
        writeExp(e.expression, EXPRESSION);
      });
    } else if (e is This) {
      write('this');
    } else {
      throw "Unexpected expression: $e";
    }
  }

  void writeParameters(Parameters params) {
    write('(');
    bool first = true;
    writeEach(',', params.requiredParameters, (Parameter p) {
      if (p.type != null) {
        writeType(p.type);
        write(' ');
      }
      write(p.name);
      if (p.parameters != null) {
        writeParameters(p.parameters);
      }
    });
    if (params.hasOptionalParameters) {
      if (params.requiredParameters.length > 0) {
        write(',');
      }
      write(params.hasNamedParameters ? '{' : '[');
      writeEach(',', params.optionalParameters, (Parameter p) {
        if (p.type != null) {
          writeType(p.type);
          write(' ');
        }
        write(p.name);
        if (p.parameters != null) {
          writeParameters(p.parameters);
        }
        if (p.defaultValue != null) {
          write(params.hasNamedParameters ? ':' : '=');
          writeExp(p.defaultValue, EXPRESSION);
        }
      });
      write(params.hasNamedParameters ? '}' : ']');
    }
    write(')');
  }

  void writeStatement(Statement stmt, {bool shortIf: true}) {
    stmt = unfoldBlocks(stmt);
    if (stmt is Block) {
      write('{');
      stmt.statements.forEach(writeBlockMember);
      write('}');
    } else if (stmt is Break) {
      write('break');
      if (stmt.label != null) {
        write(' ');
        write(stmt.label);
      }
      write(';');
    } else if (stmt is Continue) {
      write('continue');
      if (stmt.label != null) {
        write(' ');
        write(stmt.label);
      }
      write(';');
    } else if (stmt is EmptyStatement) {
      write(';');
    } else if (stmt is ExpressionStatement) {
      writeExp(stmt.expression, EXPRESSION, beginStmt:true);
      write(';');
    } else if (stmt is For) {
      write('for(');
      Node init = stmt.initializer;
      if (init is Expression) {
        writeExp(init, EXPRESSION);
      } else if (init is VariableDeclarations) {
        writeVariableDefinitions(init);
      }
      write(';');
      if (stmt.condition != null) {
        writeExp(stmt.condition, EXPRESSION);
      }
      write(';');
      writeEach(',', stmt.updates, writeExpression);
      write(')');
      writeStatement(stmt.body, shortIf: shortIf);
    } else if (stmt is ForIn) {
      write('for(');
      Node lhv = stmt.leftHandValue;
      if (lhv is Identifier) {
        write(lhv.name);
      } else {
        writeVariableDefinitions(lhv as VariableDeclarations);
      }
      write(' in ');
      writeExp(stmt.expression, EXPRESSION);
      write(')');
      writeStatement(stmt.body, shortIf: shortIf);
    } else if (stmt is While) {
      write('while(');
      writeExp(stmt.condition, EXPRESSION);
      write(')');
      writeStatement(stmt.body, shortIf: shortIf);
    } else if (stmt is DoWhile) {
      write('do '); // TODO(asgerf): Minimize use of whitespace.
      writeStatement(stmt.body);
      write('while(');
      writeExp(stmt.condition, EXPRESSION);
      write(');');
    } else if (stmt is If) {
      // if (E) S else ; ==> if (E) S
      Statement elsePart = unfoldBlocks(stmt.elseStatement);
      if (elsePart is EmptyStatement) {
        elsePart = null;
      }
      if (!shortIf && elsePart == null) {
        write('{');
      }
      write('if(');
      writeExp(stmt.condition, EXPRESSION);
      write(')');
      writeStatement(stmt.thenStatement, shortIf: elsePart == null);
      if (elsePart != null) {
        write('else ');
        writeStatement(elsePart, shortIf: shortIf);
      }
      if (!shortIf && elsePart == null) {
        write('}');
      }
    } else if (stmt is LabeledStatement) {
      write(stmt.label);
      write(':');
      writeStatement(stmt.statement, shortIf: shortIf);
    } else if (stmt is Rethrow) {
      write('rethrow;');
    } else if (stmt is Return) {
      write('return');
      if (stmt.expression != null) {
        write(' ');
        writeExp(stmt.expression, EXPRESSION);
      }
      write(';');
    } else if (stmt is Switch) {
      write('switch(');
      writeExp(stmt.expression, EXPRESSION);
      write('){');
      for (SwitchCase caze in stmt.cases) {
        if (caze.isDefaultCase) {
          write('default:');
        } else {
          for (Expression exp in caze.expressions) {
            write('case ');
            writeExp(exp, EXPRESSION);
            write(':');
          }
        }
        if (caze.statements.isEmpty) {
          write(';'); // Prevent fall-through.
        } else {
          caze.statements.forEach(writeBlockMember);
        }
      }
      write('}');
    } else if (stmt is Try) {
      write('try');
      writeBlock(stmt.tryBlock);
      for (CatchBlock block in stmt.catchBlocks) {
        if (block.onType != null) {
          write('on ');
          writeType(block.onType);
        }
        if (block.exceptionVar != null) {
          write('catch(');
          write(block.exceptionVar);
          if (block.stackVar != null) {
            write(',');
            write(block.stackVar);
          }
          write(')');
        }
        writeBlock(block.body);
      }
      if (stmt.finallyBlock != null) {
        write('finally');
        writeBlock(stmt.finallyBlock);
      }
    } else if (stmt is VariableDeclarations) {
      writeVariableDefinitions(stmt);
      write(';');
    } else if (stmt is FunctionDeclaration) {
      if (stmt.returnType != null) {
        writeType(stmt.returnType);
        write(' ');
      }
      write(stmt.name);
      writeParameters(stmt.parameters);
      Statement body = unfoldBlocks(stmt.body);
      if (body is Return) {
        write('=> '); // TODO(asgerf): Minimize use of whitespace.
        writeExp(body.expression, EXPRESSION);
        write(';');
      } else {
        writeBlock(body);
      }
    } else {
      throw "Unexpected statement: $stmt";
    }
  }

  /// Writes a variable definition statement without the trailing semicolon
  void writeVariableDefinitions(VariableDeclarations vds) {
    if (vds.isConst)
      write('const ');
    else if (vds.isFinal)
      write('final ');
    if (vds.type != null) {
      writeType(vds.type);
      write(' ');
    }
    if (!vds.isConst && !vds.isFinal && vds.type == null) {
      write('var ');
    }
    writeEach(',', vds.declarations, (VariableDeclaration vd) {
      write(vd.name);
      if (vd.initializer != null) {
        write('=');
        writeExp(vd.initializer, EXPRESSION);
      }
    });
  }

  /// True of statements that introduce variables in the scope of their
  /// surrounding block. Blocks containing such statements cannot be unfolded.
  static bool definesVariable(Statement s) {
    return s is VariableDeclarations || s is FunctionDeclaration;
  }

  /// Writes the given statement in a context where only blocks are allowed.
  void writeBlock(Statement stmt) {
    if (stmt is Block) {
      writeStatement(stmt);
    } else {
      write('{');
      writeBlockMember(stmt);
      write('}');
    }
  }

  /// Outputs a statement that is a member of a block statement (or a similar
  /// sequence of statements, such as in switch statement).
  /// This will flatten blocks and skip empty statement.
  void writeBlockMember(Statement stmt) {
    if (stmt is Block && !stmt.statements.any(definesVariable)) {
      stmt.statements.forEach(writeBlockMember);
    } else if (stmt is EmptyStatement) {
      // do nothing
    } else {
      writeStatement(stmt);
    }
  }

  void writeType(TypeAnnotation type) {
    write(type.name);
    if (type.typeArguments != null && type.typeArguments.length > 0) {
      write('<');
      writeEach(',', type.typeArguments, writeType);
      write('>');
    }
  }

  /// A list of string quotings that the printer may use to quote strings.
  // Ignore multiline quotings for now. Would need to make sure that no
  // newline (potentially prefixed by whitespace) follows the quoting.
  // TODO(asgerf): Include multiline quotation schemes.
  static const _QUOTINGS = const <tree.StringQuoting>[
      const tree.StringQuoting(characters.$DQ, raw: false, leftQuoteLength: 1),
      const tree.StringQuoting(characters.$DQ, raw: true, leftQuoteLength: 1),
      const tree.StringQuoting(characters.$SQ, raw: false, leftQuoteLength: 1),
      const tree.StringQuoting(characters.$SQ, raw: true, leftQuoteLength: 1),
  ];

  static StringLiteralOutput analyzeStringLiteral(Expression node) {
    // TODO(asgerf): This might be a bit too expensive. Benchmark.
    // Flatten the StringConcat tree.
    List parts = []; // Expression or int (char node)
    void collectParts(Expression e) {
      if (e is StringConcat) {
        e.expressions.forEach(collectParts);
      } else if (e is Literal && e.value is dart2js.StringConstant) {
        for (int char in e.value.value) {
          parts.add(char);
        }
      } else {
        parts.add(e);
      }
    }
    collectParts(node);

    // We use a dynamic algorithm to compute the optimal way of printing
    // the string literal.
    //
    // Using string juxtapositions, it is possible to switch from one quoting
    // to another, e.g. the constant "''''" '""""' uses this trick.
    //
    // As we move through the string from left to right, we maintain a strategy
    // for each StringQuoting Q, denoting the best way to print the current
    // prefix so that we end with a string literal quoted with Q.
    // At every step, each strategy is either:
    //  1) Updated to include the cost of printing the next character.
    //  2) Abandoned because it is cheaper to use another strategy as prefix,
    //     and then switching quotation using a juxtaposition.

    int getQuoteCost(tree.StringQuoting quot) {
      return quot.leftQuoteLength + quot.rightQuoteLength;
    }

    // Create initial scores for each StringQuoting and index them
    // into raw/non-raw and single-quote/double-quote.
    List<OpenStringChunk> best = <OpenStringChunk>[];
    List<int> raws = <int>[];
    List<int> nonRaws = <int>[];
    List<int> sqs = <int>[];
    List<int> dqs = <int>[];
    for (tree.StringQuoting q in _QUOTINGS) {
      OpenStringChunk chunk = new OpenStringChunk(null, q, getQuoteCost(q));
      int index = best.length;
      best.add(chunk);

      if (q.raw) {
        raws.add(index);
      } else {
        nonRaws.add(index);
      }
      if (q.quote == characters.$SQ) {
        sqs.add(index);
      } else {
        dqs.add(index);
      }
    }


    /// Applies additional cost to each track in [penalized], and considers
    /// switching from each [penalized] to a [nonPenalized] track.
    void penalize(List<int> penalized,
                  List<int> nonPenalized,
                  int endIndex,
                  num cost(tree.StringQuoting q)) {
      for (int j in penalized) {
        // Check if another track can benefit from switching from this track.
        for (int k in nonPenalized) {
          num newCost = best[j].cost
                      + 1             // Whitespace in string juxtaposition
                      + getQuoteCost(best[k].quoting);
          if (newCost < best[k].cost) {
            best[k] = new OpenStringChunk(
                best[j].end(endIndex),
                best[k].quoting,
                newCost);
          }
        }
        best[j].cost += cost(best[j].quoting);
      }
    }

    // Iterate through the string and update the score for each StringQuoting.
    for (int i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (part is int) {
        int char = part;
        switch (char) {
          case characters.$$:
          case characters.$BACKSLASH:
            penalize(nonRaws, raws, i, (q) => 1);
            break;
          case characters.$DQ:
            penalize(dqs, sqs, i, (q) => q.raw ? double.INFINITY : 1);
            break;
          case characters.$SQ:
            penalize(sqs, dqs, i, (q) => q.raw ? double.INFINITY : 1);
            break;
          case characters.$LF:
          case characters.$CR:
          case characters.$FF:
          case characters.$BS:
          case characters.$VTAB:
          case characters.$TAB:
          case characters.$EOF:
            penalize(raws, nonRaws, i, (q) => double.INFINITY);
            break;
        }
      } else {
        // Penalize raw literals for string interpolation.
        penalize(raws, nonRaws, i, (q) => double.INFINITY);

        // Splitting a string can sometimes allow us to use a shorthand
        // string interpolation that would otherwise be illegal.
        // E.g. "...${foo}x..." -> "...$foo" 'x...'
        // If are other factors that make splitting advantageous,
        // we can gain even more by doing the split here.
        if (part is Identifier &&
            !part.name.contains(r'$') &&
            i + 1 < parts.length &&
            isIdentifierPartNoDollar(parts[i+1])) {
          for (int j in nonRaws) {
            for (int k = 0; k < best.length; k++) {
              num newCost = best[j].cost
                          + 1             // Whitespace in string juxtaposition
                          - 2             // Save two curly braces
                          + getQuoteCost(best[k].quoting);
              if (newCost < best[k].cost) {
                best[k] = new OpenStringChunk(
                    best[j].end(i+1),
                    best[k].quoting,
                    newCost);
              }
            }
          }
        }
      }
    }

    // Select the cheapest strategy
    OpenStringChunk bestChunk = best[0];
    for (OpenStringChunk chunk in best) {
      if (chunk.cost < bestChunk.cost) {
        bestChunk = chunk;
      }
    }

    return new StringLiteralOutput(parts, bestChunk.end(parts.length));
  }

  void writeStringLiteral(Expression node) {
    StringLiteralOutput output = analyzeStringLiteral(node);
    List parts = output.parts;
    void printChunk(StringChunk chunk) {
      int startIndex;
      if (chunk.previous != null) {
        printChunk(chunk.previous);
        write(' '); // String juxtaposition requires a space between literals.
        startIndex = chunk.previous.endIndex;
      } else {
        startIndex = 0;
      }
      if (chunk.quoting.raw) {
        write('r');
      }
      write(chunk.quoting.quoteChar);
      bool raw = chunk.quoting.raw;
      int quoteCode = chunk.quoting.quote;
      for (int i=startIndex; i<chunk.endIndex; i++) {
        var part = parts[i];
        if (part is int) {
          int char = part;
          write(getEscapedCharacter(char, quoteCode, raw));
        } else if (part is Identifier &&
                   !part.name.contains(r'$') &&
                   (i == chunk.endIndex - 1 ||
                    !isIdentifierPartNoDollar(parts[i+1]))) {
          write(r'$');
          write(part.name);
        } else {
          write(r'${');
          writeExpression(part);
          write('}');
        }
      }
      write(chunk.quoting.quoteChar);
    }
    printChunk(output.chunk);
  }

  static String getEscapedCharacter(int char, int quoteCode, bool raw) {
    switch (char) {
      case characters.$$:
        return raw ? r'$' : r'\$';
      case characters.$BACKSLASH:
        return raw ? r'\' : r'\\';
      case characters.$DQ:
        return quoteCode == char ? r'\"' : r'"';
      case characters.$SQ:
        return quoteCode == char ? r"\'" : r"'";
      case characters.$LF:
        return r'\n';
      case characters.$CR:
        return r'\r';
      case characters.$FF:
        return r'\f';
      case characters.$BS:
        return r'\b';
      case characters.$TAB:
        return r'\t';
      case characters.$VTAB:
        return r'\v';
      case characters.$EOF:
        return r'\x00';
      default:
        return new String.fromCharCode(char);
    }
  }

}

/// The contents of a string literal together with a strategy for printing it.
class StringLiteralOutput {
  /// Mix of [Expression] and `int`. Each expression is a string interpolation,
  /// and each `int` is the character code of a character in a string literal.
  final List parts;
  final StringChunk chunk;

  StringLiteralOutput(this.parts, this.chunk);
}


/// Strategy for printing a prefix of a string literal.
/// A chunk represents the substring going from [:previous.endIndex:] to
/// [endIndex] (or from 0 to [endIndex] if [previous] is null).
class StringChunk {
  final StringChunk previous;
  final tree.StringQuoting quoting;
  final int endIndex;

  StringChunk(this.previous, this.quoting, this.endIndex);
}

/// [StringChunk] that has not yet been assigned an [endIndex].
/// It additionally has a [cost] denoting the number of auxilliary characters
/// (quotes, spaces, etc) needed to print the literal using this strategy
class OpenStringChunk {
  final StringChunk previous;
  final tree.StringQuoting quoting;
  num cost;

  OpenStringChunk(this.previous, this.quoting, this.cost);

  StringChunk end(int endIndex) {
    return new StringChunk(previous, quoting, endIndex);
  }
}