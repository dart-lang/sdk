// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.eval;

import 'dart:async';
import 'dart:collection';

@MirrorsUsed(metaTargets: const [Reflectable, ObservableProperty],
    override: 'polymer_expressions.eval')
import 'dart:mirrors';

import 'package:observe/observe.dart';

import 'async.dart';
import 'expression.dart';
import 'filter.dart';
import 'visitor.dart';
import 'src/mirrors.dart';

final _BINARY_OPERATORS = {
  '+':  (a, b) => a + b,
  '-':  (a, b) => a - b,
  '*':  (a, b) => a * b,
  '/':  (a, b) => a / b,
  '==': (a, b) => a == b,
  '!=': (a, b) => a != b,
  '>':  (a, b) => a > b,
  '>=': (a, b) => a >= b,
  '<':  (a, b) => a < b,
  '<=': (a, b) => a <= b,
  '||': (a, b) => a || b,
  '&&': (a, b) => a && b,
  '|':  (a, f) {
    if (f is Transformer) return f.forward(a);
    if (f is Filter) return f(a);
    throw new EvalException("Filters must be a one-argument function.");
  }
};

final _UNARY_OPERATORS = {
  '+': (a) => a,
  '-': (a) => -a,
  '!': (a) => !a,
};

final _BOOLEAN_OPERATORS = ['!', '||', '&&'];

/**
 * Evaluation [expr] in the context of [scope].
 */
Object eval(Expression expr, Scope scope) {
  var observer = observe(expr, scope);
  new Updater(scope).visit(observer);
  return observer._value;
}

/**
 * Returns an [ExpressionObserver] that evaluates [expr] in the context of
 * scope] and listens for any changes on [Observable] values that are
 * returned from sub-expressions. When a value changes the expression is
 * reevaluated and the new result is sent to the [onUpdate] stream of the
 * [ExpressionObsserver].
 */
ExpressionObserver observe(Expression expr, Scope scope) {
  var observer = new ObserverBuilder(scope).visit(expr);
  return observer;
}

/**
 * Causes [expr] to be reevaluated a returns it's value.
 */
Object update(ExpressionObserver expr, Scope scope) {
  new Updater(scope).visit(expr);
  return expr.currentValue;
}

/**
 * Assign [value] to the variable or field referenced by [expr] in the context
 * of [scope].
 *
 * [expr] must be an /assignable/ expression, it must not contain
 * operators or function invocations, and any index operations must use a
 * literal index.
 */
void assign(Expression expr, Object value, Scope scope) {

  notAssignable() =>
      throw new EvalException("Expression is not assignable: $expr");

  Expression expression;
  var property;
  bool isIndex = false;
  var filters = <Expression>[]; // reversed order for assignment

  while (expr is BinaryOperator) {
    BinaryOperator op = expr;
    if (op.operator != '|') {
      break;
    }
    filters.add(op.right);
    expr = op.left;
  }

  if (expr is Identifier) {
    expression = empty();
    Identifier ident = expr;
    property = ident.value;
  } else if (expr is Index) {
    if (expr.argument is! Literal) notAssignable();
    expression = expr.receiver;
    Literal l = expr.argument;
    property = l.value;
    isIndex = true;
  } else if (expr is Getter) {
    expression = expr.receiver;
    property = expr.name;
  } else if (expr is Invoke) {
    expression = expr.receiver;
    if (expr.method != null) {
      if (expr.arguments != null) notAssignable();
      property = expr.method;
    } else {
      notAssignable();
    }
  } else {
    notAssignable();
  }

  // transform the values backwards through the filters
  for (var filterExpr in filters) {
    var filter = eval(filterExpr, scope);
    if (filter is! Transformer) {
      throw new EvalException("filter must implement Transformer: $filterExpr");
    }
    value = filter.reverse(value);
  }
  // make the assignment
  var o = eval(expression, scope);
  if (o == null) throw new EvalException("Can't assign to null: $expression");
  if (isIndex) {
    o[property] = value;
  } else {
    reflect(o).setField(new Symbol(property), value);
  }
}

/**
 * A mapping of names to objects. Scopes contain a set of named [variables] and
 * a single [model] object (which can be thought of as the "this" reference).
 * Names are currently looked up in [variables] first, then the [model].
 *
 * Scopes can be nested by giving them a [parent]. If a name in not found in a
 * Scope, it will look for it in it's parent.
 */
class Scope {
  final Scope parent;
  final Object model;
  // TODO(justinfagnani): disallow adding/removing names
  final ObservableMap<String, Object> _variables;
  InstanceMirror __modelMirror;

  Scope({this.model, Map<String, Object> variables, this.parent})
      : _variables = new ObservableMap.from(variables == null ? {} : variables);

  InstanceMirror get _modelMirror {
    if (__modelMirror != null) return __modelMirror;
    __modelMirror = reflect(model);
    return __modelMirror;
  }

  Object operator[](String name) {
    if (name == 'this') {
      return model;
    } else if (_variables.containsKey(name)) {
      return _convert(_variables[name]);
    } else if (model != null) {
      var symbol = new Symbol(name);
      var classMirror = _modelMirror.type;
      var memberMirror = getMemberMirror(classMirror, symbol);
      // TODO(jmesserly): simplify once dartbug.com/13002 is fixed.
      // This can just be "if memberMirror != null" and delete the Method class.
      if (memberMirror is VariableMirror ||
          (memberMirror is MethodMirror && memberMirror.isGetter)) {
        return _convert(_modelMirror.getField(symbol).reflectee);
      } else if (memberMirror is MethodMirror) {
        return new Method(_modelMirror, symbol);
      }
    }
    if (parent != null) {
      return _convert(parent[name]);
    } else {
      throw new EvalException("variable '$name' not found");
    }
  }

  Object ownerOf(String name) {
    if (name == 'this') {
      // we could return the Scope if it were Observable, but since assigning
      // a model to a template destroys and recreates the instance, it doesn't
      // seem neccessary
      return null;
    } else if (_variables.containsKey(name)) {
      return _variables;
    } else {
      var symbol = new Symbol(name);
      var classMirror = _modelMirror.type;
      if (getMemberMirror(classMirror, symbol) != null) {
        return model;
      }
    }
    if (parent != null) {
      return parent.ownerOf(name);
    }
  }

  bool contains(String name) {
    if (_variables.containsKey(name)) {
      return true;
    } else {
      var symbol = new Symbol(name);
      var classMirror = _modelMirror.type;
      if (getMemberMirror(classMirror, symbol) != null) {
        return true;
      }
    }
    if (parent != null) {
      return parent.contains(name);
    }
    return false;
  }
}

Object _convert(v) {
  if (v is Stream) return new StreamBinding(v);
  return v;
}

abstract class ExpressionObserver<E extends Expression> implements Expression {
  final E _expr;
  ExpressionObserver _parent;

  StreamSubscription _subscription;
  Object _value;

  StreamController _controller = new StreamController.broadcast();
  Stream get onUpdate => _controller.stream;

  ExpressionObserver(this._expr);

  Object get currentValue => _value;

  update(Scope scope) => _updateSelf(scope);

  _updateSelf(Scope scope) {}

  _invalidate(Scope scope) {
    _observe(scope);
    if (_parent != null) {
      _parent._invalidate(scope);
    }
  }

  _observe(Scope scope) {
    // unobserve last value
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    var _oldValue = _value;

    // evaluate
    _updateSelf(scope);

    if (!identical(_value, _oldValue)) {
      _controller.add(_value);
    }
  }

  String toString() => _expr.toString();
}

class Updater extends RecursiveVisitor {
  final Scope scope;

  Updater(this.scope);

  visitExpression(ExpressionObserver e) {
    e._observe(scope);
  }

  visitInExpression(InObserver c) {
    visit(c.right);
    visitExpression(c);
  }
}

class ObserverBuilder extends Visitor {
  final Scope scope;
  final Queue parents = new Queue();

  ObserverBuilder(this.scope);

  visitEmptyExpression(EmptyExpression e) => new EmptyObserver(e);

  visitParenthesizedExpression(ParenthesizedExpression e) => visit(e.child);

  visitGetter(Getter g) {
    var receiver = visit(g.receiver);
    var getter = new GetterObserver(g, receiver);
    receiver._parent = getter;
    return getter;
  }

  visitIndex(Index i) {
    var receiver = visit(i.receiver);
    var arg = visit(i.argument);
    var index =  new IndexObserver(i, receiver, arg);
    receiver._parent = index;
    arg._parent = index;
    return index;
  }

  visitInvoke(Invoke i) {
    var receiver = visit(i.receiver);
    var args = (i.arguments == null)
        ? null
        : i.arguments.map(visit).toList(growable: false);
    var invoke =  new InvokeObserver(i, receiver, args);
    receiver._parent = invoke;
    if (args != null) args.forEach((a) => a._parent = invoke);
    return invoke;
  }

  visitLiteral(Literal l) => new LiteralObserver(l);

  visitMapLiteral(MapLiteral l) {
    var entries = l.entries.map(visit).toList(growable: false);
    var map = new MapLiteralObserver(l, entries);
    entries.forEach((e) => e._parent = map);
    return map;
  }

  visitMapLiteralEntry(MapLiteralEntry e) {
    var key = visit(e.key);
    var value = visit(e.entryValue);
    var entry = new MapLiteralEntryObserver(e, key, value);
    key._parent = entry;
    value._parent = entry;
    return entry;
  }

  visitIdentifier(Identifier i) => new IdentifierObserver(i);

  visitBinaryOperator(BinaryOperator o) {
    var left = visit(o.left);
    var right = visit(o.right);
    var binary = new BinaryObserver(o, left, right);
    left._parent = binary;
    right._parent = binary;
    return binary;
  }

  visitUnaryOperator(UnaryOperator o) {
    var expr = visit(o.child);
    var unary = new UnaryObserver(o, expr);
    expr._parent = unary;
    return unary;
  }

  visitInExpression(InExpression i) {
    // don't visit the left. It's an identifier, but we don't want to evaluate
    // it, we just want to add it to the comprehension object
    var left = visit(i.left);
    var right = visit(i.right);
    var inexpr = new InObserver(i, left, right);
    right._parent = inexpr;
    return inexpr;
  }
}

class EmptyObserver extends ExpressionObserver<EmptyExpression>
    implements EmptyExpression {

  EmptyObserver(EmptyExpression value) : super(value);

  _updateSelf(Scope scope) {
    _value = scope.model;
    // TODO(justin): listen for scope.model changes?
  }

  accept(Visitor v) => v.visitEmptyExpression(this);
}

class LiteralObserver extends ExpressionObserver<Literal> implements Literal {

  LiteralObserver(Literal value) : super(value);

  dynamic get value => _expr.value;

  _updateSelf(Scope scope) {
    _value = _expr.value;
  }

  accept(Visitor v) => v.visitLiteral(this);
}

class MapLiteralObserver extends ExpressionObserver<MapLiteral>
    implements MapLiteral {

  final List<MapLiteralEntryObserver> entries;

  MapLiteralObserver(MapLiteral value, this.entries) : super(value);

  _updateSelf(Scope scope) {
    _value = entries.fold(new Map(),
        (m, e) => m..[e.key._value] = e.entryValue._value);
  }

  accept(Visitor v) => v.visitMapLiteral(this);
}

class MapLiteralEntryObserver extends ExpressionObserver<MapLiteralEntry>
    implements MapLiteralEntry {

  final LiteralObserver key;
  final ExpressionObserver entryValue;

  MapLiteralEntryObserver(MapLiteralEntry value, this.key, this.entryValue)
      : super(value);

  accept(Visitor v) => v.visitMapLiteralEntry(this);
}

class IdentifierObserver extends ExpressionObserver<Identifier>
    implements Identifier {

  IdentifierObserver(Identifier value) : super(value);

  String get value => _expr.value;

  _updateSelf(Scope scope) {
    _value = scope[value];

    var owner = scope.ownerOf(value);
    if (owner is Observable) {
      var symbol = new Symbol(value);
      _subscription = (owner as Observable).changes.listen((changes) {
        if (changes.any(
            (c) => c is PropertyChangeRecord && c.name == symbol)) {
          _invalidate(scope);
        }
      });
    }
  }

  accept(Visitor v) => v.visitIdentifier(this);
}

class ParenthesizedObserver extends ExpressionObserver<ParenthesizedExpression>
    implements ParenthesizedExpression {
  final ExpressionObserver child;

  ParenthesizedObserver(ParenthesizedExpression expr, this.child) : super(expr);


  _updateSelf(Scope scope) {
    _value = child._value;
  }

  accept(Visitor v) => v.visitParenthesizedExpression(this);
}

class UnaryObserver extends ExpressionObserver<UnaryOperator>
    implements UnaryOperator {
  final ExpressionObserver child;

  UnaryObserver(UnaryOperator expr, this.child) : super(expr);

  String get operator => _expr.operator;

  _updateSelf(Scope scope) {
    var f = _UNARY_OPERATORS[_expr.operator];
    if (operator == '!') {
      _value = f(_toBool(child._value));
    } else {
      _value = (child._value == null) ? null : f(child._value);
    }
  }

  accept(Visitor v) => v.visitUnaryOperator(this);
}

class BinaryObserver extends ExpressionObserver<BinaryOperator>
    implements BinaryOperator {

  final ExpressionObserver left;
  final ExpressionObserver right;

  BinaryObserver(BinaryOperator expr, this.left, this.right)
      : super(expr);

  String get operator => _expr.operator;

  _updateSelf(Scope scope) {
    var f = _BINARY_OPERATORS[operator];
    if (operator == '&&' || operator == '||') {
      _value = f(_toBool(left._value), _toBool(right._value));
    } else if (operator == '==' || operator == '!=') {
      _value = f(left._value, right._value);
    } else if (left._value == null || right._value == null) {
      _value = null;
    } else {
      if (operator == '|' && left._value is ObservableList) {
        _subscription = (left._value as ObservableList).listChanges
            .listen((_) => _invalidate(scope));
      }
      _value = f(left._value, right._value);
    }
  }

  accept(Visitor v) => v.visitBinaryOperator(this);

}

class GetterObserver extends ExpressionObserver<Getter> implements Getter {
  final ExpressionObserver receiver;

  GetterObserver(Expression expr, this.receiver) : super(expr);

  String get name => _expr.name;

  _updateSelf(Scope scope) {
    var receiverValue = receiver._value;
    if (receiverValue == null) {
      _value = null;
      return;
    }
    var mirror = reflect(receiverValue);
    var symbol = new Symbol(_expr.name);
    _value = mirror.getField(symbol).reflectee;

    if (receiverValue is Observable) {
      _subscription = (receiverValue as Observable).changes.listen((changes) {
        if (changes.any((c) => c is PropertyChangeRecord && c.name == symbol)) {
          _invalidate(scope);
        }
      });
    }
  }

  accept(Visitor v) => v.visitGetter(this);
}

class IndexObserver extends ExpressionObserver<Index> implements Index {
  final ExpressionObserver receiver;
  final ExpressionObserver argument;

  IndexObserver(Expression expr, this.receiver, this.argument) : super(expr);

  _updateSelf(Scope scope) {
    var receiverValue = receiver._value;
    if (receiverValue == null) {
      _value = null;
      return;
    }
    var key = argument._value;
    _value = receiverValue[key];

    if (receiverValue is Observable) {
      _subscription = (receiverValue as Observable).changes.listen((changes) {
        if (changes.any((c) => c is MapChangeRecord && c.key == key)) {
          _invalidate(scope);
        }
      });
    }
  }

  accept(Visitor v) => v.visitIndex(this);
}

class InvokeObserver extends ExpressionObserver<Invoke> implements Invoke {
  final ExpressionObserver receiver;
  final List<ExpressionObserver> arguments;

  InvokeObserver(Expression expr, this.receiver, this.arguments)
      : super(expr) {
    assert(arguments != null);
  }

  String get method => _expr.method;

  _updateSelf(Scope scope) {
    var args = arguments.map((a) => a._value).toList();
    var receiverValue = receiver._value;
    if (receiverValue == null) {
      _value = null;
      return;
    }
    if (_expr.method == null) {
      // top-level function or model method
      // TODO(justin): listen to model changes to see if the method has
      // changed? listen to the scope to see if the top-level method has
      // changed?
      assert(receiverValue is Function);
      _value = call(receiverValue, args);
    } else {
      var mirror = reflect(receiverValue);
      var symbol = new Symbol(_expr.method);
      _value = mirror.invoke(symbol, args, null).reflectee;

      if (receiverValue is Observable) {
        _subscription = (receiverValue as Observable).changes.listen(
            (List<ChangeRecord> changes) {
              if (changes.any(
                  (c) => c is PropertyChangeRecord && c.name == symbol)) {
                _invalidate(scope);
              }
            });
      }
    }
  }

  accept(Visitor v) => v.visitInvoke(this);
}

class InObserver extends ExpressionObserver<InExpression>
    implements InExpression {
  IdentifierObserver left;
  ExpressionObserver right;

  InObserver(Expression expr, this.left, this.right) : super(expr);

  _updateSelf(Scope scope) {
    Identifier identifier = left;
    var iterable = right._value;

    if (iterable is! Iterable && iterable != null) {
      throw new EvalException("right side of 'in' is not an iterator");
    }

    if (iterable is ObservableList) {
      _subscription = iterable.listChanges.listen((_) => _invalidate(scope));
    }

    // TODO: make Comprehension observable and update it
    _value = new Comprehension(identifier.value, iterable);
  }

  accept(Visitor v) => v.visitInExpression(this);
}

_toBool(v) => (v == null) ? false : v;

/** Call a [Function] or a [Method]. */
// TODO(jmesserly): remove this once dartbug.com/13002 is fixed.
// Just inline `_convert(Function.apply(...))` to the call site.
Object call(Object receiver, List args) {
  var result;
  if (receiver is Method) {
    Method method = receiver;
    result = method.mirror.invoke(method.symbol, args, null).reflectee;
  } else {
    result = Function.apply(receiver, args, null);
  }
  return _convert(result);
}

/**
 * A comprehension declaration ("a in b"). [identifier] is the loop variable
 * that's added to the scope during iteration. [iterable] is the set of
 * objects to iterate over.
 */
class Comprehension {
  final String identifier;
  final Iterable iterable;

  Comprehension(this.identifier, Iterable iterable)
      : iterable = (iterable != null) ? iterable : const [];
}

/** A method on a model object in a [Scope]. */
class Method {
  final InstanceMirror mirror;
  final Symbol symbol;

  Method(this.mirror, this.symbol);

  /**
   * Support for calling single argument methods like [Filter]s.
   * This does not work for calls that need to pass more than one argument.
   */
  call(arg0) => mirror.invoke(symbol, [arg0], null).reflectee;
}

class EvalException implements Exception {
  final String message;
  EvalException(this.message);
  String toString() => "EvalException: $message";
}
