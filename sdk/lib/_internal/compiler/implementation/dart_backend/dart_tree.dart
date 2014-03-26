// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_tree;

import '../dart2jslib.dart' as dart2js;
import '../util/util.dart';
import '../elements/elements.dart' show FunctionElement, FunctionSignature;
import '../ir/ir_nodes.dart' as ir;
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart';

// The Tree language is the target of translation out of the CPS-based IR.
//
// The translation from CPS to Dart consists of several stages.  Among the
// stages are translation to direct style, translation out of SSA, eliminating
// unnecessary names, recognizing high-level control constructs.  Combining
// these separate concerns is complicated and the constraints of the CPS-based
// language do not permit a multi-stage translation.
//
// For that reason, CPS is translated to the direct-style language Tree.
// Translation out of SSA, unnaming, and control-flow, as well as 'instruction
// selection' are performed on the Tree language.
//
// In contrast to the CPS-based IR, non-primitive expressions can be named and
// arguments (to calls, primitives, and blocks) can be arbitrary expressions.

/**
 * The base class of all Tree nodes.
 */
abstract class Node {
  accept(Visitor visitor);
}

/**
 * The base class of [Expression]s.
 */
abstract class Expression extends Node {}

/**
 * Variables are [Expression]s.
 */
class Variable extends Expression {
  // A counter used to generate names.  The counter is reset to 0 for each
  // function emitted.
  static int counter = 0;
  static String _newName() => 'v${counter++}';

  ast.Identifier identifier = null;

  ast.Identifier assignIdentifier() {
    assert(identifier == null);
    String name = _newName();
    identifier = new ast.Identifier(
        new StringToken.fromString(IDENTIFIER_INFO, name, -1));
    return identifier;
  }

  accept(Visitor visitor) => visitor.visitVariable(this);
}

/**
 * A local binding of a [Variable] to an [Expression].
 *
 * In contrast to the CPS-based IR, non-primitive expressions can be named
 * with let.
 */
class LetVal extends Expression {
  final Variable variable;
  final Expression definition;
  final Expression body;

  LetVal(this.variable, this.definition, this.body);

  accept(Visitor visitor) => visitor.visitLetVal(this);
}

/**
 * A call to a static target.
 *
 * In contrast to the CPS-based IR, the arguments can be arbitrary expressions.
 */
class InvokeStatic extends Expression {
  final FunctionElement target;
  final List<Expression> arguments;

  InvokeStatic(this.target, this.arguments);

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Expression {
  final Expression value;

  Return(this.value);

  accept(Visitor visitor) => visitor.visitReturn(this);
}

/**
 * A constant.
 */
class Constant extends Expression {
  final dart2js.Constant value;

  Constant(this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

abstract class Visitor<T> {
  // Abstract classes.
  T visitNode(Node node) => node.accept(this);
  T visitExpression(Expression node) => visitNode(node);

  // Concrete classes.
  T visitVariable(Variable node) => visitExpression(node);
  T visitLetVal(LetVal node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
  T visitReturn(Return node) => visitExpression(node);
  T visitConstant(Constant node) => visitExpression(node);
}

/**
 * Builder translates from CPS-based IR to direct-style Tree.
 *
 * A call `Invoke(fun, cont, args)`, where cont is a singly-referenced
 * non-exit continuation `Cont(v, body)` is translated into a direct-style call
 * whose value is bound in the continuation body:
 *
 * `LetVal(v, Invoke(fun, args), body)`
 *
 * and the continuation definition is eliminated.  A similar translation is
 * applied to continuation invocations where the continuation is
 * singly-referenced, though such invocations should not appear in optimized
 * IR.
 *
 * A call `Invoke(fun, cont, args)`, where cont is multiply referenced, is
 * translated into a call followed by a jump with an argument:
 *
 * `Jump L(Invoke(fun, args))`
 *
 * and the continuation is translated into a named block that takes an
 * argument:
 *
 * `LetLabel(L, v, body)`
 *
 * Block arguments are later replaced with data flow during the Tree-to-Tree
 * translation out of SSA.  Jumps are eliminated during the Tree-to-Tree
 * control-flow recognition.
 *
 * Otherwise, the output of Builder looks very much like the input.  In
 * particular, intermediate values and blocks used for local control flow are
 * still all named.
 */
class Builder extends ir.Visitor<Expression> {
  final dart2js.Compiler compiler;

  // Uses of IR definitions are replaced with Tree variables.  This is the
  // mapping from definitions to variables.
  final Map<ir.Definition, Variable> variables = {};

  ir.Continuation returnContinuation;

  Builder(this.compiler);

  List<Expression> translateArguments(List<ir.Reference> args) {
    return new List.generate(args.length,
         (int index) => variables[args[index].definition]);
  }

  Expression visitFunction(ir.Function node) {
    // Functions are simplistically translated to their bodies.  For now this
    // is good enough.
    returnContinuation = node.returnContinuation;
    return node.body.accept(this);
  }

  Expression visitLetPrim(ir.LetPrim node) {
    // LetPrim is translated to LetVal.
    Variable variable = new Variable();
    Expression definition = node.primitive.accept(this);
    variables[node.primitive] = variable;
    return new LetVal(variable, definition, node.body.accept(this));
  }

  Expression visitLetCont(ir.LetCont node) {
    // TODO(kmillikin): Allow continuations to have multiple uses.  This could
    // arise due to the representation of local control flow or due to
    // optimization.
    assert(node.continuation.hasAtMostOneUse);
    return node.body.accept(this);
  }

  Expression visitInvokeStatic(ir.InvokeStatic node) {
    // Calls are translated to direct style.
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeStatic(node.target, arguments);
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      return new Return(invoke);
    } else {
      assert(cont.hasExactlyOneUse);
      Variable variable = new Variable();
      variables[cont.parameter] = variable;
      return new LetVal(variable, invoke, cont.body.accept(this));
    }
  }

  Expression visitInvokeContinuation(ir.InvokeContinuation node) {
    // TODO(kmillikin): Support non-return continuations.  These could arise
    // due to local control flow or due to inlining or other optimization.
    assert(node.continuation.definition == returnContinuation);
    return new Return(variables[node.argument.definition]);
  }

  Expression visitConstant(ir.Constant node) {
    return new Constant(node.value);
  }

  Expression visitParameter(ir.Parameter node) {
    // Continuation parameters are not visited (continuations themselves are
    // not visited yet).
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }

  Expression visitContinuation(ir.Continuation node) {
    // Until continuations with multiple uses are supported, they are not
    // visited.
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }
}

/**
 * [Emitter] translates Tree to a Dart AST.
 *
 * The AST is handed off to the Dart backend for renaming and to emit Dart
 * code.  Generating an AST is a temporary approach to integrating Tree into
 * the Dart backend.  Ultimately, either Dart code directly will be emitted or
 * the translation will be to a backend-specific Dart AST and not the same
 * one used by the front end.
 *
 * The front end's AST is an unwieldy interface for constructing and generating
 * Dart code.  AST nodes require references to tokens and the tokens will be
 * used by the unparser.  This means that constructing an AST also requires
 * constructing (redundant) tokens.  Unparsing AST nodes also requires a
 * mapping from nodes to elements --- so this mapping must be constructed by
 * the emitter.
 */
class Emitter extends Visitor<ast.Node> {
  ConstantEmitter constantEmitter = new ConstantEmitter();

  // Accumulate a list of variables used, these are hoisted and declared on
  // entry to the function.
  List<ast.Identifier> variables = <ast.Identifier>[];

  // A mapping from nodes to elements, constructed while walking the input
  // tree.
  dart2js.TreeElementMapping treeElements;

  /**
   * Translate the body of a function to an AST FunctionExpression.
   */
  ast.FunctionExpression emit(FunctionElement element,
                              dart2js.TreeElementMapping treeElements,
                              Expression expr) {
    // Reset the variable index.  This function is not reentrant.
    Variable.counter = 0;
    this.treeElements = treeElements;
    ast.Identifier name = new ast.Identifier(
        new StringToken.fromString(IDENTIFIER_INFO, element.name, -1));

    ast.NodeList parameters = new ast.NodeList(
        new BeginGroupToken(OPEN_PAREN_INFO, -1),
        const Link<ast.Node>(),
        new SymbolToken(CLOSE_PAREN_INFO, -1),
        ',');
    ast.Node body = expr.accept(this);

    ast.Identifier modifier =
        new ast.Identifier(new KeywordToken(Keyword.keywords['var'], -1));
    ast.VariableDefinitions definitions = new ast.VariableDefinitions(
        null,
        new ast.Modifiers(new ast.NodeList(
            null,
            new Link<ast.Node>.fromList([modifier]),
            null,
            ' ')),
        new ast.NodeList(
            null,
            new Link<ast.Node>.fromList(variables),
            new SymbolToken(SEMICOLON_INFO, -1),
            ','));
    body = concatenate(definitions, body);
    return new ast.FunctionExpression(name, parameters, body, null,
        ast.Modifiers.EMPTY, null, null);
  }

  static ast.SendSet makeAssignment(ast.Identifier identifier,
                                    ast.Expression expression) {
    return new ast.SendSet(
        null,
        identifier,
        new ast.Operator(new SymbolToken(EQ_INFO, -1)),
        new ast.NodeList.singleton(expression));
  }


  /**
   * Translate a list of arguments to an AST NodeList.
   */
  ast.NodeList makeArgumentList(List<Expression> args) {
    List<ast.Expression> arguments =
        args.map((e) => e.accept(this)).toList(growable: false);
    return new ast.NodeList(
        new BeginGroupToken(OPEN_PAREN_INFO, -1),
        new Link.fromList(arguments),
        new SymbolToken(CLOSE_PAREN_INFO, -1),
        ',');
  }

  /**
   * Concatenate a pair of AST expressions or statements into a single Block
   * statement.
   */
  static ast.Node concatenate(ast.Node first, ast.Node second) {
    // This is a convenient but very inefficient way to accumulate statements.
    // The Block and NodeList nodes are not mutable so we can't simply use a
    // Block or NodeList as an accumulator.  Using a List<Node> requires
    // special casing and extra state to handle the expression/statement
    // distinction.
    // TODO(kmillikin): If we don't get rid of this Emitter, use a more
    // efficient way to accumulate nodes.
    Link<ast.Node> statements;
    if (second is ast.Block) {
      statements = second.statements.nodes;
    } else {
      statements = new Link<ast.Node>();
      if (second is ast.Expression) {
        second = new ast.ExpressionStatement(second,
            new SymbolToken(SEMICOLON_INFO, -1));
      }
      statements = statements.prepend(second);
    }

    if (first is ast.Block) {
      LinkBuilder<ast.Node> front = new LinkBuilder<ast.Node>();
      for (var n in first.statements.nodes) {
        front.addLast(n);
      }
      statements = front.toLink(statements);
    } else {
      if (first is ast.Expression) {
        first = new ast.ExpressionStatement(first,
            new SymbolToken(SEMICOLON_INFO, -1));
      }
      statements = statements.prepend(first);
    }

    return new ast.Block(new ast.NodeList(
        new BeginGroupToken(OPEN_CURLY_BRACKET_INFO, -1),
        statements,
        new SymbolToken(CLOSE_CURLY_BRACKET_INFO, -1)));
  }

  ast.Node visitVariable(Variable node) {
    // The scope of variables is the body of their binding, so a name has
    // already been generated when we visit a variable.
    assert(node.identifier != null);
    return new ast.Send(null, node.identifier);
  }

  ast.Node visitLetVal(LetVal node) {
    // Let bindings translate into assignments.
    ast.Identifier identifier = node.variable.assignIdentifier();
    variables.add(identifier);

    ast.Expression expression = node.definition.accept(this);
    ast.Expression assignment = makeAssignment(identifier, expression);

    ast.Node rest = node.body.accept(this);
    return concatenate(assignment, rest);
  }

  ast.Node visitInvokeStatic(InvokeStatic node) {
    ast.Identifier name = new ast.Identifier(
        new StringToken.fromString(IDENTIFIER_INFO, node.target.name, -1));
    ast.Send send =
        new ast.Send(null, name, makeArgumentList(node.arguments));
    treeElements[send] = node.target;
    return send;
  }

  ast.Node visitReturn(Return node) {
    ast.Expression expression = node.value.accept(this);
    return new ast.Return(
        new KeywordToken(Keyword.keywords['return'], -1),
        new SymbolToken(SEMICOLON_INFO, -1),
        expression);
  }

  ast.Node visitConstant(Constant node) {
    return node.value.accept(constantEmitter);
  }
}

class ConstantEmitter extends dart2js.ConstantVisitor<ast.Expression> {
  ast.Expression unimplemented() => throw new UnimplementedError();

  ast.Expression visitFunction(dart2js.FunctionConstant constant) {
    return unimplemented();
  }

  ast.Expression visitNull(dart2js.NullConstant constant) {
    return new ast.LiteralNull(
        new KeywordToken(Keyword.keywords['null'], -1));
  }

  ast.Expression visitInt(dart2js.IntConstant constant) {
    return new ast.LiteralInt(
        new StringToken.fromString(INT_INFO, constant.value.toString(), -1),
        null);
  }

  ast.Expression visitDouble(dart2js.DoubleConstant constant) {
    return new ast.LiteralDouble(
        new StringToken.fromString(DOUBLE_INFO, constant.value.toString(), -1),
        null);
  }

  ast.Expression visitTrue(dart2js.TrueConstant constant) {
    return new ast.LiteralBool(
        new KeywordToken(Keyword.keywords['true'], -1), null);
  }

  ast.Expression visitFalse(dart2js.FalseConstant constant) {
    return new ast.LiteralBool(
        new KeywordToken(Keyword.keywords['false'], -1), null);
  }

  ast.Expression visitString(dart2js.StringConstant constant) {
    return unimplemented();
  }

  ast.Expression visitList(dart2js.ListConstant constant) {
    return unimplemented();
  }

  ast.Expression visitMap(dart2js.MapConstant constant) {
    return unimplemented();
  }

  ast.Expression visitConstructed(dart2js.ConstructedConstant constant) {
    return unimplemented();
  }

  ast.Expression visitType(dart2js.TypeConstant constant) {
    return unimplemented();
  }

  ast.Expression visitInterceptor(dart2js.InterceptorConstant constant) {
    return unimplemented();
  }

  ast.Expression visitDummy(dart2js.DummyConstant constant) {
    return unimplemented();
  }
}
