// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.eval;

import 'dart:async';
import 'dart:collection';

import 'package:observe/observe.dart';
import 'package:smoke/smoke.dart' as smoke;

import 'async.dart';
import 'expression.dart';
import 'filter.dart';
import 'visitor.dart';

final _BINARY_OPERATORS = {
  '+':   (a, b) => a + b,
  '-':   (a, b) => a - b,
  '*':   (a, b) => a * b,
  '/':   (a, b) => a / b,
  '%':   (a, b) => a % b,
  '==':  (a, b) => a == b,
  '!=':  (a, b) => a != b,
  '===': (a, b) => identical(a, b),
  '!==': (a, b) => !identical(a, b),
  '>':   (a, b) => a > b,
  '>=':  (a, b) => a >= b,
  '<':   (a, b) => a < b,
  '<=':  (a, b) => a <= b,
  '||':  (a, b) => a || b,
  '&&':  (a, b) => a && b,
  '|':   (a, f) {
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
Object eval(Expression expr, Scope scope) => new EvalVisitor(scope).visit(expr);

/**
 * Returns an [ExpressionObserver] that evaluates [expr] in the context of
 * scope] and listens for any changes on [Observable] values that are
 * returned from sub-expressions. When a value changes the expression is
 * reevaluated and the new result is sent to the [onUpdate] stream of the
 * [ExpressionObsserver].
 */
ExpressionObserver observe(Expression expr, Scope scope) {
  var observer = new ObserverBuilder().visit(expr);
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
Object assign(Expression expr, Object value, Scope scope,
    {bool checkAssignability: true}) {

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
    property = expr.value;
  } else if (expr is Index) {
    expression = expr.receiver;
    property = expr.argument;
    isIndex = true;
  } else if (expr is Getter) {
    expression = expr.receiver;
    property = expr.name;
  } else {
    if (checkAssignability) {
      throw new EvalException("Expression is not assignable: $expr");
    }
    return null;
  }

  // transform the values backwards through the filters
  for (var filterExpr in filters) {
    var filter = eval(filterExpr, scope);
    if (filter is! Transformer) {
      if (checkAssignability) {
        throw new EvalException("filter must implement Transformer to be "
            "assignable: $filterExpr");
      } else {
        return null;
      }
    }
    value = filter.reverse(value);
  }
  // evaluate the receiver
  var o = eval(expression, scope);

  // can't assign to a property on a null LHS object. Silently fail.
  if (o == null) return null;

  if (isIndex) {
    var index = eval(property, scope);
    o[index] = value;
  } else {
    smoke.write(o, smoke.nameToSymbol(property), value);
  }
  return value;
}


/**
 * A scope in polymer expressions that can map names to objects. Scopes contain
 * a set of named variables and a unique model object. The scope structure
 * is then used to lookup names using the `[]` operator. The lookup first
 * searches for the name in local variables, then in global variables,
 * and then finally looks up the name as a property in the model.
 */
abstract class Scope implements Indexable<String, Object> {
  static int __seq = 1;
  final int _seq = __seq++;

  Scope._();

  /** Create a scope containing a [model] and all of [variables]. */
  factory Scope({Object model, Map<String, Object> variables}) {
    var scope = new _ModelScope(model);
    return variables == null ? scope
        : new _GlobalsScope(new Map<String, Object>.from(variables), scope);
  }

  /** Return the unique model in this scope. */
  Object get model;

  /**
   * Lookup the value of [name] in the current scope. If [name] is 'this', then
   * we return the [model]. For any other name, this finds the first variable
   * matching [name] or, if none exists, the property [name] in the [model].
   */
  Object operator [](String name);

  operator []=(String name, Object value) {
    throw new UnsupportedError('[]= is not supported in Scope.');
  }

  /**
   * Returns whether [name] is defined in [model], that is, a lookup
   * would not find a variable with that name, but there is a non-null model
   * where we can look it up as a property.
   */
  bool _isModelProperty(String name);

  /** Create a new scope extending this scope with an additional variable. */
  Scope childScope(String name, Object value) =>
      new _LocalVariableScope(name, value, this);

  String toString() => 'Scope(seq: $_seq model: $model)';

}

/**
 * A scope that looks up names in a model object. This kind of scope has no
 * parent scope because all our lookup operations stop when we reach the model
 * object. Any variables added in scope or global variables are added as child
 * scopes.
 */
class _ModelScope extends Scope {
  final Object model;

  _ModelScope(this.model) : super._();

  Object operator[](String name) {
    if (name == 'this') return model;
    var symbol = smoke.nameToSymbol(name);
    if (model == null || symbol == null) {
      throw new EvalException("variable '$name' not found");
    }
    return _convert(smoke.read(model, symbol));
  }

  Object _isModelProperty(String name) => name != 'this';

  String toString() => "[model: $model]";
}

/**
 * A scope that holds a reference to a single variable. Polymer expressions
 * introduce variables to the scope one at a time. Each time a variable is
 * added, a new [_LocalVariableScope] is created.
 */
class _LocalVariableScope extends Scope {
  final Scope parent;
  final String varName;
  // TODO(sigmund,justinfagnani): make this @observable?
  final Object value;

  _LocalVariableScope(this.varName, this.value, this.parent) : super._() {
    if (varName == 'this') {
      throw new EvalException("'this' cannot be used as a variable name.");
    }
  }

  Object get model => parent != null ? parent.model : null;

  Object operator[](String name) {
    if (varName == name) return _convert(value);
    if (parent != null) return parent[name];
    throw new EvalException("variable '$name' not found");
  }

  bool _isModelProperty(String name) {
    if (varName == name) return false;
    return parent == null ? false : parent._isModelProperty(name);
  }

  String toString() => "$parent > [local: $varName]";
}

/** A scope that holds a reference to a global variables. */
class _GlobalsScope extends Scope {
  final _ModelScope parent;
  final Map<String, Object> variables;

  _GlobalsScope(this.variables, this.parent) : super._() {
    if (variables.containsKey('this')) {
      throw new EvalException("'this' cannot be used as a variable name.");
    }
  }

  Object get model => parent != null ? parent.model : null;

  Object operator[](String name) {
    if (variables.containsKey(name)) return _convert(variables[name]);
    if (parent != null) return parent[name];
    throw new EvalException("variable '$name' not found");
  }

  bool _isModelProperty(String name) {
    if (variables.containsKey(name)) return false;
    return parent == null ? false : parent._isModelProperty(name);
  }

  String toString() => "$parent > [global: ${variables.keys}]";
}

Object _convert(v) => v is Stream ? new StreamBinding(v) : v;

abstract class ExpressionObserver<E extends Expression> implements Expression {
  final E _expr;
  ExpressionObserver _parent;

  StreamSubscription _subscription;
  Object _value;

  StreamController _controller = new StreamController.broadcast();
  Stream get onUpdate => _controller.stream;

  ExpressionObserver(this._expr);

  Expression get expression => _expr;

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
}

class EvalVisitor extends Visitor {
  final Scope scope;

  EvalVisitor(this.scope);

  visitEmptyExpression(EmptyExpression e) => scope.model;

  visitParenthesizedExpression(ParenthesizedExpression e) => visit(e.child);

  visitGetter(Getter g) {
    var receiver = visit(g.receiver);
    if (receiver == null) return null;
    var symbol = smoke.nameToSymbol(g.name);
    return smoke.read(receiver, symbol);
  }

  visitIndex(Index i) {
    var receiver = visit(i.receiver);
    if (receiver == null) return null;
    var key = visit(i.argument);
    return receiver[key];
  }

  visitInvoke(Invoke i) {
    var receiver = visit(i.receiver);
    if (receiver == null) return null;
    var args = (i.arguments == null)
        ? null
        : i.arguments.map(visit).toList(growable: false);

    if (i.method == null) {
      assert(receiver is Function);
      return Function.apply(receiver, args);
    }

    var symbol = smoke.nameToSymbol(i.method);
    return smoke.invoke(receiver, symbol, args);
  }

  visitLiteral(Literal l) => l.value;

  visitListLiteral(ListLiteral l) => l.items.map(visit).toList();

  visitMapLiteral(MapLiteral l) {
    var map = {};
    for (var entry in l.entries) {
      var key = visit(entry.key);
      var value = visit(entry.entryValue);
      map[key] = value;
    }
    return map;
  }

  visitMapLiteralEntry(MapLiteralEntry e) =>
      throw new UnsupportedError("should never be called");

  visitIdentifier(Identifier i) => scope[i.value];

  visitBinaryOperator(BinaryOperator o) {
    var operator = o.operator;
    var left = visit(o.left);
    var right = visit(o.right);

    var f = _BINARY_OPERATORS[operator];
    if (operator == '&&' || operator == '||') {
      // TODO: short-circuit
      return f(_toBool(left), _toBool(right));
    } else if (operator == '==' || operator == '!=') {
      return f(left, right);
    } else if (left == null || right == null) {
      return null;
    }
    return f(left, right);
  }

  visitUnaryOperator(UnaryOperator o) {
    var expr = visit(o.child);
    var f = _UNARY_OPERATORS[o.operator];
    if (o.operator == '!') {
      return f(_toBool(expr));
    }
    return (expr == null) ? null : f(expr);
  }

  visitTernaryOperator(TernaryOperator o) =>
      visit(o.condition) == true ? visit(o.trueExpr) : visit(o.falseExpr);

  visitInExpression(InExpression i) =>
      throw new UnsupportedError("can't eval an 'in' expression");

  visitAsExpression(AsExpression i) =>
      throw new UnsupportedError("can't eval an 'as' expression");
}

class ObserverBuilder extends Visitor {
  final Queue parents = new Queue();

  ObserverBuilder();

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

  visitListLiteral(ListLiteral l) {
    var items = l.items.map(visit).toList(growable: false);
    var list = new ListLiteralObserver(l, items);
    items.forEach((e) => e._parent = list);
    return list;
  }

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

  visitTernaryOperator(TernaryOperator o) {
    var condition = visit(o.condition);
    var trueExpr = visit(o.trueExpr);
    var falseExpr = visit(o.falseExpr);
    var ternary = new TernaryObserver(o, condition, trueExpr, falseExpr);
    condition._parent = ternary;
    trueExpr._parent = ternary;
    falseExpr._parent = ternary;
    return ternary;
  }

  visitInExpression(InExpression i) {
    throw new UnsupportedError("can't eval an 'in' expression");
  }

  visitAsExpression(AsExpression i) {
    throw new UnsupportedError("can't eval an 'as' expression");
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

class ListLiteralObserver extends ExpressionObserver<ListLiteral>
    implements ListLiteral {

  final List<ExpressionObserver> items;

  ListLiteralObserver(ListLiteral value, this.items) : super(value);

  _updateSelf(Scope scope) {
    _value = items.map((i) => i._value).toList();
  }

  accept(Visitor v) => v.visitListLiteral(this);
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
    if (!scope._isModelProperty(value)) return;
    var model = scope.model;
    if (model is! Observable) return;
    var symbol = smoke.nameToSymbol(value);
    _subscription = (model as Observable).changes.listen((changes) {
      if (changes.any((c) => c is PropertyChangeRecord && c.name == symbol)) {
        _invalidate(scope);
      }
    });
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

class TernaryObserver extends ExpressionObserver<TernaryOperator>
    implements TernaryOperator {

  final ExpressionObserver condition;
  final ExpressionObserver trueExpr;
  final ExpressionObserver falseExpr;

  TernaryObserver(TernaryOperator expr, this.condition, this.trueExpr,
      this.falseExpr) : super(expr);

  _updateSelf(Scope scope) {
    _value = _toBool(condition._value) ? trueExpr._value : falseExpr._value;
  }

  accept(Visitor v) => v.visitTernaryOperator(this);

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
    var symbol = smoke.nameToSymbol(_expr.name);
    _value = smoke.read(receiverValue, symbol);

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

    if (receiverValue is ObservableList) {
      _subscription = (receiverValue as ObservableList).listChanges
          .listen((changes) {
        if (changes.any((c) => c.indexChanged(key))) _invalidate(scope);
      });
    } else if (receiverValue is Observable) {
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
      _value = _convert(Function.apply(receiverValue, args));
    } else {
      var symbol = smoke.nameToSymbol(_expr.method);
      _value = smoke.invoke(receiverValue, symbol, args);

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

_toBool(v) => (v == null) ? false : v;

class EvalException implements Exception {
  final String message;
  EvalException(this.message);
  String toString() => "EvalException: $message";
}
