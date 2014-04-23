// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_tree;

import '../dart2jslib.dart' as dart2js;
import '../dart_types.dart';
import '../util/util.dart';
import '../elements/elements.dart'
    show Element, FunctionElement, FunctionSignature, ParameterElement;
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
abstract class Expression extends Node {
  bool get isPure;
}

/**
 * Variables are [Expression]s.
 */
class Variable extends Expression {
  // A counter used to generate names.  The counter is reset to 0 for each
  // function emitted.
  static int counter = 0;
  static String _newName() => 'v${counter++}';

  final Element element;
  String name;
  ast.Identifier identifier;

  Variable(this.element);

  ast.Identifier assignIdentifier() {
    assert(identifier == null);
    name = (element == null) ? _newName() : element.name;
    identifier = Emitter.makeIdentifier(name);
    return identifier;
  }

  final bool isPure = true;

  accept(Visitor visitor) => visitor.visitVariable(this);
}

/**
 * A sequence of expressions.
 */
class Sequence extends Expression {
  final List<Expression> expressions;

  Sequence(this.expressions);

  bool get isPure => expressions.every((e) => e.isPure);

  accept(Visitor visitor) => visitor.visitSequence(this);
}

/**
 * A local binding of a [Variable] to an [Expression].
 *
 * In contrast to the CPS-based IR, non-primitive expressions can be named
 * with let.
 */
class LetVal extends Expression {
  final Variable variable;
  Expression definition;
  Expression body;
  final bool hasExactlyOneUse;

  LetVal(this.variable, this.definition, this.body, this.hasExactlyOneUse);

  bool get isPure => definition.isPure && body.isPure;

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

  final bool isPure = false;

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Expression {
  Expression value;

  Return(this.value);

  final bool isPure = true;

  accept(Visitor visitor) => visitor.visitReturn(this);
}

/**
 * A constant.
 */
class Constant extends Expression {
  final dart2js.Constant value;

  Constant(this.value);

  final bool isPure = true;

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class FunctionDefinition extends Node {
  final List<Variable> parameters;
  Expression body;

  FunctionDefinition(this.parameters, this.body);

  accept(Visitor visitor) => visitor.visitFunctionDefinition(this);
}

abstract class Visitor<T> {
  T visit(Node node) => node.accept(this);

  // Abstract classes.
  T visitNode(Node node) => null;
  T visitFunctionDefinition(FunctionDefinition node) => visitNode(node);
  T visitExpression(Expression node) => visitNode(node);

  // Concrete classes.
  T visitVariable(Variable node) => visitExpression(node);
  T visitSequence(Sequence node) => visitExpression(node);
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

  FunctionDefinition function;
  ir.Continuation returnContinuation;

  Builder(this.compiler);

  FunctionDefinition build(ir.FunctionDefinition node) {
    visit(node);
    return function;
  }

  List<Expression> translateArguments(List<ir.Reference> args) {
    return new List.generate(args.length,
         (int index) => variables[args[index].definition]);
  }

  Expression visitFunctionDefinition(ir.FunctionDefinition node) {
    returnContinuation = node.returnContinuation;
    List<Variable> parameters = <Variable>[];
    for (ir.Parameter p in node.parameters) {
      Variable parameter = new Variable(p.element);
      parameters.add(parameter);
      variables[p] = parameter;
    }
    function = new FunctionDefinition(parameters, visit(node.body));
    return null;
  }

  Expression visitLetPrim(ir.LetPrim node) {
    // LetPrim is translated to LetVal.
    Expression definition = visit(node.primitive);
    if (node.primitive.hasAtLeastOneUse) {
      Variable variable = new Variable(null);
      variables[node.primitive] = variable;
      return new LetVal(variable, definition, node.body.accept(this),
          node.primitive.hasExactlyOneUse);
    } else if (node.primitive is ir.Constant) {
      // TODO(kmillikin): Implement more systematic treatment of pure CPS
      // values (e.g., as part of a shrinking reductions pass).
      return visit(node.body);
    } else {
      return new Sequence([definition, visit(node.body)]);
    }
  }

  Expression visitLetCont(ir.LetCont node) {
    // TODO(kmillikin): Allow continuations to have multiple uses.  This could
    // arise due to the representation of local control flow or due to
    // optimization.
    assert(node.continuation.hasAtMostOneUse);
    return visit(node.body);
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
      assert(cont.parameters.length == 1);
      ir.Parameter parameter = cont.parameters[0];
      if (parameter.hasAtLeastOneUse) {
        Variable variable = new Variable(null);
        variables[parameter] = variable;
        return new LetVal(variable, invoke, cont.body.accept(this),
            parameter.hasExactlyOneUse);
      } else {
        return new Sequence([invoke, visit(cont.body)]);
      }
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
 * Unnamer propagates single-use definitions to their use site when possible.
 *
 * After translating out of CPS, all intermediate values are bound by [LetVal].
 * This transformation propagates such definitions to their uses when it is
 * safe and profitable.  Bindings are processed "on demand" when their uses are
 * seen, but are only processed once to keep this transformation linear in
 * the size of the tree.
 *
 * The transformation builds an environment containing [LetVal] bindings that
 * are in scope.  These bindings have yet-untranslated definitions.  When a use
 * is encountered the transformation determines if it is safe and profitable
 * to propagate the definition to its use.  If so, it is removed from the
 * environment and the definition is recursively processed (in the
 * new environment at the use site) before being propagated.
 *
 * See [visitVariable] for the implementation of the heuristic for propagating
 * a definition.
 */
class Unnamer extends Visitor<Expression> {
  // The binding environment.  The rightmost element of the list is the nearest
  // enclosing binding.
  List<LetVal> environment;

  void unname(FunctionDefinition definition) {
    environment = <LetVal>[];
    definition.body = visit(definition.body);

    // TODO(kmillikin):  Allow definitions that are not propagated.  Here,
    // this means rebuilding the binding with a recursively unnamed definition,
    // or else introducing a variable definition and an assignment.
    assert(environment.isEmpty);
  }

  Expression visitVariable(Variable node) {
    // Propagate a variable's definition to its use site if:
    // 1.  It has a single use, to avoid code growth and potential duplication
    //     of side effects, AND
    // 2a. It is pure (i.e., does not have side effects that prevent it from
    //     being moved), OR
    // 2b. There are only pure expressions between the definition and use.

    // TODO(kmillikin): It's not always beneficial to propagate pure
    // definitions---it can prevent propagation of their inputs.  Implement
    // a heuristic to avoid this.

    // TODO(kmillikin): Replace linear search with something faster in
    // practice.
    bool seenImpure = false;
    for (int i = environment.length - 1; i >= 0; --i) {
      if (environment[i].variable == node) {
        if ((!seenImpure || environment[i].definition.isPure)
            && environment[i].hasExactlyOneUse) {
          // Use the definition if it is pure or if it is the first impure
          // definition (i.e., propagating past only pure expressions).
          return visit(environment.removeAt(i).definition);
        }
        break;
      } else if (!environment[i].definition.isPure) {
        // Once the first impure definition is seen, impure definitions should
        // no longer be propagated.  Continue searching for a pure definition.
        seenImpure = true;
      }
    }
    // If the definition could not be propagated, leave the variable use.
    return node;
  }

  Expression visitSequence(Sequence node) {
    for (int i = 0; i < node.expressions.length; ++i) {
      node.expressions[i] = visit(node.expressions[i]);
    }
    return node;
  }

  Expression visitLetVal(LetVal node) {
    environment.add(node);
    Expression body = visit(node.body);

    if (!environment.isEmpty && environment.last == node) {
      // The definition could not be propagated.  Residualize the let binding.
      node.body = body;
      environment.removeLast();
      node.definition = visit(node.definition);
      return node;
    }
    assert(!environment.contains(node));
    return body;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visit(node.arguments[i]);
    }
    return node;
  }

  Expression visitReturn(Return node) {
    node.value = visit(node.value);
    return node;
  }

  visitConstant(Constant node) {
    return node;
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

  // Tokens needed in the AST.
  final Token openParen = new BeginGroupToken(OPEN_PAREN_INFO, -1);
  final Token closeParen = new SymbolToken(CLOSE_PAREN_INFO, -1);
  final Token openBrace = new BeginGroupToken(OPEN_CURLY_BRACKET_INFO, -1);
  final Token closeBrace = new SymbolToken(CLOSE_CURLY_BRACKET_INFO, -1);
  final Token semicolon = new SymbolToken(SEMICOLON_INFO, -1);

  // Helper methods to construct ASTs.
  static ast.Identifier makeIdentifier(String name) {
    return new ast.Identifier(
        new StringToken.fromString(IDENTIFIER_INFO, name, -1));
  }

  ast.NodeList makeArgumentList(List<ast.Node> arguments) {
    return new ast.NodeList(openParen,
                            new Link<ast.Node>.fromList(arguments),
                            closeParen,
                            ',');
  }

  ast.Block makeBlock(List<ast.Node> statements) {
    return new ast.Block(new ast.NodeList(
        openBrace, new Link<ast.Node>.fromList(statements), closeBrace));
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
   * Translate the body of a function to an AST FunctionExpression.
   */
  ast.FunctionExpression emit(FunctionElement element,
                              dart2js.TreeElementMapping treeElements,
                              FunctionDefinition definition) {
    // Reset the variable index.  This function is not reentrant.
    Variable.counter = 0;
    this.treeElements = treeElements;
    ast.Identifier name = makeIdentifier(element.name);

    TypeEmitter typeEmitter = new TypeEmitter();
    FunctionSignature signature = element.functionSignature;
    ast.TypeAnnotation returnType;
    if (!signature.type.returnType.isDynamic) {
      returnType = typeEmitter.visit(signature.type.returnType, treeElements);
    }

    List<ast.VariableDefinitions> parameterList = <ast.VariableDefinitions>[];
    for (Variable parameter in definition.parameters) {
      ParameterElement element = parameter.element;
      parameter.assignIdentifier();
      ast.TypeAnnotation type;
      if (!element.type.isDynamic) {
        type = typeEmitter.visit(element.type, treeElements);
      }
      parameterList.add(new ast.VariableDefinitions(
          type,
          ast.Modifiers.EMPTY,
          new ast.NodeList.singleton(parameter.identifier)));
    }
    ast.NodeList parameters =
        new ast.NodeList(openParen,
                         new Link<ast.Node>.fromList(parameterList),
                         closeParen,
                         ',');

    ast.Node body = visit(definition.body);

    if (!variables.isEmpty) {
      // Introduce hoisted definitions for all variables.
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
              semicolon,
              ','));
      body = concatenate(definitions, body);
    }

    if (body is ast.Return) {
      // Use a short form for bodies that are a single return.
      ast.Expression value = (body as ast.Return).expression;
      if (value is ast.LiteralNull) {
        // '{ return null; }' is '{}'.
        body = makeBlock([]);
      } else {
        // '{ return e; }' is '=> e;'.
        body = new ast.Return(new SymbolToken(FUNCTION_INFO, -1),
                              semicolon,
                              value);
      }
    } else if (body is ast.Block) {
      // Remove a final 'return null' that ends the body block.
      Link<ast.Node> nodes = (body as ast.Block).statements.nodes;
      ast.Node last;
      for (ast.Node n in nodes) {
        last = n;
      }
      if (last is ast.Return
          && (last as ast.Return).expression is ast.LiteralNull) {
        List<ast.Node> statements =
            (body as ast.Block).statements.nodes.toList();
        statements.removeLast();
        body = makeBlock(statements);
      }
    }

    return new ast.FunctionExpression(name, parameters, body, returnType,
        ast.Modifiers.EMPTY, null, null);
  }

  /**
   * Translate a list of arguments to an AST NodeList.
   */
  ast.NodeList translateArguments(List<Expression> args) {
    List<ast.Expression> arguments = args.map(visit).toList(growable: false);
    return makeArgumentList(arguments);
  }

  /**
   * Concatenate a pair of AST expressions or statements into a single Block
   * statement.
   */
  ast.Node concatenate(ast.Node first, ast.Node second) {
    // This is a convenient but very inefficient way to accumulate statements.
    // The Block and NodeList nodes are not mutable so we can't simply use a
    // Block or NodeList as an accumulator.  Using a List<Node> requires
    // special casing and extra state to handle the expression/statement
    // distinction.
    // TODO(kmillikin): If we don't get rid of this Emitter, use a more
    // efficient way to accumulate nodes.
    LinkBuilder<ast.Node> statements = new LinkBuilder<ast.Node>();

    addStatements(ast.Node node) {
      if (node is ast.Block) {
        for (ast.Node n in node.statements.nodes) {
          statements.addLast(n);
        }
      } else if (node is ast.Expression) {
          statements.addLast(new ast.ExpressionStatement(node, semicolon));
      } else {
        statements.addLast(node);
      }
    }

    addStatements(first);
    addStatements(second);

    return new ast.Block(
        new ast.NodeList(openBrace, statements.toLink(), closeBrace));
  }

  ast.Node visitVariable(Variable node) {
    // The scope of variables is the body of their binding, so a name has
    // already been generated when we visit a variable.
    assert(node.identifier != null);
    return new ast.Send(null, node.identifier);
  }

  ast.Node visitSequence(Sequence node) {
    return node.expressions.map(visit).reduce(concatenate);
  }

  ast.Node visitLetVal(LetVal node) {
    // Let bindings translate into assignments.
    ast.Identifier identifier = node.variable.assignIdentifier();
    variables.add(identifier);

    ast.Expression expression = visit(node.definition);
    ast.Expression assignment = makeAssignment(identifier, expression);

    ast.Node rest = visit(node.body);
    return concatenate(assignment, rest);
  }

  ast.Node visitInvokeStatic(InvokeStatic node) {
    ast.Identifier name = makeIdentifier(node.target.name);
    ast.Send send =
        new ast.Send(null, name, translateArguments(node.arguments));
    treeElements[send] = node.target;
    return send;
  }

  ast.Node visitReturn(Return node) {
    ast.Expression expression = visit(node.value);
    return new ast.Return(
        new KeywordToken(Keyword.keywords['return'], -1),
        semicolon,
        expression);
  }

  ast.Node visitConstant(Constant node) {
    return node.value.accept(constantEmitter);
  }
}

class TypeEmitter extends
    DartTypeVisitor<ast.TypeAnnotation, dart2js.TreeElementMapping> {

  // Supported types are verified at IR construction time.  The unimplemented
  // emit methods should be unreachable.
  ast.TypeAnnotation unimplemented() => throw new UnimplementedError();

  ast.TypeAnnotation makeSimpleAnnotation(
      DartType type,
      dart2js.TreeElementMapping treeElements) {
    ast.TypeAnnotation annotation =
        new ast.TypeAnnotation(Emitter.makeIdentifier(type.toString()), null);
    treeElements.setType(annotation, type);
    return annotation;
  }

  ast.TypeAnnotation visit(DartType type,
                           dart2js.TreeElementMapping treeElements) {
    return type.accept(this, treeElements);
  }

  ast.TypeAnnotation visitType(DartType type,
                               dart2js.TreeElementMapping treeElements) {
    return unimplemented();
  }

  ast.TypeAnnotation visitVoidType(VoidType type,
                                   dart2js.TreeElementMapping treeElements) {
    return makeSimpleAnnotation(type, treeElements);
  }

  ast.TypeAnnotation visitInterfaceType(
      InterfaceType type,
      dart2js.TreeElementMapping treeElements) {
    assert(!type.isGeneric);
    return makeSimpleAnnotation(type, treeElements);
  }

  ast.TypeAnnotation visitTypedefType(
      TypedefType type,
      dart2js.TreeElementMapping treeElements) {
    assert(!type.isGeneric);
    return makeSimpleAnnotation(type, treeElements);
  }

  ast.TypeAnnotation visitDynamicType(
      DynamicType type,
      dart2js.TreeElementMapping treeElements) {
    return unimplemented();
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
