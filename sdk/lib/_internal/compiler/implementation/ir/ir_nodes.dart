// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' as dart2js show Constant;
import '../elements/elements.dart' show FunctionElement, LibraryElement;
import 'ir_pickler.dart' show Pickler, IrConstantPool;
import '../universe/universe.dart' show Selector, SelectorKind;
import '../util/util.dart' show Spannable;

abstract class Node {
  static int hashCount = 0;
  final int hashCode = hashCount = (hashCount + 1) & 0x3fffffff;

  accept(Visitor visitor);
}

abstract class Expression extends Node {
  Expression plug(Expression expr) => throw 'impossible';
}

/// The base class of things that variables can refer to: primitives,
/// continuations, function and continuation parameters, etc.
abstract class Definition extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Reference firstRef = null;

  bool get hasAtMostOneUse => firstRef == null || firstRef.nextRef == null;
  bool get hasExactlyOneUse => firstRef != null && firstRef.nextRef == null;
}

abstract class Primitive extends Definition {
}

/// Operands to invocations and primitives are always variables.  They point to
/// their definition and are linked into a list of occurrences.
class Reference {
  Definition definition;
  Reference nextRef = null;

  Reference(this.definition) {
    nextRef = definition.firstRef;
    definition.firstRef = this;
  }
}

/// Binding a value (primitive or constant): 'let val x = V in E'.  The bound
/// value is in scope in the body.
/// During one-pass construction a LetVal with an empty body is used to
/// represent one-level context 'let val x = V in []'.
class LetPrim extends Expression {
  final Primitive primitive;
  Expression body = null;

  LetPrim(this.primitive);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetPrim(this);
}


/// Binding a continuation: 'let cont k(v) = E in E'.  The bound continuation
/// is in scope in the body and the continuation parameter is in scope in the
/// continuation body.
/// During one-pass construction a LetCont with an empty continuation body is
/// used to represent the one-level context 'let cont k(v) = [] in E'.
class LetCont extends Expression {
  final Continuation continuation;
  final Expression body;

  LetCont(this.continuation, this.body);

  Expression plug(Expression expr) {
    assert(continuation.body == null);
    return continuation.body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetCont(this);
}

/// Invoke a static function in tail position.
class InvokeStatic extends Expression {
  final FunctionElement target;

  /**
   * The selector encodes how the function is invoked: number of positional
   * arguments, names used in named arguments. This information is required
   * to build the [StaticCallSiteTypeInformation] for the inference graph.
   */
  final Selector selector;

  final Reference continuation;
  final List<Reference> arguments;

  InvokeStatic(this.target, this.selector, Continuation cont,
               List<Definition> args)
      : continuation = new Reference(cont),
        arguments = args.map((t) => new Reference(t)).toList(growable: false) {
    assert(selector.kind == SelectorKind.CALL);
    assert(selector.name == target.name);
  }

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/// Invoke a continuation in tail position.
class InvokeContinuation extends Expression {
  final Reference continuation;
  final Reference argument;

  InvokeContinuation(Continuation cont, Definition arg)
      : continuation = new Reference(cont),
        argument = new Reference(arg);

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

class Constant extends Primitive {
  final dart2js.Constant value;

  Constant(this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class Parameter extends Primitive {
  Parameter();

  accept(Visitor visitor) => visitor.visitParameter(this);
}

/// Continuations are normally bound by 'let cont'.  A continuation with no
/// parameter (or body) is used to represent a function's return continuation.
/// The return continuation is bound by the Function, not by 'let cont'.
class Continuation extends Definition {
  final Parameter parameter;
  Expression body = null;

  Continuation(this.parameter);

  Continuation.retrn() : parameter = null;

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

/// A function definition, consisting of parameters and a body.  The parameters
/// include a distinguished continuation parameter.
class Function extends Node {
  final int endOffset;
  final int namePosition;

  final Continuation returnContinuation;
  final Expression body;

  Function(this.endOffset, this.namePosition, this.returnContinuation,
           this.body);

  List<int> pickle(IrConstantPool constantPool) {
    return new Pickler(constantPool).pickle(this);
  }

  accept(Visitor visitor) => visitor.visitFunction(this);
}

abstract class Visitor<T> {
  // Abstract classes.
  T visitNode(Node node) => node.accept(this);
  T visitExpression(Expression node) => visitNode(node);
  T visitDefinition(Definition node) => visitNode(node);
  T visitPrimitive(Primitive node) => visitDefinition(node);

  // Concrete classes.
  T visitFunction(Function node) => visitNode(node);

  T visitLetPrim(LetPrim node) => visitExpression(node);
  T visitLetCont(LetCont node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
  T visitInvokeContinuation(InvokeContinuation node) => visitExpression(node);

  T visitConstant(Constant node) => visitPrimitive(node);
  T visitParameter(Parameter node) => visitPrimitive(node);
  T visitContinuation(Continuation node) => visitDefinition(node);
}

/// Generate a Lisp-like S-expression representation of an IR node as a string.
/// The representation is not pretty-printed, but it can easily be quoted and
/// dropped into the REPL of one's favorite Lisp or Scheme implementation to be
/// pretty-printed.
class SExpressionStringifier extends Visitor<String> {
  final Map<Definition, String> names = <Definition, String>{};

  int _valueCounter = 0;
  int _continuationCounter = 0;

  String newValueName() => 'v${_valueCounter++}';
  String newContinuationName() => 'k${_continuationCounter++}';

  String visitFunction(Function node) {
    names[node.returnContinuation] = 'return';
    return '(Function ${node.body.accept(this)})';
  }

  String visitLetPrim(LetPrim expr) {
    String name = newValueName();
    names[expr.primitive] = name;
    String value = expr.primitive.accept(this);
    String body = expr.body.accept(this);
    return '(LetPrim $name $value) $body';
  }

  String visitLetCont(LetCont expr) {
    String cont = newContinuationName();
    String param = newValueName();
    names[expr.continuation] = cont;
    names[expr.continuation.parameter] = param;
    String contBody = expr.continuation.body.accept(this);
    String body = expr.body == null ? 'null' : expr.body.accept(this);
    return '(LetCont ($cont $param) $contBody) $body';
  }

  String visitInvokeStatic(InvokeStatic expr) {
    String name = expr.target.name;
    String cont = names[expr.continuation.definition];
    List<String> args =
        expr.arguments.map((v) => names[v.definition]).toList(growable: false);
    return '(InvokeStatic $name $cont ${args.join(' ')})';
  }

  String visitInvokeContinuation(InvokeContinuation expr) {
    String cont = names[expr.continuation.definition];
    String arg = names[expr.argument.definition];
    return '(InvokeContinuation $cont $arg)';
  }

  String visitConstant(Constant triv) {
    return '(Constant ${triv.value})';
  }

  String visitParameter(Parameter triv) {
    // Parameters are visited directly in visitLetCont.
    return '(Unexpected Parameter)';
  }

  String visitContinuation(Continuation triv) {
    // Continuations are visited directly in visitLetCont.
    return '(Unexpected Continuation)';
  }
}
