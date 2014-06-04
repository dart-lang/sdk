// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' as dart2js show Constant;
import '../elements/elements.dart'
    show FunctionElement, LibraryElement, ParameterElement, ClassElement;
import '../universe/universe.dart' show Selector, SelectorKind;
import '../dart_types.dart' show DartType, GenericType;

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
  bool get hasAtLeastOneUse => firstRef != null;
  bool get hasMultipleUses => !hasAtMostOneUse;

  void substituteFor(Definition other) {
    if (other.firstRef == null) return;
    Reference previous, current = other.firstRef;
    do {
      current.definition = this;
      previous = current;
      current = current.nextRef;
    } while (current != null);
    previous.nextRef = firstRef;
    firstRef = other.firstRef;
  }
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

abstract class Invoke {
  Selector get selector;
  List<Reference> get arguments;
}

/// Invoke a static function in tail position.
class InvokeStatic extends Expression implements Invoke {
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
        arguments = _referenceList(args) {
    assert(selector.kind == SelectorKind.CALL);
    assert(selector.name == target.name);
  }

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/// Invoke a method, operator, getter, setter, or index getter/setter in
/// tail position.
class InvokeMethod extends Expression implements Invoke {
  final Reference receiver;
  final Selector selector;
  final Reference continuation;
  final List<Reference> arguments;

  InvokeMethod(Definition receiver,
               this.selector,
               Continuation cont,
               List<Definition> args)
      : receiver = new Reference(receiver),
        continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(selector != null);
    assert(selector.kind == SelectorKind.CALL ||
           selector.kind == SelectorKind.OPERATOR ||
           (selector.kind == SelectorKind.GETTER && arguments.isEmpty) ||
           (selector.kind == SelectorKind.SETTER && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 1) ||
           (selector.kind == SelectorKind.INDEX && arguments.length == 2));
  }

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);
}

/// Non-const call to a constructor. The [target] may be a generative
/// constructor, factory, or redirecting factory.
class InvokeConstructor extends Expression implements Invoke {
  final GenericType type;
  final FunctionElement target;
  final Reference continuation;
  final List<Reference> arguments;
  final Selector selector;

  /// The class being instantiated. This is the same as `target.enclosingClass`
  /// and `type.element`.
  ClassElement get targetClass => target.enclosingElement;

  /// True if this is an invocation of a factory constructor.
  bool get isFactory => target.isFactoryConstructor;

  InvokeConstructor(this.type,
                    this.target,
                    this.selector,
                    Continuation cont,
                    List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args) {
    assert(target.isConstructor);
    assert(type.element == target.enclosingElement);
  }

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

class InvokeConstConstructor extends Primitive {
  final GenericType type;
  final FunctionElement constructor;
  final List<Reference> arguments;
  final Selector selector;

  /// The class being instantiated. This is the same as `target.enclosingClass`
  /// and `type.element`.
  ClassElement get targetClass => constructor.enclosingElement;

  /// True if this is an invocation of a factory constructor.
  bool get isFactory => constructor.isFactoryConstructor;

  InvokeConstConstructor(this.type,
                    this.constructor,
                    this.selector,
                    List<Definition> args)
      : arguments = _referenceList(args) {
    assert(constructor.isConstructor);
    assert(type.element == constructor.enclosingElement);
  }

  accept(Visitor visitor) => visitor.visitInvokeConstConstructor(this);
}

/// Invoke [toString] on each argument and concatenate the results.
class ConcatenateStrings extends Expression {
  final Reference continuation;
  final List<Reference> arguments;

  ConcatenateStrings(Continuation cont, List<Definition> args)
      : continuation = new Reference(cont),
        arguments = _referenceList(args);

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/// Invoke a continuation in tail position.
class InvokeContinuation extends Expression {
  final Reference continuation;
  final List<Reference> arguments;

  // An invocation of a continuation is recursive if it occurs in the body of
  // the continuation itself.
  bool isRecursive;

  InvokeContinuation(Continuation cont, List<Definition> args,
                     {recursive: false})
      : continuation = new Reference(cont),
        arguments = _referenceList(args),
        isRecursive = recursive {
    if (recursive) cont.isRecursive = true;
  }

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

/// The base class of things which can be tested and branched on.
abstract class Condition extends Node {
}

class IsTrue extends Condition {
  final Reference value;

  IsTrue(Definition val) : value = new Reference(val);

  accept(Visitor visitor) => visitor.visitIsTrue(this);
}

/// Choose between a pair of continuations based on a condition value.
class Branch extends Expression {
  final Condition condition;
  final Reference trueContinuation;
  final Reference falseContinuation;

  Branch(this.condition, Continuation trueCont, Continuation falseCont)
      : trueContinuation = new Reference(trueCont),
        falseContinuation = new Reference(falseCont);

  accept(Visitor visitor) => visitor.visitBranch(this);
}

class Constant extends Primitive {
  final dart2js.Constant value;

  Constant(this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class LiteralList extends Primitive {
  List<Reference> values;

  LiteralList(List<Primitive> values)
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMap extends Primitive {
  List<Reference> keys;
  List<Reference> values;

  LiteralMap(List<Primitive> keys, List<Primitive> values)
      : this.keys = _referenceList(keys),
        this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralMap(this);
}

class Parameter extends Primitive {
  final ParameterElement element;

  Parameter(this.element);

  accept(Visitor visitor) => visitor.visitParameter(this);
}

/// Continuations are normally bound by 'let cont'.  A continuation with no
/// parameter (or body) is used to represent a function's return continuation.
/// The return continuation is bound by the Function, not by 'let cont'.
class Continuation extends Definition {
  final List<Parameter> parameters;
  Expression body = null;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive = false;

  Continuation(this.parameters);

  Continuation.retrn() : parameters = null;

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

/// A function definition, consisting of parameters and a body.  The parameters
/// include a distinguished continuation parameter.
class FunctionDefinition extends Node {
  final Continuation returnContinuation;
  final List<Parameter> parameters;
  final Expression body;

  FunctionDefinition(this.returnContinuation, this.parameters, this.body);

  accept(Visitor visitor) => visitor.visitFunctionDefinition(this);
}

List<Reference> _referenceList(List<Definition> definitions) {
  return definitions.map((e) => new Reference(e)).toList(growable: false);
}

abstract class Visitor<T> {
  T visit(Node node) => node.accept(this);
  // Abstract classes.
  T visitNode(Node node) => null;
  T visitExpression(Expression node) => visitNode(node);
  T visitDefinition(Definition node) => visitNode(node);
  T visitPrimitive(Primitive node) => visitDefinition(node);
  T visitCondition(Condition node) => visitNode(node);

  // Concrete classes.
  T visitFunctionDefinition(FunctionDefinition node) => visitNode(node);

  // Expressions.
  T visitLetPrim(LetPrim node) => visitExpression(node);
  T visitLetCont(LetCont node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
  T visitInvokeContinuation(InvokeContinuation node) => visitExpression(node);
  T visitInvokeMethod(InvokeMethod node) => visitExpression(node);
  T visitInvokeConstructor(InvokeConstructor node) => visitExpression(node);
  T visitConcatenateStrings(ConcatenateStrings node) => visitExpression(node);
  T visitBranch(Branch node) => visitExpression(node);

  // Definitions.
  T visitLiteralList(LiteralList node) => visitPrimitive(node);
  T visitLiteralMap(LiteralMap node) => visitPrimitive(node);
  T visitConstant(Constant node) => visitPrimitive(node);
  T visitInvokeConstConstructor(InvokeConstConstructor node) => visitPrimitive(node);
  T visitParameter(Parameter node) => visitPrimitive(node);
  T visitContinuation(Continuation node) => visitDefinition(node);

  // Conditions.
  T visitIsTrue(IsTrue node) => visitCondition(node);
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

  String visitFunctionDefinition(FunctionDefinition node) {
    names[node.returnContinuation] = 'return';
    String parameters = node.parameters
        .map((p) {
          String name = p.element.name;
          names[p] = name;
          return name;
        })
        .join(' ');
    return '(FunctionDefinition ($parameters return) ${visit(node.body)})';
  }

  String visitLetPrim(LetPrim node) {
    String name = newValueName();
    names[node.primitive] = name;
    String value = visit(node.primitive);
    String body = visit(node.body);
    return '(LetPrim $name $value) $body';
  }

  String visitLetCont(LetCont node) {
    String cont = newContinuationName();
    names[node.continuation] = cont;
    String parameters = node.continuation.parameters
        .map((p) {
          String name = newValueName();
          names[p] = name;
          return ' $name';
        })
       .join('');
    String contBody = visit(node.continuation.body);
    String body = visit(node.body);
    String op = node.continuation.isRecursive ? 'LetCont*' : 'LetCont';
    return '($op ($cont$parameters) $contBody) $body';
  }

  String formatArguments(Invoke node) {
    int positionalArgumentCount = node.selector.positionalArgumentCount;
    List<String> args = new List<String>();
    args.addAll(node.arguments.getRange(0, positionalArgumentCount)
        .map((v) => names[v.definition]));
    for (int i = 0; i < node.selector.namedArgumentCount; ++i) {
      String name = node.selector.namedArguments[i];
      Definition arg = node.arguments[positionalArgumentCount + i].definition;
      args.add("($name: $arg)");
    }
    return args.join(' ');
  }

  String visitInvokeStatic(InvokeStatic node) {
    String name = node.target.name;
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '(InvokeStatic $name $args $cont)';
  }

  String visitInvokeMethod(InvokeMethod node) {
    String name = node.selector.name;
    String rcv = names[node.receiver.definition];
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '(InvokeMethod $rcv $name $args $cont)';
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${node.type}';
    } else {
      callName = '${node.type}.${node.target.name}';
    }
    String cont = names[node.continuation.definition];
    String args = formatArguments(node);
    return '(InvokeConstructor $callName $args $cont)';
  }

  String visitConcatenateStrings(ConcatenateStrings node) {
    String cont = names[node.continuation.definition];
    String args = node.arguments.map((v) => names[v.definition]).join(' ');
    return '(ConcatenateStrings $args $cont)';
  }

  String visitInvokeContinuation(InvokeContinuation node) {
    String cont = names[node.continuation.definition];
    String args = node.arguments.map((v) => names[v.definition]).join(' ');
    String op =
        node.isRecursive ? 'InvokeContinuation*' : 'InvokeContinuation';
    return '($op $cont $args)';
  }

  String visitBranch(Branch node) {
    String condition = visit(node.condition);
    String trueCont = names[node.trueContinuation.definition];
    String falseCont = names[node.falseContinuation.definition];
    return '(Branch $condition $trueCont $falseCont)';
  }

  String visitConstant(Constant node) {
    return '(Constant ${node.value})';
  }

  String visitParameter(Parameter node) {
    // Parameters are visited directly in visitLetCont.
    return '(Unexpected Parameter)';
  }

  String visitContinuation(Continuation node) {
    // Continuations are visited directly in visitLetCont.
    return '(Unexpected Continuation)';
  }

  String visitIsTrue(IsTrue node) {
    String value = names[node.value.definition];
    return '(IsTrue $value)';
  }
}
