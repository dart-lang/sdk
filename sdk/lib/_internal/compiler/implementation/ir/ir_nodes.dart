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

// Trivial is the base class of things that variables can refer to: primitives,
// continuations, function and continuation parameters, etc.
abstract class Trivial extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Variable firstUse = null;
}

// Operands to invocations and primitives are always variables.  They point to
// their definition and are linked into a list of occurrences.
class Variable {
  Trivial definition;
  Variable nextUse = null;
  
  Variable(this.definition) {
    nextUse = definition.firstUse;
    definition.firstUse = this;
  }
}

// Binding a value (primitive or constant): 'let val x = V in E'.  The bound
// value is in scope in the body.
// During one-pass construction a LetVal with an empty body is used to
// represent one-level context 'let val x = V in []'.
class LetVal extends Expression {
  final Trivial value;
  Expression body = null;
  
  LetVal(this.value);
  
  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }
  
  accept(Visitor visitor) => visitor.visitLetVal(this);
}


// Binding a continuation: 'let cont k(v) = E in E'.  The bound continuation is
// in scope in the body and the continuation parameter is in scope in the
// continuation body.
// During one-pass construction a LetCont with an empty continuation body is
// used to represent the one-level context 'let cont k(v) = [] in E'.
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

// Invoke a static function in tail position.
class InvokeStatic extends Expression {
  final FunctionElement target;

  /**
   * The selector encodes how the function is invoked: number of positional
   * arguments, names used in named arguments. This information is required
   * to build the [StaticCallSiteTypeInformation] for the inference graph.
   */
  final Selector selector;

  final Variable continuation;
  final List<Variable> arguments;
  
  InvokeStatic(this.target, this.selector, Continuation cont,
               List<Trivial> args)
      : continuation = new Variable(cont),
        arguments = args.map((t) => new Variable(t)).toList(growable: false) {
    assert(selector.kind == SelectorKind.CALL);
    assert(selector.name == target.name);
  }

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

// Invoke a continuation in tail position.
class InvokeContinuation extends Expression {
  final Variable continuation;
  final Variable argument;
  
  InvokeContinuation(Continuation cont, Trivial arg)
      : continuation = new Variable(cont),
        argument = new Variable(arg);
  
  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

// Constants are values, they are always bound by 'let val'.
class Constant extends Trivial {
  final dart2js.Constant value;
  
  Constant(this.value);
  
  accept(Visitor visitor) => visitor.visitConstant(this);
}

// Function and continuation parameters are trivial.
class Parameter extends Trivial {
  Parameter();
  
  accept(Visitor visitor) => visitor.visitParameter(this);
}

// Continuations are trivial.  They are normally bound by 'let cont'.  A
// continuation with no parameter (or body) is used to represent a function's
// return continuation.
class Continuation extends Trivial {
  final Parameter parameter;
  Expression body = null;
  
  Continuation(this.parameter);
  
  Continuation.retrn() : parameter = null;
  
  accept(Visitor visitor) => visitor.visitContinuation(this);
}

// A function definition, consisting of parameters and a body.  The parameters
// include a distinguished continuation parameter.
class Function extends Expression {
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
  T visitNode(Node node) => node.accept(this);
  
  T visitFunction(Function node) => visitNode(node);
  T visitExpression(Expression node) => visitNode(node);
  T visitTrivial(Trivial node) => visitNode(node);
  
  T visitLetVal(LetVal expr) => visitExpression(expr);
  T visitLetCont(LetCont expr) => visitExpression(expr);
  T visitInvokeStatic(InvokeStatic expr) => visitExpression(expr);
  T visitInvokeContinuation(InvokeContinuation expr) => visitExpression(expr);
  
  T visitConstant(Constant triv) => visitTrivial(triv);
  T visitParameter(Parameter triv) => visitTrivial(triv);
  T visitContinuation(Continuation triv) => visitTrivial(triv);
}
